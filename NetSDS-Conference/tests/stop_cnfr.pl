#!/usr/bin/perl -w

package Test; 

use strict;

use lib '../lib';
use ConferenceDB;

my $error = '{ "status": "error", "message": "%s" }';

my $cnfr = ConferenceDB->new;
my $cid = $ARGV[0];

my $status = $cnfr->stop_cnfr(1, $cid);

warn Dumper ($status);

exit(0);
