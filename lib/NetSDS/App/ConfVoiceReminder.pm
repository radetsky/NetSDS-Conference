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

package NetSDS::App::ConfVoiceReminder;

use 5.8.0;
use strict;
use warnings;

use Data::Dumper;
use Sys::Proctitle qw/:all/;

use NetSDS::Asterisk::Originator;
use NetSDS::Asterisk::EventListener;

use base qw(NetSDS::App);

use version; our $VERSION = "0.01";
our @EXPORT_OK = qw();

#-----------------------------------------------------------------------

=item B<start> - 

Generic Start Conference Voice Reminder. 

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

    # this->{'cnfr_id'} contains cnfr_id ;)
    setproctitle( "ConfVoiceReminder (" . $this->{'cnfr_id'} . ")" );

    # ConferenceDB
    $this->mk_accessors('mydb');
    $this->mydb( ConferenceDB->new() );

    $this->speak( "[$$] ConfVoiceReminder start with conference ID: "
          . $this->{'cnfr_id'} );
    $this->log( "info",
        "ConfVoiceReminder start with conference ID: " . $this->{'cnfr_id'} );

    # log record
    $this->mydb->conflog( $this->{'cnfr_id'}, 'voice_reminder', undef );

}

sub process {
    my $this = shift;

    # Get properties of conference
    my $conf = $this->mydb->cnfr_get( $this->{'cnfr_id'} );
    unless ( defined($conf) ) {
        $this->log( "warning",
            "Can't get properties of the conference #" . $this->{'cnfr_id'} );
        return undef;
    }
    $this->{'conf_properties'} = $conf;

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

    # Set Playfile
    my $playfile_id = $this->{'conf_properties'}->{'au_id'};

    $this->speak("[$$] Set Playfile ID to $playfile_id");
    $this->log( "info", "Set Playfile ID to $playfile_id" );

    # Set Protocol to make call
    my $call_proto = $this->conf->{'call_proto'};
    unless ( defined($call_proto) ) {
        $call_proto = 'SIP';
    }

    # Set PBX name to make call (for SIP/IAX)
    my $pbx_name = $this->conf->{'pbx_name'};

    # Set Asterisk Parameters
    my $astManagerHost   = $this->conf->{'asterisk'}->{'host'};
    my $astManagerPort   = $this->conf->{'asterisk'}->{'port'};
    my $astManagerUser   = $this->conf->{'asterisk'}->{'user'};
    my $astManagerSecret = $this->conf->{'asterisk'}->{'secret'};

    # Set Event Listener
    my $event_listener = NetSDS::Asterisk::EventListener->new(
        host     => $astManagerHost,
        port     => $astManagerPort,
        username => $astManagerUser,
        secret   => $astManagerSecret
    );

    # Get Destinations
    my @dsts     = $this->mydb->cnfr_getPhonesList( $this->{'cnfr_id'} );
    my $tryCount = 0;

  A1:
    my $dstCount = @dsts;

    if ( $dstCount == 0 ) {
        $this->speak("[$$] All users have remind. Exiting.");
        $this->log( "info", "All users have remind. Exiting." );
        return 1;
    }
    if ( $tryCount > $this->conf->{'max_tries_restore_link'} ) {
        $this->speak("[$$] Maximum tries is exceed. Exiting.");
        $this->log( "warning", "Maximum tries is exceed. Exiting." );
        return 1;
    }
    my $success;
    my $origSuccessCounter = 0;

    foreach my $dst (@dsts) {
        my $event = $event_listener->_getEvent();
        unless ($event) {
            goto T1;
        }

        unless ( defined( $event->{'Event'} ) ) {
            $this->log( "warning",
                "STRANGE UNDEFINED EVENT.Potential it's a bug. " );
            $this->log( "warning", Dumper($event) );
        }
        else {

# Звонок успешно поставлен в очередь в процессе обработки текущего списка ?
            if ( $event->{'Event'} =~ /OriginateResponse/i ) {
                $origSuccessCounter = $origSuccessCounter - 1;
                my $actionID = $event->{'ActionID'};
                my $response = $event->{'Response'};
                $this->speak(
                    "[$$] Got OriginateResponse $response for $actionID");
                $this->log( "info",
                    "Got OriginateResponse $response for $actionID" );

                if ( $response =~ /Success/i ) {
                    $success->{$dst} = 1;
                }
            }
        }
      T1:

        # Prepare channel to call
        my $channel;
        unless ( defined($pbx_name) ) {

            # We're using pri datacard
            # Zap/g1/5949641
            $channel = sprintf( "%s/%s", $call_proto, $dst );
        }
        else {

            # We're using SIP/IAX
            # SIP/5949641@softswitch
            $channel = sprintf( "%s/%s@%s", $call_proto, $dst, $pbx_name );
        }
        $this->speak("[$$] Set Channel to $channel");
        $this->log( "info", "Set Channel to $channel" );

        my $orig = NetSDS::Asterisk::Originator->new(
            actionid       => $dst,
            destination    => $dst,
            callerid       => $callerid,
            return_context => 'NetSDS-Conference-VoiceReminder',
            variables      => 'PLAYFILE=' . $playfile_id,
            channel        => $channel,
        );

        my $reply = $orig->originate(
            $astManagerHost, $astManagerPort,
            $astManagerUser, $astManagerSecret
        );
        unless ( defined($reply) ) {
            $this->speak("[$$] Originate to $dst failed.");
            $this->log( "warning", " Originate to $dst failed." );
            next;
        }
        $origSuccessCounter = $origSuccessCounter + 1;
    }

    $this->speak("[$$] All destinations originated. Waiting for responses.");
    $this->log( "info", "All destinations originated. Waiting for responses." );

    # Reading events. Waiting for OriginateResponse
    my $orCount = 0;    # Counting OriginateResponses
    while (1) {
        my $event = $event_listener->_getEvent();
        unless ($event) {
            next;
        }
        if ( $event->{'Event'} =~ /OriginateResponse/i ) {
            my $dst = $event->{'ActionID'};
            my $res = $event->{'Response'};
            $this->speak("[$$] Got OriginateResponse $res for $dst");
            $this->log( "info", "Got OriginateResponse $res for $dst" );

            if ( $res =~ /Success/i ) {
                $success->{$dst} = 1;
            }
            $orCount = $orCount + 1;
            if ( $orCount == $origSuccessCounter ) {
                last;
            }
        }
    }

    $tryCount = $tryCount + 1;
    $this->speak("[$$] Next try: $tryCount");
    $this->log( "info", "Next try: $tryCount" );

    # repack array
    my @dsts_new;
    foreach my $dst_new (@dsts) {
        if ( defined( $success->{$dst_new} ) ) {
            next;
        }
        push @dsts_new, $dst_new;
    }
    @dsts = @dsts_new;
    undef @dsts_new;

    goto A1;

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




