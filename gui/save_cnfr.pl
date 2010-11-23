#!/usr/bin/perl -w

use strict;
use CGI;
use Date::Manip;

use lib './lib';
use ConferenceDB;

my %days = ("Пн"=>"Mon",
						"Вт"=>"Tue",
						"Ср"=>"Wed",
						"Чт"=>"Thu",
						"Пт"=>"Fri",
						"Сб"=>"Sat",
						"Вс"=>"Sun");

my %d_ord = ("Mon"=>1, "Tue"=>2, "Wed"=>3, "Thu"=>4, "Fri"=>5, "Sat"=>6, "Sun"=>7);

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

my $next_type = $cgi->param('next_sched');
my ($next_start, $next_duration) = ("", "");
my @schedules = ();

if($next_type eq "next") {
	my $n_d = $cgi->param('next_date');
	my $n_h = $cgi->param('hours_begin');
	my $n_m = $cgi->param('min_begin');

	$next_start = "$n_d $n_h:$n_m" if(defined $n_d and defined $n_h and defined $n_m);

	my $n_d_h = $cgi->param('dur_hours');
	my $n_d_m = $cgi->param('dur_min');

	$next_duration = "$n_d_h:$n_d_m:00" if(defined $n_d_h and defined $n_d_m);
} else {
	my $scheds = $cgi->param('schedules');
	my @every_sch = split(/\|/,$scheds);
	my @deltas = ();
	my @nexts = ();
	my $base = ParseDate("today");
	my $start = $base;
	my $err;
	my $stop = DateCalc("today","+ 2 month",\$err);
	while(my $it = shift @every_sch) {
		my %sch = ();
		my $d;
		($d, $sch{'begin'}, $sch{'duration'}) = split(/,/, $it);
		$d =~ s/^(.*)[\s]+$/$1/;
		my $format;
		if($d =~ /^[\d]+$/) {
			$sch{'day'} = $d;
			$format = sprintf "0:1*0:%s:%s:0", $d, $sch{'begin'};
		} else {
			$sch{'day'} = $days{$d};
			$format = sprintf "0:0:1*%s:%s:0", $d_ord{$sch{'day'}}, $sch{'begin'};
		}
		my @recur = ParseRecur($format,$base,$start,$stop);
		my $diff = DateCalc("today", $recur[0], $err, 1);
		$sch{'duration'} .= ":00";
		push @schedules, \%sch;
		push @deltas, $diff;
		push @nexts, $recur[0];
	}
# FIXME вот здесь должно идти выяснение, когда следующая конференция
	my $min = &ParseDateDelta($deltas[0]);
	my $ind = 0;
	for(my $j=1; $j<=$#deltas; $j++) {
		next if(&Date_Cmp(&ParseDateDelta($deltas[$j]), $min) >= 0);
		$ind = $j;
		$min = &ParseDateDelta($deltas[$j]);
	}
	$next_start = &UnixDate($nexts[$ind], "%Y-%m-%d %H:%M");
	$next_duration = $schedules[$ind]{'duration'};
}

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
my $phone_remind = (defined $cgi->param('ph_remind'))? 1 : 0;
my $email_remind = (defined $cgi->param('em_remind'))? 1 : 0;
my $till_remind = "";
if($phone_remind or $email_remind) {
	$till_remind = $cgi->param('remind_time');
}


my @partic = ();
my $pp = $cgi->param('phs_ids');
if(defined $pp and length $pp) {
	@partic = split(/[\s]+/, $pp);
}

$cnfr->save_cnfr($login, $id, $ce_name, $next_start, $next_duration, $auth_type, $auth_string, 
								 $auto_assemble, $phone_remind, $email_remind, $till_remind, $lost_control, 
								 $need_record, $audio_lang, \@partic, \@schedules);

if($admin) {
	my @ops =  split(/[\s]+/, $cgi->param('ops_ids'));
	$cnfr->set_cnfr_operators($login, $id, @ops);
	my $number_b = $cgi->param('number_b');
	$number_b = "" unless(defined $number_b and length $number_b);
	my $res = $cnfr->set_number_b($login, $id, $number_b);
}

my $out = sprintf $error, "false";
print $cgi->header(-type=>'application/json',-charset=>'utf-8');
print $out;
exit;

