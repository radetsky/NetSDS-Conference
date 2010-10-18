#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;

my $error = '{ "error": "%s" }';

my $cgi = CGI->new;

my $cnfr = ConferenceDB->new;

my $login = $cgi->remote_user();

my @users = $cnfr->get_user_list();

my %u_to_ph = ();

my $cid = $cgi->param('cid');

if(defined $cid and length $cid) {
	%u_to_ph = $cnfr->get_cnfr_participants($cid);
}

my $json = "[";

for(my $i=0; $i<=$#users; $i++) {
	my $obj = "\n" . '{ "name": "' . $users[$i]{'name'} . '",';
	$obj .= '"uid": "' . $users[$i]{'id'} . '",';
	if(exists $u_to_ph{$users[$i]{'id'}}{'id'}) {
		$obj .= ' "disable": true, ';
	} else {
		$obj .= ' "disable": false, ';
	}
	my @phs = @{$users[$i]{'phones'}};
	my @phs_id =  @{$users[$i]{'phones_id'}};
	my $p_lst = "";
	for(my $j=0; $j<=$#phs; $j++) {
		$p_lst .= "\n" . '{ "ph_id": "' . $phs_id[$j] . '", "phone": "' . $phs[$j] . '"},';
	}
	chop $p_lst;
	$json .= $obj . "\n" . '"ph_list": [' . $p_lst . "\n" . ']},';
}

chop $json;
$json .= "]\n";

print $cgi->header(-type=>'application/json',-charset=>'utf-8');
print $json,"\n";
