install:
	echo -n "Creating base directories..." 
	mkdir -p /opt/NetSDS
	mkdir -p /opt/NetSDS/bin 
	mkdir -p /opt/NetSDS/lib
	echo -n "Installing main binary..."
	install bin/NetSDS-Conference.pl /opt/NetSDS/bin/
	echo -n "Installing low-level database library..."
	install lib/ConferenceDB.pm /opt/NetSDS/lib/
	echo -n "Installing NetSDS framework..."
	cp -a lib/NetSDS /opt/NetSDS/lib
	ln -s /opt/NetSDS/lib /var/www/astconf/lib 

config: 
	mkdir -p /etc/netstyle 
	install etc/netstyle/conference.conf /etc/netstyle 

gui:
	
	install ./gui/*.pl /var/www/astconf/
	install ./gui/*.html /var/www/astconf/ 
	install ./lib/ConferenceDB.pm /var/www/astconf/lib/ 
	install ./gui/js /var/www/astconf/js/ 
	install ./gui/css /var/www/astconf/css/
 
#	cp -fv ./utils/bin/* /var/lib/asterisk/agi-bin
#	cp -fv ./utils/lib/* /var/lib/asterisk/agi-bin
