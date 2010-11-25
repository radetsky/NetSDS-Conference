#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;

my $error = '{ "status": "error", "message": "%s" }';

my $cgi = CGI->new;
my $login = $cgi->remote_user();
my $auid = $cgi->param('auid');

my $cnfr = ConferenceDB->new;
my $admin = $cnfr->is_admin($login);

print $cgi->header(-type=>'application/json',-charset=>'utf-8');

unless(defined $auid and length $auid) {
	my $out = sprintf $error, "Не определен файл для удаления";
	print $out,"\n";
	exit;
}

unless($admin) {
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


