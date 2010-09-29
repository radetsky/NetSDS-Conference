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
	my @users = {};

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

=item %orgs = get_org_list();

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

1;
