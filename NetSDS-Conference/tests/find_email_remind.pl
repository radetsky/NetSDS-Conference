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

use lib '../lib/';

use base qw(NetSDS::App);
use ConferenceDB;
use Data::Dumper;
use Date::Manip;
use NetSDS::App::ConferenceMan;
use NetSDS::App::ConfEmailReminder; 
use Time::HiRes qw/usleep/;

# Массив для запоминания списков
# Детей, что  им можно было  послать сигналы.
my @CHILDREN = array();
my %ACTIVE;
my %REMINDED;

sub start {
    my ($this) = @_;

    $this->speak("[$$] NetStyle NetSDS-Test script start.");
    $this->mk_accessors('mydb');
    $this->mydb( ConferenceDB->new() );

	$this->_add_signal_handlers();
}

sub process {
    my ($this) = @_;
    while (1) {
		my $cnfrs = $this->mydb->cnfr_find_email_reminders();		
		foreach my $cnfr_id ( keys %$cnfrs ) {
			my $c = $this->_check_reminded($cnfr_id);
			if ( defined ($c) ) { 
				next; 
			} 
			$this->_conference_email_reminder_start($cnfrs->{$cnfr_id}); 
			$this->_add_reminded($cnfr_id); 
		}
		$this->_clear_reminded($cnfrs); 
        usleep(250);
    }
}

sub _add_reminded { 
	my $this = shift; 
	my $cnfr_id = shift; 

	$REMINDED{$cnfr_id} = 1;
	$this->speak("[$$] Added # $cnfr_id to reminded list.");
	$this->log("info","Added # $cnfr_id to reminded list.");
} 

sub _check_reminded { 
	my $this = shift; 
	my $cnfr_id = shift; 

	foreach my $cnfr_done_id (keys %REMINDED) { 
		if ($cnfr_done_id == $cnfr_id) {
			$this->log("info"," # $cnfr_id already in reminded list");
			return 1; 
		} 
	} 

	return undef; 
}
sub _clear_reminded { 
	my ($this,$cnfrs) = @_; 

	foreach my $cnfr_done_id (keys %REMINDED) { 
		my $found = undef; 
		foreach my $cnfr_id (keys %$cnfrs) { 
			if ($cnfr_done_id == $cnfr_id) { 
				$found = 1; 
			}
		}
		unless ( defined ( $found ) ) { 
			delete $REMINDED{$cnfr_done_id};
			$this->speak("[$$] Removing # $cnfr_done_id from already reminded list.");
			$this->log("info","Removing # $cnfr_done_id from already reminded list.");
		}
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

