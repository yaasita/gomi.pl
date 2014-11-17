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

subtest 'toban' => sub { #{{{
    ok(toban("1.txt"));
    diag "1 => @toban";
    my @toban1 = sort @toban;
    my @test1 = sort ( "three","two" );
    is_deeply \@toban1,\@test1;
    @toban = ();

    ok(toban("2.txt"));
    diag "2 => @toban";
    ok("@toban" =~ /(two|three|four) (two|three|four)/);
    ok("@toban" !~ /(\w+) (\1)/);
    @toban = ();

    ok(toban("3.txt"));
    diag "3 => @toban";
    ok("@toban" =~ /five (two|three|four)/);
    @toban = ();

}; #}}}
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
subtest 'countup' => sub { #{{{
    {
        @toban = qw(one two);
        system("cp c1-before.txt c1-after.txt") and die $!;
        ok(countup("c1-after.txt"));
        open(my $fh,'<:encoding(UTF-8)',"c1-after.txt") or die $!;
        my @line = <$fh>;
        chomp @line;
        is $line[0],"# 名前, 当番回数";
        is $line[1],"one,2";
        is $line[2],"two,1";
        is $line[3],"three,0";
        is $line[4],"four,1";
        close $fh;
    }

    {
        @toban = qw(てすと test);
        system("cp c2-before.txt c2-after.txt") and die $!;
        ok(countup("c2-after.txt"));
        open(my $fh,'<:encoding(UTF-8)',"c2-after.txt") or die $!;
        my @line = <$fh>;
        chomp @line;
        is $line[0],"# 名前, 当番回数";
        is $line[1],"テスト,8";
        is $line[2],"てすと,10";
        is $line[4],"test,10";
        close $fh;
    }
}; #}}}
done_testing;

sub toban{ #{{{
    # 当番選出
    open (my $fh,'<:encoding(UTF-8)',$_[0]) or die $!;
    my %member;
    while (<$fh>){
        next if /^\s*#/ or /^\s*$/;
        my ($name,$count) = split(/\s*,\s*/);
        $member{$name}=$count;
    }
    my @sort_member = sort { $member{$a} <=> $member{$b} } keys %member;
    my @kouho;
    for (0..1){
        my $n=$_;
        @kouho = grep{ $member{$_} == $member{$sort_member[$n]} } @sort_member;
        push(@toban,splice(@kouho,int rand @kouho+0,1)) for 1..2;
    }
    splice(@toban,2);
} #}}}
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
sub countup{ #{{{
    # カウントup
    open (my $read,'<:encoding(UTF-8)',$_[0]) or die $!;
    my @line = <$read>;
    close $read;
    open (my $write,'>:encoding(UTF-8)',$_[0]) or die $!;
    for (@line){
        if (/^$toban[0]/ or /^$toban[1]/){
            my ($name,$count) = split(/\s*,\s*/);
            print $write "$name,",$count+1,"\n";
        }
        else {
            print $write $_;
        }
    }
    close $write;
} #}}}
