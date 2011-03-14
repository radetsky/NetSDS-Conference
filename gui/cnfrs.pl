#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;

my %c_states = (
    "inactive" => "Выкл",
    "active"   => "Вкл",
    "stop"     => "Останов"
);
my %funct = (
    "inactive" => "edit_cnfr",
    "active"   => "show_active",
    "stop"     => "show_active"
);

my %s_days = (
    "Mon" => "Пн",
    "Tue" => "Вт",
    "Wed" => "Ср",
    "Thu" => "Чт",
    "Fri" => "Пт",
    "Sat" => "Сб",
    "Sun" => "Вс"
);

my %langs = ( "en" => "English","ru" => "Русский", "ua" => "Украинский" );

my $thead = <<EOH;
<thead>
<tr>
<th rowspan="2">N</th>
<th rowspan="2">Название</th>
<th rowspan="2">Состояние</th>
<th colspan="2">Последнее совещание</th>
<th colspan="2">Следующее совещание</th>
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
<th>Длительность</th>
<tr>
</tr>
</thead>
EOH

my $cgi = CGI->new;

my $cnfr = ConferenceDB->new;
my $login = $cnfr->login;
my @cnfrs  = $cnfr->cnfr_list();
my @rights = $cnfr->get_cnfr_rights($login);

my $row = <<EOR;
<tr class="%s %s" onclick="%s(%s, '%s'); return false;">
<td>%s</td> <td>%s</td> <td>%s</td> <td>%s</td> <td>%s</td> <td>%s</td> <td>%s</td>
<td>%s</td> <td>%s</td> <td>%s</td> <td>%s</td> <td>%s</td> <td>%s</td> <td>%s</td>
</tr>
EOR

my $out = "<table id=\"cnfr-list\" class=\"tab-table\">" . $thead;

my $check = '<span class="ui-icon ui-icon-check center-icon"></span>';
my $minus = '<span class="ui-icon ui-icon-minus center-icon"></span>';

my $evenodd = 'gray';

while ( my $i = shift @rights ) {
    my @args = ();
    push @args, $cnfrs[$i]{'cnfr_state'};
    push @args, $evenodd;
    if ( $evenodd eq 'gray' ) {
        $evenodd = 'white';
    }
    else {
        $evenodd = 'gray';
    }

    push @args, $funct{ $cnfrs[$i]{'cnfr_state'} };
    push @args, $i;
    push @args, $cnfrs[$i]{'cnfr_name'};
    push @args, $i;
    push @args, $cnfrs[$i]{'cnfr_name'};
    push @args, $c_states{ $cnfrs[$i]{'cnfr_state'} };
    push @args, $cnfrs[$i]{'last_start'};
    push @args, $cnfrs[$i]{'last_end'};
    push @args, $cnfrs[$i]{'next_start'};
    if ( length $cnfrs[$i]{'next_duration'}
        and $cnfrs[$i]{'next_duration'} =~ /^(.*):[\d]{2}$/ )
    {
        push @args, $1;
    }
    else {
        push @args, $cnfrs[$i]{'next_duration'};
    }
    my $at = "";
    if ( $cnfrs[$i]{'auth_type'} =~ /number/ ) {
        $at .= "По номеру";
    }
    if ( $cnfrs[$i]{'auth_type'} =~ /pin/ ) {
        $at .= ", " if ( length $at );
        $at .= "По PIN'у";
    }
    push @args, $at;
    push @args, $cnfrs[$i]{'auth_string'};
    if ( $cnfrs[$i]{'auto_assemble'} ) {
        push @args, $check;
    }
    else {
        push @args, $minus;
    }
    if ( $cnfrs[$i]{'lost_control'} ) {
        push @args, $check;
    }
    else {
        push @args, $minus;
    }
    if ( $cnfrs[$i]{'need_record'} ) {
        push @args, $check;
    }
    else {
        push @args, $minus;
    }
    push @args, $cnfrs[$i]{'number_b'};
    if ( length $cnfrs[$i]{'audio_lang'} ) {
        push @args, $langs{ $cnfrs[$i]{'audio_lang'} };
    }
    else {
        push @args, "";
    }

    $out .= sprintf $row, @args;
}
$out .= "</table>";

print $cgi->header( -type => 'text/html', -charset => 'utf-8', -cookie=>$cnfr->cookie );
print $out;

exit(0);
