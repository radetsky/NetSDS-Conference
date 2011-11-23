HOMEDIR=$(DESTDIR)

all: install

install:
	mkdir -p $(HOMEDIR)/opt/NetSDS/{bin,lib}
	install bin/NetSDS-Conference.pl $(HOMEDIR)/opt/NetSDS/bin/
	install lib/ConferenceDB.pm $(HOMEDIR)/opt/NetSDS/lib/
	install lib/ConferenceAuth.pm $(HOMEDIR)/opt/NetSDS/lib/
	install lib/ConferenceAuth.pm $(HOMEDIR)/opt/NetSDS/lib/ 
	cp -a lib/NetSDS $(HOMEDIR)/opt/NetSDS/lib
	mkdir -p $(HOMEDIR)/var/run/NetSDS/
	mkdir -p $(HOMEDIR)/etc/netstyle 
	install etc/netstyle/conference.conf $(HOMEDIR)/etc/netstyle 

config: 
	mkdir -p $(HOMEDIR)/etc/netstyle 
	install etc/netstyle/conference.conf $(HOMEDIR)/etc/netstyle 

gui:
	
	install gui/* -d -t $(HOMEDIR)/var/www/html
	mkdir -p $(HOMEDIR)/var/www/html/css/images/kievsvt/
	install gui/css/* -t $(HOMEDIR)/var/www/html/css 
	install gui/css/images/* -t $(HOMEDIR)/var/www/html/css/images 
	install gui/css/images/kievsvt/* -t $(HOMEDIR)/var/www/html/css/images/kievsvt
	mkdir -p $(HOMEDIR)/var/www/html/js
	install gui/js/* -t $(HOMEDIR)/var/www/html/js
	ln -s $(HOMEDIR)/opt/NetSDS/lib $(HOMEDIR)/var/www/html/lib 

