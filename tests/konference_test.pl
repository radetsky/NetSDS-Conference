#!/usr/bin/perl 

use warnings; 
use strict; 

use NetSDS::Konference;
use Data::Dumper; 


my $konf = NetSDS::Konference->new();

$konf->konference_connect('localhost','5038','asterikastwww','asterikastwww');

my $res = $konf->konference_list(); 

unless ( defined ($res) ) { 
	printf ("Some error occured.\n");
} 

if ($res == 0) { 
	print("No active Konference!\n"); 
	exit 0; 
}

foreach my $conf ( keys %$res ) { 
	printf("Konf No: $conf Members %s Volume %s Duration %s\n",
			$res->{$conf}->{'members'}, 
			$res->{$conf}->{'volume'},
			$res->{$conf}->{'duration'} ); 
	
	my $members = $konf->konference_list_konf($conf); 
	warn Dumper ($members);

	my $kicked = $konf->konference_kick ($conf,49); 
	warn Dumper ($kicked);
	unless ( defined ( $kicked ) ) { 
		printf("Kick member_id 49 from $conf failed.\n");
	} 
	
	$kicked = $konf->konference_kick ($conf,1); 
	warn Dumper ($kicked); 
	if ( defined ( $kicked) ) {
		printf("Kick member_id 1 from $conf success.\n"); 
	}
	 

}

  


