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

subtest 'toban-comb2' => sub { #{{{
    @toban = ();
    toban("1.txt");
    @toban = sort @toban;
    diag "1 => @toban";
    my @expect = sort ( "three","two" );
    is_deeply \@toban,\@expect;
}; #}}}
subtest 'toban-comb2' => sub {  #{{{
    @toban = ();
    toban("2.txt");
    diag "2 => @toban";
    ok("@toban" =~ /(two|three|four) (two|three|four)/);
    ok("@toban" !~ /(\w+) (\1)/);
}; #}}}
subtest 'toban-comb2-2' => sub {  #{{{
    @toban = ();
    toban("3.txt");
    diag "3 => @toban";
    ok("@toban" =~ /five (two|three|four)/);
    @toban = ();
}; #}}}
subtest 'toban-random' => sub {  #{{{
    @toban = ();
    toban("4.txt");
    diag "4 => @toban";
    ok("@toban" =~ /山下/);
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
