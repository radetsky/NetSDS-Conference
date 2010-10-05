#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;

my $thead=<<EOH;
<thead>
<tr>
<th>Должность</th>
</tr>
</thead>
EOH

my $cgi = CGI->new;

my $login = $cgi->remote_user();

my $cnfr = ConferenceDB->new;

my $id = $cgi->param('id');
my $pos_name = $cgi->param('name');

if(defined $id and length $id and defined $pos_name and length $pos_name) {
  $cnfr->update_posns($id, $pos_name, $login);
}

my @posns = $cnfr->get_pos_list();

my $row =<<EOR;
<tr onclick="edit_pos('%s','%s');return false;">
<td>%s</td>
</tr>
EOR

my $out = "<table id=\"user-list\">" . $thead;

while(my $i = shift @posns) {
	$out .= sprintf $row, $$i{'id'}, $$i{'name'}, $$i{'name'};
}
$out .= "</table>";
$out .= "<p onclick=\"edit_pos('new','');return false;\" id=\"add\">Добавить >>>>>>></p>";

print $cgi->header(-type=>'text/html',-charset=>'utf-8');
print $out;

exit(0);
