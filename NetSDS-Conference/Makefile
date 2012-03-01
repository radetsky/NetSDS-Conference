HOMEDIR=$(DESTDIR)
all: install

depends-ubuntu:
	sudo apt-get install asterisk asterisk-dev asterisk-config asterisk-sounds-main \
	libcgi-session-expiresessions-perl libcgi-session-perl \
	libclass-accessor-perl libconfig-general-perl libconfig-json-perl \
	libdata-structure-util-perl libdate-manip-perl libdbd-pg-perl \
	libdbi-perl libproc-daemon-perl libproc-pid-file-perl \
	libtimedate-perl libunix-syslog-perl liburi-perl libwww-perl libasterisk-agi-perl \
	apache2 apache2-mpm-prefork apache2-utils apache2.2-common libapache2-mod-php5 
	wget http://search.cpan.org/CPAN/authors/id/G/GE/GEEWIZ/CGI-Session-Auth-1.07.tar.gz
	tar zxvf CGI-Session-Auth-1.07.tar.gz
	cd CGI-Session-Auth-1.07 &&	perl Makefile.PL && make && sudo make install && cd .. 
	wget http://search.cpan.org/CPAN/authors/id/R/RJ/RJBS/Class-Accessor-Class-0.501.tar.gz 
	tar zxvf ./Class-Accessor-Class-0.501.tar.gz
	cd Class-Accessor-Class-0.501/ && perl Makefile.PL && make && sudo make install && cd ..
	wget http://search.cpan.org/CPAN/authors/id/O/OP/OPI/Sys-Proctitle-0.04.tar.gz
	tar zxvf ./Sys-Proctitle-0.04.tar.gz
	cd Sys-Proctitle-0.04/ && perl Makefile.PL && make && sudo make install && cd ..

install:
	mkdir -p $(HOMEDIR)/opt/NetSDS/bin
	mkdir -p $(HOMEDIR)/opt/NetSDS/lib
	install bin/NetSDS-Conference.pl $(HOMEDIR)/opt/NetSDS/bin/
	install lib/ConferenceDB.pm $(HOMEDIR)/opt/NetSDS/lib/
	install lib/ConferenceAuth.pm $(HOMEDIR)/opt/NetSDS/lib/ 
	cp -a lib/NetSDS $(HOMEDIR)/opt/NetSDS/lib
	mkdir -p $(HOMEDIR)/var/run/NetSDS/
	mkdir -p $(HOMEDIR)/etc/netstyle 
	install etc/netstyle/conference.conf $(HOMEDIR)/etc/netstyle 
	mkdir -p $(HOMEDIR)/etc/httpd2/conf/addon.d
	install etc/apache2/A.conference.conf $(HOMEDIR)/etc/httpd2/conf/addon.d/A.conference.conf
	mkdir -p $(HOMEDIR)/usr/share/NetSDS/Conference
	cp -ar asterisk-configs $(HOMEDIR)/usr/share/NetSDS/Conference
	cp -a ivr/dialplan/conference.ael $(HOMEDIR)/usr/share/NetSDS/Conference/
	mkdir -p $(HOMEDIR)/usr/share/asterisk/sounds
	cp -ar sounds $(HOMEDIR)/usr/share/asterisk
	mkdir -p  $(HOMEDIR)/usr/lib/astconf 
	cp utils/lib/sh-agi.inc /usr/lib/astconf 
	cp utils/bin/* $(HOMEDIR)/usr/share/asterisk/agi-bin
	cp etc/init.d/nibelite-conference /etc/init.d/nibelite-conference
	update-rc.d nibelite-conference defaults 98 
	update-rc.d nibelite-conference enable 
	cd contrib/konference && make && make install && make clean 
 
sql-install:
	su - postgres -c 'psql -i ./sql/pgsql.sql'
	psql -U astconf -i ./sql/schema.sql

gui-install:
	mkdir -p /var/www/conference 
	cp -a gui/* $(HOMEDIR)/var/www/conference
	ln -s $(HOMEDIR)/opt/NetSDS/lib $(HOMEDIR)/var/www/conference/lib

asterisk-configs:
	cp -a etc/asterisk/* /etc/asterisk 
	asterisk -rx "core restart now" 

apache2-configs:
	cp etc/apache2/conference /etc/apache2/sites-available
	a2ensite conference
	a2dissite default 
	a2enmod proxy
	a2enmod proxy_http 
	/etc/init.d/apache2 restart 


