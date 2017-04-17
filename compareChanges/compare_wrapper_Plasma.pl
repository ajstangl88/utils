#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev);

my %options = ();
GetOptions (\%options,
        'input_file=s',
        'mapping_file=s',
        'help|h') || pod2usage();


my $infile= $options{'input_file'};

my @input_array;
open (IFH, "$infile") or die "Cannot open $infile $!\n";
my $mappingfile = $options{'mapping_file'};
my $headerline = <IFH>;

while (my $line = <IFH>) {
	chomp $line;
	@input_array = split('\t',$line);
	my $oldfile_loc = $input_array[0];
	my $oldfile_name = $input_array[1];
	my $run_name = $input_array[2];
	my $newfile_loc = $input_array[3];
	my $newfile_name = $input_array[4];
	my $run_name2 = $input_array[5];
	my $out_dir = $input_array[6];

	my $cmd = qx(perl comparePairMaker_Plasma.pl --sample_location1=$oldfile_loc --sample_name1=$oldfile_name  --run_name1=$run_name --sample_location2=$newfile_loc --sample_name2=$newfile_name --run_name2=$run_name2 --outdir=$out_dir --mapping_file=$mappingfile);
	    print "$cmd\n";
}


