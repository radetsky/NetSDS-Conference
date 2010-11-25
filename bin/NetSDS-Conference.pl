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

use Time::HiRes qw/usleep/;

# Массив для запоминания списков
# Детей, что  им можно было  послать сигналы.
my @CHILDREN = array();
my %ACTIVE;

sub start {
    my ($this) = @_;

#    warn Dumper ($this->conf); 

    $this->_add_signal_handlers();

    $this->speak("[$$] NetStyle NetSDS-Conference Service start.");
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
}

sub process {
    my ($this) = @_;
		$this->speak("[$$] Start processing.");
    while (1) 
		{
				# find non-active next starting conferences 
        my $cnfrs = $this->mydb->cnfr_find_4_start();
				foreach my $cnfr_id (keys %$cnfrs) {
					$this->_conference_start($cnfrs->{$cnfr_id});
				}

				usleep(250); 

    }
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
            konf        => $conf,
            infinite    => undef,
            verbose     => 1,
            has_conf    => 1,
            conf_file   => '/etc/netstyle/conference.conf',
            debug       => 1,

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
            konf        => $conf,
            restore     => 1,
            infinite    => undef,
            verbose     => 1,
            has_conf    => 1,
            conf_file => '/etc/netstyle/conference.conf',
            debug       => 1,

        );
        die "[$$] NetSDS::App::ConferenceMan died.";
    }
    push @CHILDREN, $pid;
	$ACTIVE{ $conf->{'cnfr_id'} } = $pid;
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

