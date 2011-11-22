#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  NetSDS-Conference.pl
#
#        USAGE:  ./NetSDS-Conference.pl
#
#  DESCRIPTION:  NetSDS-Conference service.
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Alex Radetsky (Rad), <rad@rad.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.0
#      CREATED:  16.10.2010 14:22:38 EEST
#     REVISION:  ---
#===============================================================================

use 5.8.0;
use strict;
use warnings;

EmailReminderTest->run(
    daemon      => undef,
    verbose     => 1,
    use_pidfile => 1,
    has_conf    => 1,
    debug       => 1,
    conf_file   => "/etc/netstyle/conference.conf",
    infinite    => undef,

);

1;

package EmailReminderTest;

use 5.8.0;
use strict;
use warnings;

use lib '../lib/';

use base qw(NetSDS::App);
use ConferenceDB;
use Data::Dumper;
use NetSDS::App::ConfVoiceReminder;
use NetSDS::Asterisk::Originator; 
use utf8;

sub start {
    my ($this) = @_;
    $this->speak("[$$] NetStyle NetSDS-Conference ConfVoiceReminder test.");
}

sub process {
    my ($this) = @_;
    $this->speak("[$$] Start processing.");
	my $cnfr_id = $ARGV[0]; 

	$this->_conference_email_reminder_start($cnfr_id); 

}

sub _conference_email_reminder_start { 
	my $this = shift; 
	my $cnfr_id = shift; 

        $this->speak( "[$$] Running NetSDS::App::ConfVoiceReminder ("
              . $cnfr_id . ")" );
	        my $cm = NetSDS::App::ConfVoiceReminder->run(
            infinite  => undef,
            verbose   => 1,
            has_conf  => 1,
            conf_file => '/etc/netstyle/conference.conf',
            debug     => 1,
			cnfr_id   => $cnfr_id,

        );
}

1;

#===============================================================================

__END__

=head1 NAME

NetSDS-Conference.pl

=head1 SYNOPSIS

NetSDS-Conference.pl

=head1 DESCRIPTION 

Главный процесс в иерархии процессов по NetSDS-Conference. Следит за необходимостью старторвать новую
конференцию, управляет дочерними процессами. 

=head1 EXAMPLES

FIXME

=head1 BUGS

Unknown.

=head1 TODO

Empty.

=head1 AUTHOR

Alex Radetsky <rad@rad.kiev.ua>

=cut

