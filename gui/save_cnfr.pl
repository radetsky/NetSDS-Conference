#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;

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

my $ce_name = $cgi->param('ce_name');
$ce_name = "Конференция $id" unless(defined $ce_name);
my $n_d = $cgi->param('next_date');
my $n_h = $cgi->param('hours_begin');
my $n_m = $cgi->param('min_begin');

my $next_start = "$n_d $n_h:$n_m";
warn $next_start;
$next_start = undef unless(defined $n_d and defined $n_h and defined $n_m);

my $next_duration = $cgi->param('duration');

my $schedule_day = $cgi->param('schedule_day');
my $s_h = $cgi->param('schedule_hours_begin');
my $s_m = $cgi->param('schedule_min_begin');
my $schedule_time = undef;
$schedule_time = "$s_h:$s_m" if(defined $s_h and defined $s_m 
																and $s_h =~ /^[1,2][0-9]$/ and $s_m =~ /^[0-6][0-9]$/);
my $auth_string = $cgi->param('auth_string');
my $auth_type = $cgi->param('auth_type');
$auth_type = undef unless(defined $auth_string);
my $auto_assemble = (defined $cgi->param('auto_assemble'))? 1 : 0;
my $lost_control = (defined $cgi->param('lost_control'))? 1 : 0;
my $need_record = (defined $cgi->param('need_record'))? 1 : 0;
my $audio_lang = $cgi->param('audio_lang');

my @partic = split(/[\s]+/, $cgi->param('phs_ids'));

$cnfr->save_cnfr($login, $id, $ce_name, $next_start, $next_duration, $schedule_day, $schedule_time,
								 $auth_type, $auth_string, $auto_assemble, $lost_control, $need_record, $audio_lang,
								 \@partic);

my $out = sprintf $error, "false";
print $cgi->header(-type=>'application/json',-charset=>'utf-8');
print $out;
exit;

