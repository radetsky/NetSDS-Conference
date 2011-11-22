--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- Name: plpgsql; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: postgres
--

CREATE PROCEDURAL LANGUAGE plpgsql;


ALTER PROCEDURAL LANGUAGE plpgsql OWNER TO postgres;

SET search_path = public, pg_catalog;

--
-- Name: upd_tstamp(); Type: FUNCTION; Schema: public; Owner: astconf
--

CREATE FUNCTION upd_tstamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        NEW.change_date := current_timestamp;
        RETURN NEW;
    END;
$$;


ALTER FUNCTION public.upd_tstamp() OWNER TO astconf;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: admins; Type: TABLE; Schema: public; Owner: astconf; Tablespace: 
--

CREATE TABLE admins (
    admin_id integer NOT NULL,
    user_id integer NOT NULL,
    login character varying(30) NOT NULL,
    passwd_hash character varying(30) NOT NULL,
    is_admin boolean
);


ALTER TABLE public.admins OWNER TO astconf;

--
-- Name: admins_admin_id_seq; Type: SEQUENCE; Schema: public; Owner: astconf
--

CREATE SEQUENCE admins_admin_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.admins_admin_id_seq OWNER TO astconf;

--
-- Name: admins_admin_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: astconf
--

ALTER SEQUENCE admins_admin_id_seq OWNED BY admins.admin_id;


--
-- Name: audio; Type: TABLE; Schema: public; Owner: astconf; Tablespace: 
--

CREATE TABLE audio (
    au_id integer NOT NULL,
    description character varying(200),
    audio_data bytea,
    create_date timestamp without time zone DEFAULT now() NOT NULL,
    oper_id integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.audio OWNER TO astconf;

--
-- Name: audio_au_id_seq; Type: SEQUENCE; Schema: public; Owner: astconf
--

CREATE SEQUENCE audio_au_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.audio_au_id_seq OWNER TO astconf;

--
-- Name: audio_au_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: astconf
--

ALTER SEQUENCE audio_au_id_seq OWNED BY audio.au_id;


--
-- Name: change_log; Type: TABLE; Schema: public; Owner: astconf; Tablespace: 
--

CREATE TABLE change_log (
    change_id integer NOT NULL,
    auth_user character varying(100) NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    db_query text,
    db_params text
);


ALTER TABLE public.change_log OWNER TO astconf;

--
-- Name: change_log_change_id_seq; Type: SEQUENCE; Schema: public; Owner: astconf
--

CREATE SEQUENCE change_log_change_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.change_log_change_id_seq OWNER TO astconf;

--
-- Name: change_log_change_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: astconf
--

ALTER SEQUENCE change_log_change_id_seq OWNED BY change_log.change_id;


--
-- Name: conferences; Type: TABLE; Schema: public; Owner: astconf; Tablespace: 
--

CREATE TABLE conferences (
    cnfr_id integer NOT NULL,
    cnfr_name character varying(256) NOT NULL,
    cnfr_state character varying(30) NOT NULL,
    last_start timestamp without time zone,
    last_end timestamp without time zone,
    next_start timestamp without time zone,
    next_duration interval,
    auth_type character varying(30),
    auth_string character varying(30),
    auto_assemble boolean,
    lost_control boolean,
    need_record boolean,
    number_b character varying(20),
    audio_lang character varying(2),
    change_date timestamp without time zone DEFAULT now() NOT NULL,
    voice_remind boolean,
    email_remind boolean,
    remind_ahead interval,
    au_id integer
);


ALTER TABLE public.conferences OWNER TO astconf;

--
-- Name: conferences_cnfr_id_seq; Type: SEQUENCE; Schema: public; Owner: astconf
--

CREATE SEQUENCE conferences_cnfr_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.conferences_cnfr_id_seq OWNER TO astconf;

--
-- Name: conferences_cnfr_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: astconf
--

ALTER SEQUENCE conferences_cnfr_id_seq OWNED BY conferences.cnfr_id;


--
-- Name: config; Type: TABLE; Schema: public; Owner: astconf; Tablespace: 
--

CREATE TABLE config (
    key character varying(32) NOT NULL,
    value character varying(128) NOT NULL
);


ALTER TABLE public.config OWNER TO astconf;

--
-- Name: conflog; Type: TABLE; Schema: public; Owner: astconf; Tablespace: 
--

CREATE TABLE conflog (
    log_id bigint NOT NULL,
    cnfr_id integer NOT NULL,
    event_time timestamp without time zone DEFAULT now(),
    event_type character varying(16) DEFAULT NULL::character varying,
    userfield character varying(32) DEFAULT NULL::character varying
);


ALTER TABLE public.conflog OWNER TO astconf;

--
-- Name: conflog_log_id_seq; Type: SEQUENCE; Schema: public; Owner: astconf
--

CREATE SEQUENCE conflog_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.conflog_log_id_seq OWNER TO astconf;

--
-- Name: conflog_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: astconf
--

ALTER SEQUENCE conflog_log_id_seq OWNED BY conflog.log_id;


--
-- Name: operators_of_conferences; Type: TABLE; Schema: public; Owner: astconf; Tablespace: 
--

CREATE TABLE operators_of_conferences (
    admin_id integer NOT NULL,
    cnfr_id integer NOT NULL
);


ALTER TABLE public.operators_of_conferences OWNER TO astconf;

--
-- Name: organizations; Type: TABLE; Schema: public; Owner: astconf; Tablespace: 
--

CREATE TABLE organizations (
    org_id integer NOT NULL,
    org_name character varying(200) NOT NULL,
    oper_id integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.organizations OWNER TO astconf;

--
-- Name: organizations_org_id_seq; Type: SEQUENCE; Schema: public; Owner: astconf
--

CREATE SEQUENCE organizations_org_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.organizations_org_id_seq OWNER TO astconf;

--
-- Name: organizations_org_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: astconf
--

ALTER SEQUENCE organizations_org_id_seq OWNED BY organizations.org_id;


--
-- Name: phones; Type: TABLE; Schema: public; Owner: astconf; Tablespace: 
--

CREATE TABLE phones (
    phone_id integer NOT NULL,
    user_id integer NOT NULL,
    phone_number character varying(30) NOT NULL,
    order_nmb integer NOT NULL,
    line_state character varying(20),
    change_date timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.phones OWNER TO astconf;

--
-- Name: phones_phone_id_seq; Type: SEQUENCE; Schema: public; Owner: astconf
--

CREATE SEQUENCE phones_phone_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.phones_phone_id_seq OWNER TO astconf;

--
-- Name: phones_phone_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: astconf
--

ALTER SEQUENCE phones_phone_id_seq OWNED BY phones.phone_id;


--
-- Name: positions; Type: TABLE; Schema: public; Owner: astconf; Tablespace: 
--

CREATE TABLE positions (
    position_id integer NOT NULL,
    position_name character varying(200) NOT NULL,
    position_order integer NOT NULL,
    oper_id integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.positions OWNER TO astconf;

--
-- Name: positions_position_id_seq; Type: SEQUENCE; Schema: public; Owner: astconf
--

CREATE SEQUENCE positions_position_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.positions_position_id_seq OWNER TO astconf;

--
-- Name: positions_position_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: astconf
--

ALTER SEQUENCE positions_position_id_seq OWNED BY positions.position_id;


--
-- Name: schedule; Type: TABLE; Schema: public; Owner: astconf; Tablespace: 
--

CREATE TABLE schedule (
    sched_id integer NOT NULL,
    cnfr_id integer,
    schedule_date character varying(10),
    schedule_time time without time zone,
    schedule_duration interval,
    change_date timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.schedule OWNER TO astconf;

--
-- Name: schedule_sched_id_seq; Type: SEQUENCE; Schema: public; Owner: astconf
--

CREATE SEQUENCE schedule_sched_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.schedule_sched_id_seq OWNER TO astconf;

--
-- Name: schedule_sched_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: astconf
--

ALTER SEQUENCE schedule_sched_id_seq OWNED BY schedule.sched_id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: astconf; Tablespace: 
--

CREATE TABLE users (
    user_id integer NOT NULL,
    full_name character varying(500) NOT NULL,
    position_id integer,
    org_id integer,
    department character varying(200),
    email character varying(300),
    change_date timestamp without time zone DEFAULT now() NOT NULL,
    oper_id integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.users OWNER TO astconf;

--
-- Name: users_on_conference; Type: TABLE; Schema: public; Owner: astconf; Tablespace: 
--

CREATE TABLE users_on_conference (
    record_id integer NOT NULL,
    cnfr_id integer NOT NULL,
    phone_id integer NOT NULL,
    participant_order integer NOT NULL,
    priority_member boolean,
    change_date timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.users_on_conference OWNER TO astconf;

--
-- Name: users_on_conference_record_id_seq; Type: SEQUENCE; Schema: public; Owner: astconf
--

CREATE SEQUENCE users_on_conference_record_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.users_on_conference_record_id_seq OWNER TO astconf;

--
-- Name: users_on_conference_record_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: astconf
--

ALTER SEQUENCE users_on_conference_record_id_seq OWNED BY users_on_conference.record_id;


--
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: public; Owner: astconf
--

CREATE SEQUENCE users_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.users_user_id_seq OWNER TO astconf;

--
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: astconf
--

ALTER SEQUENCE users_user_id_seq OWNED BY users.user_id;


--
-- Name: admin_id; Type: DEFAULT; Schema: public; Owner: astconf
--

ALTER TABLE admins ALTER COLUMN admin_id SET DEFAULT nextval('admins_admin_id_seq'::regclass);


--
-- Name: au_id; Type: DEFAULT; Schema: public; Owner: astconf
--

ALTER TABLE audio ALTER COLUMN au_id SET DEFAULT nextval('audio_au_id_seq'::regclass);


--
-- Name: change_id; Type: DEFAULT; Schema: public; Owner: astconf
--

ALTER TABLE change_log ALTER COLUMN change_id SET DEFAULT nextval('change_log_change_id_seq'::regclass);


--
-- Name: cnfr_id; Type: DEFAULT; Schema: public; Owner: astconf
--

ALTER TABLE conferences ALTER COLUMN cnfr_id SET DEFAULT nextval('conferences_cnfr_id_seq'::regclass);


--
-- Name: log_id; Type: DEFAULT; Schema: public; Owner: astconf
--

ALTER TABLE conflog ALTER COLUMN log_id SET DEFAULT nextval('conflog_log_id_seq'::regclass);


--
-- Name: org_id; Type: DEFAULT; Schema: public; Owner: astconf
--

ALTER TABLE organizations ALTER COLUMN org_id SET DEFAULT nextval('organizations_org_id_seq'::regclass);


--
-- Name: phone_id; Type: DEFAULT; Schema: public; Owner: astconf
--

ALTER TABLE phones ALTER COLUMN phone_id SET DEFAULT nextval('phones_phone_id_seq'::regclass);


--
-- Name: position_id; Type: DEFAULT; Schema: public; Owner: astconf
--

ALTER TABLE positions ALTER COLUMN position_id SET DEFAULT nextval('positions_position_id_seq'::regclass);


--
-- Name: sched_id; Type: DEFAULT; Schema: public; Owner: astconf
--

ALTER TABLE schedule ALTER COLUMN sched_id SET DEFAULT nextval('schedule_sched_id_seq'::regclass);


--
-- Name: user_id; Type: DEFAULT; Schema: public; Owner: astconf
--

ALTER TABLE users ALTER COLUMN user_id SET DEFAULT nextval('users_user_id_seq'::regclass);


--
-- Name: record_id; Type: DEFAULT; Schema: public; Owner: astconf
--

ALTER TABLE users_on_conference ALTER COLUMN record_id SET DEFAULT nextval('users_on_conference_record_id_seq'::regclass);


--
-- Name: admins_login_key; Type: CONSTRAINT; Schema: public; Owner: astconf; Tablespace: 
--

ALTER TABLE ONLY admins
    ADD CONSTRAINT admins_login_key UNIQUE (login);


--
-- Name: admins_pkey; Type: CONSTRAINT; Schema: public; Owner: astconf; Tablespace: 
--

ALTER TABLE ONLY admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (admin_id);


--
-- Name: audio_pkey; Type: CONSTRAINT; Schema: public; Owner: astconf; Tablespace: 
--

ALTER TABLE ONLY audio
    ADD CONSTRAINT audio_pkey PRIMARY KEY (au_id);


--
-- Name: change_log_pkey; Type: CONSTRAINT; Schema: public; Owner: astconf; Tablespace: 
--

ALTER TABLE ONLY change_log
    ADD CONSTRAINT change_log_pkey PRIMARY KEY (change_id);


--
-- Name: conferences_pkey; Type: CONSTRAINT; Schema: public; Owner: astconf; Tablespace: 
--

ALTER TABLE ONLY conferences
    ADD CONSTRAINT conferences_pkey PRIMARY KEY (cnfr_id);


--
-- Name: config_pkey; Type: CONSTRAINT; Schema: public; Owner: astconf; Tablespace: 
--

ALTER TABLE ONLY config
    ADD CONSTRAINT config_pkey PRIMARY KEY (key);


--
-- Name: conflog_pkey; Type: CONSTRAINT; Schema: public; Owner: astconf; Tablespace: 
--

ALTER TABLE ONLY conflog
    ADD CONSTRAINT conflog_pkey PRIMARY KEY (log_id);


--
-- Name: operators_of_conferences_pkey; Type: CONSTRAINT; Schema: public; Owner: astconf; Tablespace: 
--

ALTER TABLE ONLY operators_of_conferences
    ADD CONSTRAINT operators_of_conferences_pkey PRIMARY KEY (admin_id, cnfr_id);


--
-- Name: organizations_pkey; Type: CONSTRAINT; Schema: public; Owner: astconf; Tablespace: 
--

ALTER TABLE ONLY organizations
    ADD CONSTRAINT organizations_pkey PRIMARY KEY (org_id);


--
-- Name: phones_phone_number_key; Type: CONSTRAINT; Schema: public; Owner: astconf; Tablespace: 
--

ALTER TABLE ONLY phones
    ADD CONSTRAINT phones_phone_number_key UNIQUE (phone_number);


--
-- Name: phones_pkey; Type: CONSTRAINT; Schema: public; Owner: astconf; Tablespace: 
--

ALTER TABLE ONLY phones
    ADD CONSTRAINT phones_pkey PRIMARY KEY (phone_id);


--
-- Name: positions_pkey; Type: CONSTRAINT; Schema: public; Owner: astconf; Tablespace: 
--

ALTER TABLE ONLY positions
    ADD CONSTRAINT positions_pkey PRIMARY KEY (position_id);


--
-- Name: schedule_pkey; Type: CONSTRAINT; Schema: public; Owner: astconf; Tablespace: 
--

ALTER TABLE ONLY schedule
    ADD CONSTRAINT schedule_pkey PRIMARY KEY (sched_id);


--
-- Name: users_on_conference_pkey; Type: CONSTRAINT; Schema: public; Owner: astconf; Tablespace: 
--

ALTER TABLE ONLY users_on_conference
    ADD CONSTRAINT users_on_conference_pkey PRIMARY KEY (record_id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: astconf; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: only_50; Type: RULE; Schema: public; Owner: astconf
--

CREATE RULE only_50 AS ON INSERT TO conferences DO NOTHING;


--
-- Name: cnfr_stamp; Type: TRIGGER; Schema: public; Owner: astconf
--

CREATE TRIGGER cnfr_stamp
    BEFORE UPDATE ON conferences
    FOR EACH ROW
    EXECUTE PROCEDURE upd_tstamp();


--
-- Name: phones_stamp; Type: TRIGGER; Schema: public; Owner: astconf
--

CREATE TRIGGER phones_stamp
    BEFORE UPDATE ON phones
    FOR EACH ROW
    EXECUTE PROCEDURE upd_tstamp();


--
-- Name: schedule_stamp; Type: TRIGGER; Schema: public; Owner: astconf
--

CREATE TRIGGER schedule_stamp
    BEFORE UPDATE ON schedule
    FOR EACH ROW
    EXECUTE PROCEDURE upd_tstamp();


--
-- Name: uoc_stamp; Type: TRIGGER; Schema: public; Owner: astconf
--

CREATE TRIGGER uoc_stamp
    BEFORE UPDATE ON users_on_conference
    FOR EACH ROW
    EXECUTE PROCEDURE upd_tstamp();


--
-- Name: users_stamp; Type: TRIGGER; Schema: public; Owner: astconf
--

CREATE TRIGGER users_stamp
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE PROCEDURE upd_tstamp();


--
-- Name: admins_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: astconf
--

ALTER TABLE ONLY admins
    ADD CONSTRAINT admins_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: conferences_au_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: astconf
--

ALTER TABLE ONLY conferences
    ADD CONSTRAINT conferences_au_id_fkey FOREIGN KEY (au_id) REFERENCES audio(au_id) ON DELETE RESTRICT;


--
-- Name: operators_of_conferences_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: astconf
--

ALTER TABLE ONLY operators_of_conferences
    ADD CONSTRAINT operators_of_conferences_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES admins(admin_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: operators_of_conferences_cnfr_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: astconf
--

ALTER TABLE ONLY operators_of_conferences
    ADD CONSTRAINT operators_of_conferences_cnfr_id_fkey FOREIGN KEY (cnfr_id) REFERENCES conferences(cnfr_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: phones_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: astconf
--

ALTER TABLE ONLY phones
    ADD CONSTRAINT phones_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- Name: schedule_cnfr_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: astconf
--

ALTER TABLE ONLY schedule
    ADD CONSTRAINT schedule_cnfr_id_fkey FOREIGN KEY (cnfr_id) REFERENCES conferences(cnfr_id) ON DELETE CASCADE;


--
-- Name: users_on_conference_cnfr_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: astconf
--

ALTER TABLE ONLY users_on_conference
    ADD CONSTRAINT users_on_conference_cnfr_id_fkey FOREIGN KEY (cnfr_id) REFERENCES conferences(cnfr_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: users_on_conference_phone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: astconf
--

ALTER TABLE ONLY users_on_conference
    ADD CONSTRAINT users_on_conference_phone_id_fkey FOREIGN KEY (phone_id) REFERENCES phones(phone_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: users_org_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: astconf
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_org_id_fkey FOREIGN KEY (org_id) REFERENCES organizations(org_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: users_position_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: astconf
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_position_id_fkey FOREIGN KEY (position_id) REFERENCES positions(position_id) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

