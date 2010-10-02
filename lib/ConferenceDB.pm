package ConferenceDB;

use strict;

use DBI;

=head ConferenceDb package

use ConferenceDB;

$conference = ConferenceDB->new;

=cut

my $dbh;

sub _connect {
	unless(defined $dbh and $dbh->ping()) {
		$dbh = DBI->connect("dbi:Pg:dbname=astconf", 'astconf', 'Rjyathtywbz', {AutoCommit => 0});
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

	my $query = "SELECT cnfr_id, cnfr_name, cnfr_state, last_start, last_end, next_start, ".
							"next_duration, shedule_date, shedule_time, auth_type, auth_string, lost_control, ".
							"need_record, number_b, audio_lang FROM conferences order by cnfr_id";
	$self->_connect();
	my $sth = $dbh->prepare($query);
	$sth->execute();

	while(my @tmp = $sth->fetchrow_array()) {
		$res[$tmp[0]]{'cnfr_name'} = (defined $tmp[1])? $tmp[1] : " ";
		$res[$tmp[0]]{'cnfr_state'} = (defined $tmp[2])? $tmp[2] : " ";
		$res[$tmp[0]]{'last_start'} = (defined $tmp[3])? $tmp[3] : " ";
		$res[$tmp[0]]{'last_end'} = (defined $tmp[4])? $tmp[4] : " ";
		$res[$tmp[0]]{'next_start'} = (defined $tmp[5])? $tmp[5] : " ";
		$res[$tmp[0]]{'next_duration'} = (defined $tmp[6])? $tmp[6] : " ";
		$res[$tmp[0]]{'shedule_date'} = (defined $tmp[7])? $tmp[7] : " ";
		$res[$tmp[0]]{'shedule_time'} = (defined $tmp[8])? $tmp[8] : " ";
		$res[$tmp[0]]{'auth_type'} = (defined $tmp[9])? $tmp[9] : " ";
		$res[$tmp[0]]{'auth_string'} = (defined $tmp[10])? $tmp[10] : " ";
		$res[$tmp[0]]{'lost_control'} = (defined $tmp[11])? $tmp[11] : " ";
		$res[$tmp[0]]{'need_record'} = (defined $tmp[12])? $tmp[12] : " ";
		$res[$tmp[0]]{'number_b'} = (defined $tmp[13])? $tmp[13] : " ";
		$res[$tmp[0]]{'audio_lang'} = (defined $tmp[14])? $tmp[14] : " ";
	}

	return @res;
}

=item @cnfr_list = get_cnfr_rights($login)

Возвращает список номеров конференций, доступных пользователю с
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

Если какое-либо из полей не определено, то значение этого элемента массива будет пробел.

=cut

sub get_user_list {
	my $self = shift;
	my @users = ();

	my $q = "select u.user_id, u.full_name, u.department, u.email, o.org_name, ".
					"p.position_name FROM users as u left outer join organizations as o on ".
					"(u.org_id=o.org_id) left outer join positions as p on ".
					"(u.position_id=p.position_id)";
	$self->_connect();
	my $sth = $dbh->prepare($q);
	$sth->execute();
	while(my @tmp = $sth->fetchrow_array()) {
		my %row = ();
		$row{'id'} = $tmp[0];
		$row{'name'} = (defined $tmp[1])? $tmp[1] : " ";
		$row{'organization'} = (defined $tmp[4])? $tmp[4] : " ";
		$row{'department'} = (defined $tmp[2])? $tmp[2] : " ";
		$row{'position'} = (defined $tmp[5])? $tmp[5] : " ";
		$row{'email'} = (defined $tmp[3])? $tmp[3] : " ";
		push @users, \%row;
	}
	return @users;
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
		$dbh->rollback();
		my $warn = $0 . " " . scalar(localtime (time)) . " " . $dbh->errstr;
		warn $warn;
		return undef;
	}

	$dbh->commit();
	$self->write_to_log($user, $q, @bind);
	return $self->get_pos_list();
}

sub update_user {
	my $self = shift;
	my $h = shift;
	my $loggedin = shift;

  my $q = "";
  my @bind = ();
	my %user = %{$h};
  return undef unless(defined $loggedin);
	$self->_connect();

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
		my $sth = $dbh->prepare($q);
		$sth->execute(@bind);
	};

	if($@) {
		$dbh->rollback();
		my $warn = $0 . " " . scalar(localtime (time)) . " " . $dbh->errstr;
		warn $warn;
		return undef;
	}

	$dbh->commit();
	$self->write_to_log($loggedin, $q, @bind);
	return $self->get_user_list();
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

1;
