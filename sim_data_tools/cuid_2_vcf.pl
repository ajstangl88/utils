#!/usr/bin/perl

use strict;
use warnings;

while (<>) {
  chomp;
  my $cuid = $_;
  /(chr[^.]+\.fa):(\d+)(?:-\d+)?_([ACGT]*)_([ACGT]*)/ or die "malformed line '$_', line no. $.\n";
  my ($chr, $pos1, $ref, $alt) = ($1, $2, $3, $4);
  if (length($ref) == length($alt)) {  # substitution (can't really sim 2+ bp subs easily, but we'll ignore that for now)
    # Nothing needed?
  }
  elsif (length($alt) == 0) {  # Deletion
    my $refpre = uc `echo "$chr\t@{[$pos1-2]}\t@{[$pos1-1]}" | bedtools getfasta -fi /Users/dwood/hg19/hg19_pgdx.fa -bed - -fo - | tail -n 1`;
    chomp $refpre;
    $ref = "$refpre$ref";
    $alt = "$refpre";
    $pos1--;
  }
  elsif (length($ref) == 0) {  # Insertion
    $pos1--;
    my $refpre = uc `echo "$chr\t@{[$pos1-1]}\t@{[$pos1]}" | bedtools getfasta -fi /Users/dwood/hg19/hg19_pgdx.fa -bed - -fo - | tail -n 1`;
    chomp $refpre;
    $ref = $refpre;
    $alt = "$refpre$alt";
  }
  else {  # Complex indel
     # also nothing needed?
  }
  print "$chr\t$pos1\t$cuid\t$ref\t$alt\t.\tPASS\t.\t.\t1\n";
}
