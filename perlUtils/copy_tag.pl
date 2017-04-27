#!/usr/bin/perl 

use strict;
use File::Basename;
use Cwd qw(abs_path);
use lib( dirname( abs_path(__FILE__) ).'/lib' );
use PGDX::Tag;
use Data::Dumper;
use Parallel::ForkManager;


#my $infile = $ARGV[0];
my $infile = "/Users/astangl/PycharmProjects/utils/perlUtils/tag_list.tsv";

open (my $fh, "<$infile") or die "Could not open file '$infile' $!";

while (my $line = <$fh>) {
    chomp($line);
    my ($tagname, $host, $dest) = split('\t', $line);
    print "$tagname\n$host\n$dest";
    my @desthosts = split(/,/, $dest);
    my $pm = new Parallel::ForkManager(10);
    foreach my $h (@desthosts) {
        print "$h\n";
        my $pid = $pm->start and next;
        print "Getting Tag\n";
        my $tag = &PGDX::Tag::get_tag($tagname, $host);
        my $exists = &PGDX::Tag::check_tag_exists($tagname, $h);
        if ($exists) {
            print "Updating Tag\n";
            &PGDX::Tag::update_tag($tag->[0], $h);
        }
        else {
            &PGDX::Tag::create_tag($tag->[0], $h);
        }

        print "Checking Tag\n";
        my $tag = &PGDX::Tag::get_tag($tagname, $h);
        print "\nTag Check result: ".Dumper $tag;
        $pm->finish;
    }
    $pm->wait_all_children;
    print "Completely Done!\n";
}

