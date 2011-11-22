#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;

my $error = '{ "status": "error", "message": "%s" }';

my $cgi = CGI->new;
my $cnfr = ConferenceDB->new;
my $login = $cnfr->login;
my $cid = $cgi->param('cid');

print $cgi->header(-type=>'application/json',-charset=>'utf-8',-cookie=>$cnfr->cookie);

$cnfr->stop_cnfr($login, $cid);

print '{ "status": "ok" }',"\n";
exit(0);
