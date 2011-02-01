install:
	cp -fv ./gui/*.pl /var/www/astconf/ 
	cp -fv ./gui/*.html /var/www/astconf/ 
	cp -fv ./lib/ConferenceDB.pm /var/www/astconf/lib/ 
	cp -fva ./gui/js /var/www/astconf/js/ 
	cp -fva ./gui/css /var/www/astconf/css/
 
#	cp -fv ./utils/bin/* /var/lib/asterisk/agi-bin
#	cp -fv ./utils/lib/* /var/lib/asterisk/agi-bin
