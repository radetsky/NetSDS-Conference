#!/usr/bin/env perl

use 5.8.0;
use strict;
use warnings;

NetSDSApp->run(
        daemon => 0,
        infinite => 0,
);

1;

package NetSDSApp;

use Data::Dumper;
use IPC::SysV qw(IPC_PRIVATE S_IRUSR S_IWUSR);
use IPC::Msg;
use POSIX ":sys_wait_h";
use IO::Socket;
use JSON;

use base 'NetSDS::App';

### TOOLS ####################################

sub create_child {
    my ($this, $type) = @_;

    my $pid = fork();

    if ($pid == 0) {
        $this->daemon_type($type);
    } else {
        printf $pid . " start\n";
        push @{$this->childs}, $pid;
    }

    return $pid;
}

sub Wait { 
    printf STDOUT "httpd[" . $$ . "]: Wait\n";
    wait; 
}

sub freshtop {
#    my $str = `/bin/date +%s`;
    return ( time(), time() );
}

### HTTP #####################################

sub parseREQUEST {
	my %PARAM = ();
	my $request = $_[0] if $_[0];
	$request =~ s/^\/// 	if $request;
	$request =~ s/^\?// 	if $request;
	if( $request =~ m/^\S+$/ ){	
		my @parts = split( /\&/, $request ); 
		foreach my $part (@parts) {
			my ( $name, $value ) = split( /\=/, $part );
			$value =~ ( s/%23/\#/g ) if $value;
			$value =~ ( s/%2F/\//g ) if $value;
			$PARAM {"$name"} = $value;
		}
	}	
	return %PARAM;
}

### IPC ######################################

sub send_msg {
    my ($this, $msg, $msgtype, $flags) = @_;

    $this->ipcmsg->snd($msgtype, $msg, $flags);
}

sub rcv_msg {
    my ($this, $msg, $len, $msgtype, $flags) = @_;

    $this->ipcmsg->rcv($msg, $len, $msgtype, $flags);
    
    $_[1] = $msg;
}

### ASTRMNGR #################################

sub start_astd {
    my ($this) = @_;

    my $pid = create_child($this, 'astd');

    if ($pid == 0) {
        print "start astd[" . $$ . "]>\n";
    }

    return $pid;
}

sub process_astd {
    my ($this) = @_;
    my $msg;

    while (1) {
        rcv_msg($this, $msg, 256, 2);
        printf "astd[" . $$ . "]: rcv:" . $msg . "\n";

        if ($msg eq '/') {
            $msg = 'access';
        } else {
            $msg = 'forbidden';
        }
   
        send_msg($this, $msg, 1);
        printf "astd[" . $$ . "]: snd:" . $msg . "\n";

    }
}

### HTTPD ####################################

sub start_httpd {
    my ($this) = @_;

    my $pid = create_child($this, 'httpd');
    
#    my $pid = 0;
    
    if ($pid == 0) {
        $this->mk_accessors('httpd');
        $this->httpd(IO::Socket::INET->new(LocalPort => 8088,
                                           Type => SOCK_STREAM,
                                           Reuse => 1,
                                           Listen => 10));
        $this->httpd->autoflush(1);
        $SIG{CHLD} = \&Wait;
        print "start httpd[" . $$ . "] at: <URL:http://0.0.0.0:8088/>\n";
    }

    return $pid;
}

sub process_httpd {
    my ($this) = @_;
    my $msg;
    my $client;

    printf STDOUT "httpd[" . $$ . "]: process_httpd\n";

    while ($client = $this->httpd->accept()) {
        next if my $pid = fork;
        die "fork - $!\n" unless defined $pid;

        my $client_info; my $VARGET; my $VARPOST;

        while(<$client>){ 
            last if /^\r\n$/; 
            $VARGET = $_ if /^GET /; 	$VARGET =~ s/^\S+\s(\S+)\s.*$/$1/ if $VARGET;  
            $VARPOST = $_ if /^POST /; 	$VARPOST =~ s/^\S+\s(\S+)\s.*$/$1/ if $VARPOST; 
            $client_info .= $_; 
        }
        
        if($VARGET){
            my %_GET = parseREQUEST($VARGET);
            my $remotime = defined($_GET{"timestamp"})?$_GET{"timestamp"}:0;
            while( $remotime >= time() ) { select(undef, undef, undef, 0.25); } 
        }	
        
        my ( $lastcase, $data ) = freshtop();

        my $resp = ();
        $resp->{'data'} = $data;
        $resp->{'timestamp'} = $lastcase;

        select $client;

        printf STDOUT "HTTP/1.0 200 OK\r\n";
		printf STDOUT "Content-type: text/plain\r\n\r\n";
		printf STDOUT "strJSON = ".to_json($resp);

        $| = 1;

        print $client "HTTP/1.0 200 OK\r\n";
        print $client "Content-type: text/plain\r\n\r\n";
        print $client "strJSON = ".to_json($resp);

        close($client);
        exit( fork );
    }  continue {
        close($client); 
        kill CHLD => -$$;
    }
}

### MAIN ####################################

sub start {
    my ($this) = @_;

    $this->mk_accessors('daemon_type');
    $this->daemon_type('master');

    $this->mk_accessors('ipcmsg');
#    $this->ipcmsg(IPC::Msg->new(IPC_PRIVATE, S_IRUSR | S_IWUSR));
#    printf $this->ipcmsg->id . "\n";
        
    $this->mk_accessors('childs');
    my @childs = ();
    $this->childs(\@childs);

    start_httpd($this) || return;
#    start_astd($this) || return;
}

sub process {
    my ($this) = @_;

    my $msg;
    my $msgtype;

    if ($this->daemon_type eq 'httpd') {
        process_httpd($this);
#    } elsif ($this->daemon_type eq 'astd') {
#        process_astd($this);
    } else {
        return;
    }
}

sub stop {
    my ($this) = @_;
    my $pid;

    printf STDOUT "master[" . $$ . "]: sleeping\n";
    
    sleep(1000);


    if ($this->daemon_type eq 'master') {
        foreach $pid (@{$this->childs}) {
            waitpid($pid, 0);
            printf $pid . " exit\n";
        }
#        $this->ipcmsg->remove;
    }
}
