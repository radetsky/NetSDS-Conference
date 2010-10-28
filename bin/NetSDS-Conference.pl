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

# Массив для запоминания списков
# Детей, что  им можно было  послать сигналы.
my @CHILDREN = array();
my %ACTIVE;

sub start {
    my ($this) = @_;

    $this->_add_signal_handlers();

    $this->speak("[$$] NetStyle NetSDS-Conference Service start.");
    $this->mk_accessors('mydb');
    $this->mydb( ConferenceDB->new() );

}

sub _add_signal_handlers {
    my $this = @_;

    $SIG{INT} = sub {
        $this->speak("SIGINT caught");
        $this->log( "warn", "SIGINT caught" );
        my $perm = kill "TERM" => @CHILDREN;
        $this->speak("Sent TERM to $perm processes");
        $this->{to_finalize} = 1;
    };

    $SIG{TERM} = sub {
        $this->speak("[$$] SIGTERM caught");
        $this->log( "warn", "[$$] SIGTERM caught" );
        my $perm = kill "TERM" => @CHILDREN;
        $this->speak("Sent TERM to $perm processes");
        $this->{to_finalize} = 1;
    };
}

sub process {
    my ($this) = @_;
    while (1) {
        $this->speak("[$$] Processing .");

        # Get list of the conference
        my @conf_list = $this->mydb->cnfr_list();

        foreach my $conf (@conf_list) {

            # Looking for conferences with defined 'next start'
            #		warn Dumper ($conf);
            #$VAR1 = {
            #          'cnfr_state' => 'inactive',
            #          'number_b' => '',
            #          'schedule_date' => '',
            #          'cnfr_id' => 2,
            #          'schedule_duration' => '',
            #          'next_start' => '2010-10-19 11:00',
            #          'next_duration' => '00:00:00',
            #          'lost_control' => '0',
            #          'need_record' => '1',
            #          'auth_type' => '',
            #          'auto_assemble' => '0',
            #          'last_end' => '',
            #          'auth_string' => '',
            #          'audio_lang' => '',
            #          'schedule_time' => '',
            #          'last_start' => '',
            #          'cnfr_name' => 'Тестовая'
 
			# Restore crushed (?) ConferenceMan's ?

            if ( defined( $conf->{'cnfr_state'} ) ) {
                if ( $conf->{'cnfr_state'} =~ /^active/i ) {
                    unless ( defined( $ACTIVE{ $conf->{'cnfr_state'} } ) ) {
                        $this->speak(
                            "[$$] Restoring active ConferenceMan with ID "
                              . $conf->{'cnfr_id'} );
                        $this->log( "info",
                            "Restoring active ConferenceMan with ID "
                              . $conf->{'cnfr_id'} );
                        $this->_conference_restore($conf);
                    }
                }
            }

           unless ( defined( $conf->{'next_start'} ) ) {
                next;
            }
            if ( $conf->{'next_start'} eq '' ) {  # Next start not exist - next!
                next;
            }
            if ( $conf->{'cnfr_state'} eq 'active' )
            {    #Conferece already active -> next !
                next;
            }

            # Prepare to compare next_start and now();
            my $date_next_start = ParseDate( $conf->{'next_start'} );
            my $date_now        = ParseDate('now');

            my $last_start = $conf->{'last_start'};
            if ( $last_start eq '' ) {
                $last_start = undef;
            }

            unless ( defined($last_start) ) {

                # Last start field does not filled. Simple case.
                # check only next_start
                # Compare
                my $flag = Date_Cmp( $date_now, $date_next_start );
                if ( $flag >= 0 ) {    # next_start in the past
                    printf(
"[$$] ID: %2s Next Start: %s Last Start not defined. \n",
                        $conf->{'cnfr_id'}, $conf->{'next_start'} );
                    $this->_conference_start($conf);
                }
                else {
                    printf( "[$$] ID: %2s Next Start: %s Waiting... \n",
                        $conf->{'cnfr_id'}, $conf->{'next_start'} );
                }
                next;
            }
            my $last_end = $conf->{'last_end'};
            if ( $last_end eq '' ) {
                $last_end = undef;
            }

            unless ( defined($last_end) ) {

             # Abnormal situation when last_start defined, not active conference
             # and last_end not defined.
             # Doing like last_start not defined;
                printf( "ID: %2s Next Start: %s Last End not defined. \n",
                    $conf->{'cnfr_id'}, $conf->{'next_start'} );

                # Compare
                my $flag = Date_Cmp( $date_now, $date_next_start );
                if ( $flag >= 0 ) {    # next_start in the past
                    $this->_conference_start($conf);
                }
                next;
            }
            my $date_last_start = ParseDate($last_start);
            my $date_last_end   = ParseDate($last_end);
            my $flag = Date_Cmp( $date_next_start, $date_last_start );
            if ( $flag >= 0 ) {

                # Next_start > $last_start
                $flag = Date_Cmp( $date_next_start, $date_last_end );
                if ( $flag >= 0 ) {

                    #Next start > $last_end;
                    printf(
                        "ID: %2s Next Start: %s Last Start %s Last End %s \n",
                        $conf->{'cnfr_id'}, $conf->{'next_start'}, $last_start,
                        $last_end );
                    $this->_conference_start($conf);
                }
            }

        }
        sleep(1);
    }
}

sub _conference_start {
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
            infinite    => undef,
            verbose     => 1,
            has_conf    => 1,
            config_file => '/etc/netstyle/conference.conf',
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
            config_file => '/etc/netstyle/conference.conf',
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

