#!/usr/bin/perl 

use strict;
use File::Basename;
use Cwd qw(abs_path);
use lib( dirname( abs_path(__FILE__) ).'/lib' );
use PGDX::Tag;
use Data::Dumper;
use Parallel::ForkManager;

my $tagname = $ARGV[0];
my $host = $ARGV[1];
my $desthosts = $ARGV[2];
#my @hostlist = split(/,/,$hosts);
my @desthosts = split(/,/,$desthosts);

my $pm = new Parallel::ForkManager(10);

foreach my $h (@desthosts) {
    my $pid = $pm->start and next;
    
    print "Getting Tag\n";
    my $tag = &PGDX::Tag::get_tag($tagname,$host);
#    print "\nTag Check result: ".Dumper $tag;
    
    my $exists = &PGDX::Tag::check_tag_exists($tagname,$h);
    if($exists) {
        print "Updating Tag\n";
        &PGDX::Tag::update_tag($tag->[0],$h);        
    }
    else {
        &PGDX::Tag::create_tag($tag->[0],$h);
    }

    print "Checking Tag\n";
    my $tag = &PGDX::Tag::get_tag($tagname,$h);
    print "\nTag Check result: ".Dumper $tag;
    
    $pm->finish;
}

$pm->wait_all_children;
print "Completely Done!\n";
