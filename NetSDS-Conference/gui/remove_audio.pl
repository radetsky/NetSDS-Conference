#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;

my $error = '{ "status": "error", "message": "%s" }';

my $cgi = CGI->new;
my $auid = $cgi->param('auid');

my $cnfr = ConferenceDB->new;
my $login = $cnfr->login;
my $oper_id = $cnfr->operator($login);
my $admin = $cnfr->{oper_admin};
my $ab = $cnfr->addressbook;

print $cgi->header(-type=>'application/json',-charset=>'utf-8',-cookie=>$cnfr->cookie);

unless(defined $auid and length $auid) {
	my $out = sprintf $error, "Не определен файл для удаления";
	print $out,"\n";
	exit;
}

unless($admin or $ab) {
	my $out = sprintf $error, "Удалять файлы может только администратор";
	print $out,"\n";
	exit;
}

if($cnfr->remove_audio($auid)) {
	print '{ "status": "ok" }';
} else {
	my $out = sprintf $error, $cnfr->get_error();
	print $out,"\n";
}

exit;


