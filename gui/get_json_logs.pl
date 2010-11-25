#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;

my $error = '{ "status": "error", "message": "%s" }';

my $cgi = CGI->new;
my $login = $cgi->remote_user();
$login = "root";

my $cnfr = ConferenceDB->new;

my @rights = $cnfr->get_cnfr_rights($login);

my $cid = $cgi->param("cnf");
my $from = $cgi->param("from");
my $to = $cgi->param("to");

print $cgi->header(-type=>'application/json',-charset=>'utf-8');

unless(defined $cid and length $cid) {
	my $out = sprintf $error, "Неопределен номер конференции";
	print $out,"\n";
	exit;
}

if(!grep(/^$cid$/, @rights)) {
	my $out = sprintf $error, "Вы не являетесь оператором данной конференции";
	print $out,"\n";
	exit;
}

$from .= " 00:00:00";
$to .= " 23:59:59";

my @log_list = $cnfr->get_log($cid, $from, $to);

unless(@log_list) {
	my $out = sprintf $error, "На выбраный период времени логи для указанной конференции отсутствуют";
	print $out,"\n";
	exit;
}

my $json = '{ "status": "ok", "logs": [';

while(my $i = shift @log_list) {
	$json .= '{ "time": "' . $$i{'time'} . '", ';
	$json .= '"type": "' . $$i{'type'} . '", ';
	$json .= '"field": "' . $$i{'field'} . '"},';
}

chop $json;
$json .= '] }';

print $json;

exit;
