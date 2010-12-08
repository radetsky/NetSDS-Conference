package ConferenceDB;

use strict;

use DBI;

=head ConferenceDb package

use ConferenceDB;

$conference = ConferenceDB->new;

=cut

my $HTPASSWD = "/usr/bin/htpasswd";

my $dbh;

my $error;

sub _connect {
    unless ( defined $dbh and $dbh->ping() ) {
        $dbh =
          DBI->connect( "dbi:Pg:dbname=astconf", 'astconf', 'Rjyathtywbz',
            { AutoCommit => 0, RaiseError => 1 } );
    }
}

=item new()

Конструктор. Не делает практически ничего

=cut

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

    my $query =
        "SELECT cnfr_id, cnfr_name, cnfr_state, to_char(last_start, "
      . "'YYYY-MM-DD HH24:MI'), to_char(last_end, 'YYYY-MM-DD HH24:MI'), "
      . "to_char(next_start, 'YYYY-MM-DD HH24:MI'), next_duration, "
      . "auth_type, auth_string, auto_assemble, "
      . "lost_control, need_record, number_b, audio_lang FROM "
      . "conferences order by cnfr_id";
    $self->_connect();
    my $sth = $dbh->prepare($query);
    $sth->execute();

    while ( my @tmp = $sth->fetchrow_array() ) {
        $res[ $tmp[0] ]{'cnfr_id'}       = $tmp[0];
        $res[ $tmp[0] ]{'cnfr_name'}     = ( defined $tmp[1] ) ? $tmp[1] : "";
        $res[ $tmp[0] ]{'cnfr_state'}    = ( defined $tmp[2] ) ? $tmp[2] : "";
        $res[ $tmp[0] ]{'last_start'}    = ( defined $tmp[3] ) ? $tmp[3] : "";
        $res[ $tmp[0] ]{'last_end'}      = ( defined $tmp[4] ) ? $tmp[4] : "";
        $res[ $tmp[0] ]{'next_start'}    = ( defined $tmp[5] ) ? $tmp[5] : "";
        $res[ $tmp[0] ]{'next_duration'} = ( defined $tmp[6] ) ? $tmp[6] : "";
        $res[ $tmp[0] ]{'auth_type'}     = ( defined $tmp[7] ) ? $tmp[7] : "";
        $res[ $tmp[0] ]{'auth_string'}   = ( defined $tmp[8] ) ? $tmp[8] : "";
        $res[ $tmp[0] ]{'auto_assemble'} = ( defined $tmp[9] ) ? $tmp[9] : "";
        $res[ $tmp[0] ]{'lost_control'}  = ( defined $tmp[10] ) ? $tmp[10] : "";
        $res[ $tmp[0] ]{'need_record'}   = ( defined $tmp[11] ) ? $tmp[11] : "";
        $res[ $tmp[0] ]{'number_b'}      = ( defined $tmp[12] ) ? $tmp[12] : "";
        $res[ $tmp[0] ]{'audio_lang'}    = ( defined $tmp[13] ) ? $tmp[13] : "";
    }

    $dbh->rollback();
    return @res;
}

=item @log_list = get_log($cnfr_if, $from, $to)
Функция получения логов.
$cnfr_if -- id конференции
$from -- с даты
$to - по дату

=cut

sub get_log {
    my $self     = shift;
    my $cnfr_if  = shift;
    my $from     = shift;
    my $to       = shift;
    my @log_list = ();

    $self->_connect();
    my $q =
"SELECT to_char(event_time, 'YYYY-MM-DD HH24:MI'), event_type, userfield FROM conflog "
      . "WHERE cnfr_id=? AND event_time > ? AND event_time < ? ORDER BY event_time DESC";
    my $sth = $dbh->prepare($q);
    $sth->execute( $cnfr_if, $from, $to );
    while ( my @tmp = $sth->fetchrow_array() ) {
        my %st = ();
        $st{'time'}  = $tmp[0];
        $st{'type'}  = $tmp[1];
        $st{'field'} = "";
        $st{'field'} = $tmp[2] if ( defined $tmp[2] );
        push @log_list, \%st;
    }

    $dbh->rollback();
    return @log_list;
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

    if ( $self->is_admin($user) ) {
        my @tmp = $dbh->selectrow_array("SELECT max(cnfr_id) FROM conferences");
        @ret = ( 1 .. $tmp[0] ) if ( defined $tmp[0] );
        $dbh->rollback();
        return @ret;
    }

    my $q =
        "SELECT ooc.cnfr_id FROM operators_of_conferences ooc, admins a WHERE "
      . "a.login=? AND a.admin_id=ooc.admin_id order by ooc.cnfr_id";
    my $sth = $dbh->prepare($q);
    $sth->execute($user);
    while ( my @tmp = $sth->fetchrow_array() ) {
        push @ret, $tmp[0] if ( defined $tmp[0] );
    }
    $dbh->rollback();
    return @ret;
}

=item $res = set_priority($login, $cnfr_id, $phone_id)

=cut

sub set_priority {
    my $self     = shift;
    my $login    = shift;
    my $cnfr_id  = shift;
    my $phone_id = shift;

    $self->_connect();
    my $q = "UPDATE users_on_conference SET priority_member=? WHERE cnfr_id=?";
    eval { $dbh->do( $q, undef, 0, $cnfr_id ); };

    if ($@) {
        $error =
"Ошибка снятия приоритета пользователя в конференции";
        $dbh->rollback();
        my ( $package, $filename, $line ) = caller;
        my $warn = $filename . " " . scalar( localtime(time) ) . " " . $@;
        warn $warn;
        return 0;
    }

    $dbh->commit();
    $self->write_to_log( $login, $q, 0, $cnfr_id );

    return 1 unless ( defined $phone_id and length $phone_id );

    $q =
"UPDATE users_on_conference SET priority_member=? WHERE cnfr_id=? AND phone_id=?";

    eval { $dbh->do( $q, undef, 1, $cnfr_id, $phone_id ); };

    if ($@) {
        $error =
"Ошибка установки приоритета пользователя в конференции";
        $dbh->rollback();
        my ( $package, $filename, $line ) = caller;
        my $warn = $filename . " " . scalar( localtime(time) ) . " " . $@;
        warn $warn;
        return 0;
    }

    $dbh->commit();
    $self->write_to_log( $login, $q, 1, $cnfr_id, $phone_id );

    return 1;
}

=item %user = get_user_by_phone($phone)

Пытается найти пользователя по номеру телефона

=cut

sub get_user_by_phone {
    my $self  = shift;
    my $phone = shift;
    my %u     = ();

    $self->_connect();
    my $q = "SELECT p.phone_id, p.user_id, u.full_name FROM phones p, users u "
      . "WHERE p.user_id=u.user_id AND p.phone_number=?";
    my @tmp = $dbh->selectrow_array( $q, undef, $phone );
    if (@tmp) {
        $u{'phone'}    = $phone;
        $u{'name'}     = $tmp[2];
        $u{'phone_id'} = $tmp[0];
        $u{'user_id'}  = $tmp[1];
    }
    $dbh->rollback();

    return %u;
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
    my @tmp = $dbh->selectrow_array( $q, undef, $user );
    $dbh->rollback();

    return $tmp[0] if ( defined $tmp[0] );
    return 0;
}

=item @oper = get_oper_list()

Возвращает массив операторов, определенных в базе. Каждый элемент массива
является ссылкой на hash. Элемент array'я содержит следующие элементы
aid -- id оператора в таблице операторов
uid -- id оператора в таблице пользователей
login -- логин оператора
admin -- 1/0 является ли оператор администратором
name -- полное имя оператора
cnfrs -- ссылка на hash, содержащий список конференций, для которых данный
         пользователь является оператором. Индексы hash'а -- id конференций,
				 элементы -- названия конференций

=cut

sub get_oper_list {
    my $self = shift;
    my @oper = ();

    $self->_connect();
    my $q =
"SELECT a.admin_id, a.user_id, a.login, a.is_admin, ooc.cnfr_id, u.full_name, c.cnfr_name "
      . "FROM admins as a left outer join operators_of_conferences as ooc on "
      . "(a.admin_id=ooc.admin_id) left outer join users as u on (a.user_id=u.user_id) "
      . "left outer join conferences as c on (ooc.cnfr_id=c.cnfr_id) ORDER BY a.admin_id";
    my $sth = $dbh->prepare($q);
    $sth->execute();
    my %ooc = ();
    my %row = ();
    my $aid = 0;

    while ( my @tmp = $sth->fetchrow_array() ) {
        if ( !(%row) and !(%ooc) ) {
            $aid          = $tmp[0];
            $row{'aid'}   = $tmp[0];
            $row{'uid'}   = $tmp[1];
            $row{'login'} = $tmp[2];
            $row{'admin'} = $tmp[3];
            $row{'name'}  = $tmp[5];
            if ( !( $tmp[3] ) and defined $tmp[4] ) {
                $ooc{ $tmp[4] } = $tmp[6];
            }
        }
        elsif ( $aid ne $tmp[0] ) {
            my %tooc = %ooc;
            $row{'cnfrs'} = \%tooc;
            my %trow = %row;
            push @oper, \%trow;
            %row          = ();
            %ooc          = ();
            $aid          = $tmp[0];
            $row{'aid'}   = $tmp[0];
            $row{'uid'}   = $tmp[1];
            $row{'login'} = $tmp[2];
            $row{'admin'} = $tmp[3];
            $row{'name'}  = $tmp[5];

            if ( !( $tmp[3] ) and defined $tmp[4] ) {
                $ooc{ $tmp[4] } = $tmp[6];
            }
        }
        elsif ( !( $tmp[3] ) and defined $tmp[4] ) {
            $ooc{ $tmp[4] } = $tmp[6];
        }
    }
    $row{'cnfrs'} = \%ooc;
    push @oper, \%row;
    $dbh->rollback();
    return @oper;
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
    my $self  = shift;
    my @users = ();

    my $q =
        "select u.user_id, u.full_name, u.department, u.email, o.org_name, "
      . "p.position_name, ph.phone_number, ph.phone_id, adm.login, adm.is_admin, "
      . "adm.passwd_hash FROM users as u left outer join organizations as o on "
      . "(u.org_id=o.org_id) left outer join positions as p on (u.position_id=p.position_id) "
      . "left outer join phones as ph on (u.user_id=ph.user_id) left outer join admins as adm "
      . "on(u.user_id=adm.user_id) ORDER BY u.full_name ASC";

#					"on(u.user_id=adm.user_id) ORDER BY p.position_order, u.user_id, ph.order_nmb";
    $self->_connect();
    my $sth = $dbh->prepare($q);
    $sth->execute();
    my $uid;
    my @phs    = ();
    my @phs_id = ();
    my %row    = ();
    my $cnt    = 0;
    while ( my @tmp = $sth->fetchrow_array() ) {

        if ( $cnt eq 0 ) {
            $cnt++;
            $uid = $tmp[0];
            $row{'id'} = $tmp[0];
            $row{'name'}         = ( defined $tmp[1] )  ? $tmp[1]  : "";
            $row{'organization'} = ( defined $tmp[4] )  ? $tmp[4]  : "";
            $row{'department'}   = ( defined $tmp[2] )  ? $tmp[2]  : "";
            $row{'position'}     = ( defined $tmp[5] )  ? $tmp[5]  : "";
            $row{'email'}        = ( defined $tmp[3] )  ? $tmp[3]  : "";
            $row{'login'}        = ( defined $tmp[8] )  ? $tmp[8]  : "";
            $row{'admin'}        = ( defined $tmp[9] )  ? $tmp[9]  : 0;
            $row{'passwd'}       = ( defined $tmp[10] ) ? $tmp[10] : "";
            if ( defined $tmp[6] ) {
                push @phs,    $tmp[6];
                push @phs_id, $tmp[7];
            }
        }
        elsif ( $uid ne $tmp[0] ) {
            my @tphs    = (@phs);
            my @tphs_id = (@phs_id);
            $row{'phones'}    = \@tphs;
            $row{'phones_id'} = \@tphs_id;
            my %trow = %row;
            push @users, \%trow;
            %row       = ();
            @phs       = ();
            @phs_id    = ();
            $row{'id'} = $tmp[0];
            $uid       = $row{'id'};
            $row{'name'}         = ( defined $tmp[1] )  ? $tmp[1]  : "";
            $row{'organization'} = ( defined $tmp[4] )  ? $tmp[4]  : "";
            $row{'department'}   = ( defined $tmp[2] )  ? $tmp[2]  : "";
            $row{'position'}     = ( defined $tmp[5] )  ? $tmp[5]  : "";
            $row{'email'}        = ( defined $tmp[3] )  ? $tmp[3]  : "";
            $row{'login'}        = ( defined $tmp[8] )  ? $tmp[8]  : "";
            $row{'admin'}        = ( defined $tmp[9] )  ? $tmp[9]  : 0;
            $row{'passwd'}       = ( defined $tmp[10] ) ? $tmp[10] : "";

            if ( defined $tmp[6] ) {
                push @phs,    $tmp[6];
                push @phs_id, $tmp[7];
            }
        }
        else {
            if ( defined $tmp[6] ) {
                push @phs,    $tmp[6];
                push @phs_id, $tmp[7];
            }
        }
    }
    $row{'phones'}    = \@phs;
    $row{'phones_id'} = \@phs_id;
    push @users, \%row;
    return @users;
}

=item add_participant_to_conference($cid, $phid, $login);

Добавляет участника конференции. Принимаемые параметры:
$cid -- id конференции
$phid -- id добавляемого телефона
$login -- логин добавляющего оператора (для логгинга действий)

Возвращает 1 в случае успешной работы и undef в случае ошибки.

=cut 

sub add_participant_to_conference {
    my $self  = shift;
    my $cid   = shift;
    my $phid  = shift;
    my $login = shift;

    return undef unless ( defined $login );

    $self->_connect();
    my $q =
      "SELECT max(participant_order) FROM users_on_conference WHERE cnfr_id=?";
    my @tmp = $dbh->selectrow_array( $q, undef, $cid );
    $dbh->rollback();
    my $po = 0;
    $po = $tmp[0] + 1 if ( defined $tmp[0] );

    $q =
      "INSERT INTO users_on_conference (cnfr_id, phone_id, participant_order) "
      . "VALUES (?, ?, ?)";
    my $sth = $dbh->prepare($q);
    eval { $sth->execute( $cid, $phid, $po ); };

    if ($@) {
        $error =
"Ошибка добавления пользователя в совещание. Обратитесь к администратору";
        $dbh->rollback();
        my ( $package, $filename, $line ) = caller;
        my $warn = $filename . " " . scalar( localtime(time) ) . " " . $@;
        warn $warn;
        return undef;
    }

    $dbh->commit();
    $self->write_to_log( $login, $q, $cid, $phid, $po );
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
    my $id   = shift;
    my %res  = ();

    my $q =
"SELECT u.user_id, u.full_name, u.department, u.email, u.org_id, o.org_name, "
      . "u.position_id, p.position_name, a.login, a.is_admin FROM users as u left outer join "
      . "organizations as o on (u.org_id=o.org_id) left outer join positions as p on "
      . "(u.position_id=p.position_id) left outer join admins as a on (u.user_id=a.user_id) "
      . "WHERE u.user_id=?";
    $self->_connect();
    my @tmp = $dbh->selectrow_array( $q, undef, $id );
    $dbh->rollback();
    return () unless ( defined $tmp[0] );

    $res{'user_id'}       = $tmp[0];
    $res{'full_name'}     = ( defined $tmp[1] ) ? $tmp[1] : "";
    $res{'department'}    = ( defined $tmp[2] ) ? $tmp[2] : "";
    $res{'email'}         = ( defined $tmp[3] ) ? $tmp[3] : "";
    $res{'org_id'}        = ( defined $tmp[4] ) ? $tmp[4] : "";
    $res{'org_name'}      = ( defined $tmp[5] ) ? $tmp[5] : "";
    $res{'position_id'}   = ( defined $tmp[6] ) ? $tmp[6] : "";
    $res{'position_name'} = ( defined $tmp[7] ) ? $tmp[7] : "";
    $res{'login'}         = ( defined $tmp[8] ) ? $tmp[8] : "";
    $res{'is_admin'}      = ( defined $tmp[9] ) ? $tmp[9] : "0";
    $q = "SELECT phone_number FROM phones WHERE user_id=? ORDER BY order_nmb";
    my $sth = $dbh->prepare($q);
    $sth->execute( $res{'user_id'} );
    my @phs = ();

    while ( @tmp = $sth->fetchrow_array() ) {
        push @phs, $tmp[0];
    }
    $res{'phones'} = \@phs;
    $dbh->rollback();
    return %res;
}

=item remove_oper($login, $user_id);

Снимает с пользователя права оператора. Принимаемые параметры:
$login -- логин администратора, снимающего права оператора с пользователя
$user_id -- id пользователя, с которого снимают права оператора

=cut

sub remove_oper {
    my $self    = shift;
    my $login   = shift;
    my $user_id = shift;

    return undef unless ( defined $user_id and $user_id =~ /^[\d]+$/ );

    unless ( $self->is_admin($login) ) {
        $error =
"Снимать права оператора имеет право только администратор";
        return undef;
    }

    my $q = "DELETE FROM admins WHERE user_id=?";
    $self->_connect();
    my $sth = $dbh->prepare($q);
    eval { $sth->execute($user_id); };

    if ($@) {
        $error =
"Ошибка удаления оператора. Обратитесь к администратору.";
        $dbh->rollback();
        my ( $package, $filename, $line ) = caller;
        my $warn = $filename . " " . scalar( localtime(time) ) . " " . $@;
        warn $warn;
        return ();
    }
    $dbh->commit();
    $self->write_to_log( $login, $q, $user_id );
    return 1;
}

=item @orgs = get_org_list();

=cut

sub get_org_list {
    my $self = shift;
    my @orgs = ();

    my $q = "SELECT org_id, org_name FROM organizations ORDER BY org_name";
    $self->_connect();
    my $sth = $dbh->prepare($q);
    $sth->execute();
    while ( my @tmp = $sth->fetchrow_array() ) {
        my %st = ();
        $st{'id'}   = $tmp[0];
        $st{'name'} = $tmp[1];
        push @orgs, \%st;
    }
    $dbh->rollback();

    return @orgs;
}

=item $res = del_org($login, $org_id)

Удаляет организацию из базы данных по id организации. В случае успешного
выполнения возвращает 1, в случае ошибки -- 0 и выставляет сообщение, которое
можно получить по get_error

=cut

sub del_org {
    my $self   = shift;
    my $login  = shift;
    my $org_id = shift;

    unless ( defined $org_id ) {
        $error =
"Не определена организация к удалению";
        return 0;
    }

    $self->_connect();
    my $q = "DELETE FROM organizations WHERE org_id=?";
    eval { $dbh->do( $q, undef, $org_id ); };

    if ($@) {
        $error =
"Ошибка удаления организации. Возможно существуют пользователи, принадлежащие этой организации";
        $dbh->rollback();
        my ( $package, $filename, $line ) = caller;
        my $warn = $filename . " " . scalar( localtime(time) ) . " " . $@;
        warn $warn;
        return 0;
    }
    $dbh->commit();
    $self->write_to_log( $login, $q, $org_id );
    return 1;
}

=item $res = del_pos($login, $pos_id)

Удаляет должность из базы данных по id должности. В случае успешного
выполнения возвращает 1, в случае ошибки -- 0 и выставляет сообщение, которое
можно получить по get_error

=cut

sub del_pos {
    my $self   = shift;
    my $login  = shift;
    my $pos_id = shift;

    unless ( defined $pos_id ) {
        $error =
          "Не определена должность к удалению";
        return 0;
    }

    $self->_connect();
    my $q = "DELETE FROM positions WHERE position_id=?";
    eval { $dbh->do( $q, undef, $pos_id ); };

    if ($@) {
        $error =
"Ошибка удаления должности. Возмсжно существует пользователь, занимающий эту должность.";
        $dbh->rollback();
        my ( $package, $filename, $line ) = caller;
        my $warn = $filename . " " . scalar( localtime(time) ) . " " . $@;
        warn $warn;
        return 0;
    }
    $dbh->commit();
    $self->write_to_log( $login, $q, $pos_id );
    return 1;
}

=item $res = del_user($login, $user_id)

Удаляет пользователя из базы данных по id пользователя. В случае успешного
выполнения возвращает 1, в случае ошибки -- 0 и выставляет сообщение, которое
можно получить по get_error

=cut

sub del_user {
    my $self    = shift;
    my $login   = shift;
    my $user_id = shift;

    unless ( defined $user_id ) {
        $error =
"Не определен пользователь к удалению";
        return 0;
    }

    $self->_connect();
    my $q = "DELETE FROM users WHERE user_id=?";
    eval { $dbh->do( $q, undef, $user_id ); };

    if ($@) {
        $error =
"Ошибка удаления пользователя. Возможно он участник одной из конференций или является администратором";
        $dbh->rollback();
        my ( $package, $filename, $line ) = caller;
        my $warn = $filename . " " . scalar( localtime(time) ) . " " . $@;
        warn $warn;
        return 0;
    }
    $dbh->commit();
    $self->write_to_log( $login, $q, $user_id );
    return 1;
}

=item @pos = get_pos_list()

Возвращает array of hashes. В array'е должности выстроены по порядку
возрастания. В hash'е индескы id, name, order

=cut

sub get_pos_list {
    my $self = shift;
    my @pos  = ();

    my $q =
"SELECT position_id, position_name, position_order FROM positions ORDER BY position_order";
    $self->_connect();
    my $sth = $dbh->prepare($q);
    $sth->execute();
    while ( my @tmp = $sth->fetchrow_array() ) {
        my %row = ();
        $row{'id'}    = $tmp[0];
        $row{'name'}  = $tmp[1];
        $row{'order'} = $tmp[2];
        push @pos, \%row;
    }
    $dbh->rollback();
    return @pos;
}

=item $res = stop_cnfr($login, $cid);
$login -- логин оператора, остановившего конференцию
$cid -- id конференции

=cut

sub stop_cnfr {
    my $self  = shift;
    my $login = shift;
    my $cid   = shift;

    $self->_connect();
    my $q = "UPDATE conferences SET cnfr_state='stop' WHERE cnfr_id=?";
    eval { $dbh->do( $q, undef, $cid ); };

    if ($@) {
        $error =
"Ошибка остановки конференции. Обратитесь к разработчику";
        $dbh->rollback();
        my ( $package, $filename, $line ) = caller;
        my $warn = $filename . " " . scalar( localtime(time) ) . " " . $@;
        warn $warn;
        return undef;
    }

    $dbh->commit();
    $self->write_to_log( $login, $q, $cid );
    return 1;
}

=item %cnfr = get_cnfr($cid)

Получение параметров конференции по id конференции. Принимаемые параметры:
$cid -- id конференции

Возвращает hash. Элементами которого являются
id -- id конференции
name -- название конференции
cnfr_state -- состояние конференции
next_start -- дата/время ближайшего запуска
next_duration -- продолжительность ближайшей конференции
auth_type -- тип аутентификации
auth_string -- PIN код при аутентификации по PIN
auto_assemble -- признак автоматического сбора участников
lost_control -- признак контроля потери участников
need_record -- признак необходимости записи конференции
number_b -- номер конференции
audio_lang -- аудио язык сообщений конференции
operators -- ссылка на hash, содержащий список операторов данной конференции.
             Индекс hash'а -- idmin_id оператора, элементы -- полное имя
						 оператора.
users -- ссылка на array, состоящий из ссылок на hash. Содержит всех
         пользователей конференции. Индексами каждого hash'а являются:
				 name -- имя пользователя
				 phone -- телефон пользователя, участвующий в конференции
				 phone_id -- id телефона, участвующего в конференции

=cut

sub get_cnfr {
    my $self = shift;
    my $id   = shift;
    my %cnfr = ();

    $self->_connect();
    my $q =
"SELECT cnfr_id, cnfr_name, cnfr_state, to_char(next_start, 'YYYY-MM-DD HH24:MI'), "
      . "next_duration, auth_type, auth_string, auto_assemble, lost_control, need_record, "
      . "number_b, audio_lang, voice_remind, email_remind, to_char(remind_ahead, "
      . "'DD HH24:MI:SS'), au_id FROM conferences "
      . "WHERE cnfr_id=?";
    my @tmp = $dbh->selectrow_array( $q, undef, $id );
    $cnfr{'id'}            = $tmp[0];
    $cnfr{'name'}          = ( defined $tmp[1] ) ? $tmp[1] : "";
    $cnfr{'cnfr_state'}    = ( defined $tmp[2] ) ? $tmp[2] : "";
    $cnfr{'next_start'}    = ( defined $tmp[3] ) ? $tmp[3] : "";
    $cnfr{'next_duration'} = ( defined $tmp[4] ) ? $tmp[4] : "";
    $cnfr{'auth_type'}     = ( defined $tmp[5] ) ? $tmp[5] : "";
    $cnfr{'auth_string'}   = ( defined $tmp[6] ) ? $tmp[6] : "";
    $cnfr{'auto_assemble'} = ( defined $tmp[7] ) ? $tmp[7] : "";
    $cnfr{'lost_control'}  = ( defined $tmp[8] ) ? $tmp[8] : "";
    $cnfr{'need_record'}   = ( defined $tmp[9] ) ? $tmp[9] : "";
    $cnfr{'number_b'}      = ( defined $tmp[10] ) ? $tmp[10] : "";
    $cnfr{'audio_lang'}    = ( defined $tmp[11] ) ? $tmp[11] : "";
    $cnfr{'ph_remind'}     = ( defined $tmp[12] ) ? $tmp[12] : "";
    $cnfr{'em_remind'}     = ( defined $tmp[13] ) ? $tmp[13] : "";
    $cnfr{'remind_time'}   = ( defined $tmp[14] ) ? $tmp[14] : "";
    $cnfr{'au_id'}         = ( defined $tmp[15] ) ? $tmp[15] : "";

    $q =
"SELECT u.full_name, a.admin_id FROM operators_of_conferences ooc, admins a, "
      . "users u WHERE ooc.cnfr_id=? AND ooc.admin_id=a.admin_id AND "
      . "a.user_id=u.user_id";
    my $sth = $dbh->prepare($q);
    $sth->execute($id);
    my %ops = ();
    while ( @tmp = $sth->fetchrow_array() ) {
        $ops{ $tmp[1] } = $tmp[0];
    }
    $cnfr{'operators'} = \%ops;

    $q =
"SELECT u.full_name, ph.phone_number, ph.phone_id FROM users_on_conference uoc, "
      . "phones ph, users u WHERE uoc.cnfr_id=? AND uoc.phone_id=ph.phone_id AND "
      . "ph.user_id=u.user_id ORDER BY uoc.participant_order";
    $sth = $dbh->prepare($q);
    $sth->execute($id);
    my @conf_users = ();
    while ( @tmp = $sth->fetchrow_array() ) {
        my %member = ();
        $member{'name'}     = $tmp[0];
        $member{'phone'}    = $tmp[1];
        $member{'phone_id'} = $tmp[2];
        push @conf_users, \%member;
    }

    $cnfr{'users'} = \@conf_users;

    $q =
"SELECT schedule_date, schedule_time, schedule_duration FROM schedule WHERE "
      . "cnfr_id=? ORDER BY sched_id";
    $sth = $dbh->prepare($q);
    $sth->execute($id);
    my @schedules = ();
    while ( @tmp = $sth->fetchrow_array() ) {
        my %sch_str = ();
        $sch_str{'day'}      = $tmp[0];
        $sch_str{'begin'}    = $tmp[1];
        $sch_str{'duration'} = $tmp[2];
        push @schedules, \%sch_str;
    }

    $cnfr{'schedules'} = \@schedules;
    return %cnfr;
}

=item %users = get_cnfr_participants($cid)
Получение списка участников конференции. Получаемые параметры:
$cid -- id конференции
Возвращает hash of hash.

keys %users даст список id участников конференции
$user{$u_id}{'id'} содержит id телефона, участвующего в конференции
$user{$u_id}{'number'} содержит номер телефона, участвующего в конференции
$user{$u_id}{'name'} содержит имя пользователя, участвующего в конференции

=cut

sub get_cnfr_participants {
    my $self    = shift;
    my $cid     = shift;
    my %u_to_ph = ();

    $self->_connect();
    my $q =
        "SELECT uoc.phone_id, ph.user_id, ph.phone_number, u.full_name FROM "
      . "users_on_conference uoc, phones ph, users u WHERE uoc.phone_id=ph.phone_id "
      . "AND ph.user_id=u.user_id AND uoc.cnfr_id=? ORDER BY participant_order";
    my $sth = $dbh->prepare($q);
    $sth->execute($cid);
    while ( my @tmp = $sth->fetchrow_array() ) {
        $u_to_ph{ $tmp[1] }{'id'}     = $tmp[0];
        $u_to_ph{ $tmp[1] }{'number'} = $tmp[2];
        $u_to_ph{ $tmp[1] }{'name'}   = $tmp[3];
    }
    $dbh->rollback();
    return %u_to_ph;
}

=item save_cnfr
Сохраняет параметры конференции.

=cut

sub save_cnfr {
    my $self       = shift;
    my $login      = shift;
    my $id         = shift;
    my $ce_name    = shift;
    my $next_start = shift;
    $next_start = undef unless ( length $next_start );
    my $next_duration = shift;
    $next_duration = undef unless ( length $next_duration );
    my $auth_type = shift;
    $auth_type = undef unless ( length $auth_type );
    my $auth_string = shift;
    $auth_string = undef unless ( length $auth_string );
    my $auto_assemble = shift;
    my $ph_remind     = shift;
    my $em_remind     = shift;
    my $remind_time   = shift;
    $remind_time = undef
      unless ( defined $remind_time and length $remind_time );
    my $lost_control = shift;
    my $need_record  = shift;
    my $audio_lang   = shift;
    $audio_lang = undef unless ( length $audio_lang );
    my $au_id = shift;
    $au_id = undef unless ( length $au_id );
    my $p = shift;
    my $s = shift;

    my @phs_id = ();
    @phs_id = ( @{$p} ) if ( defined $p );
    my @schedules = ();
    @schedules = ( @{$s} ) if ( defined $s );

    my $q =
"UPDATE conferences SET cnfr_name=?, next_start=to_timestamp(?, 'YYYY-MM-DD HH24:MI'), "
      . "next_duration=?, auth_type=?, auth_string=?, auto_assemble=?, lost_control=?, "
      . "need_record=?, audio_lang=?, voice_remind=?, email_remind=?, remind_ahead=?, "
      . "au_id=? WHERE cnfr_id=?";
    my @bind = (
        $ce_name,     $next_start,    $next_duration, $auth_type,
        $auth_string, $auto_assemble, $lost_control,  $need_record,
        $audio_lang,  $ph_remind,     $em_remind,     $remind_time,
        $au_id,       $id
    );

    $self->_connect();
    eval { $dbh->do( $q, undef, @bind ); };

    if ($@) {
        my ( $package, $filename, $line ) = caller;
        $error =
"Ошибка обновления данных конференции. Обратитесь к администратору";
        $dbh->rollback();
        my $warn = $filename . " " . scalar( localtime(time) ) . " " . $@;
        warn $warn;
        warn join( '" "', @bind );
        return undef;
    }

    $dbh->commit();
    $self->write_to_log( $login, $q, @bind );

    $q =
      "INSERT INTO users_on_conference (cnfr_id, phone_id, participant_order) "
      . "VALUES (?, ?, ?)";

    my $q1 = "INSERT INTO change_log (auth_user, db_query, db_params) VALUES "
      . "(?, ?, ?)";
    my $sth  = $dbh->prepare($q);
    my $sth1 = $dbh->prepare($q1);
    my $bind_str;
    eval {
        $dbh->do( "DELETE FROM users_on_conference WHERE cnfr_id=?",
            undef, $id );
        $sth1->execute( $login,
            "DELETE FROM users_on_conference WHERE cnfr_id=?", $id );
        my $cnt = 0;
        while ( my $ph_id = shift @phs_id ) {
            $sth->execute( $id, $ph_id, $cnt );
            $bind_str =
              join( ' ', map { $dbh->quote($_) } ( $id, $ph_id, $cnt ) );
            $sth1->execute( $login, $q, $bind_str );
            $cnt++;
        }
    };

    if ($@) {
        $error =
"Ошибка сохранения списка участников. Обратитесь к администратору";
        $dbh->rollback();
        my ( $package, $filename, $line ) = caller;
        my $warn = $filename . " " . scalar( localtime(time) ) . " " . $@;
        warn $warn;
        return undef;
    }

    $dbh->commit();

    eval { $dbh->do( "DELETE FROM schedule WHERE cnfr_id=?", undef, $id ); };

    if ($@) {
        $error =
"Ошибка удаления запланированных конференций. Обратитесь к разрабочику.";
        $dbh->rollback();
        my ( $package, $filename, $line ) = caller;
        my $warn = $filename . " " . scalar( localtime(time) ) . " " . $@;
        warn $warn;
        return undef;
    }
    $dbh->commit();
    $self->write_to_log( $login, "DELETE FROM schedule WHERE cnfr_id=?", $id );

    if (@schedules) {
        $q =
"INSERT INTO schedule (cnfr_id, schedule_date, schedule_time, schedule_duration) "
          . "VALUES (?, ?, ?, ?)";
        $sth = $dbh->prepare($q);
        eval {
            while ( my $i = shift @schedules )
            {
                $sth->execute( $id, $$i{'day'}, $$i{'begin'}, $$i{'duration'} );
                $bind_str = join( ' ',
                    map { $dbh->quote($_) }
                      ( $id, $$i{'day'}, $$i{'begin'}, $$i{'duration'} ) );
                $sth1->execute( $login, $q, $bind_str );
            }
        };

        if ($@) {
            $error =
"Ошибка сохранения планируемых конференций. Обратитесь к разрабочику.";
            $dbh->rollback();
            my ( $package, $filename, $line ) = caller;
            my $warn = $filename . " " . scalar( localtime(time) ) . " " . $@;
            warn $warn;
            return undef;
        }

        $dbh->commit();
    }

    return 1;
}

=item $res = load_audio($descr, $data_file)
$descr -- описание файла, которым он будет показываться в интерфейсах
$data_file -- содержимое аудиофайла
=cut

no strict;

sub load_audio {
    my $self      = shift;
    my $descr     = shift;
    my $file_data = shift;

    $self->_connect();
    my $q   = "INSERT INTO audio (description, audio_data) VALUES (?, ?)";
    my $sth = $dbh->prepare($q);
    my $rc  = $sth->bind_param( 1, $descr );
    $rc = $sth->bind_param(
        2,
        $self->escape_bytea($file_data),
        { pg_type => PG_BYTEA }
    );
    eval { $sth->execute(); };

    if ($@) {
        $error =
          "Ошибка сохранения звукового файла.";
        $dbh->rollback();
        my ( $package, $filename, $line ) = caller;
        my $warn = $filename . " " . scalar( localtime(time) ) . " " . $@;
        warn $warn;
        return undef;
    }
    $dbh->commit();
    return 1;
}

use strict;

=item $data = escape_bytea
Служебная программа для подготовки данных для загрузки в тип bytea

=cut 

sub escape_bytea {
    my $self         = shift;
    my ($instring)   = @_;
    my $returnstring = join(
        '',
        map {
            my $tmp = ord($_);
            ( $tmp >= 32 and $tmp <= 126 and $tmp != 92 )
              ? $_
              : sprintf( '\%03o', $tmp );
          } split( //, $instring )
    );
    return $returnstring;
}

=item %lst = get_audio_list()
Возвращает hash загруженных аудио файлов. Индексом hash'а является id файла в базе данных

=cut

sub get_audio_list {
    my $self = shift;
    my %list = ();

    $self->_connect();
    my $q   = "SELECT au_id, description FROM audio ORDER BY description";
    my $sth = $dbh->prepare($q);
    $sth->execute();
    while ( my @tmp = $sth->fetchrow_array() ) {
        $list{ $tmp[0] } = $tmp[1];
    }
    $dbh->rollback();
    return %list;
}

=item $res = remove_audio($au_id)
Удаляет выбранный аудио файл
=cut

sub remove_audio {
    my $self = shift;
    my $auid = shift;

    $self->_connect();
    my $q = "DELETE FROM audio WHERE au_id=?";
    eval { $dbh->do( $q, undef, $auid ); };

    if ($@) {
        $error = "Ошибка удаления звукового файла.";
        $dbh->rollback();
        my ( $package, $filename, $line ) = caller;
        my $warn = $filename . " " . scalar( localtime(time) ) . " " . $@;
        warn $warn;
        return undef;
    }
    $dbh->commit();
    return 1;
}

=item $res = set_number_b($login, $c_id, $number_b)
Устанавливает номер конференции. Принимает следующие параметры
$login -- логин администратора (оператор не может установить номер конференции)
$c_id -- id конференции
$number_b -- номер конференции. Если содержит пустую строку, то стирает номер
             конференции.

Возвращаемые значения:
1 -- в случае удачного выполнения
undef -- в случае ошибки

=cut

sub set_number_b {
    my $self     = shift;
    my $login    = shift;
    my $c_id     = shift;
    my $number_b = shift;
    $number_b = undef unless ( defined $number_b );

    unless ( $self->is_admin($login) ) {
        $error =
"Недостаточно прав для установки номера конференции";
        return undef;
    }

    my $q = "UPDATE conferences SET number_b=? WHERE cnfr_id=?";
    $self->_connect();
    eval { $dbh->do( $q, undef, $number_b, $c_id ); };

    if ($@) {
        $error =
          "Ошибка задания номера конференции";
        $dbh->rollback();
        my ( $package, $filename, $line ) = caller;
        my $warn = $filename . " " . scalar( localtime(time) ) . " " . $@;
        warn $warn;
        return undef;
    }

    $dbh->commit();
    $self->write_to_log( $login, $q, $number_b, $c_id );
    return 1;
}

=item @orgs = update_orgs($id, $name, $user)

Добавляет или обновляет название организации. Входные параметры:
$id - Если число, то обновляет название организации с таким id. Если строка new,
то добавляет новое название организации.
$name - название организации
$user - пользователь, от которого это делается

Возвращает обновленный array аналогично функции get_org_list()

=cut 

sub update_orgs {
    my $self = shift;
    my $id   = shift;
    my $name = shift;
    my $user = shift;

    my $q    = "";
    my @bind = ();
    return () unless ( defined $user );

    $self->_connect();

    if ( $id eq "new" ) {
        $q    = "INSERT INTO organizations (org_name) VALUES (?)";
        @bind = ($name);
    }
    else {
        $q = "UPDATE organizations SET org_name=? WHERE org_id=?";
        @bind = ( $name, $id );
    }

    eval {
        my $sth = $dbh->prepare($q);
        $sth->execute(@bind);
    };

    if ($@) {
        $error =
"Внутренняя ошибка базы. Обратитесь к администратору";
        $dbh->rollback();
        my ( $package, $filename, $line ) = caller;
        my $warn = $filename . " " . scalar( localtime(time) ) . " " . $@;
        warn $warn;
        return ();
    }

    $dbh->commit();
    $self->write_to_log( $user, $q, @bind );
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
    my $id   = shift;
    my $name = shift;
    my $user = shift;

    my $q    = "";
    my @bind = ();
    return () unless ( defined $user );

    $self->_connect();
    if ( $id eq "new" ) {
        $q = "SELECT max(position_order) FROM positions";
        my @tmp = $dbh->selectrow_array($q);
        $tmp[0] = 0 unless ( defined $tmp[0] );
        my $ord = $tmp[0] + 5;
        $q =
          "INSERT INTO positions (position_name, position_order) VALUES (?, ?)";
        @bind = ( $name, $ord );
    }
    else {
        $q = "UPDATE positions SET position_name=? WHERE position_id=?";
        @bind = ( $name, $id );
    }

    eval {
        my $sth = $dbh->prepare($q);
        $sth->execute(@bind);
    };

    if ($@) {
        $error =
"Внутренняя ошибка базы. Обратитесь к администратору";
        $dbh->rollback();
        my ( $package, $filename, $line ) = caller;
        my $warn = $filename . " " . scalar( localtime(time) ) . " " . $@;
        warn $warn;
        return ();
    }

    $dbh->commit();
    $self->write_to_log( $user, $q, @bind );
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
    my $self     = shift;
    my $loggedin = shift;
    my $h        = shift;
    my $p        = shift;
    my $a        = shift;

    my $q      = "";
    my @bind   = ();
    my %user   = %{$h};
    my @phones = ( @{$p} );
    my %admin  = %{$a};
    return () unless ( defined $loggedin );
    $self->_connect();
    my $sth;

    if ( $user{'id'} eq "new" ) {
        $q =
"INSERT INTO users (full_name, position_id, org_id, department, email) VALUES "
          . "(?, ?, ?, ?, ?)";
        @bind = (
            $user{'name'}, $user{'posid'}, $user{'orgid'},
            $user{'dept'}, $user{'email'}
        );
    }
    else {
        $q =
"UPDATE users SET full_name=?, position_id=?, org_id=?, department=?, email=? "
          . "WHERE user_id=?";
        @bind = (
            $user{'name'}, $user{'posid'}, $user{'orgid'},
            $user{'dept'}, $user{'email'}, $user{'id'}
        );
    }

    eval {
        $sth = $dbh->prepare($q);
        $sth->execute(@bind);
    };

    if ($@) {
        if ( $user{'id'} eq "new" ) {
            $error =
"Ошибка добавления пользователя. Обратитесь к администратору";
        }
        else {
            $error =
"Ошибка обновления пользователя. Обратитесь к администратору";
        }
        $dbh->rollback();
        my ( $package, $filename, $line ) = caller;
        my $warn = $filename . " " . scalar( localtime(time) ) . " " . $@;
        warn $warn;
        return ();
    }

    $dbh->commit();
    if ( $#phones < 0 ) {
        $self->write_to_log( $loggedin, $q, @bind );

# Если пользователь уже существовал, то у него нужно удалить все номера
# телефонов
        if ( $user{'id'} =~ /^[\d]+$/ ) {
            $q = "DELETE FROM phones WHERE user_id=?";
            eval { $dbh->do( $q, undef, $user{'id'} ); };
            if ($@) {
                $error =
"Один из удалямых телефонов используется в совещании. Сначала нужно проверить, что удаляемый телефон нигде не используется";
                $dbh->rollback();
                my ( $package, $filename, $line ) = caller;
                my $warn =
                  $filename . " " . scalar( localtime(time) ) . " " . $@;
                warn $warn;
                return ();
            }
            $dbh->commit;
            $self->write_to_log( $loggedin, $q, $user{'id'} );
        }
        return $self->get_user_list();
    }

    my $new_id = undef;
    if ( $user{'id'} eq "new" ) {
        $new_id = $dbh->last_insert_id( undef, undef, "users", undef );

# Мы вытянули id нововставленного юзера (или не вытянули), но мы можем уже
# записать строку логгирования запросов
        $self->write_to_log( $loggedin, $q, @bind );
        unless ( defined $new_id ) {
            my $qq =
                "SELECT user_id FROM users WHERE full_name=?, position_id=?, "
              . "org_id=?, department=?, email=?";
            my @tmp =
              $dbh->selectrow_array( $qq, undef, $user{'name'}, $user{'posid'},
                $user{'orgid'}, $user{'dept'}, $user{'email'} );
            $new_id = $tmp[0];
        }
        if ( $new_id =~ /^[\d]+$/ ) {

# Если пользователь новосозданный и у нас получилось определить его id, то нам
# нужно просто по порядку записать его номера телефонов
            $q = "INSERT INTO phones (user_id, phone_number, order_nmb) VALUES "
              . "(?, ?, ?)";
            $sth = $dbh->prepare($q);
            my $cnt = 0;
            while ( my $numb = shift @phones ) {
                eval { $sth->execute( $new_id, $numb, $cnt ); };
                if ($@) {
                    $error =
"Такой номер уже существует в базе у другого пользователя. Повторение одного номера у разных пользователей невозможно";
                    $dbh->rollback();
                    my ( $package, $filename, $line ) = caller;
                    my $warn =
                      $filename . " " . scalar( localtime(time) ) . " " . $@;
                    warn $warn;
                    return ();
                }
                $dbh->commit();
                $self->write_to_log( $loggedin, $q, $new_id, $numb, $cnt );
                $cnt++;
            }
        }
        else {
            $error =
"Ошибка создания пользователя. Обратитесь к администратору.";
            my $warn = "Can't find id of newly created user " . $user{'name'};
            warn $warn;
            return ();
        }
    }
    else {
        $self->write_to_log( $loggedin, $q, @bind );

# Пользователь уже существовал, нужно сверить телефоны и обновить список при
# этом у существующих телефонов должны сохранится их id. Сначала удаляем
# телефоны, которые есть в старом списке, но нету в новом. Потом проходим по
# новому списку, выставляя их в правильном порядке
        my %old_phones  = $self->get_user_phones( $user{'id'} );
        my @old_numbers = @{ $old_phones{'number'} };
        my @to_delete   = ();
        my @qst         = ();
        foreach my $n (@old_numbers) {
            next if ( grep( /^$n$/, @phones ) );
            push @to_delete, $n;
            push @qst,       '?';
        }
        if ( $#to_delete >= 0 ) {
            $q = "DELETE FROM phones WHERE user_id=? AND phone_number IN ("
              . join( ',', @qst ) . ")";
            eval { $dbh->do( $q, undef, $user{'id'}, @to_delete ); };
            if ($@) {
                $error =
"Один из удалямых телефонов используется в совещании. Сначала нужно проверить, что удаляемый телефон нигде не используется";
                $dbh->rollback();
                my ( $package, $filename, $line ) = caller;
                my $warn =
                  $filename . " " . scalar( localtime(time) ) . " " . $@;
                warn $warn;
                return ();
            }
            $dbh->commit();
            $self->write_to_log( $loggedin, $q, $user{'id'}, @to_delete );
        }
        my $cnt = 0;
        my @qr  = ();
        my @st  = ();
        $qr[0] =
          "UPDATE phones SET order_nmb=? WHERE user_id=? AND phone_number=?";
        $st[0] = $dbh->prepare( $qr[0] );
        $qr[1] = "INSERT INTO phones (order_nmb, user_id, phone_number) VALUES "
          . "(?, ?, ?)";
        $st[1] = $dbh->prepare( $qr[1] );

        while ( my $ph = shift @phones ) {
            my $sel_query;
            if ( grep( /^$ph$/, @old_numbers ) ) {
                $sel_query = 0;
            }
            else {
                $sel_query = 1;
            }
            eval { $st[$sel_query]->execute( $cnt, $user{'id'}, $ph ); };

            if ($@) {
                $error =
"Ошибка обновления телефонов. Обратитесь к администратору.";
                $dbh->rollback();
                my ( $package, $filename, $line ) = caller;
                my $warn =
                  $filename . " " . scalar( localtime(time) ) . " " . $@;
                warn $warn;
                return ();
            }
            $dbh->commit();
            $self->write_to_log( $loggedin, $qr[$sel_query], $cnt, $user{'id'},
                $ph );
            $cnt++;
        }
    }

    if ( $self->is_admin($loggedin) ) {
        if ( $admin{'oper'} ) {
            my $hashed = undef;
            if ( defined $admin{'passwd'} and length $admin{'passwd'} ) {
                my $cmd = "$HTPASSWD -bn some " . $admin{'passwd'};
                ( undef, $hashed ) = split( /:/, `$cmd` );
            }
            if ( $user{'id'} eq "new" ) {
                $q =
                  "INSERT INTO admins (user_id, login, passwd_hash, is_admin) "
                  . "VALUES (?, ?, ?, ?)";
                $sth = $dbh->prepare($q);
                eval {
                    $sth->execute( $new_id, $admin{'login'}, $hashed,
                        $admin{'admin'} );
                };

                if ($@) {
                    $error =
"Такое имя для входа уже используется. Выберите другое.";
                    $dbh->rollback();
                    my ( $package, $filename, $line ) = caller;
                    my $warn =
                      $filename . " " . scalar( localtime(time) ) . " " . $@;
                    warn $warn;
                    return ();
                }

                $dbh->commit();
                $self->write_to_log( $loggedin, $q, $new_id, $admin{'login'},
                    $hashed, $admin{'admin'} );
            }
            else {
                $q =
"SELECT admin_id, user_id, login FROM admins WHERE login=? or user_id=?";
                $sth = $dbh->prepare($q);
                $sth->execute( $admin{'login'}, $user{'id'} );
                my $upd = 0;
                while ( my @tmp = $sth->fetchrow_array() ) {
                    if ( $user{'id'} eq $tmp[1] ) {
                        $upd = $tmp[0];
                    }
                    else {
                        $error =
"Такое имя для входа уже используется. Выберите другое.";
                        return ();
                    }
                }
                if ($upd) {
                    if ( defined $hashed ) {
                        $q =
"UPDATE admins SET login=?, passwd_hash=?, is_admin=? WHERE "
                          . "admin_id=?";
                        @bind =
                          ( $admin{'login'}, $hashed, $admin{'admin'}, $upd );
                    }
                    else {
                        $q =
"UPDATE admins SET login=?, is_admin=? WHERE admin_id=?";
                        @bind = ( $admin{'login'}, $admin{'admin'}, $upd );
                    }
                }
                else {
                    if ( defined $hashed ) {
                        $q =
"INSERT INTO admins (user_id, login, passwd_hash, is_admin) "
                          . "VALUES (?, ?, ?, ?)";
                        @bind = (
                            $user{'id'}, $admin{'login'},
                            $hashed,     $admin{'admin'}
                        );
                    }
                    else {
                        $error =
"Нельзя создавать оператора без пароля. Задайте пароль.";
                        return ();
                    }
                }
                $sth = $dbh->prepare($q);
                eval { $sth->execute(@bind); };

                if ($@) {
                    $error =
"Ошибка сохранения прав администратора. Обратитесь к администратору.";
                    $dbh->rollback();
                    my ( $package, $filename, $line ) = caller;
                    my $warn =
                      $filename . " " . scalar( localtime(time) ) . " " . $@;
                    warn $warn;
                    return ();
                }
                $dbh->commit();
                $self->write_to_log( $loggedin, $q, @bind );
            }
        }
    }
    return $self->get_user_list();
}

=item %ops = get_conference_operators($cid)
Возвращает список операторов конференции. 
$cid -- id конференции

Возвращает hash of hashes
keys %ops возвращает список admin_id операторов
$ops{'admin_id'}{'name'} -- имя оператора конференции
$ops{'admin_id'}{'login'} -- логин оператора конференции

=cut

sub get_conference_operators {
    my $self = shift;
    my $cid  = shift;

    my %ops = ();
    $self->_connect();

    my $q =
"SELECT a.admin_id, u.full_name, a.login FROM operators_of_conferences as ooc left "
      . "outer join admins as a on (ooc.admin_id=a.admin_id) left outer join users as u on "
      . "(a.user_id=u.user_id) WHERE ooc.cnfr_id=?";
    my $sth = $dbh->prepare($q);
    $sth->execute($cid);
    while ( my @tmp = $sth->fetchrow_array() ) {
        $ops{ $tmp[0] }{'name'}  = $tmp[1];
        $ops{ $tmp[0] }{'login'} = $tmp[2];
    }
    $dbh->rollback();
    return %ops;
}

=item $res = set_cnfr_operators($login, $c_id, @adms)

Устанавливает операторов конференции. Получаемые параметры:
$login -- логин администратора, устанавливающего операторов для конференции
$c_id -- id конференции
@adms -- список admin_id операторов конференции

Возвращаемые значения:
1 -  в случае успеха
undef в случае ошибки

=cut

sub set_cnfr_operators {
    my $self  = shift;
    my $login = shift;
    my $c_id  = shift;
    my @adms  = @_;

    unless ( $self->is_admin($login) ) {
        $error =
"У вас нету прав устанавливать операторов конференции";
        return undef;
    }
    $self->_connect();
    eval {
        $dbh->do( "DELETE FROM operators_of_conferences WHERE cnfr_id=?",
            undef, $c_id );
    };

    if ($@) {
        $error =
"Ошибка базы данных, обратитесь к администратору.";
        $dbh->rollback();
        my ( $package, $filename, $line ) = caller;
        my $warn = $filename . " " . scalar( localtime(time) ) . " " . $@;
        warn $warn;
        return undef;
    }

    $dbh->commit();
    $self->write_to_log( $login,
        "DELETE FROM operators_of_conferences WHERE cnfr_id=?", $c_id );

    my $q =
      "INSERT INTO operators_of_conferences (admin_id, cnfr_id) VALUES (?, ?)";
    my $sth = $dbh->prepare($q);
    while ( my $i = shift @adms ) {
        eval { $sth->execute( $i, $c_id ); };

        if ($@) {
            $error =
"Ошибка задания оператора конференции, обратитесь к администратору.";
            $dbh->rollback();
            my ( $package, $filename, $line ) = caller;
            my $warn = $filename . " " . scalar( localtime(time) ) . " " . $@;
            warn $warn;
            return undef;
        }

        $dbh->commit();
        $self->write_to_log( $login, $q, $i, $c_id );
    }

    return 1;
}

=item @phones = get_user_phones($user_id)

$user_id -- id пользователя, телефоны которого интересуют

=cut

sub get_user_phones {
    my $self   = shift;
    my $uid    = shift;
    my %phones = ();

    return %phones unless ( defined $uid );

    my $q =
"SELECT phone_number, phone_id FROM phones WHERE user_id=? ORDER by order_nmb";
    $self->_connect();

    my $sth = $dbh->prepare($q);
    $sth->execute($uid);
    my @ph_ids = ();
    my @phs    = ();
    while ( my @tmp = $sth->fetchrow_array() ) {
        if ( defined $tmp[1] ) {
            push @phs,    $tmp[0];
            push @ph_ids, $tmp[1];
        }
    }

    $phones{'id'}     = \@ph_ids;
    $phones{'number'} = \@phs;

    $dbh->rollback();
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
    my $self  = shift;
    my $user  = shift;
    my $query = shift;
    my @bind  = @_;

    $self->_connect();

    my $bind_str = join( ' ', map { $dbh->quote($_) } @bind );
    my $q = "INSERT INTO change_log (auth_user, db_query, db_params) VALUES "
      . "(?, ?, ?)";
    my $sth = $dbh->prepare($q);
    eval { $sth->execute( $user, $query, $bind_str ); };

    if ($@) {
        $dbh->rollback();
        warn "Error writing log: $0 $user $query $bind_str";
        my ( $package, $filename, $line ) = caller;
        my $warn = $filename . " " . scalar( localtime(time) ) . " " . $@;
        return undef;
    }

    $dbh->commit();
    return 1;
}

=item $err = get_error()

Возвращает последнее сообщение об ошибке, если она произошла при выполнении
какой-либо функции.

=cut

sub get_error {
    my $self;
    return $error;
}

sub cnfr_update {
    my ( $self, $cnfr_id, $params ) = @_;

    $self->_connect();

    my @update_array;
    foreach my $param ( keys %$params ) {
        my $pair = sprintf( "%s=%s", $param, $params->{$param} );
        push @update_array, $pair;
    }

    my $update_string = join( ',', @update_array );

    my $query = sprintf( "update conferences set %s where cnfr_id=%d",
        $update_string, $cnfr_id );

    my $sth = $dbh->prepare($query);
    eval { $sth->execute(); };
    if ($@) {
        $dbh->rollback();
        my ( $package, $filename, $line ) = caller;
        my $warn = $filename . " " . scalar( localtime(time) ) . " " . $@;
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

=item $htpasswd = get_htpasswd()

Возвращает паеременную $HTPASSWD, которая устанавливается в начале и должна
содержать полный путь к апачевской утилите htpasswd

=cut

sub get_htpasswd {
    return $HTPASSWD;
}

sub cnfr_get {
    my $self = shift;
    my $conf = shift;

    unless ( defined($conf) ) {
        return undef;
    }

    my $query =
        "SELECT cnfr_id, cnfr_name, cnfr_state, to_char(last_start, "
      . "'YYYY-MM-DD HH24:MI') as last_start, to_char(last_end, 'YYYY-MM-DD HH24:MI') as last_end, "
      . "to_char(next_start, 'YYYY-MM-DD HH24:MI') as next_start, next_duration, "
      . "auth_type, auth_string, auto_assemble, "
      . "lost_control, need_record, number_b, audio_lang, au_id FROM "
      . "conferences where cnfr_id=$conf";
    $self->_connect();
    my $sth = $dbh->prepare($query);
    $sth->execute();

    my $res = $sth->fetchrow_hashref();
    $dbh->rollback();
    return $res;
}

=item B <is_operator(cnfr_id, callerid)> 

Возвращает 1 если callerid is operator , 0 иначе. 

=cut 

sub is_operator {
    my ( $self, $cnfr_id, $callerid ) = @_;

    my $q =
"select count(*) as c1 from phones p, admins a, operators_of_conferences ooc where phone_number=? and p.user_id=a.user_id and a.admin_id=ooc.admin_id and ooc.cnfr_id=?";
    $self->_connect();
    my $sth = $dbh->prepare($q);
    $sth->execute( $callerid, $cnfr_id );
    my $res = $sth->fetchrow_hashref();
    unless ( defined($res) ) {
        return undef;
    }
    $dbh->rollback();
    return $res->{'c1'};
}

=item B<get_cnfr_operator_by_callerid($callerid,$cnfr_id)

Возвращает имя логина-оператора конференции, по указанным параметрам

=cut 

sub get_cnfr_operator_by_callerid {
    my ( $self, $cnfr_id, $callerid ) = @_;

    my $q =
"select a.login as login from phones p, admins a, operators_of_conferences ooc where phone_number=? and p.user_id=a.user_id and a.admin_id=ooc.admin_id and ooc.cnfr_id=?";
    $self->_connect();
    my $sth = $dbh->prepare($q);
    $sth->execute( $callerid, $cnfr_id );
    my $res = $sth->fetchrow_hashref();
    $dbh->rollback();
    unless ( defined($res) ) {
        return undef;
    }
    return $res->{'login'};

}

=item B<conflog(cnfr_id,event_type,userfield) 

Добавляет в таблицу conflog событие описываемое тремя параметрами,
1. ИД конференции
2. Тип события: started, stopped, joined, leaved, record. 
3. Userfield: 	может быть пустым только при started, stopped, 
joined, leaved должен иметь callerid
record - имя файла 

=cut 

sub conflog {
    my ( $self, $cnfr_id, $event_type, $userfield ) = @_;

    unless ( defined($cnfr_id) ) {
        return undef;
    }
    unless ( defined($event_type) ) {
        return undef;
    }
    unless ( defined($userfield) ) {
        if (   ( $event_type eq 'joined' )
            or ( $event_type eq 'leaved' )
            or ( $event_type eq 'record' ) )
        {
            return undef;
        }
    }
    if (    ( $event_type ne 'started' )
        and ( $event_type ne 'stopped' )
        and ( $event_type ne 'joined' )
        and ( $event_type ne 'leaved' )
		and ( $event_type ne 'voice_reminder' )
		and ( $event_type ne 'email_reminder' ) 
        and ( $event_type ne 'record' ) )
    {
        return undef;
    }

    my $q =
"insert into conflog ( cnfr_id, event_type, userfield ) values ( ? , ? , ? );";
    $self->_connect();
    my $sth = $dbh->prepare($q);
    $sth->execute( $cnfr_id, $event_type, $userfield );
    $dbh->commit();

    return 1;
}

=item B<cnfr_find_4_start> 

Seaches non-active and next_start <= -300second to now() 

=cut 

sub cnfr_find_4_start {
    my $self = shift;

    my @res;

    my $query =
"SELECT * FROM conferences WHERE next_start between now() - '300 seconds'::interval and now() "
      . "and cnfr_state = 'inactive';";

    $self->_connect();
    my $sth = $dbh->prepare($query);
    $sth->execute();
    my $res = $sth->fetchall_hashref('cnfr_id');
    $dbh->rollback();
    return $res;
}

sub get_priority {
    my ( $self, $cnfr_id ) = @_;

    unless ( defined($cnfr_id) ) {
        return undef;
    }
    my $q =
"select priority_member, phone_number from users_on_conference u, phones p where u.phone_id=p.phone_id and u.cnfr_id=? and priority_member='t';";
    $self->_connect();
    my $sth = $dbh->prepare($q);
    $sth->execute($cnfr_id);
    my $res = $sth->fetchrow_hashref();
    unless ( defined($res) ) {
        return undef;
    }
    return $res->{'phone_number'};
}

=item B<cnfr_find_email_reminders> 

Ищет конференции, по которым СЕЙЧАС надо произвести оповещение по электронной почте

=cut 

sub cnfr_find_email_reminders {
    my $self = shift;

    my @res;

    my $query =

"SELECT * FROM conferences WHERE email_remind and next_start - remind_ahead between now() - interval '00:00:05' and now() + interval '00:00:05';";

    $self->_connect();
    my $sth = $dbh->prepare($query);
    $sth->execute();
    my $res = $sth->fetchall_hashref('cnfr_id');
    $dbh->rollback();
    return $res;
}

=item B<cnfr_find_email_reminders> 

Ищет конференции, по которым СЕЙЧАС надо произвести оповещение по электронной почте

=cut 

sub cnfr_find_voice_reminders {
    my $self = shift;

    my @res;

    my $query =
"SELECT * FROM conferences WHERE voice_remind and next_start - remind_ahead between now() - interval '00:00:05' and now() + interval '00:00:05';";

    $self->_connect();
    my $sth = $dbh->prepare($query);
    $sth->execute();
    my $res = $sth->fetchall_hashref('cnfr_id');
    $dbh->rollback();
    return $res;
}

=item B <cnfr_get_emails> 

Returns hashref with 'phone_number','full_name','email' items for each user for conference
where email is not empty

=cut 

sub cnfr_get_emails {
    my $self    = shift;
    my $cnfr_id = shift;

    unless ( defined($cnfr_id) ) {
        return undef;
    }

    my $query =
        "SELECT u.user_id, ph.phone_number, u.full_name,u.email "
      . "FROM users_on_conference uoc, phones ph, users u "
      . "WHERE u.email != '' and uoc.phone_id=ph.phone_id AND ph.user_id=u.user_id AND uoc.cnfr_id=? "
      . "ORDER BY participant_order; ";
    $self->_connect();
    my $sth = $dbh->prepare($query);
    $sth->execute($cnfr_id);
    my $res = $sth->fetchall_hashref('user_id');
    $dbh->rollback();
    return $res;
}


sub cnfr_getPhonesList {
    my ( $this, $cnfr_id ) = @_;
    my @dsts;
    my %members = $this->get_cnfr_participants($cnfr_id);
    foreach my $memberid ( keys %members ) {
        push @dsts, $members{$memberid}{'number'};
    }
    return @dsts;

}

sub get_audio { 
	my ($self, $au_id) = @_; 

	unless ( defined ( $au_id ) ) { 
		return undef; 
	} 
	$self->_connect(); 
	my $sth = $dbh->prepare("select * from audio where au_id=?"); 
	$sth->execute($au_id);
	my $res = $sth->fetchrow_hashref; 
	$dbh->rollback;
	return $res; 
}

1;
