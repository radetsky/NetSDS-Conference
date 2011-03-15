#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;

my $cgi = CGI->new;
my $cnfr = ConferenceDB->new;
my $login = $cnfr->login(1);
my $proto = $cgi->https ? 'https' : 'http';

if(defined $login){
    print $cgi->redirect(                                                                                               
	-location => $proto.'://'.$ENV{'HTTP_HOST'}.                                                                                    
    	    ($ENV{'HTTP_PORT'} eq '80' ? '' : ':'.$ENV{'HTTP_PORT'}).                                                       
    	    '/datagroup.html',
    	-cookie => $cnfr->cookie                                                                                                   
    );
} else {
    print $cgi->redirect(                                                                                               
	-location => $proto.'http://'.$ENV{'HTTP_HOST'}.                                                                                    
    	    ($ENV{'HTTP_PORT'} eq '80' ? '' : ':'.$ENV{'HTTP_PORT'}).                                                       
    	    '/login.html#no'
    );
}

exit(0);
