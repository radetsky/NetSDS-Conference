#===============================================================================
#
#         FILE:  ConferenceMan.pm
#
#  DESCRIPTION:  Conference Manager for each conference in NetSDS-Conference package :)
#
#        NOTES:  ---
#       AUTHOR:  Alex Radetsky (Rad), <rad@rad.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.0
#      CREATED:  18.10.10
#===============================================================================

=head1 ConferenceMan

NetSDS::App::ConferenceMan

=head1 DESCRIPTION

ConferenceMan contains package w

=cut

package NetSDS::App::ConferenceMan;

use 5.8.0;
use strict;
use warnings;

use Data::Dumper;
use Date::Manip;
use Sys::Proctitle qw/:all/;
use Time::HiRes qw/usleep/;
use NetSDS::Asterisk::Originator;
use NetSDS::Asterisk::EventListener; 
use NetSDS::Konference;


use base qw(NetSDS::App);

use version; our $VERSION = "0.01";
our @EXPORT_OK = qw();

#-----------------------------------------------------------------------

=item B<start> - Получает свойства конференции, записывает в БД что конференция отныне активна и выславляет next_start  в NULL. Вычисление следущего раза не здесь. 
Если в свойствах конференции указан автосбор, делает первую попытку собрать абонентов. 

TODO: Проверить запись и начать запись 
=cut 

sub start {
    my $this = shift;


    $SIG{INT} = sub {
        warn "[$$] SIGINT caught";
        exit(1);
    };

    $SIG{TERM} = sub {
        warn "[$$] SIGTERM caught";
        exit(1);
    };

    setproctitle( "ConferenceMan (" . $this->{'konf'}->{'cnfr_id'} . ")" );

    $this->mk_accessors('mydb');
    $this->mydb( ConferenceDB->new() );

    # Для отслеживания активных аинхронных запросов
    $this->mk_accessors('manager_queries');
    $this->manager_queries({});  

    $this->speak( "[$$] ConferenceMan start with conference ID: "
          . $this->{'konf'}->{'cnfr_id'} );

    # Getting properties of my conference
    my $konf = $this->{'konf'};

    # Setting in memory last start timestamp
    $this->{'konf'}->{'date_started'} = time();

    # Restoring control process. Do not update database.
    if ( defined( $this->{'restore'} ) and $this->{'restore'} == 1 ) {

        # Just process (control) it.
        return 1;
    }

    # Set active flag,
    # Set next_start to NULL,
    # Set Last_start to now()
    my $res = $this->mydb->cnfr_update(
        $konf->{'cnfr_id'},
        {
            cnfr_state => '\'active\'',
            next_start => 'NULL',
            last_start => 'now()'
        }
    );

    $this->{'konf'}->{'last_start'} =
      POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );

    unless ( defined($res) ) {
        $this->speak(
            "[$$] Fail to update database while starting the conference.");
    }
    else {
        $this->speak(
            "[$$] Database updated sucessfully while starting the conference.");
    }

    # If we have to make self-connection to users, just to it.

    if (    defined( $konf->{'auto_assemble'} )
        and ( $konf->{'auto_assemble'} ne '' )
        and $konf->{'auto_assemble'} == 1 )
    {

        # Get list of members
        $this->speak( "[$$] Conference ID "
              . $konf->{'cnfr_id'}
              . " have AA attribute." );
        my @phones = $this->_getPhones( $konf->{'cnfr_id'} );
        $this->_start_assemble( $konf->{'cnfr_id'}, @phones );
    }

    if (    defined( $konf->{'need_record'} )
        and ( $konf->{'need_record'} )
        and ( $konf->{'need_record'} == 1 ) )
    {

        # Start recording conference

        $this->speak("[$$] Start Recording conference");
        $this->_start_record( $konf->{'cnfr_id'} );
    }

}

sub _getPhones {
    my ( $this, $konf_id ) = @_;
    my @dsts;
    my %members = $this->mydb->get_cnfr_participants($konf_id);
    foreach my $memberid ( keys %members ) {
        $this->speak( "[$$] Will call to: " . $members{$memberid}{'number'} );
        push @dsts, $members{$memberid}{'number'};
    }
    return @dsts;

}

sub _start_assemble {
    my ( $this, $konf_id, @phones ) = @_;

    # we have a list to originate. Start it. and Return to KONF_ID in asterisk.
    foreach my $dst (@phones) {
        my $orig = NetSDS::Asterisk::Originator->new(
            destination    => $dst,
            callerid       => '0445930143',
            return_context => 'NetSDS-Conference-Outgoing',
            variables      => 'KONFNUM=' . $konf_id,
            channel        => sprintf( "SIP/%s@%s", $dst, "softswitch" ),
        );
        my $reply =
          $orig->originate( '127.0.0.1', '5038', 'asterikastwww',
            'asterikastwww' );
        unless ( defined($reply) ) {
            $this->speak("[$$] Originate to $dst failed.");
        }
    }
}

sub _start_record {
    my ( $this, $konf_id ) = @_;

    # Originate call with two local channels.
    my $orig = NetSDS::Asterisk::Originator->new(
        destination    => $konf_id,
        callerid       => '0445930143',
        return_context => 'NetSDS-Conference-Outgoing',
        variables      => 'KONFNUM=' . $konf_id,
        channel        => "Local/" . $konf_id . "\@NetSDS-Conference-Record"
    );
    my $reply =
      $orig->originate( '127.0.0.1', '5038', 'asterikastwww', 'asterikastwww' );

    unless ( defined($reply) ) {
        $this->speak("[$$] Originate for Record failed.");
    }
    else {
        $this->speak("[$$] Originate for Record OK.");
    }

}

sub process {
    my $this = shift;
    $this->speak("[$$] ConferenceMan process.");
    my $conf_id = $this->{'konf'}->{'cnfr_id'};

	# 
	# Инициализация чтения событий из астериска 
	# Log in 
	#
	my $event_listener = NetSDS::Asterisk::EventListener->new( 
		host => '127.0.0.1',
		port => '5038',
		username =>  'asterikastwww',
		secret =>  'asterikastwww'
	);

	$event_listener->_connect(); 
	my $prev_time = time; 

    while (1) {

# Читаем события 
# Фильтруем события
		my $event = $event_listener->_getEvent(); 
		unless ( $event ) { 
			my $time = time; 
			if ($time > $prev_time) { 
				$prev_time = $time;
				goto check_stop;
			}
			$prev_time = $time;
			usleep(500);
			next;
		}
	
#		warn Dumper ($event); 	

		if ($event->{'Event'} =~ /ConferenceDTMF/i ) { 
# ConferenceName: 4 
# Type: konference
# Channel: SIP/blablabla
# CallerID: 0445949641 
# Key: *(0,1,2...)
# Mute: 0 
			if ($event->{'Type'} =~ /konference/i ) { 
				if ( $event->{'ConferenceName'} == $conf_id ) {
					my $channel = $event->{'Channel'}; 
					my $key = $event->{'Key'}; 
					my $mute = $event->{'Mute'}; 
					my $callerid = $event->{'CallerID'}; 
					my $rc = $this->_DTMF ($channel, $key, $mute, $callerid,$conf_id); 
					if ($rc == 2) {  # Stop the conference
						return 1; 
					}
					
				}
			}
		} 

		if ($event->{'Event'} =~ /ConferenceLeave/i ) { 
		  if ($event->{'Type'} =~ /konference/i ) { 
		    if ($event->{'ConferenceName'} == $conf_id ) { 
# Кто-то пожелал покинуть конференцию.  
# Если установлен атрибут контроля потери, то дозвониться Х раз. 
			if ( defined( $this->{'konf'}->{'lost_control'} )
			        and ( $this->{'konf'}->{'lost_control'} )
			        and ( $this->{'konf'}->{'lost_control'} == 1 ) ) {   
				
				my $destination = $event->{'CallerID'}; 

				$this->speak("[$$] $destination leaves the conference #".$conf_id); 
			        $this->_restore_control($destination,$conf_id);

			}
		     } 
		   }
		}

		if ($event->{'Event'} =~ /ConferenceJoin/i ) { 
		  warn Dumper ($event); 
		  if ($event->{'Type'} =~ /konference/i ) {
                    if ( $event->{'ConferenceName'} eq $conf_id ) { 
		    	my $callerid = $event->{'CallerID'}; 
		    	$this->speak("[$$] $callerid has joined the conference #".$event->{'ConferenceName'}); 
		    }
		  } 
                }

# Мы к кому-то дозвонились. Если была поставлена задача дозвониться, 
# То мы таки дозваниваемся. Попыток пока по-умолчанию 5. 
# FIXME: вынести количество попыток в конфиг 

		if ( $event->{'Event'} =~ /OriginateResponse/i ) {
			if ( $event->{'Response'} =~ /Failure/i ) { 
				my $destination = $event->{'ActionID'}; 
				my $restore_konf = $this->manager_queries->{$destination}->{'cnfr_id'};
				unless ( defined ( $restore_konf ) ) { 
					# Не текущий процесс. Оставим другим. 
					next; 
				} 
				
				$this->speak("[$$] Retrying to restore link with $destination");  
				$this->_restore_control($destination,$restore_konf); 
			}
			if ( $event->{'Response'} =~ /Success/i  ) {
				my $destination = $event->{'ActionID'}; 
				unless ( defined ( $destination ) ) { 
					# Это может быть запись. Если нет ActionID, ну и фигсним.
					next; 
				}
				my $restore_konf = $this->manager_queries->{$destination}->{'cnfr_id'};
                                unless ( defined ( $restore_konf ) ) {
                                        # Не текущий процесс. Оставим другим. 
                                        next;
                                }
				delete $this->manager_queries->{$destination}; 
				$this->speak("[$$] Link restored with $destination"); 
			}
		} 

 
# Определить стоп конференции / Застопать конференцию.
# Способ номер 0 - если указан next_duration ( != 00:00:00  != '' )
# Посчитать с last_started по длине next_duration и сравнить с ним

check_stop:

        my $duration = $this->{'konf'}->{'next_duration'};
        if ( defined($duration) ) {
            if ( ( $duration ne '' ) and ( $duration ne '00:00:00' ) ) {
                my $delta     = ParseDateDelta($duration);
                my $start     = ParseDate( $this->{'konf'}->{'last_start'} );
                my $next_stop = DateCalc( $start, $delta );

                unless ( defined($next_stop) ) {
                    warn Dumper( $start, $delta );
                    warn "Error occures while Date Calculating.";
                    return undef;
                }
                my $date_now = ParseDate('now');

                #warn Dumper ($date_now,$start,$delta,$next_stop);
                my $flag = Date_Cmp( $date_now, $next_stop );
                if ( $flag > 0 ) {
                    $this->speak(
                        "[$$] Stop the conference because duration time exceed."
                    );
                    return 1;
                }
                next;

            }
        }

# Способ номер 1 - получить список конференции и список будет пустой.
# Дополнительное условие - 5 минут пустой конференции.
# В понятие "пустая конференция" так же попадает ситуация с разрешенной записью и одинм
# каналом Local в ней.

        my $konf = NetSDS::Konference->new();
        $konf->konference_connect( 'localhost', '5038', 'asterikastwww',
            'asterikastwww' );
        my $members = $konf->konference_list_konf($conf_id);

        unless ( defined($members) ) {
            $this->speak("[$$] Error while getting list of members.");
            next;
        }

        if ( $members == 0 ) {

            # No more anybody AND conference length more than 5 minutes
            my $date_now     = time();
            my $date_started = $this->{'konf'}->{'date_started'};
            my $delta        = $date_now - $date_started;

            if ( $delta > 300 ) {

                # FIXME must be in config
                # Exit from main_loop means that we will stop
                $this->speak(
                    "[$$] Stop the conference because conference is empty.");
                return 1;
            }
        }

#
# Если только пишуший робот присутствует, то тоже останавливаем конференцию.
#
        my $count = keys %$members;
        if ( $count == 1 ) {
            foreach my $member ( keys %$members ) {
                my $channel = $members->{'channel'};
                if ( $channel =~ /Local/ ) {
                    $this->speak(
"[$$] Conference is empty. Only recording channel. Stopping."
                    );
                    my $date_now     = time();
                    my $date_started = $this->{'konf'}->{'date_started'};
                    my $delta        = $date_now - $date_started;

                    if ( $delta > 300 ) {

                        $this->speak(
"[$$] Stop the conference because conference is empty."
                        );
                        return 1;
                    }
                }
            }
        }
    }
}

sub stop {
    my $this = shift;

    # Stop the conference
    $this->speak( "[$$] Stop the conference: " . $this->{'konf'}->{'cnfr_id'} );
    $this->log( "info",
        "Stop the conference: " . $this->{'konf'}->{'cnfr_id'} );

    #
    # Update Database
    #
    my $res = $this->mydb->cnfr_update(
        $this->{'konf'}->{'cnfr_id'},
        {
            cnfr_state => '\'inactive\'',
            last_end   => 'now()'
        }
    );

    #
    # Kick all members
    #

    my $konf = NetSDS::Konference->new();
    $konf->konference_connect( 'localhost', '5038', 'asterikastwww',
        'asterikastwww' );

    my $members = $konf->konference_list_konf( $this->{'konf'}->{'cnfr_id'} );

    if ( ( defined($members) ) and $members != 0 ) {
        foreach my $member ( keys %$members ) {
            my $res =
              $konf->konference_kick( $this->{'konf'}->{'cnfr_id'}, $member );
            unless ( defined($res) ) {
                $this->speak( "[$$] Kicking '" . $member
                      . "' from Konference '"
                      . $this->{'konf'}->{'cnfr_id'}
                      . "' failed." );
            }
            else {
                $this->speak( "[$$] Member '" . $member . "' kicked." );
            }
        }
    }

}

sub _DTMF { 
    my ($this, $channel, $key, $mute, $callerid,$conf_id ) = @_; 

    my $menu = 'conf-usermenu-162'; 
    my $gimme = 'conf-give-me-a-chance'; 

    my $konf = NetSDS::Konference->new();
    $konf->konference_connect( 'localhost', '5038', 'asterikastwww',
        'asterikastwww' );

# Menu
    if ($key eq '*') {
	# konference play sound <channel> <sound> mute 
            my $res = $konf->konference_playsound ($channel,$menu);
            unless ( defined ( $res ) ) { 
		$this->speak("[$$] Playing $menu to $channel FAILED"); 
	    } else { 
		$this->speak("[$$] Playing $menu to $channel SUCCESS"); 
	    }
    }

# Admin stop the konference 
 
    if ($key eq '#') { 

	my $is_operator = $this->mydb->is_operator($conf_id,$callerid); 
	unless ( defined ( $is_operator ) ) { 
		$this->speak("[$$] DB ERROR: $callerid is not operator for $conf_id"); 
		return undef; 
	} 
	unless ( $is_operator ) {  
		$this->speak("{$$] $callerid is not operator for $conf_id"); 
		return 0;
	}
 	
	return 2; 
    }



# Mute/Unmute yourself
    if ($key eq '0') { 
	if ($mute eq '0') { 
		my $res = $konf->konference_mutechannel ($channel); 
		unless ( defined ( $res  ) ) { 
			$this->speak("[$$] Mute channel $channel FAILED");
		} else { 
			$this->speak("[$$] Mute channel $channel SUCCESS");
		}
	} else { 
		my $res = $konf->konference_unmutechannel ($channel); 
		unless ( defined ( $res  ) ) { 
			$this->speak("[$$] Unmute channel $channel FAILED");
		} else { 
			$this->speak("[$$] Unmute channel $channel SUCCESS");
		}
	}
    }
	
# Admin unmute all 
    if ($key eq '1') { 

	my $is_operator = $this->mydb->is_operator($conf_id,$callerid); 
	unless ( defined ( $is_operator ) ) { 
		$this->speak("[$$] DB ERROR: $callerid is not operator for $conf_id"); 
		return undef; 
	} 
	unless ( $is_operator ) {  
		$this->speak("{$$] $callerid is not operator for $conf_id"); 
		return 0;
	}
	
	my $res = $konf->konference_unmuteconference($conf_id); 
	unless ( defined ( $res ) ) {
		$this->speak("[$$] Unmute whole conference FAILED");
	} else { 
		$this->speak("[$$] Unmute whole conference SUCCESS"); 
        }
    }

# Функция "Прошу слова". 
    if ($key eq '2') {
	my $members = $konf->konference_list_konf($conf_id);
        unless ( defined ( $members ) ) { 
		return undef;
	} 
	unless ( $members ) {
		return undef;
	}
	foreach my $member ( keys %$members ) {
	    my $channel = $members->{$member}->{'channel'}; 
            my $res = $konf->konference_playsound ($channel,$gimme);
            unless ( defined ( $res ) ) { 
		$this->speak("[$$] Playing $gimme to $channel FAILED"); 
	    } else { 
		$this->speak("[$$] Playing $gimme to $channel SUCCESS"); 
	    }
        }
    }
    if ($key eq '3') { 
	my $is_operator = $this->mydb->is_operator($conf_id,$callerid); 
	unless ( defined ( $is_operator ) ) { 
		$this->speak("[$$] DB ERROR: $callerid is not operator for $conf_id"); 
		return undef; 
	} 
	unless ( $is_operator ) { 
		$this->speak("{$$] $callerid is not operator for $conf_id"); 
		return 0;
	}

	my $res = $konf->konference_muteconference($conf_id); 
	unless ( defined ( $res ) ) {
		$this->speak("[$$] Mute whole conference FAILED");
	} else { 
		$this->speak("[$$] Mute whole conference SUCCESS"); 
        }

	$res = $konf->konference_unmutechannel( $channel); 
	unless ( defined ( $res  ) ) { 
		$this->speak("[$$] Unmute channel $channel FAILED");
	} else { 
		$this->speak("[$$] Unmute channel $channel SUCCESS");
	}

    }
    if ($key eq '4') { 

	my $res = $konf->konference_listenvolume($channel, 'down'); 
	unless ( defined ( $res ) ) {
		$this->speak("[$$] Listen volume down for $channel FAILED");
	} else { 
		$this->speak("[$$] Listen volume down for $channel SUCCESS"); 
        }

    }
    if ($key eq '5') { 

    }
    if ($key eq '6') {

	my $res = $konf->konference_listenvolume($channel, 'up'); 
	unless ( defined ( $res ) ) {
		$this->speak("[$$] Listen volume up for $channel FAILED");
	} else { 
		$this->speak("[$$] Listen volume up for $channel SUCCESS"); 
        }

    }
    if ($key eq '7') {

	my $res = $konf->konference_talkvolume ($channel, 'down'); 
 	unless ( defined ( $res ) ) {
		$this->speak("[$$] Talk volume down for $channel FAILED");
	} else { 
		$this->speak("[$$] Talk volume down for $channel SUCCESS"); 
        }


    }
    if ($key eq '8') { 

    }
    if ($key eq '9') {
	my $res = $konf->konference_talkvolume ($channel, 'up'); 
 	unless ( defined ( $res ) ) {
		$this->speak("[$$] Talk volume up for $channel FAILED");
	} else { 
		$this->speak("[$$] Talk volume up for $channel SUCCESS"); 
        }
    }


    return 1; 

}

sub _restore_control {
    my ( $this, $dst, $konf_id ) = @_;

    unless ( defined ( $this->manager_queries ) ) { 
	$this->manager_queries->{$dst} = { try => 1, ActionID=>$dst."_1" }; 
    } 
    unless ( defined ( $this->manager_queries->{$dst} ) ) { 
	$this->manager_queries->{$dst} = { try => 1, ActionID=>$dst."_1" }; 
    } 	
    my $try = 0;
    unless ( defined ( $this->manager_queries->{$dst}->{'try'} ) ) { 
	$try = 1; 
    } else { 
	$try =  $this->manager_queries->{$dst}->{'try'} + 1; 
        $this->manager_queries->{$dst}->{'try'} = $try;
        $this->manager_queries->{$dst}->{'cnfr_id'} = $konf_id;  
    }  

# Если прошло пять попыток, то нуегонафиг! 
# FIXME: копытки в конфиг 

    if ($try > 5) { 
	return undef; 
    }

    my $orig = NetSDS::Asterisk::Originator->new(
	    actionid       => $dst, 
            destination    => $dst,
            callerid       => '0445930143',
            return_context => 'NetSDS-Conference-Outgoing',
            variables      => 'KONFNUM=' . $konf_id,
            channel        => sprintf( "SIP/%s@%s", $dst, "softswitch" ),
    );
    my $reply =
          $orig->originate( '127.0.0.1', '5038', 'asterikastwww','asterikastwww' );
    unless ( defined($reply) ) {
            $this->speak("[$$] Originate to $dst FAILED.");
    } else { 
	    $this->speak("[$$] Originate to $dst SUCCESS."); 
    }

}


1;

__END__

=back

=head1 EXAMPLES


=head1 BUGS

Unknown yet

=head1 SEE ALSO

None

=head1 TODO

None

=head1 AUTHOR

Alex Radetsky <rad@rad.kiev.ua>

=cut


