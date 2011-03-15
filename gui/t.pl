#!/usr/bin/perl -w

use strict;
use CGI;

my $cgi = CGI->new;

print "Content-type: text/plain\n\n";

foreach my $k (keys %ENV) {
    print "$k\t\t=>{$ENV{$k}}\n";
}

print "\n\n";
print "HTTP Protocol is ".($cgi->http ? 'ON' : 'OFF')."\n";
print "HTTPS Protocol is ".($cgi->https ? 'ON' : 'OFF')."\n";

exit(0);
