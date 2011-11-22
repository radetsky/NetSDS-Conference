#!/usr/bin/perl 

use warnings; 
use strict; 

use lib '/opt/NetSDS/lib'; 


use ConferenceDB; 
use Data::Dumper; 

my $db = ConferenceDB->new(); 

my $cnfrs = $db->cnfr_find_4_start();
warn Dumper ($cnfrs); 


