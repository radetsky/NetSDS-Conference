#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;

my $cgi = CGI->new;
my $cnfr = ConferenceDB->new;
my $login = $cnfr->login;
print $cgi->header(-type=>'text/html',-charset=>'utf-8',-cookie=>$cnfr->cookie);
print $cnfr->servertime," <img src=\"/css/images/user.png\" style=\"vertical-align:middle;margin-left:2em;\" alt=\"\" />$login\n";

exit;
