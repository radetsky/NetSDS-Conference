Name: NetSDS-Conference
Version: 0.01
Release: alt1

Summary: NetSDS Conferencing

License: GPL

Group: Networking/Other
Url: http://www.netstyle.com.ua/

Packager: Dmitriy Kruglikov <dkr@netstyle.com.ua>

BuildArch: noarch
Source: NetSDS-Conference.tar

BuildPreReq: rpm-build-NetSDS
BuildPreReq: NetSDS-common

PreReq: NetSDS-common
PreReq: perl-NetSDS

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

%description
NetSDS Conferencing platform.

%prep
%setup -q -n NetSDS-Conference

%build

%install
%makeinstall_std DESTDIR=%buildroot

%pre

%files

%changelog
* Wed Nov 23 2011 Dmitriy Kruglikov <dkr@netstyle.com.ua> 0.01-alt1
- Initial RMP build

* Sun Aug 30 2009 Alex Radetsky <rad@rad.kiev.ua> 1.00-alt1
- Clone spec from NetSDS-Admin to NetSDS-Stat

