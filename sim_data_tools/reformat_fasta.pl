#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
my $seq = "";
while (<>) {
  if (/^>/) {
    print_seq($seq);
    print;
    $seq = "";
    next;
  }
  chomp;
  $seq .= $_;
}
print_seq($seq);

sub print_seq {
  my $seq = shift;
  while (length($seq)) {
    print substr($seq, 0, 60) . "\n";
    substr($seq, 0, 60) = "";
  }
}