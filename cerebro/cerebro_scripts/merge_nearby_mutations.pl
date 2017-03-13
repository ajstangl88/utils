#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use List::Util qw/min max/;
use Getopt::Long;
use Data::Dumper;

my $PROG = basename $0;

my %options;
%options = (reference => "/data/hg19/hg19_pgdx.fa");
GetOptions(\%options,
  'reference|f=s')
or die "Usage: $PROG [--reference FILENAME]\n";

my $reference_filename = $options{'reference'};

my @mutation_data;
while (<>) {
  chomp;
  my @fields = split /\t/;
  my ($cuid, $score, $type, $t_coverage, $t_alt_depth, $t_af, $n_coverage, $n_alt_depth, $n_af) = @fields;
  my ($chr, $lpos, $rpos, $ref, $alt) = ($cuid =~ /^(chr[^.]+\.fa):(\d+)-(\d+)_([ACGT]*)_([ACGT]*)/);
  my %mutation = (
    chrom => $chr,
    type => $type,
    refseq => $ref,
    altseq => $alt,
    cuid => $cuid,
    score => $score,
    t_coverage => $t_coverage,
    t_alt_depth => $t_alt_depth,
    t_af => $t_af,
    n_coverage => $n_coverage,
    n_alt_depth => $n_alt_depth,
    n_af => $n_af
  );

  # Crazy math follows
  # insertions before base X occupy interval [X + 0.1, X + 0.2]
  # other vars from X to Y occupy interval   [X + 0.3, Y + 0.9]
  # So:
  #   11-11_A_G occupies [11.3, 11.9]
  #   11-12_AT_ occupies [11.3, 12.9]
  #   11-11__TG occupies [11.1, 11.2]
  #   11-11_A_TG should occupy [11.3, 11.9], but may occupy [11.1, 11.9]
  #     or [11.3, 12.2] depending on how merger occurs:
  #   11-11__T + 11-11_A_G -> [11.1,11.2] + [11.3,11.9] = [11.1,11.9]
  #   11-11_A_T + 12-12__G -> [11.3,11.9] + [12.1,12.2] = [11.3,12.2]
  #   Merging code should force the insertion + other combos to be standardized
  push @mutation_data, {
    coord => ($type eq "INS" ? ($lpos + 0.1) : ($lpos + 0.3)),
    start => 1,
    %mutation
  };
  push @mutation_data, {
    coord => ($type eq "INS" ? ($lpos + 0.2) : ($rpos + 0.9)),
    start => 0,
    %mutation
  };
}
@mutation_data = sort {
  $a->{chrom} cmp $b->{chrom} ||
  $a->{coord} <=> $b->{coord} ||
  $a->{start} <=> $b->{start} ||
  $a->{cuid} cmp $b->{cuid}
} @mutation_data;

# Overlap checking - if two called variants overlap, we warn that results might be funky
for my $idx (0 .. $#mutation_data) {
  if ($idx % 2 == 1) {
    if ($mutation_data[$idx]->{cuid} ne $mutation_data[$idx - 1]->{cuid}) {
      warn "$PROG: overlapping variants $mutation_data[$idx]->{cuid} and $mutation_data[$idx-1]->{cuid}\n";
    }
  }
}

# Removal of dominated mutations
# Proceeding over mutation data list (a position-sorted list of interval start/end
# events), any time an overlap is detected (i.e., depth > 1 interval),
# pick highest scoring mutation and declare others as "dominated"
# (scheduled for removal later).
# Mutations with identical scores are sorted with substitutions dominating
# deletions, and deletions dominating insertions; identical scoring mutations
# of the same type are then sorted by ChangeUID to maintain determinism.
my %dominated_mutations;
my %covered_mutations;  # Keep track of intervals we've seen starts for w/o encountering ends yet
my %TYPE_MAP = (SBS => 3, DEL => 2, INS => 1);
for my $mutation (@mutation_data) {
  if ($mutation->{start}) {
    $covered_mutations{$mutation->{cuid}} = $mutation;
  }
  else {
    if (! exists $covered_mutations{$mutation->{cuid}}) {
      die "$PROG: programming error, mutation interval $mutation->{cuid} ended without beginning!\n";
    }
    delete $covered_mutations{$mutation->{cuid}};
  }
  if (keys %covered_mutations > 1) {
    my @mutations = map { $_->[0] }
                    sort { $a->[1] <=> $b->[1] || $a->[2] <=> $b->[2] || $a->[0] cmp $b->[0] }
                    map {
                      [$_->{cuid}, $_->{score}, $TYPE_MAP{$_->{type}}]
                    } values %covered_mutations;
    pop @mutations;  # Remove dominating mutation from list
    $dominated_mutations{$_}++ for @mutations;
  }
}

my @processing_queue;
for (@mutation_data) {
  next if exists $dominated_mutations{$_->{cuid}};
  if ($_->{start}) {
    my %queue_entry;
    for my $key (qw/chrom type refseq altseq cuid score t_alt_depth t_coverage t_af n_alt_depth n_coverage n_af/) {
      $queue_entry{$key} = $_->{$key};
    }
    $queue_entry{lpos} = $_->{coord};
    $queue_entry{rpos} = ($_->{type} eq "INS" ? $_->{coord} + 0.1 : $_->{coord} + length($_->{refseq}) - 0.4);
    push @processing_queue, \%queue_entry;
  }
}

my $mergeable_mutation;
while (@processing_queue) {
  my $first = shift @processing_queue;
  if (defined $mergeable_mutation) {
    my $merged = merge_mutations($mergeable_mutation, $first);
    unshift @processing_queue, $merged;
    undef $mergeable_mutation;
    next;
  }
  if (@processing_queue && $processing_queue[0]->{chrom} eq $first->{chrom} && $processing_queue[0]->{lpos} < $first->{rpos} + 1.5) {
    $mergeable_mutation = $first;
    next;
  }
  else {
    print_mutation($first);
  }
}

sub merge_mutations {
  my ($mut1, $mut2) = @_;
  my %merged = %$mut1;
  $merged{merged} = 1;
  $merged{lpos} = int($merged{lpos}) + 0.3;
  $merged{rpos} = $mut2->{type} eq "INS" ? int($mut2->{rpos} - 1) + 0.9 : int($mut2->{rpos}) + 0.9;
  $merged{type} = "CMP";
  my $gapseq = "";
  if ($mut1->{rpos} + 0.5 < $mut2->{lpos}) {
    my $gap1 = int($mut1->{rpos} + 1);
    if ($mut1->{type} eq "INS") { $gap1-- }
    my $gap2 = int($mut2->{lpos} - 1);
    my $gaplen = $gap2 - $gap1 + 1;
    $gapseq = `echo "$merged{chrom}\t@{[$gap1 - 1]}\t$gap2" | bedtools getfasta -fi $reference_filename -bed - -fo /dev/fd/1 | tail -1`;
    chomp $gapseq;
    $gapseq = uc $gapseq;
  }
  $merged{refseq} .= $gapseq . $mut2->{refseq};
  $merged{altseq} .= $gapseq . $mut2->{altseq};
  $merged{cuid} = $merged{chrom} . ":" . int($merged{lpos}) . "-" . int($merged{rpos}) . "_$merged{refseq}_$merged{altseq}";
  for my $key (qw/score t_alt_depth t_coverage t_af n_alt_depth n_coverage n_af/) {
    $merged{$key} = min($mut1->{$key}, $mut2->{$key});
  }
  return \%merged;
}

sub print_mutation {
  my $mutation_ref = shift;
  my %mutation = %$mutation_ref;
  my $str = join("\t", @mutation{qw/cuid score type t_coverage t_alt_depth t_af n_coverage n_alt_depth n_af/});
  print $str . "\n";
}
