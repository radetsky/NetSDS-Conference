#!/usr/bin/perl -w

use strict;
use CGI;

my $form =<<EOF;
<form method="post" enctype="multipart/form-data" action="/save_audio.pl" onsubmit="return AIM.submit(this, {'onStart' : startCallback, 'onComplete' : completeCallback})">
	Название файла: <input type="text" name="fname" id="fname" />
	Файл: <input type="file" name="fbody" id="fbody" />
	<button type="submit" name="send" value="send">Загрузить</button>
</form>
EOF

use lib './lib';
use ConferenceDB;

my $cgi = CGI->new;
my $login = $cgi->remote_user();

my $cnfr = ConferenceDB->new;

my $admin = $cnfr->is_admin($login);

my %a_list = $cnfr->get_audio_list();

my $table = "<table>\n";
foreach my $k (keys %a_list) {
	$table .= "<tr id=\"audio$k\"><td>";
	$table .= $a_list{$k} . "</td>";
	if($admin) {
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
