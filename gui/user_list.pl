#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;

my $thead;
my $th=<<EOH;
<thead>
<tr>
<th>ФИО</th>
<th>Телефон(ы)</th>
<th>Организация</th>
<th>Отдел</th>
<th>Должность</th>
<th>E-mail</th>
<th>Имя оператора</th>
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

my @users = ();

@users = $cnfr->get_user_list();

my $row =<<EOR;
<tr class='%s' >
<td onclick="edit_user('%s')"valign="top" align="left">%s</td> 
<td valign="top" align="left">%s</td> 
<td valign="top" align="left">%s</td> <td valign="top" align="left">%s</td> 
<td valign="top" align="left">%s</td> <td valign="top" align="left">%s</td>
<td valign="top" align="left">%s</td> 
</tr>
EOR

my $adm_row =<<EOR;
<tr class='%s' id="user%s">
<td onclick="edit_user('%s')"valign="top" align="left">%s</td> 
<td valign="top" align="left">%s</td> 
<td valign="top" align="left">%s</td> <td valign="top" align="left">%s</td> 
<td valign="top" align="left">%s</td> <td valign="top" align="left">%s</td>
<td valign="top" align="left">%s</td> 
<td onclick="remove_user('%s'); return false;"><span class="ui-icon ui-icon-close"></span></td>
</tr>
EOR

my $out = "<table id=\"user-list\" class=\"tab-table\">" . $thead;

my $evenodd = 'gray'; 

if($admin) {
	while(my $i = shift @users) {
		$out .= sprintf $adm_row,$evenodd, $$i{'id'}, $$i{'id'}, $$i{'name'}, join('<br/>',@{$$i{'phones'}}), 
		$$i{'organization'}, $$i{'department'}, $$i{'position'}, $$i{'email'}, $$i{'login'}, $$i{'id'};
		if ($evenodd eq 'gray') { 
			$evenodd = 'white'; 
		} else { 
			$evenodd = 'gray'; 
		}
		
	}
} else {
	while(my $i = shift @users) {
		$out .= sprintf $row, $evenodd ,$$i{'id'}, $$i{'name'}, join('<br/>',@{$$i{'phones'}}),
		$$i{'organization'}, $$i{'department'}, $$i{'position'}, $$i{'email'}, $$i{'login'};
		if ($evenodd eq 'gray') { 
			$evenodd = 'white'; 
		} else { 
			$evenodd = 'gray'; 
		}
	}
}

$out .= "</table>";
$out .= "<p onclick=\"edit_user('new');return false;\" id=\"add\">Добавить >>>>>>></p>\n";

print $cgi->header(-type=>'text/html',-charset=>'utf-8');
print $out;

exit(0);
