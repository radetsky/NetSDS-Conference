#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;
use NetSDS::Konference;

my $error = '{ "status": "error", "message": "%s" }';

my $cgi = CGI->new;
my $cnfr = ConferenceDB->new;
my $login = $cgi->remote_user();
my $admin = $cnfr->is_admin($login);
my @rights = $cnfr->get_cnfr_rights($login);
my $cid = $cgi->param("cid");

unless(defined $cid and length $cid) {
	my $out = sprintf $error, "Неопределен номер конференции";
	print $cgi->header(-type=>'application/json',-charset=>'utf-8');
	print $out,"\n";
	exit;
}

if(!grep(/^$cid$/, @rights)) {
	my $out = sprintf $error, "Вы не являетесь оператором данной конференции";
	print $cgi->header(-type=>'application/json',-charset=>'utf-8');
	print $out,"\n";
	exit;
}

my $konf = NetSDS::Konference->new();

$konf->konference_connect('localhost','5038','asterikastwww','asterikastwww');

my $res = $konf->konference_list();

unless(defined $res) {
	my $out = sprintf $error, "Ошибка подключения к Asterisk. Обратитесь к системному администратору.";
	print $cgi->header(-type=>'application/json',-charset=>'utf-8');
	print $out,"\n";
	exit;
}

unless($res ne 0 and exists $$res{$cid}) {
	my $out = sprintf $error, "Выбранная конференция не является активной.";
	print $cgi->header(-type=>'application/json',-charset=>'utf-8');
	print $out,"\n";
	exit;
}

my $u_list = $konf->konference_list_konf($cid);

my %users = $cnfr->get_cnfr_participants($cid);

foreach my $j (keys(%{$u_list})) {
	my $found = 0;
	foreach my $k (keys %users) {
		if($users{$k}{'number'} eq $$u_list{$j}{'callerid'}) {
			$found = 1;
			$users{$k}{'audio'} = $$u_list{$j}{'audio'};
			$users{$k}{'member_id'} = $j;
			$users{$k}{'spy'} = $$u_list{$j}{'spy'};
			$users{$k}{'flags'} = $$u_list{$j}{'flags'};
			$users{$k}{'volume'} = $$u_list{$j}{'volume'};
			$users{$k}{'channel'} = $$u_list{$j}{'channel'};
		}
	}
	unless($found) {
	}
}


my $json = '[';

foreach my $k (keys %users) {
	$json .= '{ "user_id": "' . $k . '", ';
	$json .= '"user_name": "' . $users{$k}{'name'} . '", ';
	$json .= '"phone": "' . $users{$k}{'number'} . '", ';
	$json .= '"phone_id": "' . $users{$k}{'id'} . '",';
	if(defined $users{$k}{'member_id'}) {
		$json .= '"state": "online",';
		$json .= '"audio": "' . $users{$k}{'audio'} . '",';
		$json .= '"member_id": "' . $users{$k}{'member_id'} . '",';
	} else {
		$json .= '"state": "offline",';
	}
	chop $json;
	$json .= '},';
}

chop $json;

$json .= ']';

print $cgi->header(-type=>'application/json',-charset=>'utf-8');
print $json;
exit(0);
