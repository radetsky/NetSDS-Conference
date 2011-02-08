#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;

my $form =<<EOF;
<form method="post" enctype="multipart/form-data" action="/save_audio.pl" onsubmit="return AIM.submit(this, {'onStart' : startCallback, 'onComplete' : completeCallback})"><table class="tab-table">
	<thead><tr><th>Загрузка аудиофайла (формат WAV):</th></tr></thead>
	<tbody><tr valign="middle"><td style="text-align:center;padding:0.75em;">Название файла:&nbsp;<input type="text" name="fname" id="fname" />
	Файл:&nbsp;<input type="file" name="fbody" id="fbody" />
	<button type="submit" name="send" value="send">Загрузить</button></td>
</tr></tbody></table>
</form>
EOF

my $cgi = CGI->new;
my $login = $cgi->remote_user();

my $cnfr = ConferenceDB->new;
my $oper_id = $cnfr->operator($login);
my $admin = $cnfr->{oper_admin};
my $ab = $cnfr->addressbook;

my @a_list = $cnfr->get_audio_table();

=item strusture

(
	au_id	=>	$tmp[0],
	descr	=>	$tmp[1],
	size	=>	$tmp[2],
	date	=>	$tmp[3],
	oper	=>	$tmp[4]
);

=cut

my $oper_th = $admin ? '<th>Оператор</th>' : '';
my $del_th = ($admin or $ab) ? '<th>Удалить</th>' : '';
my $table =<<THEAD;
<table class="tab-table">
<thead>
<tr>
	<th>Описание</th>
	<th>Размер,&nbsp;байт</th>
	<th>Загружено</th>
	$oper_th
	$del_th
</tr>
</thead>
<tbody>
THEAD

my $color = 'white';
foreach my $row (@a_list) {
	$table .= "<tr class=\"$color\" id=\"audio".$row->{au_id}."\">";
	
	$table .= "<td style=\"text-align:left;\">" . $row->{descr} . "</td>";
	$table .= "<td style=\"text-align:right;\">" . $row->{size} . "</td>";
	$table .= "<td>" . $row->{date} . "</td>";
	$table .= "<td>" . $row->{oper} . "</td>" if $admin;
	
	if($admin or $ab) {
		$table .= "<td onclick=\"remove_audio(".$row->{au_id}."); return false;\">";
		$table .= "<span class=\"ui-icon ui-icon-close\"></span></td>";
	}
	$table .= "</tr>\n";
	$color = $color eq 'gray' ? 'white' : 'gray'; 
}
$table .= "</tbody></table>\n";

print $cgi->header(-type=>'text/html',-charset=>'utf-8');
print $form;
print $table;

exit;
