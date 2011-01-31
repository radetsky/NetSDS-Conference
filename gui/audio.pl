#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;

my $form =<<EOF;
<form method="post" enctype="multipart/form-data" action="/save_audio.pl" onsubmit="return AIM.submit(this, {'onStart' : startCallback, 'onComplete' : completeCallback})">
	Название файла: <input type="text" name="fname" id="fname" />
	Файл: <input type="file" name="fbody" id="fbody" />
	<button type="submit" name="send" value="send">Загрузить</button>
</form>
EOF

my $cgi = CGI->new;
my $login = $cgi->remote_user();

my $cnfr = ConferenceDB->new;
my $oper_id = $cnfr->operator($login);
my $admin = $cnfr->{oper_admin};
my $ab = $cnfr->addressbook;

my %a_list = $cnfr->get_audio_list();

my $table = "<table class=\"tab-table\">\n";
foreach my $k (keys %a_list) {
	$table .= "<tr id=\"audio$k\"><td>";
	$table .= $a_list{$k} . "</td>";
	if($admin or $ab) {
		$table .= "<td onclick=\"remove_audio($k); return false;\">";
		$table .= "<span class=\"ui-icon ui-icon-close\"></span></td>";
	}
	$table .= "</tr>\n";
}
$table .= "</table>\n";

print $cgi->header(-type=>'text/html',-charset=>'utf-8');
print $table;
print $form;

exit;
