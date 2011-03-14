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

my $cnfr = ConferenceDB->new;
my $login = $cnfr->login;
my $oper_id = $cnfr->operator($login);
my $admin = $cnfr->{oper_admin};
my $ab = $cnfr->addressbook;

if($admin) {
	$thead = sprintf $th, '<th>Ответственный</th><th>Удалить</th>';
} elsif($ab) {
	$thead = sprintf $th, '<th>Удалить</th>';
} else {
	$thead = sprintf $th, '';
}

my @users = ();

@users = $cnfr->get_user_list();

my $glob_row =<<EOR;
<tr class='%s' >
<td onclick="edit_user('%s')"valign="top" align="left">%s</td> 
<td valign="top" align="left">%s</td> 
<td valign="top" align="left">%s</td> <td valign="top" align="left">%s</td> 
<td valign="top" align="left">%s</td> <td valign="top" align="left">%s</td>
<td valign="top" align="left">%s</td> 
</tr>
EOR

my $oper_row =<<EOR;
<tr class='%s' id="user%s">
<td onclick="edit_user('%s')"valign="top" align="left">%s</td> 
<td valign="top" align="left">%s</td> 
<td valign="top" align="left">%s</td> <td valign="top" align="left">%s</td> 
<td valign="top" align="left">%s</td> <td valign="top" align="left">%s</td>
<td valign="top" align="left">%s</td> 
<td onclick="remove_user('%s'); return false;"><span class="ui-icon ui-icon-close"></span></td>
</tr>
EOR

my $adm_row =<<EOR;
<tr class='%s' id="user%s">
<td onclick="edit_user('%s')"valign="top" align="left">%s</td> 
<td valign="top" align="left">%s</td> 
<td valign="top" align="left">%s</td> <td valign="top" align="left">%s</td> 
<td valign="top" align="left">%s</td> <td valign="top" align="left">%s</td>
<td valign="top" align="left">%s</td> 
<td valign="top" align="left">%s</td> 
<td onclick="remove_user('%s'); return false;"><span class="ui-icon ui-icon-close"></span></td>
</tr>
EOR

my $out = "<p><button onclick=\"edit_user('new');return false;\" id=\"add\">Добавить</button></p>\n";
$out .= "<table id=\"user-list\" class=\"tab-table\">" . $thead;

my $evenodd = 'gray'; 

if($admin) {
	while(my $i = shift @users) {
		$out .= sprintf $adm_row,$evenodd, $$i{'id'}, $$i{'id'}, $$i{'name'}, join('<br/>',@{$$i{'phones'}}), 
		$$i{'organization'}, $$i{'department'}, $$i{'position'}, $$i{'email'}, $$i{'login'}, 
		$$i{'operator'}, $$i{'id'};
		if ($evenodd eq 'gray') { 
			$evenodd = 'white'; 
		} else { 
			$evenodd = 'gray'; 
		}
		
	}
} elsif($ab) {
	while(my $i = shift @users) {
		$out .= sprintf $oper_row,$evenodd, $$i{'id'}, $$i{'id'}, $$i{'name'}, join('<br/>',@{$$i{'phones'}}), 
		$$i{'organization'}, $$i{'department'}, $$i{'position'}, $$i{'email'}, $$i{'login'}, $$i{'id'};
		if ($evenodd eq 'gray') { 
			$evenodd = 'white'; 
		} else { 
			$evenodd = 'gray'; 
		}
		
	}
} else {
	while(my $i = shift @users) {
		$out .= sprintf $glob_row, $evenodd ,$$i{'id'}, $$i{'name'}, join('<br/>',@{$$i{'phones'}}),
		$$i{'organization'}, $$i{'department'}, $$i{'position'}, $$i{'email'}, $$i{'login'};
		if ($evenodd eq 'gray') { 
			$evenodd = 'white'; 
		} else { 
			$evenodd = 'gray'; 
		}
	}
}

$out .= "</table>";

print $cgi->header(-type=>'text/html',-charset=>'utf-8',-cookie=>$cnfr->cookie);
print $out;

exit(0);
