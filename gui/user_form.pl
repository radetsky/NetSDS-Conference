#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;

my $form=<<EOH;
<form>
<fieldset>
	<legend id="userlegend">%s</legend>
	<input type="hidden" name="uid" id="uid" value="%s"/>
	<label for="fio">ФИО</label>
	<input type="text" id="fio" name="fio" value="%s"/><br/>
	<label for="phone0">Номер телефона</label>
	<input type="text" id="phone0" name="phone0" value="%s"/>
	<div id="more_phones">
	%s
	</div>
	<div onclick="add_phone_field(); return false;">
	Добавить телефон >>>
	</div>
	<label for="user_org">Организация</label>
	<select name="user_org" id="user_org">%s
	</select><br/>
	<label for="user_dept">Отдел</label>
	<input type="text" id="user_dept" name="user_dept" value="%s"/><br/>
	<label for="user_pos">Должность</label>
	<select name="user_pos" id="user_pos">%s
	</select><br/>
	<label for="user_email">E-mail</label>
	<input type="text" id="user_email" name="user_email" value="%s"/><br/>
	%s
	<input id="posbutton" type="button" onclick="send_user();return false;" value="%s"/>
	<input type="button" onclick="close_user_dialog();return false;" value="Отменить"/>
</fieldset>
</form>
EOH

my $admin_add=<<EOA;
	<label for="op_rights">Оператор</label>
	<input type="checkbox" name="op_rights" id="op_rights"%s/><br>
	<div id="ad_op"%s>
		<label for="op_login">Имя для входа</label>
		<input type="text" name="op_login" id="op_login" value="%s"/><br/>
		<label for="op_pass">Пароль</label>
		<input type="password" name="op_pass" id="op_pass" value=""/><br/>
		<label for="op_repass">Повторите пароль</label>
		<input type="password" name="op_repass" id="op_repass" value=""/><br/>
		<label for="is_admin">Администратор</label>
	  <input type="checkbox" name="is_admin" id="is_admin"%s/>
	</div>
EOA

my $cgi = CGI->new;

my $cnfr = ConferenceDB->new;

my $login = $cgi->remote_user();

my $id = $cgi->param("id");

my %user = ();

if(defined $id and $id ne "new") {
	%user = $cnfr->get_user_by_id($id);
}

# Если пользователь администратор, то он может делать других пользователей
# операторами. Иначе у него даже checkbox не должен показываться
my $adm = "";
if($cnfr->is_admin($login)) {
	if($user{'is_admin'}) {
#		$adm = sprintf $admin_add, " checked=\"checked\"", "", $user{'login'}, " checked=\"ckecked\"";
		$adm = sprintf $admin_add, " checked", "", $user{'login'}, " checked";
	} elsif(length $user{'login'}) {
#		$adm = sprintf $admin_add, " checked=\"checked\"", "", $user{'login'}, "";
		$adm = sprintf $admin_add, " checked", "", $user{'login'}, "";
	} else {
		$adm = sprintf $admin_add, "", " style=\"display: none;\"", $user{'login'}, "";
	}
}

# Получили список организаций и должностей, чтобы сделать select'ы и сразу их сделали.
my %orgs = $cnfr->get_org_list();
my @posns = $cnfr->get_pos_list();

my $pos_options = "";
# Если для пользователя определена должность, то она должна быть selected в списке select
if(defined $user{'position_id'} and length $user{'position_id'}) {
	while(my $i = shift @posns) {
		if($user{'position_id'} eq $$i{'id'}) {
			$pos_options .= sprintf "<option value=\"%s\" selected=\"selected\">%s</option>\n", $$i{'id'}, $$i{'name'};
		} else {
			$pos_options .= sprintf "<option value=\"%s\">%s</option>\n", $$i{'id'}, $$i{'name'};
		}
	}
} else {
	while(my $i = shift @posns) {
		$pos_options .= sprintf "<option value=\"%s\">%s</option>\n", $$i{'id'}, $$i{'name'};
	}
}

my $org_options = "";
# Если для пользователя определена организация, то она должна быть selected в списке select
if(defined $user{'org_id'} and length $user{'org_id'}) {
	foreach my $i (sort keys %orgs) {
		if($user{'org_id'} eq $i) {
			$org_options .= sprintf sprintf "<option value=\"%s\" selected=\"selected\">%s</option>\n", $i, $orgs{$i};
		} else {
			$org_options .= sprintf sprintf "<option value=\"%s\">%s</option>\n", $i, $orgs{$i};
		}
	}
} else {
	foreach my $i (sort keys %orgs) {
  	$org_options .= sprintf sprintf "<option value=\"%s\">%s</option>\n", $i, $orgs{$i};
	}
}

my $more_phones = "";
my $k = 1;
while(defined $user{'phones'}[$k]) {
	$more_phones .= "<input type=\"text\" id=\"phone$k\" name=\"phone$k\" value=\"" .
									$user{'phones'}[$k] . "\"/><br/>";
	$k++;
}

my $out;

if(!(defined $id) or $id eq "new" ) {
	$out = sprintf $form, "Создать пользователя", "new", "", "", "", $org_options, "", $pos_options, "", $adm, "Создать";
} else {
	$out = sprintf $form, "Редактировать пользователя", $id, $user{'full_name'}, $user{'phones'}[0], $more_phones,
								 $org_options, $user{'department'}, $pos_options, $user{'email'}, $adm, "Сохранить";
}

print $cgi->header(-type=>'text/html',-charset=>'utf-8');
print $out;

exit(0);
