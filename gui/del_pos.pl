#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;

my $error = '{ "status": "error", "message": "%s" }';

my $cgi = CGI->new;
my $cnfr = ConferenceDB->new;
my $login = $cgi->remote_user();
my $oper_id = $cnfr->operator($login);
my $admin = $cnfr->{oper_admin};
my $ab = $cnfr->addressbook;
my $pos_id = $cgi->param("pos_id");

unless($admin or $ab) {
	my $out = sprintf $error, "У вас нет прав удалять должности";
	print $cgi->header(-type=>'application/json',-charset=>'utf-8');
	print $out,"\n";
	exit;
}

unless(defined $pos_id and length $pos_id) {
  my $out = sprintf $error, "Не определена должность для удаления";
  print $cgi->header(-type=>'application/json',-charset=>'utf-8');
  print $out,"\n";
  exit;
}

if($cnfr->del_pos($login, $pos_id)) {
	print $cgi->header(-type=>'application/json',-charset=>'utf-8');
	print '{ "status": "ok" }',"\n";
} else {
	my $out = sprintf $error, $cnfr->get_error();
	print $cgi->header(-type=>'application/json',-charset=>'utf-8');
	print $out,"\n";
}

exit;
