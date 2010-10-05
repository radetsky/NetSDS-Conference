#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;

my $form=<<EOH;
<form>
<fieldset>
	<legend id="cnfrlegend">Редактировать совещание</legend>
	<input type="hidden" name="cnfrid" id="cnfrid" value="%s"/>
	<label for="cnfr_name">Название совещания</label>
	<input type="text" id="cnfr_name" name="cnfr_name" value="%s"/><br/>
	
	Здесь будут еще некоторые поля

	<label for="lost_control">Контроль потери участника</label>
	<select id="lost_control" name="lost_control">
		<option value="1">Да</option>
		<option value="0">Нет</option>
	</select>
	<label for="need_record">Запись совещания</label>
	<select id="need_record" name="need_record">
		<option value="1">Да</option>
		<option value="0">Нет</option>
	</select>
	<label for="number_b">Номер конференции</label>
	<input type="text" id="number_b" name="number_b" value="%s"/>
	<label for="audio_lang">Аудиоязык</label>
	<select id="audio_lang" name="audio_lang">
		<option value="ru">Русский</option>
		<option value="ua">Украинский</option>
	</select>
	%s
	<label for="user_on_conf">Участники совещания</label>
	<table id="cnfr_users_phones">
	<tr>
	<td >
	<select name="user0" id="user0" onchange="">
		%s
	</select><br/>
	</td>
	<td>
	</td>
	</tr>
	</table>
	<div id="add_user" onclick="add_user(); return false;">
	</div>

	<input id="posbutton" type="button" onclick="upd_cnfr();return false;" value="Сохранить"/>
	<input type="button" onclick="close_cnfr_dialog();return false;" value="Отменить"/>
</fieldset>
</form>
EOH

my $op_add=<<EOO;
	<label for="op0">Оператор(ы)</label>
	<select name="op0" id="op0">
		%s
	</select>
	<div id="more_ops">
	%s
	</div>
	<div onclick="add_op_select(); return false;">
	Добавить оператора >>>
	</div>
EOO

my $cgi = CGI->new;

my $cnfr = ConferenceDB->new;

my $login = $cgi->remote_user();

my $id = $cgi->param("id");

my %cn = $cnfr->get_cnfr($id);

my $out = sprintf $form, $cn{'id'}, $cn{'name'}, $cn{'number_b'}, "";

print $cgi->header(-type=>'text/html',-charset=>'utf-8');
print $out;

exit(0);
