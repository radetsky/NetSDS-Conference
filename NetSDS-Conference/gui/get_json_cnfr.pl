#!/usr/bin/perl -w

use strict;
use CGI;

my %s_days = ("Mon"=>"Пн", "Tue"=>"Вт", "Wed"=>"Ср", "Thu"=>"Чт", "Fri"=>"Пт", "Sat"=>"Сб", "Sun"=>"Вс");

use lib './lib';
use ConferenceDB;

my $error = '{ "error": "%s" }';

my $cgi = CGI->new;

my $cnfr = ConferenceDB->new;

my $login = $cnfr->login;

my $oper_id = $cnfr->operator($login);
my $admin = $cnfr->{oper_admin};
my $ab = $cnfr->addressbook;

my @rights = $cnfr->get_cnfr_rights($login);

my $id = $cgi->param("id");

if(!grep(/^$id$/, @rights)) {
	my $out = sprintf $error, "Вы не можете редактировать это совещание";
	print $cgi->header(-type=>'application/json',-charset=>'utf-8',-cookie=>$cnfr->cookie);
	print $out;
	exit;
}

my %cn = $cnfr->get_cnfr($id);

my ($next_d, $next_t, $hours_begin, $min_begin, $dur_hours, $dur_min) = ("","","","","","");

my $cn_name = $cn{'name'}; 
$cn_name =~ s/"/\\"/g; 

my $json = "{";
$json .= '"id": '.$cn{'id'};
$json .= ', "name": "'. $cn_name . '"';
if($admin) {
	$json .= ', "admin": true';
} else {
	$json .= ', "admin": false';
}
($next_d, $next_t) = split(/[\s]+/, $cn{'next_start'})
			if(length $cn{'next_start'});
($hours_begin, $min_begin) = split(/:/, $next_t) if(length $next_t);
$json .= ', "next_date": "' . $next_d . '"';
$json .= ', "hours_begin": "' . $hours_begin . '"';
$json .= ', "min_begin": "' . $min_begin . '"';
($dur_hours, $dur_min, undef) = split(/:/, $cn{'next_duration'})
			if(length $cn{'next_duration'});
$json .= ', "dur_hours": "'. $dur_hours .'", "dur_min": "'. $dur_min .'"';
if($cn{'auth_type'} =~ /pin/) {
	$json .= ', "pin_auth": true';
} else {
	$json .= ', "pin_auth": false';
}
if($cn{'auth_type'} =~ /number/) {
	$json .= ', "number_auth": true';
} else {
	$json .= ', "number_auth": false';
}

$json .= ', "auth_string": "' . $cn{'auth_string'} . '"';
$json .= ', "auto_assemble": "' . $cn{'auto_assemble'} . '"';
$json .= ', "lost_control": "' . $cn{'lost_control'} . '"';
$json .= ', "need_record": "' . $cn{'need_record'} . '"';
$json .= ', "number_b": "' . $cn{'number_b'} . '"';
$json .= ', "audio_lang": "' . $cn{'audio_lang'} . '"';
$json .= ', "ph_remind": "' . $cn{'ph_remind'} . '"';
$json .= ', "em_remind": "' . $cn{'em_remind'} . '"';
if(length $cn{'remind_time'}) {
	$cn{'remind_time'} =~ s/^([\d]{2}:[\d]{2}).*$/$1/;
}
$json .= ', "remind_time": "' . $cn{'remind_time'} . '"';

my @sched = @{$cn{'schedules'}};
$json .= ', "schedules": [ ';

for(my $k=0; $k<=$#sched; $k++) {
	if($sched[$k]{'day'} =~ /^[\d]+$/) {
		$json .= ' {"day": "' . $sched[$k]{'day'} .'",';
	} else {
		$json .= ' {"day": "' . $s_days{$sched[$k]{'day'}} .'",';
	}
	$sched[$k]{'begin'} =~ s/^([\d]{2}:[\d]{2}).*$/$1/;
	$json .= ' "begin": "' . $sched[$k]{'begin'} .'",';
	$sched[$k]{'duration'} =~ s/^([\d]{2}:[\d]{2}).*$/$1/;
	$json .= ' "duration": "' . $sched[$k]{'duration'} .'",';
	$json .= ' "valid": true},';
}

chop $json;
$json .= "]";

my %a_list = $cnfr->get_audio_list();

$json .= ', "audio": [ ';
foreach my $k (keys %a_list) {
	$json .= ' {"auid": "' . $k . '", ';
	if($cn{'au_id'} eq $k) {
		$json .= ' "selected": true, ';
	} else {
		$json .= ' "selected": false, ';
	}
	$json .= ' "name": "' . $a_list{$k} . '"},';
}

chop $json;
$json .= "]";

my @users = @{$cn{'users'}};

$json .= ', "users": [ ';
for(my $k=0; $k<=$#users; $k++) {
	$json .= ' {"usr": "' . $users[$k]{'name'} .'",';
	$json .= ' "phone": "' . $users[$k]{'phone'} .'",';
	$json .= ' "phone_id": "' . $users[$k]{'phone_id'} .'"},';
}

chop $json;
$json .= "]";

my %ops = $cnfr->get_conference_operators($id);

$json .= ', "opers": [ ';

foreach my $j (keys %ops) {
	$json .= ' {"oper_id": "' . $j . '",';
	$json .= ' "fname": "' . $ops{$j}{'name'} . '",';
	$json .= ' "login": "' . $ops{$j}{'login'} . '"},';
}

chop $json;

$json .= "]}";

print $cgi->header(-type=>'application/json',-charset=>'utf-8',-cookie=>$cnfr->cookie);
print "$json\n";
