#!/usr/bin/perl
# vim: fdm=marker
use strict;
use warnings;
use feature qw(say);
use Test::More;
use utf8;
use Data::Dumper;
use FindBin;
use Encode;
use File::Temp qw(tempfile tempdir);

my @toban;
my $send_address='hoge@hoge.com';

chdir $FindBin::Bin;

subtest 'sendmail' => sub { #{{{
    @toban=('ほげ','ふが');
    ok(sendmail("1.eml"));
    open (my $fh,'<:encoding(ISO-2022-JP)','1.eml') or die $!;
    my @line = <$fh>;
    chomp @line;
    unshift (@line,"dummy");
    is $line[1],"From: $send_address";
    is $line[2],"To: $send_address";
    like $line[4],qr/Message-Id: <\d+$send_address>/;
    like $line[8],qr/^$/;
    like $line[9],qr/今週のゴミ当番は/;
    like $line[11],qr#^\d{4}/\d{2}/\d{2}\(.\) - \d{4}/\d{2}/\d{2}\(.\)#;
    like $line[12],qr/・ほげ/;
    like $line[13],qr/・ふが/;
    like $line[15],qr/よろしくお願いします/;
    close $fh;
}; #}}}
done_testing;

sub sendmail { #{{{
    # メール送信
    #open (my $sendmail,'|-:encoding(ISO-2022-JP)',"/usr/sbin/sendmail -i -f $send_address $send_address") or die $!;
    open (my $sendmail,'>:encoding(ISO-2022-JP)',$_[0]) or die $!;
    my $message_id = time() . $send_address;
    my $date;
    {
        my ($sec,$min,$hour,$mday,$mon,$year,$wday) = localtime(time);
        my @week = ('Sun','Mon','Tue','Wed','Thu','Fri','Sat');
        my @month = ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');
        $date = sprintf("%s, %d %s %04d %02d:%02d:%02d +0900 (JST)", $week[$wday],$mday,$month[$mon],$year+1900,$hour,$min,$sec);
    }
    my $start = decode("UTF-8",`date +"%Y/%m/%d(%a)"`);
    my $end   = decode("UTF-8",`date +"%Y/%m/%d(%a)" --date "4 days"`);
    chomp($start,$end);
    print $sendmail
          "From: $send_address\n"
        . "To: $send_address\n"
        . "Content-Type: text/plain; charset=\"ISO-2022-JP\"\n"
        . "Message-Id: <$message_id>\n"
        . "Date: $date\n"
        # Subject: 今週のゴミ当番
        . "Subject: =?ISO-2022-JP?B?GyRCOiM9NSROJTQlX0V2SFYbKEI=?=\n"
        . "Content-Transfer-Encoding: 7bit\n"
        . "\n"
        . "今週のゴミ当番は以下の方です\n"
        . "\n"
        . "$start - $end\n";
    print $sendmail "・$_\n" for @toban;
    print $sendmail
          "\n"
        . "よろしくお願いします\n";
} #}}}
