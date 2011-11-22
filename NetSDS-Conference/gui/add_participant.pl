#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;

my $error = '{ "error": "%s" }';

my $cgi = CGI->new;

my $cnfr = ConferenceDB->new;
my $login = $cnfr->login();

my $cn_id = $cgi->param("cnid");

my $ph_id = $cgi->param("phid");

my $out = '{"result": "ok"}';

unless($cnfr->add_participant_to_conference($cn_id, $ph_id, $login)) {
	$out = sprintf $error, $cnfr->get_error();
}

print $cgi->header(-type=>'application/json',-charset=>'utf-8',-cookie=>$cnfr->cookie());
print "$out\n";

