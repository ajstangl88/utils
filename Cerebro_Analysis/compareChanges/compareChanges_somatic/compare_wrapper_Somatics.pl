use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev);
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev);
use Data::Dumper;
use File::Glob;
use File::Basename;
use Cwd 'abs_path';

my %options = ();
GetOptions (\%options,
		'input_file=s',
		'mapping_file=s',
		'help|h') || pod2usage();


my $scriptPath = dirname(abs_path($0));
my $infile= $options{'input_file'};

my @input_array;
open (IFH, "$infile") or die "Cannot open $infile $!\n";
my $mappingfile = $options{'mapping_file'};
my $headerline = <IFH>;


my $i = 1;
while (my $line = <IFH>) {
		chomp $line;
		@input_array = split('\t',$line);
		my $oldfile_loc = $input_array[0];
		my $oldfile_name = $input_array[1];
		my $run_name = $input_array[2];
		my $newfile_loc = $input_array[3];
		my $newfile_name = $input_array[4];
		my $run_name2 = $input_array[5];
#		my $out_dir = $input_array[6];
		my $out_dir = "$scriptPath/Results_CompareChanges/$run_name2$i";
		$i++;
		my $run_compare = compare_changes($oldfile_loc, $oldfile_name, $run_name, $newfile_loc, $newfile_name, $run_name2, $out_dir, $mappingfile);
#		my $run_cna = compare_cna($oldfile_loc, $newfile_loc, $out_dir);
#		my $run_summary = compare_summary($oldfile_loc, $newfile_loc, $out_dir);
#		my $run_rearrangments = compare_rearrangments($oldfile_loc, $newfile_loc, $out_dir);
#		my $run_msi = compare_msi($oldfile_loc, $newfile_loc, $out_dir);


}

sub compare_changes {
	## This function constructs the string to execute for compare_changes.
	my $sample_location1 = shift;
	my $sample_name1 = shift;
	my $run_name1 = shift;

	my $sample_location2 = shift;
	my $sample_name2 = shift;
	my $run_name2 = shift;

	my $outdir = shift;
	my $mapping_file = shift;

	my $command = "perl $scriptPath/comparePairMaker_Somatics.pl --sample_location1=$sample_location1 --sample_name1=$sample_name1  --run_name1=$run_name1 --sample_location2=$sample_location2 --sample_name2=$sample_name2 --run_name2=$run_name2 --outdir=$outdir --mapping_file=$mapping_file";
	print qx($command);
	
}

sub compare_cna {
	my $oldfile_loc = shift;
	my $newfile_loc = shift;
	my $outdir = shift;
	
	## Loop through the possible files we might want to compare and set the varibles to reflect the file.
	
	

#
	`mkdir -p $outdir/CNA_comparison`;
	`touch $outdir/CNA_comparison/out`;

	my $oldfile = find_file("$oldfile_loc/TN/", "*.Fcna_snps.txt");
	my $newfile = find_file("$newfile_loc/TN/", "*.Fcna_snps.txt");
	my $command_string = "perl $scriptPath/compareChanges_Somatics --oldfile=$oldfile --newfile=$newfile --uniqcol=\"Lookup ID\" --oldversion=plasma-3.4.0b4 --newversion=Plasma_RearrangementsThresholds-3.5.0b5 --printsummary --outdir=$outdir/CNA_comparison --ignorecols=\"AddlInfo,Sample Name,dbSNP138: Sample,Report: Sample Name,dbSNP: Sample,Row\" >> $outdir/CNA_comparison/out 2>&1";
	print qx($command_string);
	
	$oldfile = find_file("$oldfile_loc/UN/", "*.Fcna_snps.txt");
	$newfile = find_file("$newfile_loc/UN/", "*.Fcna_snps.txt");
	$command_string = "perl $scriptPath/compareChanges_Somatics --oldfile=$oldfile --newfile=$newfile --uniqcol=\"Lookup ID\" --oldversion=plasma-3.4.0b4 --newversion=Plasma_RearrangementsThresholds-3.5.0b5 --printsummary --outdir=$outdir/CNA_comparison --ignorecols=\"AddlInfo,Sample Name,dbSNP138: Sample,Report: Sample Name,dbSNP: Sample,Row\" >> $outdir/CNA_comparison/out 2>&1";
	print qx($command_string);

	$oldfile = find_file("$oldfile_loc/TN_TO/", "*.Fcna_snps.txt");
	$newfile = find_file("$newfile_loc/TN_TO/", "*.Fcna_snps.txt");
	$command_string = "perl $scriptPath/compareChanges_Somatics --oldfile=$oldfile --newfile=$newfile --uniqcol=\"Lookup ID\" --oldversion=plasma-3.4.0b4 --newversion=Plasma_RearrangementsThresholds-3.5.0b5 --printsummary --outdir=$outdir/CNA_comparison --ignorecols=\"AddlInfo,Sample Name,dbSNP138: Sample,Report: Sample Name,dbSNP: Sample,Row\" >> $outdir/CNA_comparison/out 2>&1";
	print qx($command_string);


}

sub compare_summary {
	my $oldfile_loc = shift;
	my $newfile_loc = shift;
	my $out_dir = shift;

	## Make the Output directory
	`mkdir -p $out_dir/Summary_sheet`;
	my $summary = qx(python $scriptPath/coverage_comp.py -f1 $oldfile_loc -f2 $newfile_loc -p1 .02 -p2 .02 -o $out_dir/Summary_sheet/summary_sheet_comparison.txt);
	my $summaryTest = "$out_dir/Summary_sheet/summary_sheet_tests.txt";
	open (my $sum_handle, '>', $summaryTest) or die "Could not open file '$summaryTest' $!";
	print $sum_handle "$summary";
	close $sum_handle;
}


sub compare_msi {

	## This sub-routine performs a diff on the MSI files
	my $oldfile_loc = shift;
	my $newfile_loc = shift;
	my $out_dir = shift;
	## Make the Output directory
	`mkdir -p $out_dir/MSI`;

	my $msifile = "$out_dir/MSI/MSI_Comparison.txt";
	open(my $msi, '>', $msifile) or die "Could not open file '$msifile' $!";
	my @old_msi = glob("$oldfile_loc/msi/*.msi.txt");
	my @new_msi = glob("$newfile_loc/TN/*.msi.txt");
	my $msi_command = "diff $old_msi[0] $new_msi[0]";
	print $msi "$old_msi[0]\t$new_msi[0]\n";
	print $msi `$msi_command`;
	
	@old_msi = glob("$oldfile_loc/msi/*.msi.txt");
	@new_msi = glob("$newfile_loc/TN_TO/*.msi.txt");
	print $msi "$old_msi[0]\t$new_msi[0]\n";
	print $msi `$msi_command`;
	
	
	@old_msi = glob("$oldfile_loc/msi/*.msi.txt");
	@new_msi = glob("$newfile_loc/UN/*.msi.txt");
	print $msi "$old_msi[0]\t$new_msi[0]\n";
	print $msi `$msi_command`;
	
	close $msi;
}

sub compare_rearrangments {
	##Proccess Rearrangements Differences
	my $oldfile_loc = shift;
	my $newfile_loc = shift;
	my $out_dir = shift;

	`mkdir -p $out_dir/Rearrangements`;
	my $filename = "$out_dir/Rearrangements/Rearrangements_Comparison.txt";
	open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
	my @old_rear = glob("$oldfile_loc/pare/*.Rearrangements.txt");
	my @new_rear = glob("$newfile_loc/pare/*.Rearrangements.txt");
	my $command = "diff $old_rear[0] $new_rear[0]";
	print $fh "$old_rear[0]\t$new_rear[0]\n";
	print $fh `$command`;
	close $fh;
}

sub find_file {
	my $indir = shift;
	my $search = shift;
	my @ret_file = glob("$indir/$search");
	return $ret_file[0];
}
