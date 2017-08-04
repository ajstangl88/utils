#!/usr/bin/perl
use strict;
use warnings;

my ($oldFile, $newFile) = @ARGV;
my $changes_script = "/mnt/user_data/astangl/compareChanges/compareChanges_plasma/compareChanges_Plasma";
my $outdir = `basename $newFile`;
my @temp = split(/\./, $outdir);
$outdir = $temp[0];
my $command = qx(perl $changes_script --oldfile=\"$oldFile\" --newfile=\"$newFile\" --oldversion=1 --newversion=2 --printsummary  --outdir=\"$outdir\" --ignorecols=\"AddlInfo,Sample Name,dbSNP138: Sample,Report: Sample Name,dbSNP: Sample,Row,sample,#Prefix\" 2>> /dev/null);
`cp $oldFile $newFile $outdir`;
print $command;