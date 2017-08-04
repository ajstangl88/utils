#!/usr/bin/perl

use strict;
use warnings;
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
	push(@INC, $cwd);
}
#use PGDX;

my ($oldfile, $newfile);

# Integration between Getopt::Long and Pod::Usage to enable help-/man-style output
my $help = 0;
my $man = 0;

GetOptions (
	'old_changes|o=s' => \$oldfile,
	'new_changes|n=s' => \$newfile,
	'help|?' => \$help, man => \$man
) or pod2usage(2);


my $old_hash = get_hash($oldfile, "old");
my $new_hash = get_hash($newfile, "new");

my @lookupVals = (
	"ChangeUID",
	"DistinctCoverage",
	"Supermutant",
	"SupermutantAvg",
	"SupermutantPct",
	"SupermutantCov",
	"Score"
);

my @missing_cuids;
my @gained = @missing_cuids;
my @new_cuids;
my @lost = @new_cuids;
my @header;

my @concodant;
my @data_row;
foreach my $key (natural_sort(keys %$new_hash)) {
	if (exists $old_hash->{$key}) {
		push(@concodant, $key);
	}
}


foreach my $key (natural_sort(keys %$new_hash)) {
	# First loop through the keys in the hash (IE the ChangeUIDs) and check if the ChangeUID is in both files
	if (exists $old_hash->{$key}) {
		# Loop through each header val (Hard coded aboved) and construct a hash data structure with % difference
		my @temp;
		my @temp_header;
		foreach my $element (@lookupVals) {
			# Set the variables that do not currently exist
			my $percent_diff;
			my $outstr;
			my $outheader;
			if ($element eq "ChangeUID") {
				$percent_diff = $new_hash->{$key}->{$element};
				$outstr = $percent_diff;
				$outheader = "ChangeUID";
				push(@temp, $outstr);
				push(@temp_header, $outheader);
			}
			
			my $old_header = "Old $element";
			my $old_val = $old_hash->{$key}->{$element};

			my $new_header = "New $element";
			my $new_val = $new_hash->{$key}->{$element};

			my $percent_header = "% Difference $element";
			$percent_diff = get_diff($old_val, $new_val);
			unless ($element eq "ChangeUID") {
				$outstr = "$old_val\t$new_val\t$percent_diff";
				push(@temp, $outstr);
				$outheader = "$old_header\t$new_header\t$percent_header";
				push(@temp_header, $outheader);
			}
		}
		my $val_str =  join("\t", @temp);
		push(@data_row, $val_str);
		my $temp_header_str = join("\t", @temp_header[0..6]);
		push(@header, $temp_header_str);
	}

	# Push the Missing CUIDS to another list -- Actually these are the gained mutations
	else {
		push(@missing_cuids, $key);
	}
}

# Then do the old hash -- Used to find the missing CUIDs
foreach my $key (keys %$old_hash) {
	unless (exists $new_hash->{$key}) {
		push(@new_cuids, $key)
	}
}

print $header[0];
print "\n";
my $out = join("\n", @data_row);
print "$out\n";


sub hash_to_tsv {
	my $hash = shift;
	my @array = @_;
	my @fields;
	# Loop through the hash using sorted CUID and push the keys to the fields array
	foreach my $cuid (@array) {
		foreach my $field (keys %{$hash->{$cuid}}) {
			unless ($field ~~ @fields) {
				push @fields, $field
			}
		}
	}
	# Sort and Join the Array
	my @sorted_fields = natural_sort(@fields);
	my $out_fields = join("\t", @sorted_fields);
	print "$out_fields\n";
	# Then loop through the hash again, push to a temp array
	foreach my $cuid (@array) {
		my @row;
		foreach my $field (@sorted_fields) {
			my $val = $hash->{$cuid}->{$field};
			push(@row, $val);
		}
		# Join the temp array in the outter loop and print it
		my $out_string = join("\t", @row);
		print "$out_string\n";
	}
}


sub get_diff {
	my $old_val = shift;
	my $new_val = shift;
	my $retval;
	if ($new_val =~ /^\d+.*/ && $old_val =~ /^\d+.*/) {
		my $num = abs($old_val - $new_val);
		if ($num eq 0) {
			return 0;
		}
		my $denom = ($old_val + $new_val) / 2;
		
		if ($denom eq 0) {
			return "0";
		}
		$retval = $num / $denom;
		$retval = $retval * 100;
	}
	else {
		$retval = "N/A";
	}
	return $retval;
}


sub get_hash {
	my $filename = shift;
	my $type = shift;
	my $result_hash = { };
	my $i = 0;
	open IN, "<$filename" or die "Unable to Open $filename";
	my $header = <IN>;
	my @header_fields = split(/\t/, $header);
	my $header_lookup = { };
	map {$header_lookup->{$_} = $i;
		$i++} @header_fields;
	my ($ChangeUID, $DistinctCoverage, $Supermutant, $SupermutantAvg, $SupermutantPct, $SupermutantCov, $Score);
	while (my $row = <IN>) {
		chomp $row;
		my @vals = split(/\t/, $row);
		$ChangeUID = $vals[$header_lookup->{'ChangeUID'}];
		$result_hash->{$ChangeUID}->{'ChangeUID'} = $ChangeUID;
		
		$DistinctCoverage = $vals[$header_lookup->{'DistinctCoverage'}];
		$result_hash->{$ChangeUID}->{'DistinctCoverage'} = $DistinctCoverage;
		
		$Supermutant = $vals[$header_lookup->{'Supermutant'}];
		$result_hash->{$ChangeUID}->{'Supermutant'} = $Supermutant;
		
		$SupermutantAvg = $vals[$header_lookup->{'SupermutantAvg'}];
		$result_hash->{$ChangeUID}->{'SupermutantAvg'} = $SupermutantAvg;
		
		$SupermutantPct = $vals[$header_lookup->{'SupermutantPct'}];
		$result_hash->{$ChangeUID}->{'SupermutantPct'} = $SupermutantPct;
		
		$SupermutantCov = $vals[$header_lookup->{'SupermutantCov'}];
		$result_hash->{$ChangeUID}->{'SupermutantCov'} = $SupermutantCov;
		
		if ($type eq 'old') {
			$Score = "N/A";
			$result_hash->{$ChangeUID}->{'Score'} = $Score;
		}
		else {
			$Score = $vals[$header_lookup->{'Score'}];
			$result_hash->{$ChangeUID}->{'Score'} = $Score;
		}
	}
	close IN;
	return $result_hash;
}


sub getChangesHeaderIndex {
	my $config = shift;
	my @headers = @{$config->{headers}};

	my $headerslookup;
	map {$headerslookup->{$_}='YES'}@headers;
	open IN, "<$config->{changes}";
	my $head = <IN>; close IN;
	if(!$head) {
		die "Couldn't get the header for $config->{changes} $head\n";
	}
	chomp $head;
	my @hvals = split(/\t/,$head);
	for(my $i =0;$i<@hvals;$i++) {
		if($headerslookup->{$hvals[$i]}) {
			$headerslookup->{$hvals[$i]} = $i;
		}
	}
	return $headerslookup;
}


sub natural_sort {
	my @temp_array = @_;
	my @sorted= grep {s/(^|\D)0+(\d)/$1$2/g,1} sort grep {s/(\d+)/sprintf"%06.6d",$1/ge,1} @temp_array;
	return @sorted;
}

