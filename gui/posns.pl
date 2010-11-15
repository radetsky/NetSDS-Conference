#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;

my $thead;
my $th=<<EOH;
<thead>
<tr>
<th>Должность</th>
%s
</tr>
</thead>
EOH

my $cgi = CGI->new;

my $login = $cgi->remote_user();

my $cnfr = ConferenceDB->new;

my $id = $cgi->param('id');
my $pos_name = $cgi->param('name');
my $admin = $cnfr->is_admin($login);

if($admin) {
	$thead = sprintf $th, '<th>Удалить</th>';
} else {
	$thead = sprintf $th, '';
}

if(defined $id and length $id and defined $pos_name and length $pos_name) {
  $cnfr->update_posns($id, $pos_name, $login);
}

my @posns = $cnfr->get_pos_list();

my $adm_row =<<EOR;
<tr id="pos%s">
<td onclick="edit_pos('%s','%s');return false;">%s</td>
<td onclick="del_pos('%s'); return false;">
<span class="ui-icon ui-icon-close"></span>
</td>
</tr>
EOR

my $row =<<EOR;
<tr onclick="edit_pos('%s','%s');return false;">
<td>%s</td>
</tr>
EOR

my $out = "<table id=\"user-list\">" . $thead;

if($admin) {
	while(my $i = shift @posns) {
		$out .= sprintf $adm_row, $$i{'id'}, $$i{'id'}, $$i{'name'}, $$i{'name'}, $$i{'id'};
	}
} else {
	while(my $i = shift @posns) {
		$out .= sprintf $row, $$i{'id'}, $$i{'name'}, $$i{'name'};
	}
}

$out .= "</table>";
$out .= "<p onclick=\"edit_pos('new','');return false;\" id=\"add\">Добавить >>>>>>></p>";

print $cgi->header(-type=>'text/html',-charset=>'utf-8');
print $out;

exit(0);
