%define installdir /opt/NetSDS

Name: NetSDS-Conference
Version: 0.02
Release: alt2

Summary: NetSDS Conferencing

License: GPL

Group: Networking/Other
Url: http://www.netstyle.com.ua/

Packager: Dmitriy Kruglikov <dkr@netstyle.com.ua>

BuildArch: noarch
Source: NetSDS-Conference.tar

Requires: asterisk1.6.2 
Requires: asterisk1.6.2-chan_sip 
Requires: asterisk1.6.2-ael 
Requires: asterisk1.6.2-pgsql
Requires: postgresql9.0-server 
Requires: postgresql9.0 
Requires: apache2  
Requires: apache2-mod_fastcgi 
Requires: perl-Class-Accessor-Class
Requires: perl-Data-Structure-Util
Requires: perl-Unix-Syslog
Requires: perl-Config-General 
Requires: perl-JSON
Requires: perl-libwww
Requires: perl-TimeDate
Requires: perl-Proc-Daemon
Requires: perl-Proc-PID-File
Requires: perl-CGI-Session 
Requires: perl-asterisk-perl 
Requires: perl-Asterisk-FastAGI
Requires: perl-Date-Manip
Requires: perl-CGI-Session-Auth
Requires: perl-Sys-Proctitle

%add_findreq_skiplist */NetSDS/*pm
%add_findreq_skiplist */NetSDS/*pl
%add_findreq_skiplist */conference/*pl

%description
NetSDS Conferencing platform.

%prep
%setup -q -n NetSDS-Conference

%build

%install
%makeinstall_std DESTDIR=%buildroot

%pre

%post

%files
%installdir/*
/var/www/webapps/conference/*
/usr/share/asterisk/sounds/*
/usr/share/NetSDS/Conference/*
%config(noreplace) %_sysconfdir/netstyle/conference.conf
%config(noreplace) %_sysconfdir/httpd2/conf/addon.d/A.conference.conf

%changelog
* Tue Nov 24 2011 Dmitriy Kruglikov <dkr@netstyle.com.ua> 0.02-alt2
- Added asterisk files and apache config

* Wed Nov 23 2011 Dmitriy Kruglikov <dkr@netstyle.com.ua> 0.02-alt1
- Added WEB gui files

* Wed Nov 23 2011 Dmitriy Kruglikov <dkr@netstyle.com.ua> 0.01-alt1
- Initial RMP build

* Sun Aug 30 2009 Alex Radetsky <rad@rad.kiev.ua> 1.00-alt1
- Clone spec from NetSDS-Admin to NetSDS-Stat

