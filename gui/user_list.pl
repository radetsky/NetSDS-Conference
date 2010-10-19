#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;

my $thead=<<EOH;
<thead>
<tr>
<th>ФИО</th>
<th>Телефон(ы)</th>
<th>Организация</th>
<th>Отдел</th>
<th>Должность</th>
<th>E-mail</th>
<th>Имя оператора</th>
</tr>
</thead>
EOH

my $cgi = CGI->new;

my $login = $cgi->remote_user();

my $cnfr = ConferenceDB->new;

my $admin = $cnfr->is_admin($login);

my @users = ();

@users = $cnfr->get_user_list();

my $row =<<EOR;
<tr onclick="edit_user('%s')">
<td valign="top" align="left">%s</td> <td valign="top" align="left">%s</td> 
<td valign="top" align="left">%s</td> <td valign="top" align="left">%s</td> 
<td valign="top" align="left">%s</td> <td valign="top" align="left">%s</td>
<td valign="top" align="left">%s</td>
</tr>
EOR

my $out = "<table id=\"user-list\">" . $thead;

while(my $i = shift @users) {
	$out .= sprintf $row, $$i{'id'}, $$i{'name'}, join('<br/>',@{$$i{'phones'}}), 
									$$i{'organization'}, $$i{'department'}, $$i{'position'}, $$i{'email'}, $$i{'login'};
}
$out .= "</table>";
$out .= "<p onclick=\"edit_user('new');return false;\" id=\"add\">Добавить >>>>>>></p>\n";

print $cgi->header(-type=>'text/html',-charset=>'utf-8');
print $out;

exit(0);
