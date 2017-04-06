#!/usr/bin/perl

use strict;
use warnings;
use Fatal qw/open close/;
use List::Util qw/min max/;
use Getopt::Long;
use File::Basename;

my $PROG = basename $0;

my $first_run = 1;
my $read_length = 100;
my $list_filename = "";
my $fake_normal = 0;
GetOptions(
  "first-run!" => \$first_run,
  "read-length=i" => \$read_length,
  "list-filename=s" => \$list_filename,
  "fake-normal" => \$fake_normal
) or die "$PROG: error parsing command line\n";

chomp(my @common_cuids = `cat $list_filename`);
my %common_cuid_hash = map {($_ => 1)} @common_cuids;

while (<>) {
  chomp;
  my @fields = split /\t/;
  my ($cuid, $tumor_bqual_mean, $tumor_fwd_cov, $tumor_rev_cov,
    $tumor_distinct_cov, $tumor_distinct_pairs, $tumor_maf, $variant_type,
    $normal_distinct_cov, $normal_distinct_pairs, $normal_maf, $poly_n,
    $poly_nn, $poly_nnn, $polymut, $dust,
    $rm_score, $tumor_rms_mapq, $normal_rms_mapq, $tumor_nerd_mean,
    $tumor_nerd_sd, $tumor_mutant_rms_mapq, $normal_mutant_rms_mapq, $gc_count,
    $at_count, $rmd_score, $normal_bqual_mean, $fisher_left,
    $fisher_right, $fisher_twotail, $tumor_mismatch_avg, $tumor_mutant_mismatch_avg) =
  @fields[0, 11, 12, 13,
      14, 16, 17, 18,
      31, 36, 33, 69,
      70, 71, 72, 73,
      74, 76, 77, 78,
      79, 80, 81, 82,
      83, 84, 85, 86,
      87, 88, 63, 64];
  next unless $common_cuid_hash{$cuid};

  if ($fake_normal) {
    $normal_distinct_cov = int max($tumor_distinct_cov, $normal_distinct_cov * 1.5, 30);
    $normal_distinct_pairs = 0;
    $normal_maf = 0;
    $normal_rms_mapq = $tumor_rms_mapq;
    $normal_mutant_rms_mapq = $normal_rms_mapq;
    $normal_bqual_mean = 40;
    $fisher_left = 0;
    $fisher_right = 1;
    $fisher_twotail = 0;
  }

  $variant_type =~ s/^Homo-//;
  $cuid =~ s/\(null\)//;
  my $indel_length = 0;
  if ($variant_type ne "SBS") {
    my ($from_seq, $to_seq) = ($cuid =~ /_([^_]*)_([^_]*)$/);
    $indel_length = abs(length($from_seq) - length($to_seq));
  }
  my $strand_prop_hat = min($tumor_fwd_cov, $tumor_rev_cov) / ($tumor_fwd_cov + $tumor_rev_cov);
  my $strand_bias_Z = sprintf '%g', 2 * sqrt($tumor_distinct_pairs) * (0.5 - $strand_prop_hat);
  # Error for 50% CI
  my $strand_bias_E = sprintf '%g', 0.6745 / (2 * sqrt($tumor_distinct_pairs));
  # Lower bound of 50% CI
  my $strand_bias_r1 = sprintf '%g', max(0, $strand_prop_hat - $strand_bias_E);
  # Upper bound of 50% CI
  my $strand_bias_r2 = sprintf '%g', min(1, $strand_prop_hat + $strand_bias_E);
  my $strand_bias = sprintf '%g', abs(0.5 - $tumor_fwd_cov / ($tumor_fwd_cov + $tumor_rev_cov));
  my $tvc_qual_estimate = sprintf '%g', log($tumor_distinct_pairs + 1) * $tumor_bqual_mean;
  my $nvc_qual_estimate = sprintf '%g', log($normal_distinct_pairs + 1) * $normal_bqual_mean;
  my $mapq_sample_diff = sprintf '%g', abs($tumor_rms_mapq - $normal_rms_mapq);
  my $mapq_mutant_diff = sprintf '%g', ($tumor_rms_mapq - $tumor_mutant_rms_mapq);
  my $important_read_count = sprintf '%g', ($tumor_distinct_pairs + $normal_distinct_cov);
  my $gc_percent = sprintf '%g', ($gc_count / ($gc_count + $at_count));

  $tumor_nerd_mean = sprintf '%g', $tumor_nerd_mean / $read_length;
  $tumor_nerd_sd = sprintf '%g', $tumor_nerd_sd / $read_length;

  my @out_fields = (
    $tvc_qual_estimate, $nvc_qual_estimate,
    $tumor_distinct_cov, $tumor_distinct_pairs, $tumor_maf,
    $normal_distinct_cov, $normal_distinct_pairs, $normal_maf,
    $strand_bias_Z, $strand_bias_r1, $strand_bias_r2,
    $tumor_bqual_mean, $normal_bqual_mean,
    $tumor_nerd_mean, $tumor_nerd_sd,
    $tumor_rms_mapq, $normal_rms_mapq,
    $tumor_mutant_rms_mapq, $normal_mutant_rms_mapq,
    $tumor_mismatch_avg, $tumor_mutant_mismatch_avg,
    $mapq_sample_diff, $mapq_mutant_diff, $important_read_count,
    $fisher_left, $fisher_right, $fisher_twotail
  );
  if ($first_run) {
    unshift @out_fields, $variant_type, $indel_length, $poly_n, $poly_nn, $poly_nnn, $polymut, $dust, $rm_score, $rmd_score, $gc_percent;
  }
  unshift @out_fields, $cuid;
  print join("\t", @out_fields) . "\n";
}
