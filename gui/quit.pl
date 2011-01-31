#!/usr/bin/perl -w

use strict;
use CGI;

#my $cgi = CGI->new;
#print $cgi->header(
#	-nph => 1, 
#    -status  => '401 Unauthorized',
#	-www_authenticate => 'Basic realm="test"',
#	-type => 'text/html');
#
#$cgi->start_html('Authorization required');
#$cgi->h2('Authorization required');
#$cgi->end_html; 
#
print "Status: 401 Unauthorized\n";
print "WWW-Authenticate: Basic realm=\"Quit\"\n";
print "Location: /datagroup.html\n";
print "Content-type: text/html\n"; 
print "\n\n";
print "<html><head>";
print "<meta http-equiv=\"Refresh\" content=\"1; url=/datagroup.html\" />\n"; 
print "</head></html>"; 


exit;
