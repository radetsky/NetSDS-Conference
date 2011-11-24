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
	mkdir -p $(HOMEDIR)/etc/httpd2/conf/addon.d
	install etc/apache2/A.conference.conf $(HOMEDIR)/etc/httpd2/conf/addon.d/A.conference.conf

	mkdir -p $(HOMEDIR)/var/www/webapps/conference
	cp -a gui/* $(HOMEDIR)/var/www/webapps/conference
	ln -s -t $(HOMEDIR)/var/www/webapps/conference /opt/NetSDS/lib

	mkdir -p $(HOMEDIR)/usr/share/NetSDS/Conference
	cp -ar asterisk-configs $(HOMEDIR)/usr/share/NetSDS/Conference
	cp -a ivr/dialplan/conference.ael $(HOMEDIR)/usr/share/NetSDS/Conference/
	
	mkdir -p $(HOMEDIR)/usr/share/asterisk/sounds
	cp -ar sounds $(HOMEDIR)/usr/share/asterisk
