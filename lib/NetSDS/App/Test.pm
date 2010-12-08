#===============================================================================
#
#         FILE:  ConfEmailReminder.pm
#
#  DESCRIPTION:  Conference Manager for each conference in NetSDS-Conference package :)
#
#        NOTES:  ---
#       AUTHOR:  Alex Radetsky (Rad), <rad@rad.kiev.ua>
#      COMPANY:  Net.Style
#      VERSION:  1.0
#      CREATED:  18.10.10
#===============================================================================

=head1 ConfEmailReminder

NetSDS::App::ConfEmailReminder

=head1 DESCRIPTION

ConfEmailReminder contains package w

=cut
package Test; 

NetSDS::App::ConfEmailReminder->run(); 

1; 


package NetSDS::App::ConfEmailReminder;

use 5.8.0;
use strict;
use warnings;

use base qw(NetSDS::App);

use Data::Dumper;
use Sys::Proctitle qw/:all/;
#use MIME::Base64 qw/encode_base64/;

use version; our $VERSION = "0.01";
our @EXPORT_OK = qw();

#-----------------------------------------------------------------------

=item B<start> - 

Generic Start Conference Email Reminder. 

=cut 

sub start {
    my $this = shift;

    $SIG{INT} = sub {
        warn "[$$] SIGINT caught";
        exit(1);
    };

    $SIG{TERM} = sub {
        warn "[$$] SIGTERM caught";
        exit(1);
    };

    # this->{'cnfr_id'} contains cnfr_id ;)
    setproctitle( "ConfEmailReminder (" . $this->{'cnfr_id'} . ")" );

    # ConferenceDB
    $this->mk_accessors('mydb');
    $this->mydb( ConferenceDB->new() );

    $this->speak( "[$$] ConfEmailReminder start with conference ID: "
          . $this->{'cnfr_id'} );

    # log record
    $this->mydb->conflog( $this->{'cnfr_id'}, 'email_reminder_started', undef );

}

sub process {
    my $this = shift;

    $this->speak("[$$] ConfEmailReminder process.");

    # Get properties of conference
    my $conf = $this->mydb->cnfr_get( $this->{'cnfr_id'} );
    unless ( defined($conf) ) {
        $this->log( "warning",
            "Can't get properties of the conference #" . $this->{'cnfr_id'} );
        return undef;
    }
    $this->{'conf_properties'} = $conf;

    # Get list of emails
    my $list = $this->mydb->cnfr_get_emails( $this->{'cnfr_id'} );
    foreach my $user_id ( keys %$list ) {
        my $res = $this->_sendmail_reminder( $list->{$user_id}->{'email'} );
    }
}

sub _sendmail_reminder {
    my $this  = shift;
    my $email = shift;

    unless ( defined($email) ) {
        return undef;
    }

    # Get the template of mail
    my $template = $this->conf->{'reminder'}->{'email_body'};
    unless ( defined($template) ) {
        $this->speak("[$$] Can't get template of mail body. Exiting.");
        $this->log( "warning", "Can't get template of mail body. Exiting." );
        return undef;
    }

    my $email_body = $this->_find_n_replace_macros($template);
    my $sendmail   = '/usr/sbin/sendmail';
    my $to         = $email;
    my $from       = $this->conf->{'reminder'}->{'email_from'};

#    my $subject =
#      MIME::Base64::encode_base64( $this->conf->{'reminder'}->{'subject'} );
    my $subject =~ s/\n//g;
#    my $data     = MIME::Base64::encode_base64($email_body);
    my $boundary = 'simple boundary';
    open( MAIL, "| $sendmail -t -oi" ) or die("$!");

    print MAIL <<EOF;
To: $email 
From: $from
Subject: =?UTF-8?B?$subject?= 
Content-Type: multipart/mixed; boundary="$boundary" 
 
This is a multi-part message in MIME format. 
--$boundary 
Content-Type: text/html; charset=UTF-8 
Content-Transfer-Encoding: base64 
 
$email_body 
EOF

    close MAIL;

}

sub _find_n_replace_macros {
    my $this     = shift;
    my $template = shift;

    my $date = $this->{'conf_properties'}->{'next_start'};
    $template =~ s/%date/$$date/g;

    return $template;

}
1;

__END__

=back

=head1 EXAMPLES


=head1 BUGS

Unknown yet

=head1 SEE ALSO

None

=head1 TODO

None

=head1 AUTHOR

Alex Radetsky <rad@rad.kiev.ua>

=cut


