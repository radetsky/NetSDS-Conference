#!/usr/bin/perl -w

use strict;
use CGI;

use lib './lib';
use ConferenceDB;

my @SOX = ("/usr/bin/sox", "-t", "wav", "-c", "1", "-r", "8000");

my $cgi = CGI->new;

my $cnfr = ConferenceDB->new;

my $login = $cnfr->login;
my $oper_id = $cnfr->operator($login);
my $admin = $cnfr->{oper_admin};
my $ab = $cnfr->addressbook;


my $msg = "ok";

my $filename = $cgi->param('fbody');
my $desc = $cgi->param('fname');
my $buffer;

if(defined $filename) {
	my $base = &gen_name();
	my $output = "/tmp/" . $base . ".wav";
	open(OUTFILE,">$output");
	while(my $bytesread=read($filename,$buffer,1024)) {
		print OUTFILE $buffer;
	}
	close(OUTFILE);
	my $convert = "/tmp/" . $base . "_1.wav";
#	my $res = system(@SOX, $output, $convert);
	my $res = system("/usr/bin/sox",$output,"-t","wav","-c","1","-r","8000",$convert); 

	if($res == 0) {
		open(CNVT, "<$convert");
		my $file_data = "";
		while (read(CNVT,$buffer,1024)) {
		  $file_data.=$buffer;
		}
		warn length($file_data);
		close(CNVT);
	
		unless($cnfr->load_audio($desc, $file_data)) {
			$msg = "Ошибка сохранения файла.";
		}
		unlink $output;
		unlink $convert;
	} else {
		$msg = "Ошибка преобразования файла. Возможно файл неверного формата. Данный файл сохранить невозможно.";
	}
} else {
	$msg = "Не определен файл для загрузки.";
}

print $cgi->header(-type=>'text/plain',-charset=>'utf-8',-cookie=>$cnfr->cookie);
print $msg;

exit;

sub gen_name {
  srand();
  return join '', ('A'..'Z', 'a'..'z', 0..9)[
             rand 62, rand 62, rand 62, rand 62,
             rand 62, rand 62, rand 62, rand 62];
}
