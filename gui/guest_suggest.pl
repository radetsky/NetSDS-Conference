#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;

my $cgi = CGI->new;
my $cnfr = ConferenceDB->new;
my $ph = $cgi->param('phone');

my %user = $cnfr->get_user_by_phone($ph);

my $json = '{';

if(%user) {
	$json .= ' "known": true, ';
	$json .= ' "user_id": "' . $user{'user_id'} . '", ';
	$json .= ' "phone_id": "' . $user{'phone_id'} . '", ';
	$json .= ' "phone": "' . $user{'phone'} . '", ';
	$json .= ' "user_name": "' . $user{'name'} . '"';
} else {
	$json .= ' "known": false, ';
	if (length($ph) <= 2) { 
		$json .= ' "user_name": "Запись конференции", ';
	} else { 
		$json .= ' "user_name": "Неизвестный пользователь", ';
	}
	$json .= ' "phone": "' . $ph . '"';
}

$json .= '}';

#warn $json;

print $cgi->header(-type=>'application/json',-charset=>'utf-8');
print $json;
exit(0);
