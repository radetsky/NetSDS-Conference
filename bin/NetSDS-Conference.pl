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

NetSDSConference->run (
		daemon => undef, 
		verbose => 1, 
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

use base qw(NetSDS::App); 

use DBI;
use ConferenceDB;

sub start { 
	my ($this) = @_; 

	$this->speak("[$$] NetStyle NetSDS-Conference Service start.");

	# DB Connect
	
	
}

sub process { 
	my ($this) = @_; 
	$this->speak("[$$] Processing ."); 



}



1;
#===============================================================================

__END__

=head1 NAME

NetSDS-Conference.pl

=head1 SYNOPSIS

NetSDS-Conference.pl

=head1 DESCRIPTION

FIXME

=head1 EXAMPLES

FIXME

=head1 BUGS

Unknown.

=head1 TODO

Empty.

=head1 AUTHOR

Alex Radetsky <rad@rad.kiev.ua>

=cut

