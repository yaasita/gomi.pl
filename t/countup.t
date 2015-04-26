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
