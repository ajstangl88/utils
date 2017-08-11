#!/usr/bin/perl

use strict;
use File::Basename qw(dirname);
use File::Spec;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev auto_version);
use Pod::Usage;
use Data::Dumper;

# Establish current working directory if required
my ($cwd);
BEGIN {
    # Set the version for Getopt::Long auto_version and general version checking
    our $VERSION = 0.01;
    $cwd = File::Spec->rel2abs(__FILE__);
    $cwd = dirname($cwd);
    # Add cwd to @INC, often required for use of PGDX::* modules
    push(@INC, $cwd);
}
use PGDX;


my ($cuid_list,$changesfile) = @ARGV;

# Set the Result Hash Table
my $result = {};
my @cuid = ();
my $temp = {};
my $header_lookup;
eval {
    $header_lookup = PGDX::getChangesHeaderIndex({
        changes => $changesfile,
        headers => [
            'ChangeUID',
            'Score',
            'DistinctCoverage',
            'Supermutant',
            'SupermutantAvg',
            'SupermutantPct',
            'SupermutantCov',
            'GeneName'
        ] })
};


# Proccess the CUID List and build the hash
open IN1, "<$cuid_list" or die "Couldn't open $cuid_list\n";
my @row;
while (my $line = <IN1>) {
    chomp $line;
    $result->{$line} = undef;
    push(@cuid, $line);

}
close IN1;



my ($ChangeUID, $Score, $DistinctCoverage, $Supermutant, $SupermutantAvg, $SupermutantPct, $SupermutantCov, $GeneName);
open IN, "<$changesfile" or die "Couldn't open $changesfile\n";
while (my $line = <IN>) {
    chomp $line;

    @row = split(/\t/, $line);
    my $score_row = $header_lookup->{'Score'};
    $ChangeUID = $row[$header_lookup->{'ChangeUID'}];

    unless ($score_row) {
        $Score = "N/A";
    }
    else {
        $Score = $row[$header_lookup->{'Score'}];
    }
    $DistinctCoverage = $row[$header_lookup->{'DistinctCoverage'}];
    $Supermutant = $header_lookup->{'Supermutant'};
    $SupermutantAvg = $row[$header_lookup->{'SupermutantAvg'}];
    $SupermutantPct = $row[$header_lookup->{'SupermutantPct'}];
    $SupermutantCov = $row[$header_lookup->{'SupermutantCov'}];
    $GeneName = $row[$header_lookup->{'GeneName'}];


    foreach my $key (keys %$result) {
        if ($key eq $ChangeUID) {
            $result->{$key}->{'ChangeUID'} = $ChangeUID;
            $result->{$key}->{'DistinctCoverage'} = $DistinctCoverage;
            $result->{$key}->{'Supermutant'} = $Supermutant;
            $result->{$key}->{'SupermutantAvg'} = $SupermutantAvg;
            $result->{$key}->{'SupermutantPct'} = $SupermutantPct;
            $result->{$key}->{'SupermutantCov'} = $SupermutantCov;
            $result->{$key}->{'GeneName'} = $GeneName;
            $result->{$key}->{'Score'} = $Score;
        }
    }
}

close IN;

my @outcol;
my $outstr;
my @hvals = ('ChangeUID', 'Score', 'DistinctCoverage','Supermutant', 'SupermutantAvg','SupermutantPct', 'SupermutantCov', 'GeneName');
print join("\t", @hvals) . "\n";
    foreach my $key (@cuid) {
    my @damn;
    $temp = $result->{$key};
    foreach my $k (@hvals) {
        push(@damn, $temp->{$k});
    }
    $outstr =  join("\t",@damn) . "\n";
    push(@outcol, $outstr);
}

print @outcol;