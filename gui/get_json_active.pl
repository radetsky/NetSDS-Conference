#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;
#use NetSDS::Konference;

my $error = '{ "status": "error", "message": "%s" }';

my $cgi = CGI->new;
my $cnfr = ConferenceDB->new;
my $login = $cgi->remote_user();
$login = "root";
my $admin = $cnfr->is_admin($login);
my @rights = $cnfr->get_cnfr_rights($login);
my $cid = $cgi->param("cid");

unless(defined $cid and length $cid) {
	my $out = sprintf $error, "Неопределен номер конференции";
	print $cgi->header(-type=>'application/json',-charset=>'utf-8');
	print $out;
	exit;
}

if(!grep(/^$cid$/, @rights)) {
	my $out = sprintf $error, "Вы не являетесь оператором данной конференции";
	print $cgi->header(-type=>'application/json',-charset=>'utf-8');
	print $out;
	exit;
}

#my $konf = NetSDS::Konference->new();

#$konf->konference_connect('localhost','5038','asterikastwww','asterikastwww');

#my $res = $konf->konference_list();

#unless(defined $res) {
#	my $out = sprintf $error, "Ошибка подключения к Asterisk. Обратитесь к системному администратору.";
#	print $cgi->header(-type=>'application/json',-charset=>'utf-8');
#	print $out;
#	exit;
#}

my %users = $cnfr->get_cnfr_participants($cid);

my $json = '[';

foreach my $k (keys %users) {
	$json .= '{ "user_id": "' . $k . '", ';
	$json .= '"user_name": "' . $users{$k}{'name'} . '", ';
	$json .= '"phone": "' . $users{$k}{'number'} . '", ';
	$json .= '"phone_id": "' . $users{$k}{'id'} . '"},';
}

chop $json;

$json .= ']';

print $cgi->header(-type=>'application/json',-charset=>'utf-8');
print $json;
exit(0);
