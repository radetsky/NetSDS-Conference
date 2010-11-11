#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;

my $error = '{ "status": "error", "message": "%s" }';

my $cgi = CGI->new;
my $cnfr = ConferenceDB->new;
my $login = $cgi->remote_user();
my $cid = $cgi->param('cid');
my $phid = $cgi->param('phid');

if($phid eq "empty") {
	$phid = "";
}

print $cgi->header(-type=>'application/json',-charset=>'utf-8');

if($cnfr->set_priority($login, $cid, $phid)) {
	print '{ "status": "ok" }',"\n";
} else {
	my $out = sprintf $error, $cnfr->get_error();
	print $out,"\n";
}

exit;
