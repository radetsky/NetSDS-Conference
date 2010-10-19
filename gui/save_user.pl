#!/usr/bin/perl -w

use strict;
use CGI;
use Data::Dumper;

use lib './lib';
use ConferenceDB;

my $error = '{"status": "error", "message": "%s"}';

my $cgi = CGI->new;

my $login = $cgi->remote_user();

my $cnfr = ConferenceDB->new;

my $htpasswd = $cnfr->get_htpasswd();

my $admin = $cnfr->is_admin($login);

my %params = $cgi->Vars();
my %user = ();
my %admin = ();
print $cgi->header(-type=>'application/json',-charset=>'utf-8');

$user{'id'} = $cgi->param("uid");
$user{'name'} = $cgi->param("fio");
$user{'orgid'} = $cgi->param("user_org");
$user{'dept'} = $cgi->param("user_dept");
$user{'posid'} = $cgi->param("user_pos");
$user{'email'} = $cgi->param("user_email");

unless(defined $user{'id'} && length $user{'id'}) {
	my $out = sprintf $error, "Пользователь не определен";
	print $out,"\n";
	exit(0);
}

my $j = 0;
my @phones = ();
while(exists($params{("phone".$j)})) {
	push @phones, $params{("phone".$j)};
	$j++;
}

$admin{'oper'} = 0;

if(exists $params{'op_rights'} and $params{'op_rights'} eq "on") {
	unless($admin) {
		my $out = sprintf $error, "Назначать операторов имеет право только администратор";
		print $out,"\n";
		exit(0);
	}
	$admin{'oper'} = 1;
	$admin{'login'} = $cgi->param("op_login");
	$admin{'passwd'} = $cgi->param("op_pass");
	if(exists $params{"is_admin"} and $params{"is_admin"} eq "on") {
		$admin{'admin'} = 1;
	} else {
		$admin{'admin'} = 0;
	}
}

my %old = ();
if($user{'id'} ne 'new') {
	%old = $cnfr->get_user_by_id($user{'id'});	
}

my @users = undef;
if($admin) {
	if(@users = $cnfr->update_user($login, \%user, \@phones, \%admin)) {
		if(defined $admin{'passwd'} and length $admin{'passwd'}) {
			my $cmd = $htpasswd . " -b ./.htpasswd ". $admin{'login'} . " " . $admin{'passwd'};
			system($cmd);
		}
		if(length $old{'login'} and $admin{'oper'} eq 0) {
			my $cmd = $htpasswd . " -D ./.htpasswd " . $old{'login'};
			system($cmd);
			$cnfr->remove_oper($login, $user{'id'});
		}
		print '{"status": "ok"}',"\n";
		exit(0);
	} else {
		my $out = sprintf $error, $cnfr->get_error();
		print $out,"\n";
		exit(0);
	}
} else {
		if(@users = $cnfr->update_user($login, \%user, \@phones, {})) {
			print '{"status": "ok"}',"\n";
			exit(0);
		} else {
			my $out = sprintf $error, $cnfr->get_error();
			print $out,"\n";
			exit(0);
		}
}


#open(HTP, "./.htpasswd") or warn "Can't open passwd file";
#
#my %htpasswd = ();
#while(<HTP>) {
#	my ($k, $v) = split(/:/);
#	$htpasswd{$k} = $v;
#}
#close(HTP);
