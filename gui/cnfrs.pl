#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;

my $thead=<<EOH;
<thead>
<tr>
<th rowspan="2">N</th>
<th rowspan="2">Название</th>
<th rowspan="2">Состояние</th>
<th colspan="2">Последнее совещание</th>
<th colspan="2">Следующее совещание</th>
<th colspan="2">Планирование совещаний</th>
<th rowspan="2">Тип опознания</th>
<th rowspan="2">Пароль</th>
<th rowspan="2">Автосбор</th>
<th rowspan="2">Контроль потери</th>
<th rowspan="2">Запись совещания</th>
<th rowspan="2">Номер совещания</th>
<th rowspan="2">Язык</th>
</tr>
<th>Начало</th>
<th>Окончание</th>
<th>Начало</th>
<th>Продолжительность</th>
<th>Дни</th>
<th>Время</th>
<tr>
</tr>
</thead>
EOH

my $cgi = CGI->new;

my $login = $cgi->remote_user();

my $cnfr = ConferenceDB->new;

my @cnfrs = $cnfr->cnfr_list();
my @rights = $cnfr->get_cnfr_rights($login);

my $row =<<EOR;
<tr onclick="edit_cnfr(%s); return false;">
<td>%s</td> <td>%s</td> <td>%s</td> <td>%s</td> <td>%s</td> <td>%s</td> <td>%s</td>
<td>%s</td> <td>%s</td> <td>%s</td> <td>%s</td> <td>%s</td> <td>%s</td> <td>%s</td>
<td>%s</td> <td>%s</td>
</tr>
EOR

my $out = "<table id=\"cnfr-list\">" . $thead;

while(my $i = shift @rights) {
	$out .= sprintf $row, $i, $i, $cnfrs[$i]{'cnfr_name'}, $cnfrs[$i]{'cnfr_state'},
					$cnfrs[$i]{'last_start'}, $cnfrs[$i]{'last_end'}, $cnfrs[$i]{'next_start'},
					$cnfrs[$i]{'next_duration'}, $cnfrs[$i]{'shedule_date'}, $cnfrs[$i]{'shedule_time'},
					$cnfrs[$i]{'auth_type'}, $cnfrs[$i]{'auth_string'}, $cnfrs[$i]{'auto_assemble'},
					$cnfrs[$i]{'lost_control'}, $cnfrs[$i]{'need_record'}, 
					$cnfrs[$i]{'number_b'}, $cnfrs[$i]{'audio_lang'};
}
$out .= "</table>";

print $cgi->header(-type=>'text/html',-charset=>'utf-8');
print $out;

exit(0);
