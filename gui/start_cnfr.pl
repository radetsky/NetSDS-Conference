#!/usr/bin/perl -w

use strict;
use CGI;
use Date::Manip;

use lib './lib';
use ConferenceDB;

my %days = ("Пн"=>"mo",
						"Вт"=>"tu",
						"Ср"=>"we",
						"Чт"=>"th",
						"Пт"=>"fr",
						"Сб"=>"sa",
						"Вс"=>"su");

my $error = '{ "error": %s}';

my $cgi = CGI->new;

my $cnfr = ConferenceDB->new;

my $login = $cgi->remote_user();

my $admin = $cnfr->is_admin($login);

my @rights = $cnfr->get_cnfr_rights($login);

my $id = $cgi->param("ce_id");

if(!grep(/^$id$/, @rights)) {
	my $out = sprintf $error, '"Вы не можете редактировать это совещание"';
	print $cgi->header(-type=>'application/json',-charset=>'utf-8');
	print $out;
	exit;
}

if($admin) {
	my @ops =  split(/[\s]+/, $cgi->param('ops_ids'));
	$cnfr->set_cnfr_operators($login, $id, @ops);
	my $number_b = $cgi->param('number_b');
	$number_b = "" unless(defined $number_b and length $number_b);
	my $res = $cnfr->set_number_b($login, $id, $number_b);
}

my $ce_name = $cgi->param('ce_name');
$ce_name = "Конференция $id" unless(defined $ce_name);

my $next_type = $cgi->param('next_sched');
my ($next_start, $next_duration, $schedule_day, $schedule_time, $schedule_duration) =
("", "", "", "", "");

if($next_type eq "next") {
	my $n_d_h = $cgi->param('dur_hours');
	my $n_d_m = $cgi->param('dur_min');

	$next_duration = "$n_d_h:$n_d_m:00" if(defined $n_d_h and defined $n_d_m);
} else {
	my $sched = $cgi->param('schedule_day');
	if($sched =~ /^[0-9\s]+$/) {
		$schedule_day = $sched;
	} else {
		$schedule_day = join(' ', (map { $days{$_} } split(/[\s]/, $sched)));
	}
	my $s_h = $cgi->param('schedule_hours_begin');
	my $s_m = $cgi->param('schedule_min_begin');
	$schedule_time = "$s_h:$s_m" if(defined $s_h and defined $s_m );
	my $s_h_d = $cgi->param("sched_dur_hours");
	my $s_m_d = $cgi->param("sched_dur_min");
	$schedule_duration = "$s_h_d:$s_m_d:00" if(defined $s_h_d and defined $s_m_d);
	$next_duration = $schedule_duration;
}

$next_start = UnixDate("today", "%Y-%m-%d %H:%M");

#warn "$schedule_day $schedule_time $schedule_duration";

my $auth_type = "";
my $auth_string = $cgi->param('auth_string');
if(defined $cgi->param('number_auth') and $cgi->param('number_auth') eq "on") {
	$auth_type .= "number ";
}

if(defined $cgi->param('pin_auth') and $cgi->param('pin_auth') eq "on" and
	 defined $auth_string and length $auth_string) {
	$auth_type .= "pin";
} else {
	$auth_string = "";
}

my $auto_assemble = (defined $cgi->param('auto_assemble'))? 1 : 0;
my $lost_control = (defined $cgi->param('lost_control'))? 1 : 0;
my $need_record = (defined $cgi->param('need_record'))? 1 : 0;
my $audio_lang = $cgi->param('audio_lang');

my @partic = ();
my $pp = $cgi->param('phs_ids');
if(defined $pp and length $pp) {
	@partic = split(/[\s]+/, $pp);
}

$cnfr->save_cnfr($login, $id, $ce_name, $next_start, $next_duration, $schedule_day, $schedule_time, $schedule_duration,
								 $auth_type, $auth_string, $auto_assemble, $lost_control, $need_record, $audio_lang,
								 \@partic);

my $out = sprintf $error, "false";
print $cgi->header(-type=>'application/json',-charset=>'utf-8');
print $out;
exit;
