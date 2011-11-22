create table conflog ( 
 log_id bigserial primary key, 
 cnfr_id integer not null, 
 event_time timestamp without time zone default now(), 
 event_type varchar (16) default null,
 userfield  varchar (32) default null
); 

-- event type : started, stopped, joined, leaved, record
-- userfield: callerid (joined, leaved ), 
-- userfield: 20101028-1323-49.wav ( record ) 

