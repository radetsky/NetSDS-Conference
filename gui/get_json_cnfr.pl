#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;

my $error = '{ "error": "%s" }';

my $cgi = CGI->new;

my $cnfr = ConferenceDB->new;

my $login = $cgi->remote_user();

#$login = "root";

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

my $json = "{";
$json .= '"id": '.$cn{'id'};
$json .= ', "name": "'. $cn{'name'} . '"';
$json .= ', "shedule_day": "' . $cn{'shedule_date'} . '"';
my ($schedule_hours_begin, $schedule_min_begin) = split(/:/, $cn{'shedule_time'});
$json .= ', "schedule_hours_begin": "' . $schedule_hours_begin . '"';
$json .= ', "schedule_min_begin": "' . $schedule_min_begin . '"';
my ($next_d, $next_t) = split(/[\s]+/, $cn{'next_start'});
my ($hours_begin, $min_begin) = split(/:/, $next_t);
$json .= ', "next_date": "' . $next_d . '"';
$json .= ', "hours_begin": "' . $hours_begin . '"';
$json .= ', "min_begin": "' . $min_begin . '"';
$json .= ', "next_duration": "' . $cn{'next_duration'} . '"';
$json .= ', "auth_type": "' . $cn{'auth_type'} . '"';
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
