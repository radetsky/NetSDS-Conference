#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;

my $cgi = CGI->new;
my $cnfr = ConferenceDB->new;
print $cgi->header(-type=>'text/html',-charset=>'utf-8');
print $cnfr->servertime,"\n";

exit;
