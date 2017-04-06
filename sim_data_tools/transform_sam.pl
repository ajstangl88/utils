#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use File::Basename;

my $PROG = basename $0;
my @bar_codes = qw/ ACGTAT ACTGAC AGCATT CATGCT CGTATG CTACGT GACTAT GATCAT GCATGC TACTGC TCTGTG TGACTA /;
my $num_duplicates = 1;

=cut
print <<'__EOF__';
@HD	VN:1.4
@SQ	SN:chr1.fa	LN:249250621
@SQ	SN:chr2.fa	LN:243199373
@SQ	SN:chr3.fa	LN:198022430
@SQ	SN:chr4.fa	LN:191154276
@SQ	SN:chr5.fa	LN:180915260
@SQ	SN:chr6.fa	LN:171115067
@SQ	SN:chr7.fa	LN:159138663
@SQ	SN:chr8.fa	LN:146364022
@SQ	SN:chr9.fa	LN:141213431
@SQ	SN:chr10.fa	LN:135534747
@SQ	SN:chr11.fa	LN:135006516
@SQ	SN:chr12.fa	LN:133851895
@SQ	SN:chr13.fa	LN:115169878
@SQ	SN:chr14.fa	LN:107349540
@SQ	SN:chr15.fa	LN:102531392
@SQ	SN:chr16.fa	LN:90354753
@SQ	SN:chr17.fa	LN:81195210
@SQ	SN:chr18.fa	LN:78077248
@SQ	SN:chr19.fa	LN:59128983
@SQ	SN:chr20.fa	LN:63025520
@SQ	SN:chr21.fa	LN:48129895
@SQ	SN:chr22.fa	LN:51304566
@SQ	SN:chrX.fa	LN:155270560
@SQ	SN:chrY.fa	LN:59373566
@SQ	SN:chrM.fa	LN:16571
__EOF__
=cut

while (<>) {
  print and next if /^@/;
  chomp;
  my @fields = split /\t/;
  my $qname = $fields[0];
  my $bar_code = $bar_codes[ unpack("%8W*", $qname) % @bar_codes ];
  push(@fields, "BC:Z:" . $bar_code);
  print join("\t", @fields) . "\n";
}
