#!/usr/bin/perl -w

use strict;
use CGI;


my $cgi = CGI->new;
my $login = $cgi->remote_user();

my $out = "<img src='/css/images/kievsvt_maket.jpg'>";

print $cgi->header(-type=>'text/html',-charset=>'utf-8');
print $out;

exit(0);
