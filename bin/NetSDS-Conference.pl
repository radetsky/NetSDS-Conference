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

use lib '../lib/'; 

use base qw(NetSDS::App); 
use ConferenceDB;
use Data::Dumper;
use Date::Manip;

sub start { 
	my ($this) = @_; 

	$this->speak("[$$] NetStyle NetSDS-Conference Service start.");
	$this->mk_accessors('mydb'); 	
	$this->mydb(ConferenceDB->new());  
		
	
}

sub process { 
	my ($this) = @_; 
	$this->speak("[$$] Processing ."); 
	my @conf_list=$this->mydb->cnfr_list(); 
	
	foreach my $conf (@conf_list) { 	
		my $conf_start = $conf->{'next_start'};
		unless ( defined ( $conf_start ) ) { next; } 
		if ($conf_start eq '') { 
			next; 
		} 
		printf("ID: %2s Next Start: %s\n",$conf->{'cnfr_id'},$conf->{'next_start'} );
		my $date_from_db = ParseDate($conf->{'next_start'}); 
		my $date_now     = ParseDate('now'); 
		my $flag = Date_Cmp($date_now,$date_from_db); 
		if ($flag >= 0) { # next_start in the past
			if ($conf->{'cnfr_state'} ne 'active') { # Еще не установлен флаг активности 
				$this->_conference_start($conf); 
			} 
		}
	}
}

sub _conference_start { 
	my $this = shift; 
	my $conf = shift; 
	
	$this->speak("[$$] Starting conference ID: ".$conf->{'cnfr_id'}); 


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

