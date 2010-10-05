#!/usr/bin/perl -w

use strict;
use DBI;



my $dbh = DBI->connect("dbi:Pg:dbname=astconf", 'astconf', 'Rjyathtywbz', {AutoCommit => 0});


my $q = "SELECT login, passwd_hash from admins";

my $sth=$dbh->prepare($q);

$sth->execute();

while(my @tmp = $sth->fetchrow_array()) {
	print $tmp[0],":",$tmp[1],"\n";
}


$dbh->disconnect();
exit;
