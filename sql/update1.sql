create table config ( 
	key varchar(32) default '' not null, 
	value varchar(128) default '' not null 
); 

insert into config (key, value) values ('addressbook','operator'); 

alter table audio add oper_id integer DEFAULT 0 NOT NULL;

alter table organizations add oper_id integer default 1 not null; 

alter table positions add oper_id integer default 0 not null; 

alter table users add oper_id integer default 1 not null; 


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


