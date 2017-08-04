#!/usr/bin/perl
use strict;
use warnings;

my ($oldFile, $newFile, $outpath) = @ARGV;
my $changes_script = "/mnt/user_data/astangl/compareChanges/compareChanges_plasma/compareChanges_Plasma";
my $outdir = `basename $newFile`;
my @temp = split(/\./, $outdir);
$outdir = $temp[0];
my @temp2 = split(/_/, $outdir);
$outdir = $temp2[0] . "_" . $temp2[1] . "_" . $temp2[2];
$outdir = "$outpath/$outdir";
`mkdir -p $outdir`;

my $command = qx(perl $changes_script --oldfile=$oldFile --newfile=$newFile --oldversion=1 --newversion=2 --printsummary  --outdir=$outdir);
`cp $oldFile $newFile $outdir`;
print $command;
