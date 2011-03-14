#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  NetSDS-Conference.pl
#
#        USAGE:  ./NetSDS-Conference.pl
#
#  DESCRIPTION:  NetSDS-Conference service.
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Alex Radetsky (Rad), <rad@rad.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.0
#      CREATED:  16.10.2010 14:22:38 EEST
#     REVISION:  ---
#===============================================================================

use 5.8.0;
use strict;
use warnings;

NetSDSConference->run(
    daemon      => undef,
    verbose     => 1,
    use_pidfile => 1,
    has_conf    => 1,
    debug       => 1,
    conf_file   => "/etc/netstyle/conference.conf",
    infinite    => undef,

);

1;

package NetSDSConference;

use 5.8.0;
use strict;
use warnings;

use lib '/opt/NetSDS/lib/';

use base qw(NetSDS::App);
use ConferenceDB;
use Data::Dumper;
use Date::Manip;
use NetSDS::App::ConferenceMan;
use NetSDS::App::ConfEmailReminder;
use NetSDS::App::ConfVoiceReminder; 
use Time::HiRes qw/usleep/;

use POSIX ":sys_wait_h";

# Массив для запоминания списков
# Детей, что  им можно было  послать сигналы.
my @CHILDREN = array();
my %ACTIVE;
my $REMINDED; 
my $VOICE_REMINDED;

sub start {
    my ($this) = @_;

    $this->_add_signal_handlers();

    $this->log("info","NetStyle NetSDS-Conference Service start.");
    $this->mk_accessors('mydb');
    $this->mydb( ConferenceDB->new() );

}

sub _add_signal_handlers {
    my $this = @_;

  # FIXME: в детях проверить обработку сигналов!

    $SIG{INT} = sub {
        warn "[$$] SIGINT caught";
        my $perm = kill "TERM" => @CHILDREN;
        warn "Sent TERM to $perm processes";
        exit(1);
    };

    $SIG{TERM} = sub {
        warn "[$$] SIGTERM caught";
        my $perm = kill "TERM" => @CHILDREN;
        warn "Sent TERM to $perm processes";
        exit(1);
    };
	$SIG{CHLD} = sub { 
		warn "[$$] SIGCHLD caught"; 
		while ( ( my $child = waitpid(-1,WNOHANG )) > 0) { 
			# delete from CHILDREN
			warn "Process $child dead."; 
		}

	};

}

sub process {
    my ($this) = @_;
    $this->log("info","Start processing.");
    while (1) {
        # find non-active next starting conferences
        my $cnfrs = $this->mydb->cnfr_find_4_start();
        foreach my $cnfr_id ( keys %$cnfrs ) {
            $this->_conference_start( $cnfrs->{$cnfr_id} );
        }

		# Find email reminders
		$cnfrs = $this->mydb->cnfr_find_email_reminders(); 
		foreach my $cnfr_id ( keys %$cnfrs ) {
            my $c = $this->_check_reminded($cnfr_id,1);
            if ( defined ($c) ) {
                next;
            }
			$this->_conference_email_reminder_start($cnfr_id); 
			$this->_add_reminded($cnfr_id,1);
		}
		$this->_clear_reminded($cnfrs,1);

		# Find voice reminders
		$cnfrs = $this->mydb->cnfr_find_voice_reminders();
		foreach my $cnfr_id ( keys %$cnfrs ) { 
			my $c = $this->_check_reminded($cnfr_id,2);
			if ( defined ($c) ) { 
				next;
			}
			$this->_conference_voice_reminder_start($cnfr_id);
			$this->_add_reminded($cnfr_id,2);
		}
		$this->_clear_reminded($cnfrs,2);
        usleep(250);
    }
}

sub _conference_email_reminder_start { 
	my $this = shift; 
	my $cnfr_id = shift; 

	$this->mydb->_disconnect();
    $this->speak( "[$$] Starting (fork) E-Mail reminder for Conference ID: " . $cnfr_id );
    my $pid = fork();
    unless ( defined($pid) ) {
        die "[$$] Fork() for E-mail Reminder Conference ID "
          . $cnfr_id . " failed: $!";
    }

    if ( $pid == 0 ) {
        $this->speak( "[$$] Running NetSDS::App::ConfEmailReminder ("
              . $cnfr_id . ")" );
	        my $cm = NetSDS::App::ConfEmailReminder->run(
            infinite  => undef,
            verbose   => 1,
            has_conf  => 1,
            conf_file => '/etc/netstyle/conference.conf',
            debug     => 1,
			cnfr_id   => $cnfr_id,

        );
        die "[$$] NetSDS::App::ConfEmailReminder died.";
    }
    push @CHILDREN, $pid;
}

sub _conference_voice_reminder_start { 
	my $this = shift; 
	my $cnfr_id = shift; 

	$this->mydb->_disconnect();
    $this->speak( "[$$] Starting (fork) Voice reminder for Conference ID: " . $cnfr_id );
    my $pid = fork();
    unless ( defined($pid) ) {
        die "[$$] Fork() for Voice Reminder Conference ID "
          . $cnfr_id . " failed: $!";
    }

    if ( $pid == 0 ) {
        $this->speak( "[$$] Running NetSDS::App::ConfVoiceReminder ("
              . $cnfr_id . ")" );
	        my $cm = NetSDS::App::ConfVoiceReminder->run(
            infinite  => undef,
            verbose   => 1,
            has_conf  => 1,
            conf_file => '/etc/netstyle/conference.conf',
            debug     => 1,
			cnfr_id   => $cnfr_id,

        );
        die "[$$] NetSDS::App::ConfVoiceReminder died.";
    }
    push @CHILDREN, $pid;
}


sub _conference_start {
    my $this = shift;
    my $conf = shift;

    # Set active flag,
    # Set next_start to NULL,
    # Set Last_start to now()
    my $res = $this->mydb->cnfr_update(
        $conf->{'cnfr_id'},
        {
            cnfr_state => '\'active\'',
            next_start => 'NULL',
            last_start => 'now()',
            last_end   => 'NULL',
        }
    );
    unless ( defined($res) ) {
        $this->speak(
            "[$$] Fail to update database while starting the conference.");
    }
    else {
        $this->speak(
            "[$$] Database updated sucessfully while starting the conference.");
    }

    $this->mydb->_disconnect();

    $this->speak( "[$$] Starting (fork) conference ID: " . $conf->{'cnfr_id'} );
    my $pid = fork();
    unless ( defined($pid) ) {
        die "[$$] Fork() for Conference ID "
          . $conf->{'cnfr_id'}
          . " failed: $!";
    }

    if ( $pid == 0 ) {
        $this->speak( "[$$] Running NetSDS::App::ConferenceMan ("
              . $conf->{'cnfr_id'}
              . ")" );
        my $cm = NetSDS::App::ConferenceMan->run(
            konf      => $conf,
            infinite  => undef,
            verbose   => 1,
            has_conf  => 1,
            conf_file => '/etc/netstyle/conference.conf',
            debug     => 1,

        );
        die "[$$] NetSDS::App::ConferenceMan died.";
    }
    push @CHILDREN, $pid;
    $ACTIVE{ $conf->{'cnfr_id'} } = $pid;
}

sub _conference_restore {
    my $this = shift;
    my $conf = shift;

    $this->mydb->_disconnect();

    $this->speak( "[$$] Starting (fork) conference ID: " . $conf->{'cnfr_id'} );
    my $pid = fork();
    unless ( defined($pid) ) {
        die "[$$] Fork() for Conference ID "
          . $conf->{'cnfr_id'}
          . " failed: $!";
    }

    if ( $pid == 0 ) {
        $this->speak( "[$$] Running NetSDS::App::ConferenceMan ("
              . $conf->{'cnfr_id'}
              . ")" );
        my $cm = NetSDS::App::ConferenceMan->run(
            konf      => $conf,
            restore   => 1,
            infinite  => undef,
            verbose   => 1,
            has_conf  => 1,
            conf_file => '/etc/netstyle/conference.conf',
            debug     => 1,

        );
        die "[$$] NetSDS::App::ConferenceMan died.";
    }
    push @CHILDREN, $pid;
    $ACTIVE{ $conf->{'cnfr_id'} } = $pid;
}


sub _add_reminded { 
	my $this = shift; 
	my $cnfr_id = shift; 
	my $reminded = shift;

	if ($reminded == 1) { 
		$REMINDED->{$cnfr_id} = 1;
	} else { 
		$VOICE_REMINDED->{$cnfr_id} = 1; 
	} 

	$this->speak("[$$] Added # $cnfr_id to reminded list.");
	$this->log("info","Added # $cnfr_id to reminded list.");
} 

sub _check_reminded { 
	my $this = shift; 
	my $cnfr_id = shift; 
	my $reminded = shift; 

	if ($reminded == 1) { 
		$reminded = $REMINDED;
	} else {
		$reminded = $VOICE_REMINDED;
	} 
	foreach my $cnfr_done_id (keys %$reminded) { 
		if ($cnfr_done_id == $cnfr_id) {
			$this->log("info"," # $cnfr_id already in reminded list");
			return 1; 
		} 
	} 

	return undef; 
}
sub _clear_reminded { 
	my ($this,$cnfrs,$reminded) = @_;
    my $rem;

	if ($reminded == 1) {
		$rem = $REMINDED; 
	} else { 
		$rem = $VOICE_REMINDED;
	}
	foreach my $cnfr_done_id (keys %$rem) { 
		my $found = undef; 
		foreach my $cnfr_id (keys %$cnfrs) { 
			if ($cnfr_done_id == $cnfr_id) { 
				$found = 1; 
			}
		}
		unless ( defined ( $found ) ) { 
			if ($reminded == 1) { 
				delete $REMINDED->{$cnfr_done_id};
			} else {
				delete $VOICE_REMINDED->{$cnfr_done_id};
			}

			$this->speak("[$$] Removing # $cnfr_done_id from already reminded list.");
			$this->log("info","Removing # $cnfr_done_id from already reminded list.");
		}
	}
}

1;

#===============================================================================

__END__

=head1 NAME

NetSDS-Conference.pl

=head1 SYNOPSIS

NetSDS-Conference.pl

=head1 DESCRIPTION 

Главный процесс в иерархии процессов по NetSDS-Conference. Следит за необходимостью старторвать новую
конференцию, управляет дочерними процессами. 

=head1 EXAMPLES

FIXME

=head1 BUGS

Unknown.

=head1 TODO

Empty.

=head1 AUTHOR

Alex Radetsky <rad@rad.kiev.ua>

=cut

