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
<th>Должность</th>
%s
</tr>
</thead>
EOH

my $cgi = CGI->new;

my $cnfr = ConferenceDB->new;
my $login = $cnfr->login;
my $id = $cgi->param('id');
my $pos_name = $cgi->param('name');
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

if(defined $id and length $id and defined $pos_name and length $pos_name) {
  $cnfr->update_posns($id, $pos_name, $login);
}

my @posns = $cnfr->get_pos_list();

my $adm_row =<<EOR;
<tr class='%s' id="pos%s">
<td onclick="edit_pos('%s','%s');return false;">%s</td>
<td>%s</td>
<td onclick="del_pos('%s'); return false;">
<span class="ui-icon ui-icon-close"></span>
</td>
</tr>
EOR

my $oper_row =<<EOR;
<tr class='%s' id="pos%s">
<td onclick="edit_pos('%s','%s');return false;">%s</td>
<td onclick="del_pos('%s'); return false;">
<span class="ui-icon ui-icon-close"></span>
</td>
</tr>
EOR

my $glob_row =<<EOR;
<tr class='%s' onclick="edit_pos('%s','%s');return false;">
<td>%s</td>
</tr>
EOR

my $out = "<p><button onclick=\"edit_pos('new','');return false;\" id=\"add\">Добавить</button></p>";
$out .= "<table id=\"user-list\" class=\"tab-table\">" . $thead;

my $evenodd = 'gray';
 
if($admin) {
	while(my $i = shift @posns) {
		$out .= sprintf $adm_row, $evenodd, $$i{'id'}, $$i{'id'}, $$i{'name'}, $$i{'name'}, $$i{'operator'}, $$i{'id'};
		if ($evenodd eq 'gray') { 
			$evenodd = 'white'; 
		} else { 
			$evenodd = 'gray'; 
		}
	}
} elsif($ab) {
	while(my $i = shift @posns) {
		$out .= sprintf $oper_row, $evenodd, $$i{'id'}, $$i{'id'}, $$i{'name'}, $$i{'name'}, $$i{'id'};
		if ($evenodd eq 'gray') { 
			$evenodd = 'white'; 
		} else { 
			$evenodd = 'gray'; 
		}
	}
} else {
	while(my $i = shift @posns) {
		$out .= sprintf $glob_row, $evenodd, $$i{'id'}, $$i{'name'}, $$i{'name'};
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
