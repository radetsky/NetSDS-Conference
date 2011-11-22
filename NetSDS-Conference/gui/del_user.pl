#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;

my $error = '{ "status": "error", "message": "%s" }';

my $cgi = CGI->new;
my $cnfr = ConferenceDB->new;
my $login = $cnfr->login;
my $oper_id = $cnfr->operator($login);
my $admin = $cnfr->{oper_admin};
my $ab = $cnfr->addressbook;
my $user_id = $cgi->param("user_id");

if($user_id eq 1) {
	my $out = sprintf $error, "Этого пользователя нельзя удалять";
	print $cgi->header(-type=>'application/json',-charset=>'utf-8',-cookie=>$cnfr->cookie);
	print $out,"\n";
	exit;
}

unless($admin or $ab) {
	my $out = sprintf $error, "У вас нет прав удалять пользователей";
	print $cgi->header(-type=>'application/json',-charset=>'utf-8',-cookie=>$cnfr->cookie);
	print $out,"\n";
	exit;
}

unless(defined $user_id and length $user_id) {
  my $out = sprintf $error, "Не определен пользователь для удаления";
  print $cgi->header(-type=>'application/json',-charset=>'utf-8',-cookie=>$cnfr->cookie);
  print $out,"\n";
  exit;
}

if($cnfr->del_user($login, $user_id)) {
	print $cgi->header(-type=>'application/json',-charset=>'utf-8',-cookie=>$cnfr->cookie);
	print '{ "status": "ok" }',"\n";
} else {
	my $out = sprintf $error, $cnfr->get_error();
	print $cgi->header(-type=>'application/json',-charset=>'utf-8',-cookie=>$cnfr->cookie);
	print $out,"\n";
}

exit;
