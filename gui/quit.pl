#!/usr/bin/perl -w

use strict;
use lib './lib';
use CGI;
use ConferenceDB;

my $cgi = CGI->new;
my $cnfr = ConferenceDB->new;
my $login = $cnfr->login(1); # нужно для инициализации сессии
$cnfr->logout if defined $login;

print $cgi->redirect(
    'http://'.$ENV{'HTTP_HOST'}.
    ($ENV{'HTTP_PORT'} eq '80' ? '' : ':'.$ENV{'HTTP_PORT'}).
    '/login.html'
);

exit;
