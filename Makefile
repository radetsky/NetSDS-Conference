install:
	echo -ne "Creating base directories..." 
	mkdir -p /opt/NetSDS
	mkdir -p /opt/NetSDS/bin 
	mkdir -p /opt/NetSDS/lib
	echo -ne "Installing main binary..."
	install bin/NetSDS-Conference.pl /opt/NetSDS/bin/
	echo -ne "Installing low-level database library..."
	install lib/ConferenceDB.pm /opt/NetSDS/lib/
	install lib/ConferenceAuth.pm /opt/NetSDS/lib/ 
	echo -ne "Installing NetSDS framework..."
	cp -a lib/NetSDS /opt/NetSDS/lib
	echo -ne "Make /var/run/NetSDS" 
	mkdir -p /var/run/NetSDS/

config: 
	mkdir -p /etc/netstyle 
	install etc/netstyle/conference.conf /etc/netstyle 

gui:
	install gui/* -d -t /var/www/html
	mkdir -p /var/www/html/css/images/kievsvt/
	install gui/css/* -t /var/www/html/css 
	install gui/css/images/* -t /var/www/html/css/images 
	install gui/css/images/kievsvt/* -t /var/www/html/css/images/kievsvt
	mkdir -p /var/www/html/js
	install gui/js/* -t /var/www/html/js
	ln -s /opt/NetSDS/lib /var/www/html/lib 


