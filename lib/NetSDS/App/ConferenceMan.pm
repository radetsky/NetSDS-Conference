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
use NetSDS::Asterisk::Originator;
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

	setproctitle ("ConferenceMan (".$this->{'konf'}->{'cnfr_id'}.")"); 
	
	$this->mk_accessors('mydb');
    $this->mydb( ConferenceDB->new() );

    $this->speak( "[$$] ConferenceMan start with conference ID: "
          . $this->{'konf'}->{'cnfr_id'} );

    # Getting properties of my conference
    my $konf = $this->{'konf'};

    # Setting in memory last start timestamp
    $this->{'konf'}->{'date_started'} = time();


	# Restoring control process. Do not update database.
	if ( defined ($this->{'restore'}) and $this->{'restore'} == 1) {
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
    unless ( defined($res) ) {
        $this->speak(
            "[$$] Fail to update database while starting the conference.");
    }
    else {
        $this->speak(
            "[$$] Database updated sucessfully while starting the conference.");
    }

    # If we have to make self-connection to users, just to it.
	
    if ( defined ( $konf->{'auto_assemble'} ) and ( $konf->{'auto_assemble'} ne '') and   $konf->{'auto_assemble'} == 1 ) {

        # Get list of members
        $this->speak( "[$$] Conference ID "
              . $konf->{'cnfr_id'}
              . " have AA attribute." );
        my @phones = $this->_getPhones( $konf->{'cnfr_id'} );
        $this->_start_assemble( $konf->{'cnfr_id'}, @phones );
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

sub process {
    my $this = shift;
    $this->speak("[$$] ConferenceMan process.");

    while (1) {

        # Определить стоп конференции / Застопать конференцию.
		# Способ номер 1 - получить список конференции и список будет пустой.
		# Дополнительное условие - 5 минут пустой конференции.

        my $conf_id = $this->{'konf'}->{'cnfr_id'};
        my $konf    = NetSDS::Konference->new();
        $konf->konference_connect( 'localhost', '5038', 'asterikastwww',
            'asterikastwww' );
        my $members = $konf->konference_list_konf($conf_id);
        if ( $members == 0 ) {

            # No more anybody AND conference length more than 5 minutes
            my $date_now     = time();
            my $date_started = $this->{'konf'}->{'date_started'};
            my $delta        = $date_now - $date_started;

            if ( $delta > 300 ) {

                # FIXME must be in config
                # Exit from main_loop means that we will stop
                return 1;
            }
        }
		# Sleeping time 
		# FIXME Check the disconnect to Asterisk and memory leaks.
		sleep(1);
    }
}

sub stop { 
	my $this = shift; 

    # Stop the conference
	$this->speak("[$$] Stop the conference: ".$this->{'konf'}->{'cnfr_id'});
    $this->log("info","Stop the conference: ".$this->{'konf'}->{'cnfr_id'});

	# Update Database
    my $res = $this->mydb->cnfr_update(
        $this->{'konf'}->{'cnfr_id'},
        {
            cnfr_state => '\'inactive\'',
            last_end => 'now()'
        }
    );


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


