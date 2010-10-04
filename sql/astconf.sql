CREATE FUNCTION upd_tstamp() RETURNS trigger AS $upd_tstamp$
    BEGIN
        NEW.change_date := current_timestamp;
        RETURN NEW;
    END;
$upd_tstamp$ LANGUAGE plpgsql;

CREATE TABLE Positions(
 position_id serial primary key,
 position_name varchar(200) NOT NULL,
 position_order integer NOT NULL
);

CREATE TABLE Organizations(
 org_id serial primary key,
 org_name varchar(200) NOT NULL
);

CREATE TABLE Conferences(
 cnfr_id serial primary key,
 cnfr_name varchar(256) NOT NULL,
 cnfr_state varchar(30) NOT NULL,
 last_start timestamp,
 last_end timestamp,
 next_start timestamp,
 next_duration interval,
 shedule_date varchar(30),
 shedule_time time,
 auth_type varchar(30),
 auth_string varchar(30),
 lost_control boolean,
 need_record boolean,
 number_B varchar(20),
 audio_lang varchar(2),
 change_date timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER Cnfr_stamp BEFORE UPDATE ON Conferences
    FOR EACH ROW EXECUTE PROCEDURE upd_tstamp();

CREATE TABLE Users(
 user_id serial primary key,
 full_name varchar(500) NOT NULL,
 position_id integer REFERENCES Positions(position_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
 org_id integer REFERENCES Organizations(org_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
 department varchar(200),
 email varchar(300),
 change_date timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER Users_stamp BEFORE UPDATE ON Users
    FOR EACH ROW EXECUTE PROCEDURE upd_tstamp();

CREATE TABLE Admins(
 admin_id serial primary key,
 user_id integer NOT NULL REFERENCES Users(user_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
 login varchar(30) NOT NULL UNIQUE,
 passwd_hash varchar(30) NOT NULL,
 is_admin boolean
);

CREATE TABLE Operators_of_Conferences(
 admin_id integer NOT NULL REFERENCES Admins(admin_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
 cnfr_id integer NOT NULL REFERENCES Conferences(cnfr_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
 PRIMARY KEY (admin_id, cnfr_id)
);

CREATE TABLE Phones(
 phone_id serial primary key,
 user_id integer NOT NULL REFERENCES Users(user_id) ON UPDATE RESTRICT ON DELETE CASCADE,
 phone_number varchar(30) NOT NULL UNIQUE,
 order_nmb integer NOT NULL,
 change_date timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER Phones_stamp BEFORE UPDATE ON Phones
    FOR EACH ROW EXECUTE PROCEDURE upd_tstamp();

CREATE TABLE Users_on_Conference(
 record_id serial primary key,
 cnfr_id integer NOT NULL REFERENCES Conferences(cnfr_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
 phone_id integer NOT NULL REFERENCES Phones(phone_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
 participant_order integer NOT NULL,
 line_state varchar(30) NOT NULL,
 priority_member boolean,
 change_date timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER UoC_stamp BEFORE UPDATE ON Users_on_Conference
    FOR EACH ROW EXECUTE PROCEDURE upd_tstamp();

CREATE TABLE Change_log(
	change_id serial primary key,
	auth_user varchar(100) NOT NULL,
	created timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	db_query text,
	db_params text
);

INSERT INTO USERS (full_name) VALUES ('Администратор конференции');
INSERT INTO Admins (user_id, login, passwd_hash, is_admin) 
	SELECT user_id, 'root', 'r8oqyKsqD43cU', 'true' FROM Users WHERE full_name='Администратор конференции';

INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 1','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 2','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 3','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 4','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 5','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 6','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 7','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 8','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 9','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 10','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 11','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 12','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 13','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 14','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 15','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 16','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 17','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 18','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 19','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 20','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 21','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 22','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 23','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 24','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 25','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 26','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 27','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 28','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 29','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 30','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 31','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 32','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 33','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 34','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 35','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 36','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 37','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 38','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 39','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 40','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 41','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 42','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 43','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 44','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 45','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 46','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 47','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 48','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 49','inactive');
INSERT INTO Conferences (cnfr_name, cnfr_state) VALUES ('Конференция 50','inactive');

CREATE OR REPLACE RULE only_50 AS ON INSERT TO Conferences DO NOTHING;

commit;

