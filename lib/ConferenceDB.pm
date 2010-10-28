package ConferenceDB;

use strict;

use DBI;

=head ConferenceDb package

use ConferenceDB;

$conference = ConferenceDB->new;

=cut

my $HTPASSWD = "/usr/local/sbin/htpasswd";

my $dbh;

my $error;

sub _connect {
	unless(defined $dbh and $dbh->ping()) {
		$dbh = DBI->connect("dbi:Pg:dbname=astconf", 'astconf', 'Rjyathtywbz',
												{AutoCommit => 0, RaiseError => 1});
	}
}

sub new {
	my $self = {};
	bless $self;
	return $self;
}

=item cnfr_list()

Возвращает array of hashes. Индекс array'я -- номер конференции в списке. Индекс
hash'а -- название столбца в таблице conferences базы данных.
=head2 Нумерация конференций, а значит и индексов array'я начинается с 1.
Если значение поля в базе NULL, в hash'е значением соответствующего элемента
будет пробел.

=cut

sub cnfr_list {
	my $self = shift;

	my @res = {};

	my $query = "SELECT cnfr_id, cnfr_name, cnfr_state, to_char(last_start, ".
							"'YYYY-MM-DD HH24:MI'), to_char(last_end, 'YYYY-MM-DD HH24:MI'), ".
							"to_char(next_start, 'YYYY-MM-DD HH24:MI'), next_duration, ".
							"schedule_date, to_char(schedule_time, 'HH24:MI'), ".
							"schedule_duration, auth_type, auth_string, auto_assemble, ".
							"lost_control, need_record, number_b, audio_lang FROM ".
							"conferences order by cnfr_id";
	$self->_connect();
	my $sth = $dbh->prepare($query);
	$sth->execute();

	while(my @tmp = $sth->fetchrow_array()) {
		$res[$tmp[0]]{'cnfr_id'} = $tmp[0];
		$res[$tmp[0]]{'cnfr_name'} = (defined $tmp[1])? $tmp[1] : "";
		$res[$tmp[0]]{'cnfr_state'} = (defined $tmp[2])? $tmp[2] : "";
		$res[$tmp[0]]{'last_start'} = (defined $tmp[3])? $tmp[3] : "";
		$res[$tmp[0]]{'last_end'} = (defined $tmp[4])? $tmp[4] : "";
		$res[$tmp[0]]{'next_start'} = (defined $tmp[5])? $tmp[5] : "";
		$res[$tmp[0]]{'next_duration'} = (defined $tmp[6])? $tmp[6] : "";
		$res[$tmp[0]]{'schedule_date'} = (defined $tmp[7])? $tmp[7] : "";
		$res[$tmp[0]]{'schedule_time'} = (defined $tmp[8])? $tmp[8] : "";
		$res[$tmp[0]]{'schedule_duration'} = (defined $tmp[9])? $tmp[9] : "";
		$res[$tmp[0]]{'auth_type'} = (defined $tmp[10])? $tmp[10] : "";
		$res[$tmp[0]]{'auth_string'} = (defined $tmp[11])? $tmp[11] : "";
		$res[$tmp[0]]{'auto_assemble'} = (defined $tmp[12])? $tmp[12] : "";
		$res[$tmp[0]]{'lost_control'} = (defined $tmp[13])? $tmp[13] : "";
		$res[$tmp[0]]{'need_record'} = (defined $tmp[14])? $tmp[14] : "";
		$res[$tmp[0]]{'number_b'} = (defined $tmp[15])? $tmp[15] : "";
		$res[$tmp[0]]{'audio_lang'} = (defined $tmp[16])? $tmp[16] : "";
	}

	return @res;
}

=item @cnfr_list = get_cnfr_rights($login)

Возвращает список номеров конференций, доступных оператору с
аутентификационным именем $login. Может вернуть пустой список.

=cut

sub get_cnfr_rights {
	my $self = shift;
	my $user = shift;

	my @ret = ();

	return @ret unless defined $user;

	$self->_connect();

	if($self->is_admin($user)) {
		my @tmp = $dbh->selectrow_array("SELECT max(cnfr_id) FROM conferences");
		@ret = ( 1 .. $tmp[0] ) if(defined $tmp[0]);
		return @ret;
	}

	my $q = "SELECT ooc.cnfr_id FROM operators_of_conferences ooc, admins a WHERE ".
			 "a.login=? AND a.admin_id=ooc.admin_id order by ooc.cnfr_id";
	my $sth = $dbh->prepare($q);
	$sth->execute($user);
	while(my @tmp = $sth->fetchrow_array()) {
		push @ret, $tmp[0] if(defined $tmp[0]);
	}
	return @ret;
}

=item $res = is_admin($login);

Определяет, является ли пользователь $login администратором

=cut

sub is_admin {
	my $self = shift;
	my $user = shift;

	return 0 unless defined $user;
	$self->_connect();
	my $q = "SELECT is_admin FROM admins WHERE login=?";
	my @tmp = $dbh->selectrow_array($q, undef, $user);

	return $tmp[0] if(defined $tmp[0]);
	return 0;
}

=item @users = get_user_list();

Возвращает список пользователей. Данные первого пользователя в списке будут:
$users[0]{'id'}            -- внутренний id, может использоваться как уникальный идетнитфикатор пользователя
$users[0]{'name'}          -- полное имя пользователя 
$users[0]{'organization'}  -- название организации
$users[0]{'department'}    -- название отдела
$users[0]{'position'}      -- название должности
$users[0]{'email'}         -- e-mail адрес
@{users[0]{'phones'})      -- array номеров пользователя, выстроенный по приоритету номеров
@{users[0]{'phones_id'})   -- соответствующие по индексу array номерам
пользователя, id номеров пользователя

Если какое-либо из полей не определено, то значение этого элемента массива будет
пустая строка.

=cut

sub get_user_list {
	my $self = shift;
	my @users = ();

	my $q = "select u.user_id, u.full_name, u.department, u.email, o.org_name, ".
					"p.position_name, ph.phone_number, ph.phone_id, adm.login, adm.is_admin, ".
					"adm.passwd_hash FROM users as u left outer join organizations as o on ".
					"(u.org_id=o.org_id) left outer join positions as p on (u.position_id=p.position_id) ".
					"left outer join phones as ph on (u.user_id=ph.user_id) left outer join admins as adm ".
					"on(u.user_id=adm.user_id) ORDER BY p.position_order, u.user_id, ph.order_nmb";
	$self->_connect();
	my $sth = $dbh->prepare($q);
	$sth->execute();
	my $uid;
	my @phs = ();
	my @phs_id = ();
	my %row = ();
	while(my @tmp = $sth->fetchrow_array()) {
		if($#users < 0 and $#phs < 0) {
			$uid = $tmp[0];
			$row{'id'} = $tmp[0];
			$row{'name'} = (defined $tmp[1])? $tmp[1] : "";
			$row{'organization'} = (defined $tmp[4])? $tmp[4] : "";
			$row{'department'} = (defined $tmp[2])? $tmp[2] : "";
			$row{'position'} = (defined $tmp[5])? $tmp[5] : "";
			$row{'email'} = (defined $tmp[3])? $tmp[3] : "";
			$row{'login'} = (defined $tmp[8])? $tmp[8] : "";
			$row{'admin'} = (defined $tmp[9])? $tmp[9] : 0;
			$row{'passwd'} = (defined $tmp[10])? $tmp[10] : "";
			if(defined $tmp[6]) {
				push @phs, $tmp[6];
				push @phs_id, $tmp[7];
			}
		} elsif( $uid ne $tmp[0] ) {
			my @tphs = (@phs);
			my @tphs_id = (@phs_id);
			$row{'phones'} = \@tphs;
			$row{'phones_id'} = \@tphs_id;
			my %trow = %row;
			push @users, \%trow;
			%row = ();
			@phs = ();
			@phs_id = ();
			$row{'id'} = $tmp[0];
			$uid = $row{'id'};
			$row{'name'} = (defined $tmp[1])? $tmp[1] : "";
			$row{'organization'} = (defined $tmp[4])? $tmp[4] : "";
			$row{'department'} = (defined $tmp[2])? $tmp[2] : "";
			$row{'position'} = (defined $tmp[5])? $tmp[5] : "";
			$row{'email'} = (defined $tmp[3])? $tmp[3] : "";
			$row{'login'} = (defined $tmp[8])? $tmp[8] : "";
			$row{'admin'} = (defined $tmp[9])? $tmp[9] : 0;
			$row{'passwd'} = (defined $tmp[10])? $tmp[10] : "";
			if(defined $tmp[6]) {
				push @phs, $tmp[6];
				push @phs_id, $tmp[7];
			}
		} else {
			if(defined $tmp[6]) {
				push @phs, $tmp[6];
				push @phs_id, $tmp[7];
			}
		}
	}
	$row{'phones'} = \@phs;
	$row{'phones_id'} = \@phs_id;
	push @users, \%row;
	return @users;
}

sub add_participant_to_conference{
	my $self = shift;
	my $cid = shift;
	my $phid = shift;
	my $login = shift;

	return undef unless(defined $login);
	$self->_connect();
	my $q = "SELECT max(participant_order) FROM users_on_conference WHERE cnfr_id=?";
	my @tmp = $dbh->selectrow_array($q, undef, $cid);
	my $po = 0;
	$po = $tmp[0]+1 if(defined $tmp[0]);

	$q = "INSERT INTO users_on_conference (cnfr_id, phone_id, participant_order) ".
			 "VALUES (?, ?, ?)";
	my $sth = $dbh->prepare($q);
	eval {
		$sth->execute($cid, $phid, $po);
	};

	if($@) {
		$error = "Ошибка добавления пользователя в совещание. Обратитесь к администратору";
		$dbh->rollback();
		my $warn = $0 . " " . scalar(localtime (time)) . " " . $dbh->errstr;
		warn $warn;
		return undef;
	}

	$dbh->commit();
	$self->write_to_log($login, $q, $cid, $phid, $po);
	return 1;
}

=item %user = get_user_by_id($id)

$id -- id пользователя из базы

Возвращаемые элементы
$res{'user_id'} - id пользователя из базы
$res{'full_name'} - полное имя пользователя
$res{'department'} - отдел пользователя
$res{'email'} - email пользователя
$res{'org_id'} - id организации
$res{'org_name'} - название организации
$res{'position_id'} - id должности
$res{'position_name'} - название должности
$res{'login'} - логин пользователя, если он является оператором
$res{'is_admin'} - является ли оператор администратором
@{$res{'is_admin'}} - список телефонов пользователя, выстроенный в порядке понижения приоритета

=cut

sub get_user_by_id {
	my $self = shift;
	my $id = shift;
	my %res = ();

	my $q = "SELECT u.user_id, u.full_name, u.department, u.email, u.org_id, o.org_name, ".
					"u.position_id, p.position_name, a.login, a.is_admin FROM users as u left outer join ".
					"organizations as o on (u.org_id=o.org_id) left outer join positions as p on ".
					"(u.position_id=p.position_id) left outer join admins as a on (u.user_id=a.user_id) ".
					"WHERE u.user_id=?";
	$self->_connect();
	my @tmp = $dbh->selectrow_array($q, undef, $id);
	return undef unless(defined $tmp[0]);
	$res{'user_id'} = $tmp[0];
	$res{'full_name'} = (defined $tmp[1])? $tmp[1] : "" ;
	$res{'department'} = (defined $tmp[2])? $tmp[2] : "";
	$res{'email'} = (defined $tmp[3])? $tmp[3] : "";
	$res{'org_id'} = (defined $tmp[4])? $tmp[4] : "";
	$res{'org_name'} = (defined $tmp[5])? $tmp[5] : "";
	$res{'position_id'} = (defined $tmp[6])? $tmp[6] : "";
	$res{'position_name'} = (defined $tmp[7])? $tmp[7] : "";
	$res{'login'} = (defined $tmp[8])? $tmp[8] : "";
	$res{'is_admin'} = (defined $tmp[9])? $tmp[9] : "0";
	$q = "SELECT phone_number FROM phones WHERE user_id=? ORDER BY order_nmb";
	my $sth = $dbh->prepare($q);
	$sth->execute($res{'user_id'});
	my @phs = ();
	while(@tmp = $sth->fetchrow_array()) {
		push @phs, $tmp[0];
	}
	$res{'phones'} = \@phs;
	return %res;
}

=item %orgs = get_org_list();

Возвращает список организаций. Индекс массива -- id организации, элемент массива
-- ее название.

=cut

sub get_org_list {
	my $self = shift;
	my %orgs = ();

	my $q = "SELECT org_id, org_name FROM organizations ORDER BY org_id";
	$self->_connect();
	my $sth = $dbh->prepare($q);
	$sth->execute();
	while(my @tmp = $sth->fetchrow_array()) {
		$orgs{$tmp[0]} = $tmp[1];
	}

	return %orgs;
}

=item @pos = get_pos_list()

Возвращает array of hashes. В array'е должности выстроены по порядку
возрастания. В hash'е индескы id, name, order

=cut

sub get_pos_list {
	my $self = shift;
	my @pos = ();

	my $q = "SELECT position_id, position_name, position_order FROM positions ORDER BY position_order";
	$self->_connect();
	my $sth = $dbh->prepare($q);
	$sth->execute();
	while(my @tmp = $sth->fetchrow_array()) {
		my %row = ();
		$row{'id'} = $tmp[0];
		$row{'name'} = $tmp[1];
		$row{'order'} = $tmp[2];
		push  @pos, \%row;
	}
	return @pos;
}

sub get_cnfr {
	my $self = shift;
	my $id = shift;
	my %cnfr = ();

	$self->_connect();
	my $q = "SELECT cnfr_id, cnfr_name, cnfr_state, schedule_date, to_char(schedule_time, ".
					"'HH24:MI'), schedule_duration, to_char(next_start, 'YYYY-MM-DD HH24:MI'), ".
					"next_duration, auth_type, auth_string, auto_assemble, lost_control, need_record, ".
					"number_b, audio_lang FROM conferences WHERE cnfr_id=?";
	my @tmp = $dbh->selectrow_array($q, undef, $id);
	$cnfr{'id'} = $tmp[0];
	$cnfr{'name'} = (defined $tmp[1])? $tmp[1] : "";
	$cnfr{'cnfr_state'} = (defined $tmp[2])? $tmp[2] : "";
	$cnfr{'schedule_date'} = (defined $tmp[3])? $tmp[3] : "";
	$cnfr{'schedule_time'} = (defined $tmp[4])? $tmp[4] : "";
	$cnfr{'schedule_duration'} = (defined $tmp[5])? $tmp[5] : "";
	$cnfr{'next_start'} = (defined $tmp[6])? $tmp[6] : "";
	$cnfr{'next_duration'} = (defined $tmp[7])? $tmp[7] : "";
	$cnfr{'auth_type'} = (defined $tmp[8])? $tmp[8] : "";
	$cnfr{'auth_string'} = (defined $tmp[9])? $tmp[9] : "";
	$cnfr{'auto_assemble'} = (defined $tmp[10])? $tmp[10] : "";
	$cnfr{'lost_control'} = (defined $tmp[10])? $tmp[10] : "";
	$cnfr{'need_record'} = (defined $tmp[11])? $tmp[11] : "";
	$cnfr{'number_b'} = (defined $tmp[12])? $tmp[12] : "";
	$cnfr{'audio_lang'} = (defined $tmp[13])? $tmp[13] : "";

	$q = "SELECT u.full_name, a.admin_id FROM operators_of_conferences ooc, admins a, ".
			 "users u WHERE ooc.cnfr_id=? AND ooc.admin_id=a.admin_id AND ".
			 "a.user_id=u.user_id";
	my $sth = $dbh->prepare($q);
	$sth->execute($id);
	my %ops = ();
	while(@tmp = $sth->fetchrow_array()) {
		$ops{$tmp[1]} = $tmp[0];
	}
	$cnfr{'operators'} = \%ops;

	$q = "SELECT u.full_name, ph.phone_number, ph.phone_id FROM users_on_conference uoc, ".
			 "phones ph, users u WHERE uoc.cnfr_id=? AND uoc.phone_id=ph.phone_id AND ".
			 "ph.user_id=u.user_id ORDER BY uoc.participant_order";
	$sth = $dbh->prepare($q);
	$sth->execute($id);
	my @conf_users = ();
	while(@tmp = $sth->fetchrow_array()) {
		my %member = ();
		$member{'name'} = $tmp[0];
		$member{'phone'} = $tmp[1];
		$member{'phone_id'} = $tmp[2];
		push @conf_users, \%member;
	}

	$cnfr{'users'} = \@conf_users;
	return %cnfr;
}

sub get_cnfr_participants {
	my $self = shift;
	my $cid = shift;
	my %u_to_ph = ();

	$self->_connect();
	my $q = "SELECT uoc.phone_id, ph.user_id, ph.phone_number FROM users_on_conference uoc, phones ph ".
					"WHERE uoc.phone_id=ph.phone_id AND uoc.cnfr_id=?";
	my $sth = $dbh->prepare($q);
	$sth->execute($cid);
	while(my @tmp = $sth->fetchrow_array()) {
		$u_to_ph{$tmp[1]}{'id'} = $tmp[0];
		$u_to_ph{$tmp[1]}{'number'} = $tmp[2];
	}
	return %u_to_ph;
}

sub save_cnfr {
	my $self = shift;
	my $login = shift;
	my $id = shift;
	my $ce_name = shift;
	my $next_start = shift;
	$next_start = undef unless(length $next_start);
	my $next_duration = shift;
	$next_duration = undef unless(length $next_duration);
	my $schedule_day = shift;
	$schedule_day = undef unless(length $schedule_day);
	my $schedule_time = shift;
	$schedule_time = undef unless(length $schedule_time);
	my $schedule_duration = shift;
	$schedule_duration = undef unless(length $schedule_duration);
	my $auth_type = shift;
	$auth_type = undef unless(length $auth_type);
	my $auth_string = shift;
	$auth_string = undef unless(length $auth_string);
	my $auto_assemble = shift;
	my $lost_control = shift;
	my $need_record = shift;
	my $audio_lang = shift;
	$audio_lang = undef unless(length $audio_lang);
	my $p = shift;

	my @phs_id = (@{$p});

	my $q = "UPDATE conferences SET cnfr_name=?, next_start=to_timestamp(?, 'YYYY-MM-DD HH24:MI'), ".
					"next_duration=?, schedule_date=?, schedule_time=?, schedule_duration=?, auth_type=?, ".
					"auth_string=?, auto_assemble=?, lost_control=?, need_record=?, audio_lang=? WHERE ".
					"cnfr_id=?";
	my @bind = ($ce_name, $next_start, $next_duration, $schedule_day, $schedule_time, $schedule_duration,
						  $auth_type, $auth_string, $auto_assemble, $lost_control, $need_record,
							$audio_lang, $id);
	eval {
		$dbh->do($q, undef, @bind);
	};

	if($@) {
		$error = "Ошибка обновления данных конференции. Обратитесь к администратору";
		$dbh->rollback();
		my $warn = $0 . " " . scalar(localtime (time)) . " " . $dbh->errstr;
		warn $warn;
		warn join('" "', @bind);
		return undef;
	}

	$dbh->commit();
	$self->write_to_log($login, $q, @bind);

	$q = "INSERT INTO users_on_conference (cnfr_id, phone_id, participant_order) ".
			 "VALUES (?, ?, ?)";

  my $q1 = "INSERT INTO change_log (auth_user, db_query, db_params) VALUES ".
		       "(?, ?, ?)";
	my $sth = $dbh->prepare($q);
	my $sth1 = $dbh->prepare($q1);
	my $bind_str;
	eval {
		$dbh->do("DELETE FROM users_on_conference WHERE cnfr_id=?", undef, $id);
		$sth1->execute($login, "DELETE FROM users_on_conference WHERE cnfr_id=?", $id);
		my $cnt = 0;
		while(my $ph_id = shift @phs_id) {
			$sth->execute($id, $ph_id, $cnt);
			$bind_str = join(' ', map {$dbh->quote($_)} ($id, $ph_id, $cnt));
			$sth1->execute($login, $q, $bind_str);
			$cnt++;
		}
	};

	if($@) {
		$error = "Ошибка сохранения списка участников. Обратитесь к администратору";
		$dbh->rollback();
		my $warn = $0 . " " . scalar(localtime (time)) . " " . $dbh->errstr;
		warn $warn;
		return undef;
	}

	$dbh->commit();
	return 1;
}

=item %orgs = update_orgs($id, $name, $user)

Добавляет или обновляет название организации. Входные параметры:
$id - Если число, то обновляет название организации с таким id. Если строка new,
то добавляет новое название организации.
$name - название организации
$user - пользователь, от которого это делается

Возвращает обновленный hash аналогично функции get_org_list()

=cut 

sub update_orgs {
	my $self = shift;
	my $id = shift;
	my $name = shift;
	my $user = shift;

	my $q = "";
	my @bind = ();
	return undef unless(defined $user);

	$self->_connect();

	if($id eq "new") {
		$q = "INSERT INTO organizations (org_name) VALUES (?)";
		@bind = ($name);
	} else {
		$q = "UPDATE organizations SET org_name=? WHERE org_id=?";
		@bind = ($name, $id);
	}

	eval {
		my $sth = $dbh->prepare($q);
		$sth->execute(@bind);
	};

	if($@) {
		$error = "Внутренняя ошибка базы. Обратитесь к администратору";
		$dbh->rollback();
		my $warn = $0 . " " . scalar(localtime (time)) . " " . $dbh->errstr;
		warn $warn;
		return undef;
	}

	$dbh->commit();
	$self->write_to_log($user, $q, @bind);
	return $self->get_org_list();
}

=item @pos = update_posns($id, $name, $user)

Добавляет или обновляет название организации. Входные параметры:
$id - Если число, то обновляет название должности с таким id. Если строка new,
то добавляет новое название должности с наименьшим приоритетом.
$name - название должности
$user - пользователь, от которого это делается

Возвращает обновленный массив аналогично функции get_pos_list()

=cut

sub update_posns {
	my $self = shift;
	my $id = shift;
	my $name = shift;
	my $user = shift;

	my $q = "";
	my @bind = ();
	return undef unless(defined $user);

	$self->_connect();
	if($id eq "new") {
		$q = "SELECT max(position_order) FROM positions";
		my @tmp = $dbh->selectrow_array($q);
		$tmp[0] = 0 unless(defined $tmp[0]);
		my $ord = $tmp[0] + 5;
		$q = "INSERT INTO positions (position_name, position_order) VALUES (?, ?)";
		@bind = ($name, $ord);
	} else {
		$q = "UPDATE positions SET position_name=? WHERE position_id=?";
		@bind = ($name, $id);
	}

	eval {
		my $sth = $dbh->prepare($q);
		$sth->execute(@bind);
	};

	if($@) {
		$error = "Внутренняя ошибка базы. Обратитесь к администратору";
		$dbh->rollback();
		my $warn = $0 . " " . scalar(localtime (time)) . " " . $dbh->errstr;
		warn $warn;
		return undef;
	}

	$dbh->commit();
	$self->write_to_log($user, $q, @bind);
	return $self->get_pos_list();
}

=item @users = update_user($login, \%user, \@phones, \%admin);

Функция обновляет данные или создает пользователя. Возвращает обновленный список
пользователей, аналогично функции get_user_list();
Передаваемые параметры:
$user{'id'} -- id пользователя для изменения параметров или строка "new" для
создания нового пользователя
$user{'name'} -- ФИО
$user{'orgid'} -- org_id организации
$user{'dept'} -- название отдела
$user{'posid'} -- pos_id должности
$user{'email'} -- email адрес

@phones -- array номеров телефонов, выстроенных по порядку снижения приоритета
($phone[0] наиболее приоритетный)

$admin{'oper'} -- 1/0 является ли пользователь оператором
$admin{'login'} -- логин пользователя
$admin{'passwd'} -- пароль пользователя
$admin{'admin'} -- 1/0 является ли пользователь администратором

=cut

sub update_user {
	my $self = shift;
	my $loggedin = shift;
	my $h = shift;
	my $p = shift;
	my $a = shift;

  my $q = "";
  my @bind = ();
	my %user = %{$h};
	my @phones = (@{$p});
	my %admin = %{$a};
  return undef unless(defined $loggedin);
	$self->_connect();
	my $sth;

	if($user{'id'} eq "new") {
		$q = "INSERT INTO users (full_name, position_id, org_id, department, email) VALUES ".
				 "(?, ?, ?, ?, ?)";
		@bind = ($user{'name'}, $user{'posid'}, $user{'orgid'}, $user{'dept'}, $user{'email'});
	} else {
		$q = "UPDATE users SET full_name=?, position_id=?, org_id=?, department=?, email=? ".
				 "WHERE user_id=?";
		@bind = ($user{'name'}, $user{'posid'}, $user{'orgid'}, $user{'dept'}, $user{'email'}, $user{'id'});
	}

	eval {
		$sth = $dbh->prepare($q);
		$sth->execute(@bind);
	};

	if($@) {
		if($user{'id'} eq "new") {
			$error = "Ошибка добавления пользователя. Обратитесь к администратору";
		} else {
			$error = "Ошибка обновления пользователя. Обратитесь к администратору";
		}
		$dbh->rollback();
		my $warn = $0 . " " . scalar(localtime (time)) . " " . $dbh->errstr;
		warn $warn;
		return undef;
	}

	$dbh->commit();
	if($#phones < 0) {
		$self->write_to_log($loggedin, $q, @bind);
# Если пользователь уже существовал, то у него нужно удалить все номера
# телефонов
		if($user{'id'} =~ /^[\d]+$/) {
			$q = "DELETE FROM phones WHERE user_id=?";
			eval {
				$dbh->do($q, undef, $user{'id'});
			};
			if($@) {
				$error = "Один из удалямых телефонов используется в совещании. Сначала нужно проверить, что удаляемый телефон нигде не используется";
				$dbh->rollback();
				my $warn = $0 . " " . scalar(localtime (time)) . " " . $dbh->errstr;
				warn $warn;
				return undef;
			}
			$dbh->commit;
			$self->write_to_log($loggedin, $q, $user{'id'});
		}
		return $self->get_user_list();
	}

	my $new_id = undef;
	if($user{'id'} eq "new") {
		$new_id = $dbh->last_insert_id(undef, undef, "users", undef);
# Мы вытянули id нововставленного юзера (или не вытянули), но мы можем уже
# записать строку логгирования запросов
		$self->write_to_log($loggedin, $q, @bind);
		unless(defined $new_id) {
			my $qq = "SELECT user_id FROM users WHERE full_name=?, position_id=?, ".
							 "org_id=?, department=?, email=?";
			my @tmp = $dbh->selectrow_array($qq, undef, $user{'name'}, $user{'posid'},
																	$user{'orgid'}, $user{'dept'}, $user{'email'});
			$new_id = $tmp[0];
		}
		if($new_id =~ /^[\d]+$/) {
# Если пользователь новосозданный и у нас получилось определить его id, то нам
# нужно просто по порядку записать его номера телефонов
			$q = "INSERT INTO phones (user_id, phone_number, order_nmb) VALUES ".
					 "(?, ?, ?)";
			$sth = $dbh->prepare($q);
			my $cnt = 0;
			while(my $numb = shift @phones) {
				eval {
					$sth->execute($new_id, $numb, $cnt);
				};
				if($@) {
					$error = "Такой номер уже существует в базе у другого пользователя. Повторение одного номера у разных пользователей невозможно";
					$dbh->rollback();
					my $warn = $0 . " " . scalar(localtime (time)) . " " . $dbh->errstr;
					warn $warn;
					return undef;
				}
				$dbh->commit();
				$self->write_to_log($loggedin, $q, $new_id, $numb, $cnt);
				$cnt++;
			}
		} else {
			$error = "Ошибка создания пользователя. Обратитесь к администратору.";
			my $warn = "Can't find id of newly created user " . $user{'name'};
			warn $warn;
			return undef;
		}
	} else {
		$self->write_to_log($loggedin, $q, @bind);
# Пользователь уже существовал, нужно сверить телефоны и обновить список при
# этом у существующих телефонов должны сохранится их id. Сначала удаляем
# телефоны, которые есть в старом списке, но нету в новом. Потом проходим по
# новому списку, выставляя их в правильном порядке
		my %old_phones = $self->get_user_phones($user{'id'});
		my @old_numbers = @{$old_phones{'number'}};
		my @to_delete = ();
		my @qst = ();
		foreach my $n (@old_numbers) {
			next if(grep(/^$n$/, @phones));
			push @to_delete, $n;
			push @qst, '?';
		}
		if($#to_delete >= 0) {
			$q = "DELETE FROM phones WHERE user_id=? AND phone_number IN (".
					 join(',',@qst) . ")";
			eval {
				$dbh->do($q,undef, $user{'id'}, @to_delete);
			};
			if($@) {
				$error = "Один из удалямых телефонов используется в совещании. Сначала нужно проверить, что удаляемый телефон нигде не используется";
				$dbh->rollback();
				my $warn = $0 . " " . scalar(localtime (time)) . " " . $dbh->errstr;
				warn $warn;
				return undef;
			}
			$dbh->commit();
			$self->write_to_log($loggedin, $q, $user{'id'}, @to_delete);
		}
		my $cnt = 0;
		my @qr = ();
		my @st = ();
		$qr[0] = "UPDATE phones SET order_nmb=? WHERE user_id=? AND phone_number=?";
		$st[0] = $dbh->prepare($qr[0]);
		$qr[1] = "INSERT INTO phones (order_nmb, user_id, phone_number) VALUES ".
			 			 "(?, ?, ?)";
		$st[1] = $dbh->prepare($qr[1]);
		while(my $ph = shift @phones) {
			my $sel_query;
			if(grep(/^$ph$/,@old_numbers)) {
				$sel_query = 0;
			} else {
				$sel_query = 1;
			}
			eval {
				$st[$sel_query]->execute($cnt, $user{'id'}, $ph);
			};

			if($@) {
				$error = "Ошибка обновления телефонов. Обратитесь к администратору.";
				$dbh->rollback();
				my $warn = $0 . " " . scalar(localtime (time)) . " " . $dbh->errstr;
				warn $warn;
				return undef;
			}
			$dbh->commit();
			$self->write_to_log($loggedin, $qr[$sel_query], $cnt, $user{'id'}, $ph);
			$cnt++;
		}
	}

	if($self->is_admin($loggedin)) {
		if($admin{'oper'}) {
			my $hashed = undef;
			if(defined $admin{'passwd'} and length $admin{'passwd'}) {
				my $cmd = "$HTPASSWD -bn some " . $admin{'passwd'};
				(undef, $hashed) = split(/:/,`$cmd`);
			}
			if($user{'id'} eq "new") {
				$q = "INSERT INTO admins (user_id, login, passwd_hash, is_admin) ".
						 "VALUES (?, ?, ?, ?)";
				$sth = $dbh->prepare($q);
				eval {
					$sth->execute($new_id, $admin{'login'}, $hashed, $admin{'admin'});
				};
  
				if($@) {
					$error = "Такое имя для входа уже используется. Выберите другое.";
					$dbh->rollback();
					my $warn = $0 . " " . scalar(localtime (time)) . " " . $dbh->errstr;
					warn $warn;
					return undef;
				}
  
				$dbh->commit();
				$self->write_to_log($loggedin, $q, $new_id, $admin{'login'}, $hashed, $admin{'admin'});
			} else {
				$q = "SELECT admin_id, user_id, login FROM admins WHERE login=? or user_id=?";
				$sth = $dbh->prepare($q);
				$sth->execute($admin{'login'}, $user{'id'});
				my $upd = 0;
				while(my @tmp = $sth->fetchrow_array()) {
					if($user{'id'} eq $tmp[1]) {
						$upd = $tmp[0];
					} else {
						$error = "Такое имя для входа уже используется. Выберите другое.";
						return undef;
					}
				}
				if($upd) {
					if(defined $hashed) {
						$q = "UPDATE admins SET login=?, passwd_hash=?, is_admin=? WHERE ".
								 "admin_id=?";
						@bind = ($admin{'login'}, $hashed, $admin{'admin'}, $upd);
					} else {
						$q = "UPDATE admins SET login=?, is_admin=? WHERE admin_id=?";
						@bind = ($admin{'login'}, $admin{'admin'}, $upd);
					}
				} else {
					if(defined $hashed) {
						$q = "INSERT INTO admins (user_id, login, passwd_hash, is_admin) ".
								 "VALUES (?, ?, ?, ?)";
						@bind = ($user{'id'}, $admin{'login'}, $hashed, $admin{'admin'});
					} else {
						$error = "Нельзя создавать оператора без пароля. Задайте пароль.";
						return undef;
					}
				}
				$sth = $dbh->prepare($q);
				eval {
					$sth->execute(@bind);
				};
  
				if($@) {
					$error = "Ошибка сохранения прав администратора. Обратитесь к администратору.";
					$dbh->rollback();
					my $warn = $0 . " " . scalar(localtime (time)) . " " . $dbh->errstr;
					warn $warn;
					return undef;
				}
				$dbh->commit();
				$self->write_to_log($loggedin, $q, @bind);
			}
		}
	}
	return $self->get_user_list();
}

=item @phones = get_user_phones($user_id)

$user_id -- id пользователя, телефоны которого интересуют

=cut

sub get_user_phones {
	my $self = shift;
	my $uid = shift;
	my %phones = {};

	return %phones unless(defined $uid);

	my $q = "SELECT phone_number, phone_id FROM phones WHERE user_id=? ORDER by order_nmb";
	$self->_connect();

	my $sth = $dbh->prepare($q);
	$sth->execute($uid);
	my @ph_ids = ();
	my @phs = ();
	while(my @tmp = $sth->fetchrow_array()) {
		if(defined $tmp[1]) {
			push @phs, $tmp[0];
			push @ph_ids, $tmp[1];
		}
	}

	$phones{'id'} = \@ph_ids;
	$phones{'number'} = \@phs;
	return %phones;
}

=item write_to_log ($user, $query, @bind)

Записывает в таблицу логов выполненное действие.
$user - логин пользователя, от которого выполнялось действие
$query - запрос в базу
@bind - параметры, которые биндились к этому запросу

Возвращает undef в случае неудачи и 1, если все прошло успешно

=cut

sub write_to_log {
	my $self = shift;
	my $user = shift;
	my $query = shift;
	my @bind = @_;

	$self->_connect();

	my $bind_str = join(' ', map {$dbh->quote($_)} @bind);
	my $q = "INSERT INTO change_log (auth_user, db_query, db_params) VALUES ".
					"(?, ?, ?)";
	my $sth = $dbh->prepare($q);
	eval {
		$sth->execute($user, $query, $bind_str);
	};

	if($@) {
		$dbh->rollback();
		warn "Error writing log: $0 $user $query $bind_str";
		return undef;
	}

	$dbh->commit();
	return 1;
}

sub get_error {
	my $self;
	return $self->error;
}

sub cnfr_update {
	my ($self, $cnfr_id, $params) = @_; 

	$self->_connect();
	
	my @update_array; 
	foreach my $param ( keys %$params) { 
		my $pair = sprintf("%s=%s", $param, $params->{$param}); 
		push @update_array,$pair; 
	}
	
	my $update_string = join (',',@update_array); 
	warn $update_string;

	my $query = sprintf("update conferences set %s where cnfr_id=%d", 
		$update_string, $cnfr_id);
	my $sth = $dbh->prepare($query);
	eval {
		$sth->execute();
	};
	if($@) {
		$dbh->rollback();
		my $warn = $0 . " " . scalar(localtime (time)) . " " . $dbh->errstr;
		warn $warn;
		return undef;
	}
	$dbh->commit();
	return 1; 

}

sub _disconnect { 
	my $self = shift; 

	$dbh->disconnect; 
}
1;
