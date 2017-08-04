use strict;
use File::Basename;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev);
use Pod::Usage;
use Data::Dumper;

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


my $sample_location = $options{'sample_location1'};
my $sample_name = $options{'sample_name1'};
my $run_name1 = $options{'run_name1'};
my $sample_location2 = $options{'sample_location2'};
my $sample_name2 = $options{'sample_name2'};
my $run_name2 = $options{'run_name2'};
my $map = $options{'mapping_file'};
my $outdir = "$options{'outdir'}";
my $stdout = "$outdir/$sample_name.stderr";
my %hash_48;
my %hash_47;
my %hash_45;

my $protocol_version1 = findVersion($sample_location,$run_name1);
my $protocol_version2 = findVersion($sample_location2,$run_name2);
my $tumor_fraction1 = findTumorFraction($sample_location,$run_name1);
my $tumor_fraction2 = findTumorFraction($sample_location2,$run_name2);

#print "Comparing a $protocol_version1 run with $protocol_version2 run\n";
#print "Comparing Tumor Fraction of $tumor_fraction1 with $tumor_fraction2\n";

my %hash1 = createHash($sample_location, $sample_name, $protocol_version1, $map, $run_name1);
my %hash2 = createHash($sample_location2, $sample_name2, $protocol_version2, $map, $run_name2);



print "Creating Output Directory: $outdir\n";
if (-d $outdir ) {
#	print "This output directory already exists please check and rerun\n";
#	exit;
}
else {
	print `mkdir -p \"$outdir\"`;
}



foreach my $hash_key (sort keys %hash1) {
	my $cmd = qx(perl compareChanges_Somatics --oldfile=\"$hash1{$hash_key}\" --newfile=\"$hash2{$hash_key}\" --oldversion=$protocol_version1 --newversion=$protocol_version2 --printsummary  --outdir=\"$outdir\" --ignorecols=\"AddlInfo,Sample Name,dbSNP138: Sample,Report: Sample Name,dbSNP: Sample,Row\" 2>> $stdout);
	CompletionTime();
	print "Program has completed please check the output directory: $outdir\n";
}


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
#	for my $k (keys %version_hash) {
#		print "$k\t $version_hash{$k}\n";
#	}
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













