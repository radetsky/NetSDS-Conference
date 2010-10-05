#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;

my $thead=<<EOH;
<thead>
<tr>
<th>Организация</th>
</tr>
</thead>
EOH

my $cgi = CGI->new;

my $login = $cgi->remote_user();

my $cnfr = ConferenceDB->new;

my $id = $cgi->param('id');
my $org_name = $cgi->param('name');

if(defined $id and length $id and defined $org_name and length $org_name) {
	$cnfr->update_orgs($id, $org_name, $login);
}

my %orgs = $cnfr->get_org_list();

my $row =<<EOR;
<tr onclick="edit_org('%s','%s');return false;">
<td>%s</td>
</tr>
EOR

my $out = "<table id=\"orgs-list\">" . $thead;

foreach my $i (sort keys %orgs) {
	$out .= sprintf $row, $i, $orgs{$i}, $orgs{$i};
}

$out .= "</table>";
$out .= "<p onclick=\"edit_org('new','');return false;\" id=\"add\">Добавить >>>>>>></p>";

print $cgi->header(-type=>'text/html',-charset=>'utf-8');
print $out;

exit(0);
