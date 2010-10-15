#===============================================================================
#
#         FILE:  Konference.pm
#
#  DESCRIPTION:  NetSDS::Konference. Management of Konference() asterisk application
#
#        NOTES:  ---
#       AUTHOR:  Alex Radetsky (Rad), <rad@rad.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.0
#      CREATED:  15.10.2010 13:31:09 EEST
#===============================================================================

=head1 NAME

NetSDS::

=head1 SYNOPSIS

	use NetSDS::;

=head1 DESCRIPTION

C<NetSDS> module contains superclass all other classes should be inherited from.

=cut

package NetSDS::Konference;

use 5.8.0;
use strict;
use warnings;

use NetSDS::AMI;
use base qw(NetSDS::Class::Abstract);

use version; our $VERSION = "0.01";
our @EXPORT_OK = qw();

#===============================================================================
#

=head1 CLASS METHODS

=over

=item B<new([...])> - class constructor

    my $object = NetSDS::SomeClass->new(%options);

=cut

#-----------------------------------------------------------------------
sub new {

	my ( $class, %params ) = @_;
	my $this = $class->SUPER::new();

	my $this->{'AMI'} = NetSDS::AMI->new();

	return $this;

}

#***********************************************************************

=head1 OBJECT METHODS

=over

=item B<user(...)> - object method

=cut

#-----------------------------------------------------------------------
__PACKAGE__->mk_accessors('user');

sub konference_connect {
	my ( $this, $host, $port, $user, $secret ) = @_;

	my $this->{'connected'} = $conn = $this->{'AMI'}->connect( $host, $port, $user, $secret, 'Off' );
	unless ( defined( $this->{'connected'} ) ) {
		return undef;
	}
	return 1;
}
#***********************************************************************


=item B<konference_list(...)> - object method

RETURN: undef of hasref with konferences as keys, value, members and duration as values; 

=cut

#-----------------------------------------------------------------------



sub konference_list {

	my $this = shift;

	unless ( defined( $this->{'connected'} ) ) {
		$this->{'AMI'}->reconnect();
	}

	my $sent = $this->{'AMI'}->send_command(
		Action  => 'Command',
		Command => 'konference list'
	);
	unless ( defined($sent) ) {
		return undef;
	}

	my $reply = $this->{'AMI'}->receiveanswer();
	unless ( defined($reply) ) {
		return undef;
	}

	my $ret = {};

	if ( $reply->{'Response'} =~ /^follows/i ) {
		while (1) {
			$reply = $ami2->read_raw();
			if ( $reply eq '' ) {
				next;
			}    #Пропускаем пустые строки
			if ( $reply =~ /^--END\ COMMAND--\.*/ )    # Все. Конец информации
			{
				last;
			}

			else {
				# Что-то получили. Парсим. Должно быть что-то наподобие:
				# Name                 Members              Volume               Duration
				# 49                   1                    0                    00:14:13

				my ( $KName, $KMembers, $KVolume, $KDuration ) = split( ' ', $reply );
				$ret->{$KName}->{'members'}  = $KMembers;
				$ret->{$KName}->{'volume'}   = $KVolume;
				$ret->{$KName}->{'duration'} = $KDuration;
			}
		} ## end while (1)
	} ## end if ( $reply->{'Response'...

	return $ret; 

} ## end sub konference_list

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


