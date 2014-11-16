#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Encode;
my $send_address = 'member@example.net';
my @toban;
{
    # 当番選出
    my %member;
    open (my $fh,'<:encoding(UTF-8)','gomi.txt') or die $!;
    while (<$fh>){
        next if /^\s*#/ or /^\s*$/;
        my ($name,$count) = split(/\s*,\s*/);
        $member{$name}=$count;
    }
    {
        my @sort_member = sort { $member{$a} <=> $member{$b} } keys %member;
        my @kouho;
        for (0..1){
            my $n=$_;
            @kouho = grep{ $member{$_} == $member{$sort_member[$n]} } @sort_member;
            push(@toban,splice(@kouho,int rand @kouho+0,1)) for 1..2;
        }
        splice(@toban,2);
    }
}
{
    # メール送信
    open (my $sendmail,'|-:encoding(ISO-2022-JP)',"/usr/sbin/sendmail -i -f $send_address $send_address") or die $!;
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
}
{
    # カウントup
    open (my $read,'<:encoding(UTF-8)','gomi.txt') or die $!;
    my @line = <$read>;
    close $read;
    open (my $write,'>:encoding(UTF-8)','gomi.txt') or die $!;
    select $write;
    for (@line){
        if (/^$toban[0]/ or /^$toban[1]/){
            my ($name,$count) = split(/\s*,\s*/);
            print "$name,",$count+1,"\n";
        }
        else {
            print;
        }
    }
    close $write;
}
