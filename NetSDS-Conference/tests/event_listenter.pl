#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  event_listenter.pl
#
#        USAGE:  ./event_listenter.pl 
#
#  DESCRIPTION:  
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Alex Radetsky (Rad), <rad@rad.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.0
#      CREATED:  12/09/2010 06:48:06 PM MSK
#     REVISION:  ---
#===============================================================================

use 5.8.0;
use strict;
use warnings;

use lib '../lib';


use NetSDS::Asterisk::EventListener; 
use Data::Dumper; 

my $el = NetSDS::Asterisk::EventListener->new (
	       host     => '127.0.0.1',
           port     => '5038',
	       username => 'asterikastwww',
		   secret   => 'asterikastwww'
		   ); 
while (1) 
{
	my $res = $el->_getEvent(); 
	warn Dumper ($res); 
	sleep(1); 
} 




1;
#===============================================================================

__END__

=head1 NAME

event_listenter.pl

=head1 SYNOPSIS

event_listenter.pl

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

