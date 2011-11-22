#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;

my $error = '{ "status": "error", "message": "%s" }';

my $cgi = CGI->new;

my $cnfr = ConferenceDB->new;

my $login = $cnfr->login;
print $cgi->header(-type=>'application/json',-charset=>'utf-8',-cookie=>$cnfr->cookie);

my @oper = $cnfr->get_oper_list();

my $cid = $cgi->param('cid');

unless(defined $cid and length $cid) {
	my $out = sprintf $error, "Не определена конференция для добавления оператора";
	print $out,"\n";
	exit(0);
}

unless($cnfr->is_admin($login)) {
	my $out = sprintf $error, "У вас нет прав добавлять операторов";
	print $out,"\n";
	exit(0);
}

my $empty_list = 1;
for(my $i=0; $i<=$#oper; $i++) {
	next if($oper[$i]{'admin'});
	$empty_list = 0;
}

if($empty_list) {
	my $out = sprintf $error, "Отсутствуют операторы конференций";
	print $out,"\n";
	exit(0);
}

my $json = "[";

for(my $i=0; $i<=$#oper; $i++) {
	next if($oper[$i]{'admin'});
	my $obj = "\n" . '{ "name": "' . $oper[$i]{'name'} . '",';
	$obj .= '"aid": "' . $oper[$i]{'aid'} . '",';
	$obj .= '"login": "' . $oper[$i]{'login'} . '",';
	$json .= $obj . '},';
}

chop $json;
$json .= "]\n";

print $json,"\n";
