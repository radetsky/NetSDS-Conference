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

my %users = $cnfr->get_cnfr_participants($cid);
my %guests = ();
my $ind = 0;

if($res ne 0 and exists $$res{$cid}) {
	my $u_list = $konf->konference_list_konf($cid);

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
			my %u = $cnfr->get_user_by_phone($$u_list{$j}{'callerid'});
			if(%u) {
				$guests{$ind}{'user_id'} = $u{'user_id'};
				$guests{$ind}{'phone_id'} = $u{'phone_id'};
				$guests{$ind}{'name'} = $u{'name'};
			} else {
				$guests{$ind}{'name'} = "Неизвестный пользователь";
			}
			$guests{$ind}{'number'} = $$u_list{$j}{'callerid'};
			$guests{$ind}{'audio'} = $$u_list{$j}{'audio'};
			$guests{$ind}{'member_id'} = $j;
			$guests{$ind}{'spy'} = $$u_list{$j}{'spy'};
			$guests{$ind}{'flags'} = $$u_list{$j}{'flags'};
			$guests{$ind}{'volume'} = $$u_list{$j}{'volume'};
			$guests{$ind}{'channel'} = $$u_list{$j}{'channel'};
			$ind++;
		}
	}
}

my $json = '[';

foreach my $k (keys %users) {
	$json .= '{ "user_id": "' . $k . '", ';
	$json .= '"user_name": "' . $users{$k}{'name'} . '", ';
	$json .= '"phone": "' . $users{$k}{'number'} . '", ';
	$json .= '"phone_id": "' . $users{$k}{'id'} . '",';
	$json .= '"known": true,';
	if(defined $users{$k}{'member_id'}) {
		$json .= '"state": "online",';
		$json .= '"audio": "' . $users{$k}{'audio'} . '",';
		$json .= '"member_id": "' . $users{$k}{'member_id'} . '",';
		$json .= '"channel": "' . $users{$k}{'channel'} . '",';
	} else {
		$json .= '"state": "offline",';
	}
	chop $json;
	$json .= '},';
}

foreach my $k (keys %guests) {
	$json .= '{ ';
	if(exists $guests{$k}{'user_id'}) {
		$json .= '"user_id": "' . $guests{$k}{'user_id'} . '", ';
		$json .= '"phone_id": "' . $guests{$k}{'phone_id'} . '",';
	}
	$json .= '"known": false,';
	$json .= '"user_name": "' . $guests{$k}{'name'} . '",';
	$json .= '"phone": "' . $guests{$k}{'number'} . '",';
	$json .= '"state": "online",';
	$json .= '"audio": "' . $guests{$k}{'audio'} . '",';
	$json .= '"member_id": "' . $guests{$k}{'member_id'} . '",';
	$json .= '"channel": "' . $guests{$k}{'channel'} . '"},';
}

chop $json;

$json .= ']';

print $cgi->header(-type=>'application/json',-charset=>'utf-8');
print $json;
exit(0);
