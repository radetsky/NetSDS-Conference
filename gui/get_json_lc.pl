#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;

my $cgi = CGI->new;
my $login = $cgi->remote_user();

my $cnfr = ConferenceDB->new;

my @c_list = $cnfr->get_cnfr_rights($login);

my @confs = $cnfr->cnfr_list();

my $json = "[";

while(my $i = shift @c_list) {
	$json .= '{ "id": "' . $i . '", ';
	$json .= '"name": "' . $confs[$i]{'cnfr_name'} . '"},';
}

chop $json;
$json .= ']';

print $cgi->header(-type=>'application/json',-charset=>'utf-8');
print $json;

exit;
