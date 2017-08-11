#!/usr/bin/perl
use strict;
use File::Basename;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev);
use Pod::Usage;
use Data::Dumper;
use Cwd 'abs_path';

my %options = ();
GetOptions (\%options,
	'sample_location1=s',
	'sample_name1=s',
	'run_name1=s',
	'sample_location2=s',
	'sample_name2=s',
	'run_name2=s',
	'mapping_file=s',
	'outdir=s', 
	 'help|h') || pod2usage();

my $start = $^T;

# The location of the script
my $scriptPath = dirname(abs_path($0));

# The location of the the sample on the pod /data*-pgdx-pod*
my $sample_location = $options{'sample_location1'};

# Name of the sample
my $sample_name = $options{'sample_name1'};

# $sample_loc/pipeline/$sample.pipeline.config"
my $run_name = $options{'run_name1'};


my $sample_location2 = $options{'sample_location2'};
my $sample_name2 = $options{'sample_name2'};
my $run_name2 = $options{'run_name2'};


my $map = $options{'mapping_file'};
my $outdir = "$options{'outdir'}";
my $stdout = "$outdir/$sample_name.stderr";
my %hash_48;
my %hash_47;
my %hash_45;

my $protocol_version1 = findVersion($sample_location,$run_name);
my $protocol_version2 = findVersion($sample_location2,$run_name2);
my $tumor_fraction1 = findTumorFraction($sample_location,$run_name);
my $tumor_fraction2 = findTumorFraction($sample_location2,$run_name2);

print "Comparing a $protocol_version1 run with $protocol_version2 run\n";
print "Comparing Tumor Fraction of $tumor_fraction1 with $tumor_fraction2\n";


my %hash1 = createHash($sample_location, $sample_name, $protocol_version1,$map, $run_name);
my %hash2 = createHash($sample_location2, $sample_name2, $protocol_version2, $map, $run_name2);


print "Creating Output Directory: $outdir\n";
if (-d $outdir ) {
#	 print "This output directory already exists please check and rerun\n";
#	exit;
}

else {
	 print `mkdir -p \"$outdir\"`;
}


foreach my $hash_key (sort keys %hash1) {
	 if ($hash_key =~ /STR_/) {
		  (my $old_sample_name = $sample_name) =~ s/Seq2/Str2/g;
		  (my $old_file_name = basename $hash1{$hash_key}) =~  s/Seq2/Str2/g;

		  my $oldname = "$sample_location/$old_sample_name/$old_file_name";

		  (my $new_sample_name = $sample_name2) =~ s/Seq2/Str2/g;
		  (my $new_file_name = basename $hash1{$hash_key}) =~  s/Seq2/Str2/g;

		  my $newname = "$sample_location2/$new_sample_name/$new_file_name";
		  my $run_command = qx(perl compareChanges_Plasma  --oldfile=\"$oldname\" --newfile=\"$newname\" --oldversion=$protocol_version1 --newversion=$protocol_version2 --printsummary  --outdir=\"$outdir\" --ignorecols=\"AddlInfo,Sample Name,dbSNP138: Sample,Report: Sample Name,dbSNP: Sample,Row,sample,#Prefix\" 2>> $stdout);
	 }

	 ## Need to access if the file is gunzipped. If so cat it into a new file.
	 if ($hash_key eq "ALL_CHANGES" || $hash_key eq "ALLCHANGES_CNASNPS") {
		  my $oldname = "$scriptPath/" . basename($hash1{$hash_key});
		  my $newname = "$scriptPath/" . basename($hash2{$hash_key});

		  ## Copy the files locally... Approx 1 min for opperation to complete
		  print "Copying " . basename($oldname) . " and " . basename($newname) . " to $scriptPath\n";
		  my $copy = qx(cp $hash1{$hash_key} $oldname; cp $hash2{$hash_key} $newname);


		  my $cmd = qx(perl compareChanges_Plasma  --oldfile=\"$oldname\" --newfile=\"$newname\" --oldversion=$protocol_version1 --newversion=$protocol_version2 --printsummary  --outdir=\"$outdir\" --ignorecols=\"AddlInfo,Sample Name,dbSNP138: Sample,Report: Sample Name,dbSNP: Sample,Row,sample,#Prefix\" 2>> $stdout);



		  ## Clean up when done
		  my $cleanup = qx(rm -f $oldname $newname);

	 }

	 # Deal with these gzipped files
	 if ($hash1{$hash_key} =~ /.gz/ || $hash2{$hash_key} =~ /.gz/) {
		  (my $oldfile = $hash1{$hash_key}) =~ (s/.gz//g);
		  (my $newfile = $hash2{$hash_key}) =~ (s/.gz//g);
		  $oldfile = "$scriptPath/" . basename($oldfile);
		  $newfile = "$scriptPath/" . basename($newfile);

		  ## Unzip the files and re-direct them to the currect script directory
		  print "Decompressing and Copying " . basename($oldfile) . " and " . basename($newfile) . " to $scriptPath\n";

		  ## Decompress File 1
		  my $zcat1 = qx(zcat $hash1{$hash_key} > $oldfile);


		  ## Decompress File2
		  my $zcat2 = qx(zcat $hash2{$hash_key} > $newfile);

		  
		  ## Perform the commands locally and then clean up
		  my $cmd = qx(perl compareChanges_Plasma  --oldfile=\"$oldfile\" --newfile=\"$newfile\" --oldversion=$protocol_version1 --newversion=$protocol_version2 --printsummary  --outdir=\"$outdir\" --ignorecols=\"AddlInfo,Sample Name,dbSNP138: Sample,Report: Sample Name,dbSNP: Sample,Row,sample,#Prefix\" 2>> $stdout);


		  print "Removing " . basename($newfile) . " and " . basename($oldfile) . " from $scriptPath";
		  my $cleanup = qx(rm -f $newfile $oldfile);


	 }

	 ## No need to zcat things that dont end in .gz
	 else {
		  my $cmd = qx(perl compareChanges_Plasma  --oldfile=\"$hash1{$hash_key}\" --newfile=\"$hash2{$hash_key}\" --oldversion=$protocol_version1 --newversion=$protocol_version2 --printsummary  --outdir=\"$outdir\" --ignorecols=\"AddlInfo,Sample Name,dbSNP138: Sample,Report: Sample Name,dbSNP: Sample,Row,sample,#Prefix\" 2>> $stdout);
		  print "$cmd\n";
	 }
}

CompletionTime();
print "Program has completed please check the output directory: $outdir\n";


sub createHash {
my ($loc,$name,$v,$map_file, $run_name) = @_;
my @headers;
my @info;
my %version_hash;
## opening mapping file
open (IFH, "$map_file") or die "Cannot open $map_file $!\n";
my $header_line=<IFH>;
chomp $header_line;
@headers=split('\t',$header_line);

## open the mapping file
while (my $line = <IFH>) {
	 chomp $line;
	 @info = split('\t',$line);
	 my $key = $info[0];
	 for (my $i=1; $i<=scalar(@headers); $i++) {
		  if ($v eq $headers[$i]) {
				$info[$i] =~ s/\{location\}/$loc/g;
				$info[$i] =~ s/\{Sample_Name\}/$name/g;
			$info[$i] =~ s/\{Run_Name\}/$run_name/g;
				$version_hash{$key} = $info[$i];
		  }
	 }
}
	 return %version_hash;
}


sub findVersion {
	my ($sample_loc,$sample) = @_;	
	my $config_file="$sample_loc/pipeline/$sample.pipeline.config";
	my $version;
	open (IFH, "$config_file") or die "Cannot open $config_file $!\n";

	while (my $line = <IFH>) {
		chomp $line;
			  if ($line =~ /PROTOCOL/) {
					 ($version) = $line =~ /^PROTOCOL\t(.*)/;
				}
	 }
	 return $version;
}

sub findTumorFraction {
		  my ($sample_loc,$sample) = @_;
		  my $config_file="$sample_loc/pipeline/$sample.pipeline.config";
		  my $tf;
		  open (IFH, "$config_file") or die "Cannot open $config_file $!\n";

		  while (my $line = <IFH>) {
					 chomp $line;
					 if ($line =~ /CONFIG\tparams.TUMOR_FRACTION/) {
						  ($tf) = $line =~ /^CONFIG\tparams.TUMOR_FRACTION\t(.*)/;
					 }
		  }
	 return $tf;
} 


sub process_basename {
	 my $filename = shift;
	 my $new_name = basename($filename);
	 return $new_name;
}

sub CompletionTime {
	 my $secs = time - $^T;

	 if ($secs >= 86400 ) {
		  printf "\nTime Elapsed: %d days, %d hours, %d minutes and %d seconds\n", (gmtime 196364)[7, 2, 1, 0];
	 }

	 elsif ($secs >= 3600) {
		  printf "\nTime Elapsed: %d hours, %d minutes and %d seconds\n", (gmtime $secs)[2,1,0];
	 }

	 elsif ($secs >= 60) {
		  printf "\nTime Elapsed: %d minutes, %d seconds\n", (gmtime $secs)[1,0];
	 }

	 else {
		  printf "\nTime Elapsed: %d seconds\n", (gmtime $secs)[0];
	 }

}















