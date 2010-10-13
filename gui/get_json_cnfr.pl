#!/usr/bin/perl -w

use strict;
use CGI;

my %s_days = ("mo"=>"Пн", "tu"=>"Вт", "we"=>"Ср", "th"=>"Чт", "fr"=>"Пт", "sa"=>"Сб", "su"=>"Вс");

use lib './lib';
use ConferenceDB;

my $error = '{ "error": "%s" }';

my $cgi = CGI->new;

my $cnfr = ConferenceDB->new;

my $login = $cgi->remote_user();

$login = "root";

my $admin = $cnfr->is_admin($login);

my @rights = $cnfr->get_cnfr_rights($login);

my $id = $cgi->param("id");

if(!grep(/^$id$/, @rights)) {
	my $out = sprintf $error, "Вы не можете редактировать это совещание";
	print $cgi->header(-type=>'application/json',-charset=>'utf-8');
	print $out;
	exit;
}

my %cn = $cnfr->get_cnfr($id);

my ($schedule_hours_begin, $schedule_min_begin, $next_d, $next_t, $sched_d_h, $sched_d_m,
		$hours_begin, $min_begin, $dur_hours, $dur_min) = ("","","","","","","","","","");

my $json = "{";
$json .= '"id": '.$cn{'id'};
$json .= ', "name": "'. $cn{'name'} . '"';
$json .= ', "schedule_day": "';
if(length $cn{'schedule_date'}) {
	if($cn{'schedule_date'} =~ /^[0-9\s]+$/) {
		$json .= join(',', split(/[\s]+/,$cn{'schedule_date'})) . '"';
	} else {
		$json .= join(' ', (map {$s_days{$_}} split(/[\s]+/, $cn{'schedule_date'}))) . '"';
	}
} else {
	$json .= $cn{'schedule_date'} . '"';
}
($schedule_hours_begin, $schedule_min_begin) = split(/:/, $cn{'schedule_time'}) 
			if(length $cn{'schedule_time'});
$json .= ', "schedule_hours_begin": "' . $schedule_hours_begin . '"';
$json .= ', "schedule_min_begin": "' . $schedule_min_begin . '"';
($sched_d_h, $sched_d_m) = split(/:/, $cn{'schedule_duration'})
		if(length $cn{'schedule_duration'});
$json .= ', "sched_dur_hours": "'. $sched_d_h . '"';
$json .= ', "sched_dur_min": "'. $sched_d_m . '"';
($next_d, $next_t) = split(/[\s]+/, $cn{'next_start'})
			if(length $cn{'next_start'});
($hours_begin, $min_begin) = split(/:/, $next_t) if(length $next_t);
$json .= ', "next_date": "' . $next_d . '"';
$json .= ', "hours_begin": "' . $hours_begin . '"';
$json .= ', "min_begin": "' . $min_begin . '"';
($dur_hours, $dur_min, undef) = split(/:/, $cn{'next_duration'})
			if(length $cn{'next_duration'});
$json .= ', "dur_hours": "'. $dur_hours .'", "dur_min": "'. $dur_min .'"';
#$json .= ', "next_duration": "' . $cn{'next_duration'} . '"';
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

my @users = @{$cn{'users'}};

$json .= ', "users": [ ';
for(my $k=0; $k<=$#users; $k++) {
	$json .= ' {"usr": "' . $users[$k]{'name'} .'",';
	$json .= ' "phone": "' . $users[$k]{'phone'} .'",';
	$json .= ' "phone_id": "' . $users[$k]{'phone_id'} .'"},';
}

chop $json;

$json .= "]}";

print $cgi->header(-type=>'application/json',-charset=>'utf-8');
print "$json\n";
