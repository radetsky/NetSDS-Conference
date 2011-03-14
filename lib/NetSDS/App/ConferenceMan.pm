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
	$SIG{CHLD} = 'IGNORE'; 

    setproctitle( "ConferenceMan (" . $this->{'konf'}->{'cnfr_id'} . ")" );

    # ConferenceDB
    $this->mk_accessors('mydb');
    $this->mydb( ConferenceDB->new() );

# Для отслеживания активных аинхронных запросов
    $this->mk_accessors('manager_queries');
    $this->manager_queries( {} );

    # Для учета members конференции
    $this->mk_accessors('members');
    $this->members( {} );

    # Для установки приоритета
    $this->mk_accessors('priority_channel');
    $this->priority_channel('');

    # Для оперативного управления
    my $KONF = NetSDS::Konference->new();
    $KONF->konference_connect( 'localhost', '5038', 'asterikastwww',
        'asterikastwww' );
    $this->mk_accessors('konference');
    $this->konference($KONF);

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

#		my $res = $this->mydb->cnfr_update(                         This code moved to NetSDS-Conference.pl
#        $konf->{'cnfr_id'},
#        {
#            cnfr_state => '\'active\'',
#            next_start => 'NULL',
#            last_start => 'now()'
#        }
#    );

    $this->{'konf'}->{'last_start'} =
      POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime );

    # log record
    $this->mydb->conflog( $konf->{'cnfr_id'}, 'started', undef );

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

    # Set CallerID
    my $callerid = $this->conf->{'general_callerid'};
    if (
        (
            defined( $this->{'conf_properties'}->{'number_b'} )
            and ( $this->{'conf_properties'}->{'number_b'} ne '' )
        )
      )
    {
        $callerid = $this->{'conf_properties'}->{'number_b'};
    }
    $this->speak("[$$] Set CallerID to $callerid");
    $this->log( "info", "Set CallerID to $callerid" );

    # we have a list to originate. Start it. and Return to KONF_ID in asterisk.
    foreach my $dst (@phones) {
        my $orig = NetSDS::Asterisk::Originator->new(
            actionid       => $dst,
            destination    => $dst,
            callerid       => $callerid,
            return_context => 'NetSDS-Conference-Outgoing',
            variables      => 'KONFNUM=' . $konf_id . '|DIAL=' . $dst,
            ,
            channel => sprintf( "SIP/%s@%s", $dst, "softswitch" ),
        );
        my $reply = $orig->originate( '127.0.0.1', '5038', 'asterikastwww',
            'asterikastwww' );
        unless ( defined($reply) ) {
            $this->speak("[$$] Originate to $dst failed.");
        }
    }
}

sub _start_record {
    my ( $this, $konf_id ) = @_;

    my $callerid = $this->conf->{'general_callerid'};
    if ( defined( $this->{'konf'}->{'number_b'} ) ) {
        $callerid = $this->{'konf'}->{'number_b'};
    }

    # Originate call with two local channels.
    my $orig = NetSDS::Asterisk::Originator->new(
        destination    => $konf_id,
        callerid       => $callerid,
        return_context => 'NetSDS-Conference-Outgoing-Record',
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
        host     => '127.0.0.1',
        port     => '5038',
        username => 'asterikastwww',
        secret   => 'asterikastwww'
    );

    $event_listener->_connect();
    my $prev_time = time;

    while (1) {

# Проверяем приоритет пользователей в конференции
        my $priority_phone = $this->mydb->get_priority($conf_id);
        if ( defined($priority_phone) ) {
            $this->_set_priority_for_member($priority_phone);
        }
        else {
            if ( $this->priority_channel ne '' ) {
                $this->priority_channel('');
                $this->_unmute_nonpriority_channels();
            }
        }

        # Читаем события
        # Фильтруем события
        my $event = $event_listener->_getEvent();
        unless ($event) {
            my $time = time;
            if ( $time > $prev_time ) {
                $prev_time = $time;
                goto check_stop;
            }
            $prev_time = $time;
            usleep(250);
            goto check_stop; 
        }

        # Работаем с приоритетом
	unless ( defined ( $event->{'Event'} ) ) {
	   warn Dumper ($event);
	   $this->log("warning",Dumper($event));
	   goto check_stop;
	
	}

        if ( $event->{'Event'} =~ /ConferenceState/i ) {

            my $channel = $event->{'Channel'};
            my $state   = $event->{'State'};

            if ( $state =~ /Speaking/i ) {
                if ( $channel eq $this->priority_channel ) {

                    # Mute another channels
                    $this->speak("[$$] Priority channel speaks. Mute another.");
                    $this->_mute_nonpriority_channels();
                }
            }
            if ( $state =~ /Silent/i ) {
                if ( $channel eq $this->priority_channel ) {

                    # unmute another channels
                    $this->speak(
                        "[$$] Priority channel is silented. Unmute another.");
                    $this->_unmute_nonpriority_channels();
                }
            }
        }

        if ( $event->{'Event'} =~ /ConferenceDTMF/i ) {

            # ConferenceName: 4
            # Type: konference
            # Channel: SIP/blablabla
            # CallerID: 0445949641
            # Key: *(0,1,2...)
            # Mute: 0
            if ( $event->{'Type'} =~ /konference/i ) {
                if ( $event->{'ConferenceName'} == $conf_id ) {
                    my $channel  = $event->{'Channel'};
                    my $key      = $event->{'Key'};
                    my $mute     = $event->{'Mute'};
                    my $callerid = $event->{'CallerID'};
                    my $rc =
                      $this->_DTMF( $channel, $key, $mute, $callerid,
                        $conf_id );
                    if ( $rc == 2 ) {    # Stop the conference
                        return 1;
                    }

                }
            }
        }

        if ( $event->{'Event'} =~ /ConferenceLeave/i ) {
            if ( $event->{'Type'} =~ /konference/i ) {
                if ( $event->{'ConferenceName'} eq $conf_id ) {

# Кто-то пожелал покинуть конференцию.
# Если установлен атрибут контроля потери, то дозвониться Х раз.
                    my $channel = $event->{'Channel'};
                    delete $this->members->{$channel};

                    my $destination = $event->{'CallerID'};

                    $this->speak( "[$$] $destination leaved the conference #"
                          . $conf_id );
                    $this->mydb->conflog( $this->{'konf'}->{'cnfr_id'},
                        'leaved', $destination );

                    if (    defined( $this->{'konf'}->{'lost_control'} )
                        and ( $this->{'konf'}->{'lost_control'} )
                        and ( $this->{'konf'}->{'lost_control'} == 1 ) )
                    {

                        $this->_restore_control( $destination, $conf_id );

                    }
                }
            }
        }

        if ( $event->{'Event'} =~ /ConferenceJoin/i ) {
            if ( $event->{'Type'} =~ /konference/i ) {
                if ( $event->{'ConferenceName'} eq $conf_id ) {

                    # Add new member to memory
                    my $unique_channel = $event->{'Channel'};
                    my $callerid       = $event->{'CallerID'};
                    $this->members->{$unique_channel} = $callerid;

                    # Logging
                    $this->speak( "[$$] $callerid has joined the conference #"
                          . $event->{'ConferenceName'} );
                    $this->mydb->conflog( $this->{'konf'}->{'cnfr_id'},
                        'joined', $callerid );

                    # Check for blocking
                    if ( defined( $this->{'BLOCK'} ) ) {
                        if ( $this->{'BLOCK'} == 1 ) {
                            my $is_operator =
                              $this->mydb->is_operator( $conf_id, $callerid );
                            unless ( defined($is_operator) ) {
                                $this->_kick_blocked( $event->{'Channel'},
                                    $conf_id );
                            }
                            unless ($is_operator) {
                                $this->_kick_blocked( $event->{'Channel'},
                                    $conf_id );
                            }
                        }
                    }

                }
            }
        }

# Мы к кому-то дозвонились. Если была поставлена задача дозвониться,
# То мы таки дозваниваемся. Попыток пока по-умолчанию 5.

        if ( $event->{'Event'} =~ /OriginateResponse/i ) {
            if ( $event->{'Response'} =~ /Failure/i ) {
                my $destination = $event->{'ActionID'};
                my $restore_konf =
                  $this->manager_queries->{$destination}->{'cnfr_id'};
                unless ( defined($restore_konf) ) {

              # Не текущий процесс. Оставим другим.
                    next;
                }

                $this->speak("[$$] Retrying to restore link with $destination");
                $this->_restore_control( $destination, $restore_konf );
            }
            if ( $event->{'Response'} =~ /Success/i ) {
                my $destination = $event->{'ActionID'};
                unless ( defined($destination) ) {

# Это может быть запись. Если нет ActionID, ну и фигсним.
                    next;
                }
                my $restore_konf =
                  $this->manager_queries->{$destination}->{'cnfr_id'};
                unless ( defined($restore_konf) ) {

              # Не текущий процесс. Оставим другим.
                    next;
                }
                delete $this->manager_queries->{$destination};
                $this->speak("[$$] Link restored with $destination");
            }
        }

# Определить стоп конференции / Застопать конференцию.
      check_stop:

#
# проверяем нажатие кнопки "Стоп" на веб-интерфейсе.
#
        my $state = $this->_check_button_stop();
        unless ( defined($state) ) {
            goto check_stop_0;
        }
        else {
	    $this->speak("[$$] Button stop pressed. ");
	    $this->log("info","Button stop pressed. "); 
            return 1;
        }

      check_stop_0:

# Способ номер 0 - если указан next_duration ( != 00:00:00  != '' )
# Посчитать с last_started по длине next_duration и сравнить с ним

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
                    $this->log( "info",
                            "Stop the conference #"
                          . $this->{'konf'}->{'cnfr_id'}
                          . "  because duration time exceed." );
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

        if ( ( $members == 0 ) or ( $members eq "0" ) ) {

            # No more anybody AND conference length more than 5 minutes
            my $date_now     = time();
            my $date_started = $this->{'konf'}->{'date_started'};
            my $delta        = $date_now - $date_started;

            my $max_delta = 300;

            if ( defined( $this->conf->{'max_delta_empty_conference'} ) ) {
                $max_delta = $this->conf->{'max_delta_empty_conference'};
            }

            if ( $delta > $max_delta ) {

                # Exit from main_loop means that we will stop
                $this->speak(
                    "[$$] Stop the conference because conference is empty.");
                return 1;
                $this->log( "info",
                        "Stop the conference #"
                      . $this->{'konf'}->{'cnfr_id'}
                      . " because it is empty." );
            }
            next;
        }

#
# Если только пишуший робот присутствует, то тоже останавливаем конференцию.
#
#warn Dumper ($members);
        my $count = keys %$members;
        if ( $count == 1 ) {
            foreach my $member ( keys %$members ) {
                my $channel = $members->{$member}->{'channel'};
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
                        $this->log( "info",
                                "Stop the conference #"
                              . $this->{'konf'}->{'cnfr_id'}
                              . " because it is empty." );
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
            last_end   => 'now()',
            next_start => $this->_calculate_next(),
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
                $this->speak( "[$$] Kicking '" 
                      . $member
                      . "' from Konference '"
                      . $this->{'konf'}->{'cnfr_id'}
                      . "' failed." );
            }
            else {
                $this->speak( "[$$] Member '" . $member . "' kicked." );
            }
        }
    }
    $this->mydb->conflog( $this->{'konf'}->{'cnfr_id'}, 'stopped' );

}

sub _kick_blocked {

    my ( $this, $channel, $conf_id ) = @_;

    #FIXME: connect parameters to config

    my $konf = NetSDS::Konference->new();
    $konf->konference_connect( 'localhost', '5038', 'asterikastwww',
        'asterikastwww' );
    $konf->konference_playsound( $channel, "conf-blocked" );
    $konf->konference_kickchannel($channel);
    $this->speak("[$$] $channel kicked off from $conf_id. It's blocked.");

    return 1;

}

sub _DTMF {
    my ( $this, $channel, $key, $mute, $callerid, $conf_id ) = @_;

    my $menu  = 'conf-usermenu-162';
    my $gimme = 'conf-give-me-a-chance';

    #FIXME connect parameters to config

    my $konf = NetSDS::Konference->new();
    $konf->konference_connect( 'localhost', '5038', 'asterikastwww',
        'asterikastwww' );

    # Menu
    if ( $key eq '*' ) {

        # konference play sound <channel> <sound> mute
        my $res = $konf->konference_playsound( $channel, $menu );
        unless ( defined($res) ) {
            $this->speak("[$$] Playing $menu to $channel FAILED");
        }
        else {
            $this->speak("[$$] Playing $menu to $channel SUCCESS");
        }
    }

    # Admin stop the konference

    if ( $key eq '#' ) {

        my $is_operator = $this->mydb->is_operator( $conf_id, $callerid );
        unless ( defined($is_operator) ) {
            $this->speak(
                "[$$] DB ERROR: $callerid is not operator for $conf_id");
            return undef;
        }
        unless ($is_operator) {
            $this->speak("{$$] $callerid is not operator for $conf_id");
            return 0;
        }

        return 2;
    }

    # Mute/Unmute yourself
    if ( $key eq '0' ) {
        if ( $mute eq '0' ) {
            my $res = $konf->konference_mutechannel($channel);
            unless ( defined($res) ) {
                $this->speak("[$$] Mute channel $channel FAILED");
            }
            else {
                $this->speak("[$$] Mute channel $channel SUCCESS");
            }
        }
        else {
            my $res = $konf->konference_unmutechannel($channel);
            unless ( defined($res) ) {
                $this->speak("[$$] Unmute channel $channel FAILED");
            }
            else {
                $this->speak("[$$] Unmute channel $channel SUCCESS");
            }
        }
    }

    # Admin unmute all
    if ( $key eq '1' ) {

        my $is_operator = $this->mydb->is_operator( $conf_id, $callerid );
        unless ( defined($is_operator) ) {
            $this->speak(
                "[$$] DB ERROR: $callerid is not operator for $conf_id");
            return undef;
        }
        unless ($is_operator) {
            $this->speak("[$$] $callerid is not operator for $conf_id");
            return 0;
        }

        my $res = $konf->konference_unmuteconference($conf_id);
        unless ( defined($res) ) {
            $this->speak("[$$] Unmute whole conference FAILED");
        }
        else {
            $this->speak("[$$] Unmute whole conference SUCCESS");
        }
    }

    # Функция "Прошу слова".
    if ( $key eq '2' ) {
        my $members = $konf->konference_list_konf($conf_id);
        unless ( defined($members) ) {
            return undef;
        }
        unless ($members) {
            return undef;
        }
        foreach my $member ( keys %$members ) {
            my $channel = $members->{$member}->{'channel'};
            my $res = $konf->konference_playsound( $channel, $gimme );
            unless ( defined($res) ) {
                $this->speak("[$$] Playing $gimme to $channel FAILED");
            }
            else {
                $this->speak("[$$] Playing $gimme to $channel SUCCESS");
            }
        }
    }
    if ( $key eq '3' ) {
        my $is_operator = $this->mydb->is_operator( $conf_id, $callerid );
        unless ( defined($is_operator) ) {
            $this->speak(
                "[$$] DB ERROR: $callerid is not operator for $conf_id");
            return undef;
        }
        unless ($is_operator) {
            $this->speak("{$$] $callerid is not operator for $conf_id");
            return 0;
        }

        my $res = $konf->konference_muteconference($conf_id);
        unless ( defined($res) ) {
            $this->speak("[$$] Mute whole conference FAILED");
        }
        else {
            $this->speak("[$$] Mute whole conference SUCCESS");
        }

        $res = $konf->konference_unmutechannel($channel);
        unless ( defined($res) ) {
            $this->speak("[$$] Unmute channel $channel FAILED");
        }
        else {
            $this->speak("[$$] Unmute channel $channel SUCCESS");
        }

    }
    if ( $key eq '4' ) {

        my $res = $konf->konference_listenvolume( $channel, 'down' );
        unless ( defined($res) ) {
            $this->speak("[$$] Listen volume down for $channel FAILED");
        }
        else {
            $this->speak("[$$] Listen volume down for $channel SUCCESS");
        }

    }
    if ( $key eq '5' ) {

        # Block to accept from new
        my $is_operator = $this->mydb->is_operator( $conf_id, $callerid );
        unless ( defined($is_operator) ) {
            $this->log("warning", 
                "DB ERROR: $callerid is not operator for $conf_id");
            return undef;
        }
        unless ($is_operator) {
            $this->log("info"," $callerid is not operator for $conf_id");
            return 0;
        }

   	$this->{'BLOCK'} = 1;
	$this->mydb->set_blocked ( $conf_id, 1 ); 
        $this->log("info","$conf_id blocked to accept new connections.");

    }

    if ( $key eq '6' ) {

        my $res = $konf->konference_listenvolume( $channel, 'up' );
        unless ( defined($res) ) {
            $this->speak("[$$] Listen volume up for $channel FAILED");
        }
        else {
            $this->speak("[$$] Listen volume up for $channel SUCCESS");
        }

    }
    if ( $key eq '7' ) {

        my $res = $konf->konference_talkvolume( $channel, 'down' );
        unless ( defined($res) ) {
            $this->speak("[$$] Talk volume down for $channel FAILED");
        }
        else {
            $this->speak("[$$] Talk volume down for $channel SUCCESS");
        }

    }
    if ( $key eq '8' ) {

        # Unblock
        my $is_operator = $this->mydb->is_operator( $conf_id, $callerid );
        unless ( defined($is_operator) ) {
            $this->log("warning",
                "DB ERROR: $callerid is not operator for $conf_id");
            return undef;
        }
        unless ($is_operator) {
            $this->log("info","$callerid is not operator for $conf_id");
            return 0;
        }

        $this->{'BLOCK'} = 0;
	$this->mydb->set_blocked ( $conf_id, 0 ); 
        $this->log("info","$conf_id unblocked to accept new connections.");

    }
    if ( $key eq '9' ) {
        my $res = $konf->konference_talkvolume( $channel, 'up' );
        unless ( defined($res) ) {
            $this->speak("[$$] Talk volume up for $channel FAILED");
        }
        else {
            $this->speak("[$$] Talk volume up for $channel SUCCESS");
        }
    }

    return 1;

}

sub _restore_control {
    my ( $this, $dst, $konf_id ) = @_;

    unless ( defined( $this->manager_queries ) ) {
        $this->manager_queries->{$dst} = { try => 1, ActionID => $dst . "_1" };
    }
    unless ( defined( $this->manager_queries->{$dst} ) ) {
        $this->manager_queries->{$dst} = { try => 1, ActionID => $dst . "_1" };
    }
    my $try = 0;
    unless ( defined( $this->manager_queries->{$dst}->{'try'} ) ) {
        $try = 1;
    }
    else {
        $try = $this->manager_queries->{$dst}->{'try'} + 1;
        $this->manager_queries->{$dst}->{'try'}     = $try;
        $this->manager_queries->{$dst}->{'cnfr_id'} = $konf_id;
    }

    my $max_tries = 5;
    if ( defined( $this->conf->{'max_tries_restore_link'} ) ) {
        $max_tries = $this->conf->{'max_tries_restore_link'};
    }

    if ( $try > $max_tries ) {
        return undef;
    }

    my $callerid = $this->conf->{'general_callerid'};
    if ( defined( $this->{'konf'}->{'number_b'} ) ) {
        $callerid = $this->{'konf'}->{'number_b'};
    }

    my $orig = NetSDS::Asterisk::Originator->new(
        actionid       => $dst,
        destination    => $dst,
        callerid       => $callerid,
        return_context => 'NetSDS-Conference-Outgoing',
        variables      => 'KONFNUM=' . $konf_id . '|DIAL=' . $dst,
        channel        => sprintf( "SIP/%s@%s", $dst, "softswitch" ),
    );
    my $reply =
      $orig->originate( '127.0.0.1', '5038', 'asterikastwww', 'asterikastwww' );
    unless ( defined($reply) ) {
        $this->speak("[$$] Originate to $dst FAILED.");
    }
    else {
        $this->speak("[$$] Originate to $dst SUCCESS.");
    }

}

sub _set_priority_for_member {
    my ( $this, $priority_phone ) = @_;

    foreach my $channel ( keys %{ $this->members } ) {
        if ( $priority_phone eq $this->members->{$channel} ) {
            $this->priority_channel($channel);
        }
    }
}

sub _mute_nonpriority_channels {
    my ($this) = @_;

    foreach my $channel ( keys %{ $this->members } ) {
        if ( $channel ne $this->priority_channel ) {
            $this->konference->konference_mutechannel($channel);
        }
    }

}

sub _unmute_nonpriority_channels {
    my ($this) = @_;

    foreach my $channel ( keys %{ $this->members } ) {
        if ( $channel ne $this->priority_channel ) {
            $this->konference->konference_unmutechannel($channel);
        }
    }

}

sub _check_button_stop {
    my ($this)  = @_;

    my $cnfr_id = $this->{'konf'}->{'cnfr_id'};
    my %conf    = $this->mydb->get_cnfr($cnfr_id);

    if ( $conf{'cnfr_state'} =~ /stop/i ) {
        return 1;
    }
    return undef;
}

sub _calculate_next {
    my ($this) = @_;

    my $cnfr_id = $this->{'konf'}->{'cnfr_id'};
    my %conf    = $this->mydb->get_cnfr($cnfr_id);
    my $base    = ParseDate("today");
    my $err;
    my $start = $base;
    my $stop  = DateCalc( "today", "+ 2 month", \$err );
    my %d_ord = (
        "Mon" => 1,
        "Tue" => 2,
        "Wed" => 3,
        "Thu" => 4,
        "Fri" => 5,
        "Sat" => 6,
        "Sun" => 7
    );
    my $schedules = $conf{'schedules'};
    my @deltas;
    my @nexts;

    my $count = @$schedules;
    if ( $count == 0 ) {
        return 'NULL';    #It's not planned conference
    }

    foreach my $sch (@$schedules) {
        my $format;
        my $day = $sch->{'day'};
        if ( $day =~ /^[\d]+$/ ) {
            $format = sprintf "0:1*0:%s:%s", $day,
              $sch->{'begin'};    # It's a mday
        }
        else {
            $format = sprintf "0:0:1*%s:%s", $d_ord{$day},
              $sch->{'begin'};    # It's a wday
        }
        my @recur = ParseRecur( $format, $base, $start, $stop );
        my $diff = DateCalc( "today", $recur[0], $err, 1 );
        push @deltas, $diff;
        push @nexts,  $recur[0];
    }
    my $min = &ParseDateDelta( $deltas[0] );
    my $ind = 0;
    for ( my $j = 1 ; $j <= $#deltas ; $j++ ) {
        next if ( &Date_Cmp( &ParseDateDelta( $deltas[$j] ), $min ) >= 0 );
        $ind = $j;
        $min = &ParseDateDelta( $deltas[$j] );
    }
    my $next_start    = &UnixDate( $nexts[$ind], "%Y-%m-%d %H:%M" );
    my $next_sch      = @$schedules[$ind];
    my $next_duration = $next_sch->{'duration'};

    return "'$next_start'";

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


