HOMEDIR=$(DESTDIR)
all: install

depends-ubuntu:
	apt-get install asterisk asterisk-dev asterisk-config asterisk-sounds-main \
	libcgi-session-expiresessions-perl libcgi-session-perl \
	libclass-accessor-perl libconfig-general-perl libconfig-json-perl \
	libdata-structure-util-perl libdate-manip-perl libdbd-pg-perl \
	libdbi-perl libproc-daemon-perl libproc-pid-file-perl \
	libtimedate-perl libunix-syslog-perl liburi-perl libwww-perl \
	apache2 apache2-mpm-prefork apache2-utils apache2.2-common libapache2-mod-php5 
	wget http://search.cpan.org/CPAN/authors/id/G/GE/GEEWIZ/CGI-Session-Auth-1.07.tar.gz
	tar zxvf CGI-Session-Auth-1.07.tar.gz
	cd CGI-Session-Auth-1.07
	perl Makefile.PL
	make 
	sudo make install 

install:
	mkdir -p $(HOMEDIR)/opt/NetSDS/bin
	mkdir -p $(HOMEDIR)/opt/NetSDS/lib
	install bin/NetSDS-Conference.pl $(HOMEDIR)/opt/NetSDS/bin/
	install lib/ConferenceDB.pm $(HOMEDIR)/opt/NetSDS/lib/
	install lib/ConferenceAuth.pm $(HOMEDIR)/opt/NetSDS/lib/ 
	cp -a lib/NetSDS $(HOMEDIR)/opt/NetSDS/lib
	mkdir -p $(HOMEDIR)/var/run/NetSDS/

config: 
	mkdir -p $(HOMEDIR)/etc/netstyle 
	install etc/netstyle/conference.conf $(HOMEDIR)/etc/netstyle 

gui-install:
	mkdir -p /var/www/conference 
	cp -a gui/* $(HOMEDIR)/var/www/conference
	ln -s $(HOMEDIR)/opt/NetSDS/lib $(HOMEDIR)/var/www/conference/lib
 
