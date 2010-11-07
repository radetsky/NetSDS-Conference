#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;

my %c_states = ("inactive"=>"Выкл", "active"=>"Вкл");
my %funct = ("inactive"=>"edit_cnfr", "active"=>"show_active");

my %s_days = ("mo"=>"Пн", "tu"=>"Вт", "we"=>"Ср", "th"=>"Чт", "fr"=>"Пт", "sa"=>"Сб", "su"=>"Вс");

my %langs = ("ru"=>"Русский", "ua"=>"Украинский");

my $thead=<<EOH;
<thead>
<tr>
<th rowspan="2">N</th>
<th rowspan="2">Название</th>
<th rowspan="2">Состояние</th>
<th colspan="2">Последнее совещание</th>
<th colspan="2">Следующее совещание</th>
<th colspan="3">Планирование совещаний</th>
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
<th>Продолжительность</th>
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
<tr onclick="%s(%s); return false;">
<td>%s</td> <td>%s</td> <td>%s</td> <td>%s</td> <td>%s</td> <td>%s</td> <td>%s</td> <td>%s</td>
<td>%s</td> <td>%s</td> <td>%s</td> <td>%s</td> <td>%s</td> <td>%s</td> <td>%s</td> <td>%s</td>
<td>%s</td>
</tr>
EOR

my $out = "<table id=\"cnfr-list\" class=\"tab-table\">" . $thead;

my $check = '<span class="ui-icon ui-icon-check center-icon"></span>';
my $minus = '<span class="ui-icon ui-icon-minus center-icon"></span>';

while(my $i = shift @rights) {
	my @args = ();
	push @args, $funct{$cnfrs[$i]{'cnfr_state'}};
	push @args, $i;
	push @args, $i;
	push @args, $cnfrs[$i]{'cnfr_name'};
	push @args, $c_states{$cnfrs[$i]{'cnfr_state'}};
	push @args, $cnfrs[$i]{'last_start'};
	push @args, $cnfrs[$i]{'last_end'};
	push @args, $cnfrs[$i]{'next_start'};
	if(length $cnfrs[$i]{'next_duration'} and $cnfrs[$i]{'next_duration'} =~ /^(.*):[\d]{2}$/) {
		push @args, $1;
	} else {
		push @args, $cnfrs[$i]{'next_duration'};
	}
	if(length $cnfrs[$i]{'schedule_date'}) {
		if($cnfrs[$i]{'schedule_date'} =~ /^[0-9\s]+$/) {
			push @args, join(',',split(/[\s]+/, $cnfrs[$i]{'schedule_date'}));
		} else {
			push @args, join(',', (map {$s_days{$_}} split(/[\s]+/, $cnfrs[$i]{'schedule_date'})));
		}
	} else {
		push @args, $cnfrs[$i]{'schedule_date'};
	}
	push @args, $cnfrs[$i]{'schedule_time'};
	if(length $cnfrs[$i]{'schedule_duration'} and $cnfrs[$i]{'schedule_duration'} =~ /^(.*):[\d]{2}$/) {
		push @args, $1;
	} else {
		push @args, $cnfrs[$i]{'schedule_duration'};
	}
	my $at = "";
	if($cnfrs[$i]{'auth_type'} =~ /number/) {
		$at .= "По номеру";
	}
	if($cnfrs[$i]{'auth_type'} =~ /pin/) {
		$at .= ", " if(length $at);
		$at .= "По PIN'у";
	}
	push @args, $at;
	push @args, $cnfrs[$i]{'auth_string'};
	if($cnfrs[$i]{'auto_assemble'}) {
		push @args, $check;
	} else {
		push @args, $minus;
	}
	if($cnfrs[$i]{'lost_control'}) {
		push @args, $check;
	} else {
		push @args, $minus;
	}
	if($cnfrs[$i]{'need_record'}) {
		push @args, $check;
	} else {
		push @args, $minus;
	}
	push @args, $cnfrs[$i]{'number_b'};
	if(length $cnfrs[$i]{'audio_lang'}) {
		push @args, $langs{$cnfrs[$i]{'audio_lang'}};
	} else {
		push @args, "";
	}

	$out .= sprintf $row, @args;
}
$out .= "</table>";

print $cgi->header(-type=>'text/html',-charset=>'utf-8');
print $out;

exit(0);
