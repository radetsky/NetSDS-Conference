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
<tr class='%s' id="pos%s">
<td onclick="edit_pos('%s','%s');return false;">%s</td>
<td onclick="del_pos('%s'); return false;">
<span class="ui-icon ui-icon-close"></span>
</td>
</tr>
EOR

my $row =<<EOR;
<tr class='%s' onclick="edit_pos('%s','%s');return false;">
<td>%s</td>
</tr>
EOR

my $out = "<p><button onclick=\"edit_pos('new','');return false;\" id=\"add\">Добавить</button></p>";
$out .= "<table id=\"user-list\" class=\"tab-table\">" . $thead;

my $evenodd = 'gray';
 
if($admin) {
	while(my $i = shift @posns) {
		$out .= sprintf $adm_row, $evenodd, $$i{'id'}, $$i{'id'}, $$i{'name'}, $$i{'name'}, $$i{'id'};
		if ($evenodd eq 'gray') { 
			$evenodd = 'white'; 
		} else { 
			$evenodd = 'gray'; 
		}
	}
} else {
	while(my $i = shift @posns) {
		$out .= sprintf $row, $evenodd, $$i{'id'}, $$i{'name'}, $$i{'name'};
		if ($evenodd eq 'gray') { 
			$evenodd = 'white'; 
		} else { 
			$evenodd = 'gray'; 
		}
	}
}

$out .= "</table>";

print $cgi->header(-type=>'text/html',-charset=>'utf-8');
print $out;

exit(0);
