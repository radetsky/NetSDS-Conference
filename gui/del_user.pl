#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;

my $error = '{ "status": "error", "message": "%s" }';

my $cgi = CGI->new;
my $cnfr = ConferenceDB->new;
my $login = $cgi->remote_user();
my $admin = $cnfr->is_admin($login);
my $user_id = $cgi->param("user_id");

if($user_id eq 1) {
	my $out = sprintf $error, "Этого пользователя нельзя удалять";
	print $cgi->header(-type=>'application/json',-charset=>'utf-8');
	print $out,"\n";
	exit;
}

unless($admin) {
	my $out = sprintf $error, "У вас нет прав удалять пользователей";
	print $cgi->header(-type=>'application/json',-charset=>'utf-8');
	print $out,"\n";
	exit;
}

unless(defined $user_id and length $user_id) {
  my $out = sprintf $error, "Не определен пользователь для удаления";
  print $cgi->header(-type=>'application/json',-charset=>'utf-8');
  print $out,"\n";
  exit;
}

if($cnfr->del_user($login, $user_id)) {
	print $cgi->header(-type=>'application/json',-charset=>'utf-8');
	print '{ "status": "ok" }',"\n";
} else {
	my $out = sprintf $error, $cnfr->get_error();
	print $cgi->header(-type=>'application/json',-charset=>'utf-8');
	print $out,"\n";
}

exit;
