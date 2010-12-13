#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;

my $thead;
my $th=<<EOH;
<thead>
<tr>
<th>Организация</th>
%s
</tr>
</thead>
EOH

my $cgi = CGI->new;

my $login = $cgi->remote_user();

my $cnfr = ConferenceDB->new;

my $admin = $cnfr->is_admin($login);

if($admin) {
	$thead = sprintf $th, '<th>Удалить</th>';
} else {
	$thead = sprintf $th, '';
}

my $id = $cgi->param('id');
my $org_name = $cgi->param('name');

if(defined $id and length $id and defined $org_name and length $org_name) {
	$cnfr->update_orgs($id, $org_name, $login);
}

my @orgs = $cnfr->get_org_list();

my $row =<<EOR;
<tr class='%s'>
<td onclick="edit_org('%s','%s');return false;">%s</td>
</tr>
EOR

my $adm_row =<<EOAR;
<tr class='%s' id="org%s">
<td onclick="edit_org('%s','%s');return false;">%s</td>
<td onclick="remove_org('%s'); return false;"><span class="ui-icon ui-icon-close"></span></td>
</tr>
EOAR

my $out = "<p><button onclick=\"edit_org('new','');return false;\" id=\"add\">Добавить</button></p>";
$out .= "<table id=\"orgs-list\" class=\"tab-table\">" . $thead;

my $evenodd = 'gray'; 

if($admin) {
	while(my $i = shift @orgs) {
		$out .= sprintf $adm_row, $evenodd, $$i{'id'}, $$i{'id'}, $$i{'name'}, $$i{'name'}, $$i{'id'};
		if ($evenodd eq 'gray') { 
			$evenodd = 'white'; 
		} else { 
			$evenodd = 'gray'; 
		}
	}
} else {
	while(my $i = shift @orgs) {
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
