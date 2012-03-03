#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;

my $cgi = CGI->new;

my $cnfr = ConferenceDB->new;
my $login = $cnfr->login;
my @c_list = $cnfr->get_cnfr_rights($login);

my @confs = $cnfr->cnfr_list();

my $json = "[";
my $cn_name = undef; 
while(my $i = shift @c_list) {
	$json .= '{ "id": "' . $i . '", ';
	$cn_name = $confs[$i]{'cnfr_name'};
	$cn_name =~ s/"/\\"/g;
	$json .= '"name": "' . $cn_name . '"},';
}

chop $json;
$json .= ']';

print $cgi->header(-type=>'application/json',-charset=>'utf-8',-cookie=>$cnfr->cookie);
print $json;

exit;
