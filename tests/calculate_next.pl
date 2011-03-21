#!/usr/bin/perl 

use strict;
use warnings;

use lib '../lib'; 

use Date::Manip; 
use ConferenceDB;
use Data::Dumper; 

unless ( defined ( $ARGV[0] ) ) { 
	print "Where is your ConferenceID ?\n";
	exit(1);
}
my $mydb = ConferenceDB->new;
my $cnfr_id = $ARGV[0]; 

my %conf = $mydb->get_cnfr($cnfr_id);
my $base = ParseDate("today");
my $err;
my $start = $base; 
my $stop = DateCalc("today","+ 2 month",\$err);

my %d_ord = ("Mon"=>1, "Tue"=>2, "Wed"=>3, "Thu"=>4, "Fri"=>5, "Sat"=>6, "Sun"=>7);

my $schedules = $conf{'schedules'};
#print Dumper (\@schedules);

my @deltas;
my @nexts;

my $count = @$schedules;
if ($count == 0) { 
	warn "It's not planned conference.\n"; 
  exit(0);
}

foreach my $sch (@$schedules) {
	print Dumper ($sch);
  my $format; 

	my $day = $sch->{'day'}; 
	if($day =~ /^[\d]+$/) {
			$format = sprintf "0:1*0:%s:%s", $day, $sch->{'begin'}; # It's a mday
	} else {
			$format = sprintf "0:0:1*%s:%s", $d_ord{$day}, $sch->{'begin'}; # It's a wday 
	}
	my @recur = ParseRecur($format,$base,$start,$stop);

	my $diff = DateCalc("today", $recur[0], $err, 1);
	push @deltas, $diff;
	push @nexts, $recur[0];

}
my $min = &ParseDateDelta($deltas[0]);
my $ind = 0;
for(my $j=1; $j<=$#deltas; $j++) {
		next if(&Date_Cmp(&ParseDateDelta($deltas[$j]), $min) >= 0);
		$ind = $j;
		$min = &ParseDateDelta($deltas[$j]);
}
my $next_start = &UnixDate($nexts[$ind], "%Y-%m-%d %H:%M");
my $next_sch = @$schedules[$ind];
my $next_duration = $next_sch->{'duration'};

printf("Next date: $next_start\n");
printf("Next duration: $next_duration\n");
#print Dumper ($next_start,$next_duration); 


