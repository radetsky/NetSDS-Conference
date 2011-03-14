#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;

sub htmlsafe {
	# <zmeuka> Странно; я пробовал применить CGI::escapeHTML, 
	#          но оно портит руссую букву "ы" независимо от наличия 'use utf8'.
	#          Так что делаем тупенькое, но рабочее:
	local $_ = shift;
	s/\&/\&amp;/g;s/\"/\&quot;/g;s/\</\&lt;/g;s/\>/\&gt;/g;
	return $_;
}

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

my $cnfr = ConferenceDB->new;
my $login = $cnfr->login;
my $oper_id = $cnfr->operator($login);
my $admin = $cnfr->{oper_admin};
my $ab = $cnfr->addressbook;

if($admin) {
	$thead = sprintf $th, '<th>Оператор</th><th>Удалить</th>';
} elsif($ab) {
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

my $glob_row =<<EOGR;
<tr class='%s'>
<td onclick="edit_org('%s','%s');return false;">%s</td>
</tr>
EOGR

my $oper_row =<<EOOR;
<tr class='%s' id="org%s">
<td onclick="edit_org('%s','%s');return false;">%s</td>
<td onclick="remove_org('%s'); return false;"><span class="ui-icon ui-icon-close"></span></td>
</tr>
EOOR

my $adm_row =<<EOAR;
<tr class='%s' id="org%s">
<td onclick="edit_org('%s','%s');return false;">%s</td>
<td>%s</td>
<td onclick="remove_org('%s'); return false;"><span class="ui-icon ui-icon-close"></span></td>
</tr>
EOAR

my $out = "<p><button onclick=\"edit_org('new','');return false;\" id=\"add\">Добавить</button></p>";
$out .= "<table id=\"orgs-list\" class=\"tab-table\">" . $thead;

my $evenodd = 'gray'; 
#use utf8;
if($admin) {
	while(my $i = shift @orgs) {
		
		$out .= sprintf $adm_row, $evenodd, $$i{'id'}, $$i{'id'}, htmlsafe($$i{'name'}), htmlsafe($$i{'name'}), $$i{'operator'}, $$i{'id'};
		if ($evenodd eq 'gray') { 
			$evenodd = 'white'; 
		} else { 
			$evenodd = 'gray'; 
		}
	}
} elsif($ab) {
	while(my $i = shift @orgs) {
		
		$out .= sprintf $oper_row, $evenodd, $$i{'id'}, $$i{'id'}, htmlsafe($$i{'name'}), htmlsafe($$i{'name'}), $$i{'id'};
		if ($evenodd eq 'gray') { 
			$evenodd = 'white'; 
		} else { 
			$evenodd = 'gray'; 
		}
	}
} else {
	while(my $i = shift @orgs) {
		$out .= sprintf $glob_row, $evenodd, $$i{'id'}, htmlsafe($$i{'name'}), htmlsafe($$i{'name'});
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
