###########################################################
# ConferenceAuth
# Authenticated sessions for ConferenceDB
###########################################################
#
# $Id: File.pm 11 2005-10-08 23:59:12Z jlillich $
#

package ConferenceAuth;
use base qw(CGI::Session::Auth);

use 5.008;
use strict;
use warnings;
use Carp;
use DBI;

our $VERSION = do { q$Revision: 11 $ =~ /Revision: (\d+)/; sprintf "1.%03d", $1; };

###########################################################
###
### general methods
###
###########################################################

###########################################################

sub new {
	my $class = shift;
	my ($params) = shift;
	$class = ref($class) if ref($class);
	my $self = $class->SUPER::new($params);

	$self->{dbh}  = $params->{dbh} or die "dbh parameter is mandatory";
	bless($self, $class);

	return $self;
}

###########################################################
###
### backend specific methods
###
###########################################################

###########################################################

sub _login {
    
	##
	## check username and password
	##

	my $self = shift;
	my ($username, $password) = @_;

	my $result = 0;

	my ($crypted) = $self->{dbh}->selectrow_array("select passwd_hash from admins where login=".$self->{dbh}->quote($username));
	
	if (defined $crypted) {
		$crypted =~ s/\s+//gs;
		if (crypt($password,$crypted) eq $crypted) {
			$self->{userid} = $username;
			$self->_loadProfile($self->{userid});
			return 1;
		}
	}
}

###########################################################

sub _loadProfile {
    my $self = shift;
    my ($userid) = @_;
    
    # store some dummy values
    $self->{userid} = $userid;
    $self->{profile}{username} = $userid;
}
###########################################################

sub isGroupMember {
	return 1;
}

1;
__END__
