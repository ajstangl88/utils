package PGDX::FormatDir::PlasmaES;

use strict;
use warnings;
use Carp;
use Data::Dumper;

use PGDX::FormatDir;
use base qw(PGDX::FormatDir);

#
# Realign:
# 	$SAMP.summarysheet.txt                            - > $SAMP.summary.txt
# 	$SAMP.PostBLAT<REF>Changes.txt					  - > $SAMP.TOnly_mutations.txt
# 	$SAMP.pipeline.config                             - > $SAMP.pipeline.config
#
# Also create symlinks to input used.
# 	t_$SAMP.bam
# 	t_$SAMP.bam.bai
# 
# These files will also be reorder and extra columns removed. The order and columns presenta 
# are defined by the reorder.txt files passed in from format_somatics_output_directory.pl 
# script.


sub new { 
	my ($class, $opts) = @_;
	my $self = bless({}, $class); 
	$self->_init( $opts );
}

sub format_dir {
	my ($self, $dir, $opts) = @_;

	$self->debug("Called format_dir with opts: ".Dumper( $opts ) );

	my @req_opts = qw(sample);
	foreach my $r ( @req_opts ) {
		confess("Option $r is required") unless( exists( $opts->{$r} ) );
	}

	$self->_format_plasma_dir( $dir, $opts );
}

sub _format_plasma_dir {
	my ($self, $dir, $opts) = @_;
	my $sample = $opts->{'sample'};	

	my $create_file_list = sub {
		my ($dir, $subdir, $sample) = @_;
		my %files = (
			"$subdir/$sample.PostBLAThg18Changes.txt" => {
				'outfile' => "$dir/$sample.TOnly_mutations.txt",
				'reorder' => 'reorder_changes_headers',
			},
			"$subdir/$sample.PostBLAThg19Changes.txt" => {
				'outfile' => "$dir/$sample.TOnly_mutations.txt",
				'reorder' => 'reorder_changes_headers',
			},
			"$subdir/$sample.summarysheet.txt" => {
				'outfile' => "$dir/$sample.Summary.txt",
				'modify' => \&reformat_sample_sheet
			},
			"$subdir/${sample}.pipeline.config" => {
				'outfile' => "$dir/$sample.pipeline.config"
			}
		);
		return \%files;
	};

	$self->_format_dir( $dir, $create_file_list, $opts );
}

## General idea is to copy all files into a subdirectory, copy, reorder, rename files
# out of said subdirectory. Then remove the subdirectory.
sub _format_dir {
	my ($self, $dir, $get_files, $opts) = @_;

	## Move all the files into a subdirectory
	my $subdir = $dir."/tmp_formatdir_$$";
	$self->run_cmd( "mkdir $subdir");

	my $cmd = "find $dir -maxdepth 1 -type f -exec mv '{}' $subdir \\;";
	$self->run_cmd( $cmd );

	## Copy files out of directory and into main directory
	my $files = $get_files->( $dir, $subdir, $opts->{'sample'} );
	$self->_copy_files_from_subdir( $files, $dir, $subdir, $opts);
	
	## Make symlinks to original input files if input lists were passed.
	foreach my $list_type ( qw(normal_input_list tumor_input_list) ) {
		if( exists( $opts->{$list_type} ) ) {
			foreach my $list ( @{$opts->{$list_type}} ) {
				$self->debug("Making symlinks for $list");
				$self->make_symlinks( $list, $dir, $opts->{'sample'} );
			}
		}
	}

	## And remove the subdirectory unless we are devel'ing.
	unless( $opts->{'devel'} ) {
		$cmd = "rm -rf $subdir $dir/nonormal $dir/changes $dir/coverage $dir/realign $dir/realigncomplex ".
			"$dir/secondary $dir/SECONDARYN_ $dir/SECONDARY_T_ $dir/T_ $dir/unmapped $dir/N_ $dir/i1";
		$self->run_cmd( $cmd );
	}
}


sub _copy_files_from_subdir { 
	my ($self, $config, $dir, $subdir, $opts) = @_;
	
	foreach my $file ( keys %{$config} ) {
		$self->debug("Processing $file");
		unless( -e $file ) {
			$self->debug("Skipping $file because it doesn't exist");
			next;
		}

		my $c = $config->{$file};
		my $outfile = $c->{'outfile'};

		if( exists( $c->{'reorder'} ) && exists( $opts->{$c->{'reorder'}} ) ) {
			my $headers_file = $opts->{$c->{'reorder'}};
			$self->debug( Dumper( $opts ) );
			$self->debug( "Reorder $file with $headers_file" );
			&PGDX::reorder_columns({
				'file' => $file, 
				'outfile' => $outfile, 
				'headers_file' => $headers_file,
				'trim_extra' => 1,
				'remove_cnf' => 1
			});
		} elsif( exists( $c->{'modify'} ) ) {
			$c->{'modify'}->($file, $outfile);
		} else {
			my $cmd = "cp $file $outfile";
			$self->run_cmd( $cmd );	
		}
	}	

	return 1;
}

sub reformat_sample_sheet {
	my ($sample_sheet, $out_sheet) = @_;
	open(IN, "< $sample_sheet") or die("Can't open $sample_sheet: $!");
	open(OUT, "> $out_sheet") or die("Can't open $out_sheet for writing: $!");

	my %rows_to_keep = (
		'General Information' => '',
		'Database' => '',
		'Sample' => 'Sample Name',
		'Bases in Target Region' => '',
		'Read Length' => '',
		'Bases Sequenced (Filtered)' => 'Bases Sequenced',
		'Bases Mapped to Genome (filtered)' => 'Bases Mapped to Genome',
		'Percent Mapped to Genome' => 'Percent Bases Mapped to Genome',
		'Bases Mapped to ROI' => 'Bases Mapped to Target Regions',
		'Percent Mapped to ROI' => 'Percent Bases Mapped to Target Regions',
		'Targeted bases with at least 10 reads' => '',
		'Targeted bases with at least 10 reads (%)' => 'Percent Targeted bases with at least 10 reads',
		'Total Coverage Average High Quality Coverage' => 'Total Coverage',
		'Distinct Coverage Average High Quality Coverage' => 'Distinct Coverage'
	);

	my %snps = ('tumor' => 0, 'normal' => 0, 'percent' => 0);
	my $flag = "";
	while( my $line = <IN> ) {
		chomp($line);
		next if( $line =~ /^\s*$/ );

		my @cols = split(/\t/, $line);

		if( exists($rows_to_keep{$cols[0]}) ) {
			unless( $rows_to_keep{$cols[0]} eq '' ) {
				$cols[0] = $rows_to_keep{$cols[0]}; 
			}
			print OUT join("\t",@cols)."\n";
		} elsif( exists( $rows_to_keep{"$flag $cols[0]"})) {
			unless( $rows_to_keep{"$flag $cols[0]"} eq '' ) {
				$cols[0] = $rows_to_keep{"$flag $cols[0]"}; 
			}
			print OUT join("\t",@cols)."\n";
		
		} elsif( $cols[0] eq 'Total Coverage' ) {
			print OUT "\n";
			$flag = $cols[0];
		} elsif( $cols[0] eq 'Distinct Coverage' ) {
			$flag = $cols[0];
		} elsif( $cols[0] =~ /^SNPs in Tumor/ ) {
			$snps{'tumor'} = $cols[1];
		} elsif( $cols[0] eq 'Present in Normal' ) {
			$snps{'normal'} = $cols[1];
		} elsif( $cols[0] eq 'Percent Present in Normal' ) {
			$snps{'percent'} = $cols[1];
		} elsif( $cols[0] eq 'ROI' ) {
			print OUT join("\t",("Target Region", "CpCS", "CpCS"))."\n";
		}
		

	}
	

	print OUT "\n";
	print OUT join("\t",("SNPs", $snps{'tumor'}, $snps{'normal'}))."\n";

	close(IN);
	close(OUT);

}
1;
