#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

use File::Basename;

my $PROG = basename $0;
my $num_duplicates = 4;

while (<>) {
  print and next if /^@/;
  chomp;
  my @fields = split /\t/;
  for my $dup_num (1 .. $num_duplicates) {
    print join("\t", $fields[0] . "_$dup_num", @fields[1 .. $#fields]) . "\n";
  }
}
