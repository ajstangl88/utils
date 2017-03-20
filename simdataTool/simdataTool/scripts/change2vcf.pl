#!/usr/bin/perl

use strict;
use warnings;

my $header = "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tsimulated\n";
my @array;
while (<>) {
  chomp;
  my $cuid = $_;
  /(chr[^.]+\.fa):(\d+)(?:-\d+)?_([ACGT]*)_([ACGT]*)/ or die "malformed line '$_', line no. $.\n";
  my ($chr, $pos1, $ref, $alt) = ($1, $2, $3, $4);
  if (length($ref) == length($alt)) {  # substitution (can't really sim 2+ bp subs easily, but we'll ignore that for now)
    # Nothing needed?
  }
  elsif (length($alt) == 0) {  # Deletion
    my $refpre = uc `echo "$chr\t@{[$pos1-2]}\t@{[$pos1-1]}" | bedtools getfasta -fi /mnt/staging/hg19/hg19.fa -bed - -fo temp.1 && tail -n 1 temp.1 && rm -f temp.1`;#| tail -n 1`;
    chomp $refpre;
    $ref = "$refpre$ref";
    $alt = "$refpre";
    $pos1--;
  }
  elsif (length($ref) == 0) {  # Insertion
    $pos1--;
    my $refpre = uc `echo "$chr\t@{[$pos1-1]}\t@{[$pos1]}" | bedtools getfasta -fi /mnt/staging/hg19/hg19.fa -bed - -fo temp.2 && tail -n 1 temp.2 && rm -f temp.2`;#- | tail -n 1`;
    chomp $refpre;
    $ref = $refpre;
    $alt = "$refpre$alt";
  }
  else {  # Complex indel
     # also nothing needed?
  }

  $chr =~ s/.fa//;


  my $str = "$chr\t$pos1\t$cuid\t$ref\t$alt\t.\tPASS\t.\t.\t1\n";
  push (@array, $str);
}

#print $header;
print @array;
