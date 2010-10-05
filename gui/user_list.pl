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
</tr>
</thead>
EOH

my $cgi = CGI->new;

my $login = $cgi->remote_user();

my $cnfr = ConferenceDB->new;

my $admin = $cnfr->is_admin($login);

my %user = ();
my %admin = ();

$user{'id'} = $cgi->param("id");
$user{'name'} = $cgi->param("name");
$user{'orgid'} = $cgi->param("orgid");
$user{'dept'} = $cgi->param("dept");
$user{'posid'} = $cgi->param("posid");
$user{'email'} = $cgi->param("email");
$user{'phones'} = $cgi->param("phones");

$admin{'oper'} = $cgi->param("oper");
$admin{'login'} = $cgi->param("login");
$admin{'passwd'} = $cgi->param("passwd");
$admin{'admin'} = $cgi->param("admin");

my @users = ();

my @phones = ();

if(defined $user{'phones'} and length $user{'phones'}) {
	@phones = split(/\+/, $user{'phones'});
}

if(defined $user{'id'} and length $user{'id'}) {
	@users = $cnfr->update_user($login, \%user, \@phones, \%admin);
} else {
	@users = $cnfr->get_user_list();
}

my $row =<<EOR;
<tr onclick="edit_user('%s')">
<td>%s</td> <td>%s</td> <td>%s</td> <td>%s</td> <td>%s</td> <td>%s<td>
</tr>
EOR

my $out = "<table id=\"user-list\">" . $thead;

while(my $i = shift @users) {
	$out .= sprintf $row, $$i{'id'}, $$i{'name'}, join('<br/>',@{$$i{'phones'}}), 
									$$i{'organization'}, $$i{'department'}, $$i{'position'}, $$i{'email'};
}
$out .= "</table>";
$out .= "<p onclick=\"edit_user('new');return false;\" id=\"add\">Добавить >>>>>>></p>\n";

print $cgi->header(-type=>'text/html',-charset=>'utf-8');
print $out;

exit(0);
