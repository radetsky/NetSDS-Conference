#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;

# About form styling:
# unfortunately the only way to settle labels and inputs into nice two-column rows
# without hassle and form trashing because of "element does not fit" is a table.
# DIV Nazi will kill me some day but if your layout have simple grid of rows and columns -
# this is a table anyway, even if you produced it with floating block-elements.
#      -- zmeuka

my $form=<<EOH;
<form id="modify_user">
<fieldset>
	<legend id="userlegend">%s</legend>
	<input type="hidden" name="uid" id="uid" value="%s"/>
	<table class="form-layout">
	
	<tr><td><label for="uname">ФИО</label></td><td><input type="text" class="fit-column" id="uname" name="fio" value="%s"/></td></tr>
	<tr><td><label for="phone0">Номер телефона</label></td>
	    <td>
		<input type="text" class="fit-column" id="phone0" name="phone0" value="%s"/>
		<div id="more_phones">
		%s
		</div>
	    </td>
	</tr>
	<tr>
	    <td colspan="2" align="right">
		<button onclick="add_phone_field(); return false;">Добавить телефон</button>
	    </td>
	</tr>
	<tr><td><label for="user_org">Организация</label></td><td><select name="user_org" class="fit-column" id="user_org">%s</select></td></tr>
	<tr><td><label for="user_dept">Отдел</label></td><td><input type="text" class="fit-column" id="user_dept" name="user_dept" value="%s"/></td></tr>
	<tr><td><label for="user_pos">Должность</label></td><td><select name="user_pos" class="fit-column" id="user_pos">%s</select></td></tr>
	<tr><td><label for="user_email">E-mail</label></td><td><input type="text" class="fit-column" id="user_email" name="user_email" value="%s"/></td></tr>
	%s
	<tr><td align="left">
	    <button id="posbutton" onclick="send_user();return false;">%s</button>
	</td><td align="right">
	    <button onclick="close_user_dialog();return false;">Отменить</button>
	</td></tr>
	
	</table>
</fieldset>
</form>
EOH

my $admin_add=<<EOA;
	<tr><td><label for="op_rights">Оператор</label></td><td><input type="checkbox" name="op_rights" id="op_rights"%s/></td></tr>
	<tr><td colspan="2">
	    <div id="ad_op"  style="margin:4px;border:1px solid #666;padding:4px;background-color:#9c9;%s">
		<table class="form-layout">
		    <tr>
			<td><label for="op_login">Имя для входа</label></td>
			<td><input type="text" class="fit-column" name="op_login" id="op_login" value="%s"/></td>
		    </tr>
		    <tr>
			<td><label for="op_pass">Пароль</label></td>
			<td><input class="fit-column" type="password" name="op_pass" id="op_pass" value=""/></td>
		    </tr>
		    <tr>
			<td><label for="op_repass">Повторите пароль</label></td>
			<td><input class="fit-column" type="password" name="op_repass" id="op_repass" value=""/></td>
		    <tr>
			<td><label for="is_admin">Администратор</label></td>
			<td><input type="checkbox" name="is_admin" id="is_admin"%s/></td>
		    </tr>
		</table>
	    </div>
	</td></tr>
EOA

my $cgi = CGI->new;

my $cnfr = ConferenceDB->new;

my $login = $cnfr->login;

my $oper_id = $cnfr->operator($login);
my $admin = $cnfr->{oper_admin};
my $ab = $cnfr->addressbook;

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
		$adm = sprintf $admin_add, "", "display: none;", $user{'login'}, "";
	}
}

# Получили список организаций и должностей, чтобы сделать select'ы и сразу их сделали.
my @orgs = $cnfr->get_org_list();
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
	while(my $i = shift @orgs) {
		if($user{'org_id'} eq $$i{'id'}) {
			$org_options .= sprintf sprintf "<option value=\"%s\" selected=\"selected\">%s</option>\n", $$i{'id'}, $$i{'name'};
		} else {
			$org_options .= sprintf sprintf "<option value=\"%s\">%s</option>\n", $$i{'id'}, $$i{'name'};
		}
	}
} else {
	while(my $i = shift @orgs) {
  	$org_options .= sprintf sprintf "<option value=\"%s\">%s</option>\n", $$i{'id'}, $$i{'name'};
	}
}

my $more_phones = "";
my $k = 1;
while(defined $user{'phones'}[$k]) {
	$more_phones .= "<input type=\"text\" id=\"phone$k\" name=\"phone$k\" class=\"fit-column\" value=\"" .
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

print $cgi->header(-type=>'text/html',-charset=>'utf-8',-cookie=>$cnfr->cookie);
print $out;

exit(0);
