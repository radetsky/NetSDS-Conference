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

NetSDS::Konference

=head1 SYNOPSIS

use NetSDS::Konference;
my $konf = NetSDS::Konference->new();
$konf->konference_connect('localhost','5038','asterikastwww','asterikastwww');
my $res = $konf->konference_list();
my $members = $konf->konference_list_konf($conf);
my $kicked = $konf->konference_kick ($conf,49);

=head1 DESCRIPTION

C<NetSDS> module contains functions to manage Asterisk Konference() application and members of conferences. 

=cut

package NetSDS::Konference;

use 5.8.0;
use strict;
use warnings;

use NetSDS::AMI;
use Data::Dumper; 
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

	return $this;

}

#***********************************************************************

=head1 OBJECT METHODS

=over

=item B<user(...)> - object method

=cut

#-----------------------------------------------------------------------
__PACKAGE__->mk_accessors('AMI');
__PACKAGE__->mk_accessors('connected');

sub konference_connect {
	my ( $this, $host, $port, $user, $secret ) = @_;

	$this->AMI(NetSDS::AMI->new());

	$this->connected (  $this->AMI->connect( $host, $port, $user, $secret, 'Off' ) );
	unless ( defined( $this->connected ) ) {
		return undef;
	}
	return 1;
}
#***********************************************************************

=item B<konference_list(...)> - Get list of active conferences

RETURN: undef or hasref with konferences as keys, value, members and duration as values; 
Zero (0) if no active conferences; 

=cut

#-----------------------------------------------------------------------

sub konference_list {

	my $this = shift;

	unless ( defined( $this->connected ) ) {
		$this->AMI->reconnect();
	}

	my $sent = $this->AMI->sendcommand(
		Action  => 'Command',
		Command => 'konference list'
	);

	unless ( defined($sent) ) {
		return undef;
	}

	my $reply = $this->_receive_raw();

	unless ( defined($reply) ) {
		return undef;
	}
	
	if ($reply->{'raw_strings_count'} == 0) { 
		return 0; 
	} 

	my $ret = undef;
 
	if ( $reply->{'Response'} =~ /^follows/i ) {
		my $lines = $reply->{'raw'}; 
		# warn Dumper ($lines); 
		foreach my $row ( @$lines ) {
			# warn Dumper ($row);
			# Что-то получили. Парсим. Должно быть что-то наподобие:
			# Name                 Members              Volume               Duration
			# 49                   1                    0                    00:14:13
			my ( $KName, $KMembers, $KVolume, $KDuration ) = split( ' ', $row );
			if ($KName =~ /Name/i ) { 
				next; 
			} 
			$ret->{$KName}->{'members'}  = $KMembers;
			$ret->{$KName}->{'volume'}   = $KVolume;
			$ret->{$KName}->{'duration'} = $KDuration;
		} ## end foreach
	} ## end if .

	return $ret; 

} ## end sub konference_list

#***********************************************************************

=item B<konference_list_konf(Konference Number)> - Get list of members of conference

RETURN: undef or hasref with konferences as keys, value, members and duration as values; 
Zero (0) if no active members; 

=cut

#-----------------------------------------------------------------------

sub konference_list_konf {

	my $this = shift;
	my $konfnum = shift; 

	unless ( defined ( $konfnum ) ) { 
		return undef; 
	}

	unless ( defined( $this->connected ) ) {
		$this->AMI->reconnect();
	}

	my $sent = $this->AMI->sendcommand(
		Action  => 'Command',
		Command => 'konference list '.$konfnum , 
	);

	unless ( defined($sent) ) {
		return undef;
	}

	my $reply = $this->_receive_raw();

	unless ( defined($reply) ) {
		return undef;
	}

	if ($reply->{'raw_strings_count'} == 0) { 
		return 0; 
	} 

	my $ret = undef;
	if ( $reply->{'Response'} =~ /^follows/i ) {
		my $lines = $reply->{'raw'}; 
		foreach my $row ( @$lines ) {
			# warn Dumper ($row);
			# Что-то получили. Парсим. Должно быть что-то наподобие:
			#User Flags Audio Volume  Duration  Spy  Channel 
			# 1 Ra Unmuted 0:0  01:48:38  * IP/4001-0000001f
			my ( $KUser,  $KFlags, $KAudio, $KVolume, $KDuration, $KSpy, $KChannel ) = split( ' ', $row );
			if ($KUser =~ /User/i ) { 
				next; 
			}
			 
			$ret->{$KUser}->{'flags'}  = $KFlags;
			$ret->{$KUser}->{'audio'}  = $KAudio;
  			$ret->{$KUser}->{'volume'} = $KVolume;
			$ret->{$KUser}->{'duration'} = $KDuration; 
			$ret->{$KUser}->{'spy'} = $KSpy;
			$ret->{$KUser}->{'channel'} = $KChannel; 


		} ## end foreach
	} ## end if .

	# Find CallerIDNums

	my @replies = $this->AMI->get_status(); 
	foreach my $status (@replies) { 
		foreach my $member (keys %$ret) { 
			if ( $status->{'Channel'} eq $ret->{$member}->{'channel'} ) { 
				unless ( defined ( $status->{'CallerIDNum'} ) ) { 
					next; 
				}
				$ret->{$member}->{'callerid'} = $status->{'CallerIDNum'}; 
			}
		}
	}
	return $ret; 


}
#***********************************************************************

=item B<konference_kick(<conference>,<member id>)> - Kicks out Member from conference

RETURN: undef if error, 1 if ok. 

=cut

#-----------------------------------------------------------------------

sub konference_kick { 
	my ( $this, $konfnum, $member_id )  = @_; 

	unless ( defined ( $konfnum ) ) { return undef; } 
	unless ( defined ( $member_id ) ) { return undef; } 
	
	my $sent = $this->AMI->sendcommand ( 
		Action => 'Command', 
		Command => "konference kick $konfnum $member_id"
 	); 

	unless ( defined ( $sent ) ) { return undef; } 
	my $reply = $this->_receive_raw();
	unless ( defined($reply) ) { return undef; }               
	if ($reply->{'raw_strings_count'} == 0) { return undef; }  # If no confirmation like "User #: 1 kicked" - error
	my $lines = $reply->{'raw'}; 
	foreach my $row ( @$lines ) {
		# warn Dumper ($row);
		# Что-то получили. Парсим. Должно быть что-то наподобие:
		# User #: 1 kicked
		my ( $KUser, $KConfirm) = split( ':', $row );
		if ($KConfirm =~ /kicked/i) { 
			return 1; 
		}
	} ## end foreach
	
	return undef; 
}
#***********************************************************************

=item B<konference_kickchannel(<channel>)> - Kicks out channel from any conference

RETURN: undef if error, 1 if ok. 

=cut

#-----------------------------------------------------------------------

sub konference_kickchannel { 
	my ( $this, $channel )  = @_; 

	unless ( defined ( $channel ) ) { return undef; } 
	
	my $sent = $this->AMI->sendcommand ( 
		Action => 'Command', 
		Command => "konference kickchannel $channel"
 	); 

	unless ( defined ( $sent ) ) { return undef; } 
	my $reply = $this->_receive_raw();
	unless ( defined($reply) ) { return undef; }
	return 1;
}

#***********************************************************************
=item B<konference_mute(<conference>,<member id>)> - Mutes Member in conference

RETURN: undef if error, 1 if ok. 

=cut

#-----------------------------------------------------------------------

sub konference_mute { 
	my ( $this, $konfnum, $member_id )  = @_; 

	unless ( defined ( $konfnum ) ) { return undef; } 
	unless ( defined ( $member_id ) ) { return undef; } 
	
	my $sent = $this->AMI->sendcommand ( 
		Action => 'Command', 
		Command => "konference mute $konfnum $member_id"
 	); 

	unless ( defined ( $sent ) ) { return undef; } 
	my $reply = $this->_receive_raw();
	unless ( defined($reply) ) { return undef; }               
	if ($reply->{'raw_strings_count'} == 0) { return undef; }  # If no confirmation like "User #: 1 kicked" - error
	my $lines = $reply->{'raw'}; 
	foreach my $row ( @$lines ) {
		# warn Dumper ($row);
		# Что-то получили. Парсим. Должно быть что-то наподобие:
		# User #: 1 muted
		my ( $KUser, $KConfirm) = split( ':', $row );
		if ($KConfirm =~ /muted/i) { 
			return 1; 
		}
	} ## end foreach
	
	return undef; 
}
#***********************************************************************
=item B<konference_unmute(<conference>,<member id>)> - Unmutes Member in conference

RETURN: undef if error, 1 if ok. 

=cut

#-----------------------------------------------------------------------

sub konference_unmute { 
	my ( $this, $konfnum, $member_id )  = @_; 

	unless ( defined ( $konfnum ) ) { return undef; } 
	unless ( defined ( $member_id ) ) { return undef; } 
	
	my $sent = $this->AMI->sendcommand ( 
		Action => 'Command', 
		Command => "konference unmute $konfnum $member_id"
 	); 

	unless ( defined ( $sent ) ) { return undef; } 
	my $reply = $this->_receive_raw();
	unless ( defined($reply) ) { return undef; }               
	if ($reply->{'raw_strings_count'} == 0) { return undef; }  # If no confirmation like "User #: 1 kicked" - error
	my $lines = $reply->{'raw'}; 
	foreach my $row ( @$lines ) {
		# warn Dumper ($row);
		# Что-то получили. Парсим. Должно быть что-то наподобие:
		# User #: 1 muted
		my ( $KUser, $KConfirm) = split( ':', $row );
		if ($KConfirm =~ /muted/i) { 
			return 1; 
		}
	} ## end foreach
	
	return undef; 
}
#***********************************************************************
=item B<konference_mutechannel(<channel>)> - Mutes channel from any conference

RETURN: undef if error, 1 if ok. 

=cut

#-----------------------------------------------------------------------

sub konference_mutechannel { 
	my ( $this, $channel )  = @_; 

	unless ( defined ( $channel ) ) { return undef; } 
	
	my $sent = $this->AMI->sendcommand ( 
		Action => 'Command', 
		Command => "konference mutechannel $channel"
 	); 

	unless ( defined ( $sent ) ) { return undef; } 
	my $reply = $this->_receive_raw();
	unless ( defined($reply) ) { return undef; }
	return 1;
}
#***********************************************************************
=item B<konference_unmutechannel(<channel>)> - Unmutes channel from any conference

RETURN: undef if error, 1 if ok. 

=cut

#-----------------------------------------------------------------------

sub konference_unmutechannel { 
	my ( $this, $channel )  = @_; 

	unless ( defined ( $channel ) ) { return undef; } 
	
	my $sent = $this->AMI->sendcommand ( 
		Action => 'Command', 
		Command => "konference unmutechannel $channel"
 	); 

	unless ( defined ( $sent ) ) { return undef; } 
	my $reply = $this->_receive_raw();
	unless ( defined($reply) ) { return undef; }
	return 1;
}
#***********************************************************************
=item B<konference_muteconference(<conference>)> - Mutes all members in conference

RETURN: undef if error, 1 if ok. 

=cut

#-----------------------------------------------------------------------

sub konference_muteconference { 
	my ( $this, $konfnum )  = @_; 

	unless ( defined ( $konfnum ) ) { return undef; } 
	
	my $sent = $this->AMI->sendcommand ( 
		Action => 'Command', 
		Command => "konference muteconference $konfnum"
 	); 

	unless ( defined ( $sent ) ) { return undef; } 
	my $reply = $this->_receive_raw();
	unless ( defined($reply) ) { return undef; }
	return 1;
}
=item B<konference_listenvolume(<channel>,<up | down>)> - Adjust listen volume for conference member <channel>

RETURN: undef if error, 1 if ok. 

=cut

#-----------------------------------------------------------------------

sub konference_listenvolume { 
	my ( $this, $channel, $updown )  = @_; 

	unless ( defined ( $channel ) ) { return undef; } 
	unless ( defined ( $updown ) ) { return undef; } 
	if ($updown ne 'up' and $updown ne 'down') { return undef; } 

	my $sent = $this->AMI->sendcommand ( 
		Action => 'Command', 
		Command => "konference listenvolume $channel $updown"
 	); 

	unless ( defined ( $sent ) ) { return undef; } 
	my $reply = $this->_receive_raw();
	unless ( defined($reply) ) { return undef; }
	return 1;
}
=item B<konference_talkvolume(<channel>,<up | down>)> - Adjust talk volume for conference member <channel>

RETURN: undef if error, 1 if ok. 

=cut

#-----------------------------------------------------------------------

sub konference_talkvolume { 
	my ( $this, $channel, $updown )  = @_; 

	unless ( defined ( $channel ) ) { return undef; } 
	unless ( defined ( $updown ) ) { return undef; } 
	if ($updown ne 'up' and $updown ne 'down') { return undef; } 

	my $sent = $this->AMI->sendcommand ( 
		Action => 'Command', 
		Command => "konference talkvolume $channel $updown"
 	); 

	unless ( defined ( $sent ) ) { return undef; } 
	my $reply = $this->_receive_raw();
	unless ( defined($reply) ) { return undef; }
	return 1;
}

=item B<_receive_raw(...)> - Replace NetSDS::AMI->receiveanswer

RETURN: undef if error , hashref if got something

=cut

#-----------------------------------------------------------------------

sub _receive_raw { 

  my $this = shift; 

  my $result = $this->AMI->read_raw();
  unless ( defined($result) ) {
       return undef;
  }

  my $reply = undef; 

  my (@rows) = split( /\n/, $result );
  
  my @raw_strings;
    
  foreach my $row (@rows) {
    if ($row) {
	if ($row =~ /Response: Follows/i) { 
		$reply->{'Response'} = 'Follows'; 
		next;
	} elsif ( $row =~ /Privilege: Command/i ) { 
		$reply->{'Privilege'} = 'Command'; 
		next;
        } elsif ( $row =~ /--END COMMAND--/i ) { 
		last; 
	}
	push @raw_strings,$row; 
    }
  }
  $reply->{'raw_strings_count'} = @raw_strings; 
  $reply->{'raw'} = [ @raw_strings ];   

  return $reply;

}

1;

__END__

=back

=head1 EXAMPLES

see 

=head1 BUGS

Unknown yet

=head1 SEE ALSO

NetSDS::AMI, NetSDS::SMPPD

=head1 TODO

None

=head1 AUTHOR

Alex Radetsky <rad@rad.kiev.ua>

=cut


