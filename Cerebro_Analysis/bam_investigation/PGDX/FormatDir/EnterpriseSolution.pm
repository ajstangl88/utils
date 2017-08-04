package PGDX::FormatDir::EnterpriseSolution;

use strict;
use warnings;
use Carp;
use File::Basename;
use Math::Complex;
use Data::Dumper;

use PGDX::FormatDir;
use base qw(PGDX::FormatDir);

my $dqc_dir = "Data_Quality_Control";
my $fqc_dir = "FASTQC";
my $rdb_dir = "Alignment_Bam_Files";
my $aaf_dir = "Additional_Alignment_Files";
my $tmn_dir = "Tumor_Normal_Analysis_Results";
my $ton_dir = "Tumor_Only_Analysis_Results";
my $val_dir = "Verification";

my $quality_review_pass = "Pass";
my $quality_review_fail = "Visual Inspection Required";

my $default_maf_hard_cutoff = 0.02;

####################### Lookups ################################
my $consequence_lookup = {
	'Nonsynonymous coding' => 'Missense'
};
################################################################

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

	if( $self->dir_is_realign( $dir, $opts ) ) {
		$self->debug("Detected directory ($dir) is realign" );
		$self->_format_realign_dir( $dir, $opts );
	} elsif( $self->dir_is_nonrealign( $dir, $opts ) ) {
		$self->debug("Detected directory ($dir) is non-realign" );
		$self->_format_nonrealign_dir( $dir, $opts );
	} else {
		confess("Could not determine layout type (realign vs nonrealign)");
	}
}
sub _format_realign_dir {
	my ($self, $dir, $opts) = @_;
	my $samp = $opts->{'sample'};

    my $analysis_settings = {
        'maf_hard_cutoff' => $default_maf_hard_cutoff,
        'maf_soft_cutoff' => 0.05,
        'amp_hard_cutoff' => 3,
        'amp_soft_cutoff' => 4
    };

    if( $opts->{'dac_xlsx'} ) {
        $analysis_settings = $self->parse_xlsx( $opts->{'dac_xlsx'} );
    }

	my $create_file_list = sub {
		my ($dir, $indir, $sample) = @_;

		##These are not being used currently. Leaving them here
		##in case they need to be put back in. 
		my @all_muts_files = (
			{
				'infile'  => "$indir/$sample.CombinedChanges.txt",
				'out' => [{
						'dir'  => "$dir/$tmn_dir/All_Mutations",
						'file' => "$sample.allmutations.txt"
					}],
				'reorder' => 'reorder_changes_headers',
				'modify'  => \&reformat_mutation_id 
			},
			{
				'infile'  => "$indir/${sample}_nonormal.CoverageCombinedChanges.txt",
				'out' => [{
						'dir'  => "$dir/$ton_dir/All_Mutations",
						'file' => "$sample.allmutations.txt"
					}],
				'reorder' => 'reorder_changes_headers',
				'modify'  => \&reformat_mutation_id 
			},
			{
				'infile'  => "$indir/${sample}_nonormal.CoverageCombined.viewer.txt",
				'out' => [{
						'dir'  => "$dir/$ton_dir/All_Mutations",
						'file' => "$sample.allviewer.txt"
					}]
			},
			{
				'infile' => "$indir/${sample}.Combined.viewer.txt",
				'out' => [{
						'dir' => "$dir/$tmn_dir/All_Mutations",
						'file' => "$sample.allviewer.txt"
					}]
			}
		);

		my @files = (
			{
				'infile' => "$indir/$sample.summarysheet.txt",
				'out'  => [
					{ 
						'dir'  => "$dir/$dqc_dir/Summary_File",
						'file' => "$sample.summary.txt"
					},
					{ 
						'dir'  => "$dir/$tmn_dir",
						'file' => "$sample.summary.txt"
					},
					{ 
						'dir'  => "$dir/$ton_dir",
						'file' => "$sample.summary.txt"
					},
					{
						'dir'  => "$dir/$val_dir",
						'file' => "$sample.summary.txt"
					}
				],
				'modify'  => \&reformat_sample_sheet,
			},
			{
				'infile'  => "$indir/${sample}_TN.AutoVI.CoverageCombinedChanges.txt",
				'out' => [{
						'dir'  => "$dir/$tmn_dir",
						'file' => "$sample.mutations.txt" 
					}],
				'reorder' => 'reorder_changes_headers',
				'modify'  => sub { &modify_filtered_mutations_sheet(@_, 
                                    $analysis_settings->{'maf_hard_cutoff'}, 
                                    $analysis_settings->{'maf_soft_cutoff'} ) 
                             }
			},
			{
				'infile'  => "$indir/${sample}_TN.AutoVI.CoverageCombined.viewer.txt",
				'out' => [{
						'dir'  => "$dir/$tmn_dir",
						'file' => "$sample.Viewer.txt"
					}]
			},
			{
				'infile'  => "$indir/${sample}_TN.Fcna_snps.txt",
				'out' => [
					{
						'dir'  => "$dir/$tmn_dir",
						'file' => "$sample.amplifications.txt"
					},
					{
						'dir'  => "$dir/$val_dir",
						'file' => "$sample.amplifications.txt"
					}
				],
				'reorder' => 'reorder_cna_headers',
				'modify' => sub { &modify_amplifications_sheet(@_, 
                                    $analysis_settings->{'amp_hard_cutoff'},
                                    $analysis_settings->{'amp_soft_cutoff'})
                                }
			},
			{
				'infile'  => "$indir/${sample}.msi.txt",
				'out' => [
					{
						'dir'  => "$dir/$tmn_dir",
						'file' => "$sample.msi.txt",
					},
					{
						'dir'  => "$dir/$ton_dir",
						'file' => "$sample.msi.txt"
					},
					{
						'dir'  => "$dir/$val_dir",
						'file' => "$sample.msi.txt"
					}
				],
				'modify' => \&reformat_msi_sheet,
			},
			{
				'infile'  => "$indir/${sample}.rearrangements.txt",
				'out' => [
					{
						'dir'  => "$dir/$tmn_dir",
						'file' => "$sample.rearrangements.txt"
					},
					{
						'dir'  => "$dir/$ton_dir",
						'file' => "$sample.rearrangements.txt"
					},
					{
						'dir'  => "$dir/$val_dir",
						'file' => "$sample.rearrangements.txt"
					}
				],
				'reorder' => "reorder_rearrangements_headers",
				'modify' => \&modify_rearrangements_sheet
			},
			{
				'infile'  => "$indir/${sample}_UN.AutoVI.CoverageCombinedChanges.txt",
				'out' => [{
						'dir'  => "$dir/$ton_dir",
						'file' => "$sample.mutations.txt"
					}],
				'reorder' => 'reorder_changes_headers',
				'modify'  => sub { &modify_filtered_mutations_sheet(@_, 
                                    $analysis_settings->{'maf_hard_cutoff'}, 
                                    $analysis_settings->{'maf_soft_cutoff'}, 'TO' ) 
                             }
			},
			{
				'infile'  => "$indir/${sample}_UN.AutoVI.CoverageCombined.viewer.txt",
				'out' => [{
						'dir'  => "$dir/$ton_dir",
						'file' => "$sample.Viewer.txt"
					}]
			},
			{
				'infile'  => "$indir/${sample}_UN.Fcna_snps.txt",
				'out' => [{
						'dir'  => "$dir/$ton_dir",
						'file' => "$sample.amplifications.txt"
					}],
				'reorder' => 'reorder_cna_headers',
				'modify' => sub { &modify_amplifications_sheet(@_, 
                                    $analysis_settings->{'amp_hard_cutoff'},
                                    $analysis_settings->{'amp_soft_cutoff'})
                                }

			},
			{
				'infile'  => "$indir/${sample}_TN.ValidationSpecificity.txt",
				'out' => [{
						'dir'  => "$dir/$val_dir",
						'file' => "$sample.VerificationSpecificity.txt"
					}],
				'reorder' => "reorder_validation_headers",
				'modify'  => sub { &modify_filtered_mutations_sheet(@_, 
                                    $analysis_settings->{'maf_hard_cutoff'}, 
                                    $analysis_settings->{'maf_soft_cutoff'} ) 
                             }
			},
			{
				'infile'  => "$indir/${sample}_TN.ValidationSensitivity.txt",
				'out' => [{
						'dir'  => "$dir/$val_dir",
						'file' => "$sample.VerificationSensitivity.txt"
					}],
				'reorder' => "reorder_validation_headers",
				'modify'  => \&reformat_mutation_id 
			},
			{
				'infile' => "$indir/${sample}_TN.ValidationSpecificity.viewer.txt",
				'out' => [{
						'dir'  => "$dir/$val_dir",
						'file' => "$sample.VerificationSpecificity.viewer.txt"
					}]
			},
			{
				'infile'  => "$indir/${sample}.pipeline.config",
				'out' => [
					{
						'dir'  => "$dir/$tmn_dir/Pipeline_Parameters",
						'file' => "$sample.pipeline.config"
					},
					{
						'dir'  => "$dir/$ton_dir/Pipeline_Parameters",
						'file' => "$sample.pipeline.config"
					}
				]
			},
			{
				'infile'  => "$indir/${sample}_TN.AutoVI.CoverageCombinedChanges.vcf",
				'out' => [
					{
						'dir'  => "$dir/$tmn_dir/",
						'file' => "$sample.mutations.vcf"
					}
				]
			},
			{
				'infile'  => "$indir/${sample}_UN.AutoVI.CoverageCombinedChanges.vcf",
				'out' => [
					{
						'dir'  => "$dir/$ton_dir/",
						'file' => "$sample.mutations.vcf"
					}
				]
			}
		);
		return \@files;
	};

	$self->_format_dir( $dir, $create_file_list, $opts );

	## Hacky. If the validation file was not present, remove the Validation directory
	my $val_output_file = "$dir/$val_dir/$samp.VerificationSpecificity.txt";
	unless( -e $val_output_file ) {
		$self->debug("Removing verification directory because could not find VerificationMutations file [$val_output_file]");
		$self->run_cmd( "rm -rf $dir/$val_dir" );
	}

	# Also hacky, filter and sort the mutations files.
	my $files = [
		{
			'mutations' => "$dir/$tmn_dir/$samp.mutations.txt",
			'viewer'    => "$dir/$tmn_dir/$samp.Viewer.txt"
		},
		{
			'mutations' => "$dir/$ton_dir/$samp.mutations.txt",
			'viewer'    => "$dir/$ton_dir/$samp.Viewer.txt"
		},
		{
			'mutations' => "$dir/$val_dir/$samp.VerificationSpecificity.txt",
			'viewer'    => "$dir/$val_dir/$samp.VerificationSpecificity.viewer.txt"
		}
	];

	foreach my $mut_file ( @{$files} ) {
		&filter_and_sort( $mut_file );
	}

	## Determine if normal is matched or unmatched
	## And remove the appropriate directories
	if( &matched_normal( "$dir/$tmn_dir/$samp.summary.txt" ) ) {
		system("rm -rf $dir/$ton_dir");	
	} else {
		system("rm -rf $dir/$tmn_dir");
	}

}

sub parse_xlsx {
    my ($self, $xlsx) = @_;
    require PGDX::DAC::DataAcceptanceCriteria;
    my $dac = new PGDX::DAC::DataAcceptanceCriteria();
    $dac->parse_xlsx( $xlsx );
    my $analysis_settings = $dac->{'analysis_settings'};
    my $retval = {
        'maf_hard_cutoff' => $analysis_settings->{'Sequence Mutations'}->{'Mutant Allele Fraction (Hard Cutoff)'},
        'maf_soft_cutoff' => $analysis_settings->{'Sequence Mutations'}->{'Mutant Allele Fraction (Soft Cutoff)'},
        'amp_hard_cutoff' => $analysis_settings->{'Amplifications'}->{'Fold Change from Diploid (Hard Cutoff)'},
        'amp_soft_cutoff' => $analysis_settings->{'Amplifications'}->{'Fold Change from Diploid (Soft Cutoff)'},
    };
    return $retval;
}

sub matched_normal {
	my ($summary_file) = @_;
	my $retval = 0;
	open(IN, "< $summary_file") or die("Unable to open $summary_file: $!");
	while( my $line = <IN> ) {
		chomp($line);
		next unless( $line =~ /^SNPs/ );
		my @cols = split(/\s+/, $line);
		$retval = 1 if( $cols[1] == $cols[2] );
		last;
	}
	close(IN);
	return $retval;
}

sub _format_nonrealign_dir {
	my ($self, $dir, $opts) = @_;
	my $sample = $opts->{'sample'};	
	die("Not yet implemented");
}

## General idea is to copy all files into a subdirectory, copy, reorder, rename files
# out of said subdirectory. Then remove the subdirectory.
sub _format_dir {
	my ($self, $dir, $get_files, $opts) = @_;

	## Move all the files into a subdirectory
    $dir =~ s|/$||;
	my ($dirname, $basedir) = fileparse( $dir );

	## This is where the backup files will be placed.
	if( $opts->{'backup_dir'} ) {
		## Don't change the basedir unless it exists.
		if( -d $opts->{'backup_dir'} ) {
			$basedir = $opts->{'backup_dir'};
		}
	}
	my @t = localtime();
	my $datestring = ($t[5]+1900).(sprintf("%0d2", ($t[4]+1))).(sprintf("%02d",$t[3])).
		"-".($t[2]).($t[1]);
	my $subdir = "$basedir/${dirname}_pipeline_files_$datestring";
	$self->run_cmd( "mv $dir $subdir");
	$self->run_cmd( "mkdir $dir" );

	## Copy files out of directory and into main directory
	my $files = $get_files->( $dir, $subdir, $opts->{'sample'} );
	$self->_copy_files_from_subdir( $files, $dir, $subdir, $opts);

	## Make symlinks to original input files if input lists were passed.
	my $make_symlinks = sub {
		my ($bam_dir, $list_names) = @_;

		foreach my $list_type ( @{$list_names} ) {
			if( exists( $opts->{$list_type} ) ) {

				# If we have some files to copy, make the directory.
				$self->run_cmd( "mkdir -p $bam_dir" ) unless( -d $bam_dir );

				foreach my $list ( @{$opts->{$list_type}} ) {
					$self->debug("Making symlinks for $list");
					$self->make_symlinks( $list, $bam_dir, $opts->{'sample'} );
				}
			}
		}
	};

	# Make primary symlinks
	my $prim_dir = "$dir/$rdb_dir";
	$make_symlinks->($prim_dir, [qw(normal_input_list tumor_input_list)] );

	# And secondary
	my $sec_dir = "$dir/$rdb_dir/$aaf_dir";
	$make_symlinks->($sec_dir, [qw(secondary_normal_input_list secondary_tumor_input_list)] );

	# Copy in FASTQC if we can find it
	my $fastqc_dir = "$dir/$dqc_dir/$fqc_dir";
	$self->run_cmd("mkdir -p $fastqc_dir") unless( -d $fastqc_dir );
	foreach my $input_list ( qw(normal_input_list tumor_input_list secondary_normal_input_list secondary_tumor_input_list) ) {
		foreach my $list ( @{$opts->{$input_list}} ) {
			$self->_copy_fastqc( $list, $fastqc_dir );
		}
	}

	## If the validation directory exists, copy in the expected results file.
	my $validation_dir = "$dir/$val_dir";
	if( -d $validation_dir && exists( $opts->{'validation_expected_results_file'}) ) {
		my $cmd = "cp $opts->{'validation_expected_results_file'} $dir/$val_dir";
		$self->run_cmd( $cmd );
	}

	## This cleans up some directories in the original directory which is kept on mount.
	unless( $opts->{'devel'} ) {
		my $cmd = "rm -rf $subdir/changes $subdir/coverage ".
			"$subdir/SECONDARYN_ $subdir/SECONDARY_T_ $subdir/T_ $subdir/unmapped $subdir/N_ $subdir/i1 ".
			"$subdir/secondary/changes $subdir/secondary/coverage $subdir/realign/*bam $subdir/realign/*bam.bai ".
			"$subdir/realign/changes $subdir/realign/coverage $subdir/realigncomplex/*bam $subdir/realigncomplex/*bam.bai ".
			"$subdir/realigncomplex/changes $subdir/realigncomplex/coverage";
		$self->run_cmd( $cmd );
	}
}

## This will only work under very strict conditions.
sub _copy_fastqc {
	my ($self, $input_list, $dir) = @_;

	# Find the bam file in the input_list.
	my $ifh = PGDX::open_file( $input_list, "in" );
	chomp( my @lines = <$ifh> );
	close($ifh);

	my ($bam) = grep { /bam$/ } @lines;
	return unless( $bam && -e $bam );

	my ($bam_dir,$file_name) = ($1,$2) if( $bam =~ m|(.*)/bam/{1,}([^/]+)\.bam$| );
	return unless( -d $bam_dir );

	my $fastqc_dir = $bam_dir."/QC/FASTQC";
	unless( $fastqc_dir && -d $fastqc_dir ) {
		$fastqc_dir = $bam_dir."/fastqc";
	}
	return unless( $fastqc_dir && -d $fastqc_dir );

	## We have to open the directory to find the FASTQC graphs.
	opendir(DIR, $fastqc_dir) or die("Could not open directory $fastqc_dir");
	my @fastqc_files = map { "$fastqc_dir/$_" } grep { /$file_name/ && /\.png$/ } readdir(DIR);
	closedir( DIR );

	return unless( @fastqc_files == 2 );

	foreach my $fqc_file ( @fastqc_files ) {
		my $cmd = "cp $fqc_file $dir";
		$self->run_cmd( $cmd );
	}

	return 1;
}

sub _copy_files_from_subdir { 
	my ($self, $config, $dir, $subdir, $opts) = @_;
	
	foreach my $c ( @{$config} ) {
		my $file = $c->{'infile'};
		$self->debug("Processing $file");

		unless( -e $file ) {
			$self->debug("Skipping $file because it doesn't exist");
			next;
		}

		unless( exists( $c->{'out'} ) ) {
			confess("Could not find output definition for $file");
		}

		foreach my $output_definition ( @{$c->{'out'}} ) {

			my $outdir = $output_definition->{'dir'};
			$self->run_cmd( "mkdir -p $outdir" ) unless( -d $outdir );
							
			my $outfile = $outdir."/".$output_definition->{'file'};

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

				## In case we have both reorder and modify, the
				## modify will follow the reorder.
				if( exists( $c->{'modify'} ) ) {
					my $out_copy = "$outfile.bak";
					$self->run_cmd("cp $outfile $out_copy");
					$c->{'modify'}->($out_copy, $outfile);
					$self->run_cmd("rm $out_copy");
				}
			} elsif( exists( $c->{'modify'} ) ) {
				$c->{'modify'}->($file, $outfile);
			} else {
				my $cmd = "cp $file $outfile";
				$self->run_cmd( $cmd );	
			}
		}
	}	

	return 1;
}

sub filter_and_sort {
	my ($data) = @_;

	### SETTING ###
	# Set to 1 to only include mutations which require
	# quality review to the viewer sheet.
	my $only_quality_review = 0;

	my $muts_file = $data->{'mutations'};
	my $viewer = $data->{'viewer'};

	return unless( -e $muts_file && -e $viewer );

	# Get the index of the column to sort on.
	open( IN, "< $muts_file") or die("Unable to open $muts_file: $!");

	my $maf = "Tumor: Mutation Fraction";
	my $expected_headers = [$maf, 'Mutation ID', 'Quality Review', 'Chromosome'];
	chomp( my $in_head = <IN> );

	my @header_names = split("\t", $in_head);
	my $hindex = PGDX::getHeaderIndex( \@header_names, $expected_headers );
	my $sort_col_num = $hindex->{$maf} + 1;

	my $vi_required = {};
	my $vi_req_order = [];

	# Print out the rest of the file without the header
	my $tmp_outfile = $muts_file.".tmp";
	open(OUT, "> $tmp_outfile") or die("Could not open $tmp_outfile for writing: $!");

	print OUT $in_head."\n";
	my $row_by_maf = [];
	while( my $line = <IN> ) {
		chomp($line);
		my @cols = split("\t", $line);
		my $maf_val = $cols[$hindex->{$maf}];
		$maf_val =~ s/%//;
		my $qr = 1;
		if( $cols[$hindex->{'Quality Review'}] eq 'Pass' ) {
			$qr = 0;
		}

		push( @{$row_by_maf}, {
			'row' => $line,
			'mut_id' => $cols[$hindex->{'Mutation ID'}],
			'quality_review' => $qr,
			'maf_val' => $maf_val,
			'chrom' => $cols[$hindex->{'Chromosome'}]
			
		});
	}
	close(IN);


	foreach my $d ( sort by_chrom @{$row_by_maf} ) {
		print OUT $d->{'row'}."\n";
		if( !$only_quality_review || $d->{'quality_review'} ) {
			push(@{$vi_req_order}, $d->{'mut_id'});
		}
	}
	close(OUT);


	system("mv $tmp_outfile $muts_file");

	# And now filter the viewer
	open(IN, "< $viewer") or die("Could not open $viewer: $!");
	my $viewer_rows = {};
	while( my $line = <IN> ) {
		chomp( $line );
		my @cols = split("\t", $line);
		my $mut_id = $cols[3];
		$mut_id =~ s/\.fa//;
		$viewer_rows->{$mut_id} = $line;
	}
	close(IN);

	my $tmp_viewer = $viewer.".tmp";
	open(OUT, "> $tmp_viewer") or die("Could not open $tmp_viewer for writing: $!");
	foreach my $mut_id ( @{$vi_req_order} ) {
		die("Could not find $mut_id in viewer $viewer.") unless( exists( $viewer_rows->{$mut_id} ) );
		print OUT $viewer_rows->{$mut_id}."\n";
	}
	close(OUT);

	system("mv $tmp_viewer $viewer");
}
sub by_chrom {
	my $anum = $1 if( $a->{'chrom'} =~ /chr(.*)/ );
	my $bnum = $1 if( $b->{'chrom'} =~ /chr(.*)/ );
	$anum = 23 if( $anum =~ /x/i );
	$bnum = 23 if( $bnum =~ /x/i );
	$anum = 24 if( $anum =~ /y/i );
	$bnum = 24 if( $bnum =~ /y/i );
	$anum = 25 if( $anum =~ /m/i );
	$bnum = 25 if( $bnum =~ /m/i );
	return $anum <=> $bnum;
}

sub modify_rearrangements_sheet {
	my ($sample_sheet, $out_sheet) = @_;
	open(IN, "< $sample_sheet") or die("Unable to open $sample_sheet: $!");

	my $tmp_sheet = "$out_sheet.tmp";
	open(OUT, "> $tmp_sheet") or die("Unable to open $out_sheet: $!");

	my $r_type = "Rearrangement Type";
	my $in_type = "Intrachromosomal Type";
	my $expected_headers = [$r_type, $in_type];
	chomp( my $in_head = <IN> );

	my @header_names = split("\t", $in_head);
	my $hindex = &PGDX::getHeaderIndex( \@header_names, $expected_headers, 1, 0 );
	unless( exists( $hindex->{$r_type} ) ) {
		close(IN);
		close(OUT);
		system("cp $sample_sheet $out_sheet");
		return;
	}

	## No change to the header.
	print OUT join("\t", @header_names)."\n";
	while( my $line = <IN> ) {
		chomp($line);
		my @cols = split("\t", $line);

		my $rtype_value = $cols[$hindex->{$r_type}];
		my $itype_value = $cols[$hindex->{$in_type}];
		unless( $rtype_value && $rtype_value ne "" ) {
			$cols[$hindex->{$r_type}] = "NA";
		}
		unless( $itype_value && $itype_value ne "" ) {
			$cols[$hindex->{$in_type}] = "NA";
		}

		print OUT join("\t", @cols)."\n";
	}

	close(IN);
	close(OUT);

	system("mv $tmp_sheet $out_sheet");

	return 1;

}

sub modify_amplifications_sheet {
	my ($sample_sheet, $out_sheet, $amp_hard_cutoff, $amp_soft_cutoff) = @_;
	open(IN, "< $sample_sheet") or die("Unable to open $sample_sheet: $!");

	my $tmp_sheet = "$out_sheet.tmp";
	open(OUT, "> $tmp_sheet") or die("Unable to open $out_sheet: $!");

	my $fold = "Fold Change from Diploid";
    my $type = "Copy Number Alteration Type";
    my $gene_name = "Gene Name";
	my $expected_headers = [$gene_name, $fold, $type];
	chomp( my $in_head = <IN> );

	my @header_names = split("\t", $in_head);
	my $hindex = &PGDX::getHeaderIndex( \@header_names, $expected_headers, 1, 0 );
	unless( exists( $hindex->{$fold} ) ) {
		close(IN);
		close(OUT);
		system("cp $sample_sheet $out_sheet");
		return;
	}

	## No change to the header.
	print OUT join("\t", @header_names)."\n";

    my $out = {};
	while( my $line = <IN> ) {
		chomp($line);
		my @cols = split("\t", $line);

		my $fold_value = $cols[$hindex->{$fold}];
        next if( $fold_value < $amp_hard_cutoff );
        if( $fold_value >= $amp_soft_cutoff ) {
            $cols[$hindex->{$type}] = "Amplification";
        } else {
            $cols[$hindex->{$type}] = "Amplification - Indeterminate";
        }
		$fold_value = sprintf("%.2f", $fold_value);
		$cols[$hindex->{$fold}] = $fold_value;
        $out->{$cols[$hindex->{$gene_name}]} = \@cols;
	}
    
    ## Now print them out sorted.
    for my $gn ( sort keys %{$out} ) {
		print OUT join("\t", @{$out->{$gn}})."\n";
    }

	close(IN);
	close(OUT);

	system("mv $tmp_sheet $out_sheet");

	return 1;

}

## Here we add the quality review column and confidence interval
sub modify_filtered_mutations_sheet {
	my ($sample_sheet, $out_sheet, $maf_hard_cutoff, $maf_soft_cutoff, $unmatched_flag) = @_;
	open(IN, "< $sample_sheet") or die("Unable to open $sample_sheet: $!");

	my $tmp_sheet = "$out_sheet.tmp";
	open(OUT, "> $tmp_sheet") or die("Unable to open $out_sheet: $!");

	my $maf = "Tumor: Mutation Fraction";
    my $cov = "Tumor: Sequence Coverage (Distinct)";
    my $mut = "Tumor: Mutation Count (Distinct)";
	my $expected_headers = [$maf, $cov, $mut];
	chomp( my $in_head = <IN> );

	my @header_names = split("\t", $in_head);
	my $hindex = PGDX::getHeaderIndex( \@header_names, $expected_headers );
	unless( exists( $hindex->{$maf} ) ) {
		close(IN);
		close(OUT);
		system("cp $sample_sheet $out_sheet");
		return;
	}

    ## Construct the new header with the 2 new columns.
    my $quality_review_header = "Quality Review";
    my $conf_int_header = "Tumor: Mutation Fraction Confidence (95%)";
    my @new_header = ($header_names[0], $quality_review_header);
    push(@new_header, @header_names[1..$hindex->{$maf}]);
    push(@new_header, $conf_int_header);
    push(@new_header, @header_names[($hindex->{$maf}+1)..(@header_names-1)]);

    ## Remove the last 3 columns (normal related)
    ## if we are running unmatched.
    if( $unmatched_flag ) {
        @new_header = splice(@new_header,0,-3);
    }
	print OUT join("\t", @new_header)."\n";

	while( my $line = <IN> ) {
		chomp($line);
		my @cols = split("\t", $line);

		my $maf_val = $cols[$hindex->{$maf}];

        ## Don't print this mut if it's below the hard cutoff. UNLESS, the hard cutoff
        ## is default. If it's default, don't filter anything out. This is because we 
        ## keep some indels which are below 2% MAF. If the client doesn't change anything
        ## these should still be in the output
        next if( $maf_val < $maf_hard_cutoff && $maf_hard_cutoff != $default_maf_hard_cutoff );
        my $quality_review_val = ( $maf_val >= $maf_soft_cutoff ) ? $quality_review_pass : $quality_review_fail;
        my $confidence_interval = &calc_conf_int($cols[$hindex->{$cov}], $cols[$hindex->{$mut}]);
        my @row = ($cols[0], $quality_review_val, @cols[1..$hindex->{$maf}]);
        push(@row, "+/- $confidence_interval");
        push(@row, @cols[($hindex->{$maf}+1)..(@cols-1)]);

        ## Remove the last 3 columsn (normal related)
        ## for unmatched samples
        if( $unmatched_flag ) {
            @row = splice(@row,0,-3);
        }
		print OUT join("\t", @row)."\n";
	}

	close(IN);
	close(OUT);

	# Reformat mutation id
	&reformat_mutation_id( $tmp_sheet, $out_sheet );

	system("rm $tmp_sheet");
	return 1;


}

sub calc_conf_int {
    my ($coverage, $mut_count) = @_;
    ## Z value for 95%
    my $z = 1.98;
    my $p = $mut_count/$coverage;
    my $conf = $z * sqrt(($p*(1-$p))/$coverage);
    return sprintf( "%.2f%%", $conf*100);
}

sub reformat_mutation_id {
	my ($sample_sheet, $out_sheet) = @_;
	open(IN, "< $sample_sheet") or die("Unable to open $sample_sheet: $!");
	open(OUT, "> $out_sheet") or die("Unable to open $out_sheet: $!");

	my $maf = 'Tumor: Mutation Fraction';
	my $naf = 'Normal: Mutation Fraction';
	my $aac = "Amino Acid Change";
	my $mco = "Mutation Consequence";
	
	my $expected_headers = ['Mutation ID', $maf, $aac, $mco, $naf];
	chomp( my $in_head = <IN> );

	my @header_names = split("\t", $in_head);
	my $hindex = PGDX::getHeaderIndex( \@header_names, $expected_headers );
	unless( exists( $hindex->{'Mutation ID'} ) ) {
		close(IN);
		close(OUT);
		system("cp $sample_sheet $out_sheet");
		return;
	}

	unless( exists( $hindex->{$maf} ) && defined( $hindex->{$maf} ) ) {
		die("Could not find $maf in header. $sample_sheet");
	}

	print OUT "$in_head\n";
	while( my $line = <IN> ) {
		chomp($line);
		my @cols = split("\t", $line);

		## Reformat the Mutation ID to remove the .fa
		## and separate the chr from the position with a colon.
		my $mut_id = $cols[$hindex->{'Mutation ID'}];
		if( !defined( $mut_id ) ) {
			die("Mut ID is not defined: $sample_sheet");
		}
		$mut_id =~ s/^(chr.{1,2})\.fa\:/$1:/;
		$mut_id =~ s/^(chr.{1,2})_/$1:/;
		$cols[$hindex->{'Mutation ID'}] = $mut_id;

		## Replace the consequence from the lookup if available.
		if( defined( $cols[$hindex->{$mco}] ) && exists( $consequence_lookup->{$cols[$hindex->{$mco}]} ) ) {
			$cols[$hindex->{$mco}] = $consequence_lookup->{$cols[$hindex->{$mco}]};
		}

		## Make sure blank amino acid columns are a "-"
		if( !defined( $cols[$hindex->{$aac}] ) || $cols[$hindex->{$aac}] eq "" ) {
			$cols[$hindex->{$aac}] = "-";
		}

		## Reformat Mutatant Allele Fraction to be a percentage
		## and round appropriately.
		my $maf_val = $cols[$hindex->{$maf}];
		my $maf_per = sprintf("%.2f%%", $maf_val*100);
		$cols[$hindex->{$maf}] = $maf_per;

        if( exists( $hindex->{$naf} ) && $hindex->{$naf} ne '' ) {
		    my $naf_val = $cols[$hindex->{$naf}];
		    my $naf_per = sprintf("%.2f%%",$naf_val*100);
		    $cols[$hindex->{$naf}] = $naf_per;
        }

		print OUT join("\t", @cols)."\n";
	}

	close(IN);
	close(OUT);
	return 1;
}

sub reformat_sample_sheet {
	my ($sample_sheet, $out_sheet) = @_;
	open(IN, "< $sample_sheet") or die("Can't open $sample_sheet: $!");
	open(OUT, "> $out_sheet") or die("Can't open $out_sheet for writing: $!");

	########################## Some helper formatting subroutines ##########################
	my $add_commas = sub {
		my $num = int($_[0]+.5);
		my @s = unpack( "(A3)*", reverse($num) );
		return reverse(join(",",@s));
	};
	my $percent = sub { 
		my $s = sprintf( "%.2f%%", $_[0]*100);
		return $s;
	};
	########################################################################################

	my %rows_to_keep = (
		'General Information' => '',
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

	my %keep_dac = (
		'General Information' => 1,
		'Bases Sequenced' => 1,
		'Percent Bases Mapped to Target Regions' => 1,
		'Total Coverage' => 1,
		'Distinct Coverage' => 1
	);
	
	my $format_dispatch = {
		'Bases in Target Region' => $add_commas,
		'Bases Sequenced' => $add_commas,
		'Bases Mapped to Genome' => $add_commas,
		'Percent Bases Mapped to Genome' => $percent,
		'Bases Mapped to Target Regions' => $add_commas,
		'Percent Bases Mapped to Target Regions' => $percent,
		'Targeted bases with at least 10 reads' => $add_commas,
		'Percent Targeted bases with at least 10 reads' => $percent,
		'Total Coverage' => $add_commas,
		'Distinct Coverage' => $add_commas
	};

	my %snps = ('tumor' => 0, 'normal' => 0, 'percent' => 0);
	my $da_snps = 0;
	my $flag = "";
	while( my $line = <IN> ) {
		chomp($line);
		next if( $line =~ /^\s*$/ );

		my @cols = split(/\t/, $line);

		if( exists($rows_to_keep{$cols[0]}) ) {
			unless( $rows_to_keep{$cols[0]} eq '' ) {
				$cols[0] = $rows_to_keep{$cols[0]}; 
			}
			if( exists( $format_dispatch->{$cols[0]} ) ) {
				$cols[1] = $format_dispatch->{$cols[0]}->($cols[1]); 
				$cols[2] = $format_dispatch->{$cols[0]}->($cols[2]); 
			}
			if( exists( $keep_dac{$cols[0]} ) ) {
				if( exists( $format_dispatch->{$cols[0]} ) ) {
					$cols[3] = $format_dispatch->{$cols[0]}->($cols[3]) if( $cols[3] ); 
					$cols[5] = $format_dispatch->{$cols[0]}->($cols[5]) if( $cols[5] ); 
				}
				print OUT join("\t",@cols)."\n";
			} else {
				print OUT join("\t",@cols[0..2])."\n";
			}
		} elsif( exists( $rows_to_keep{"$flag $cols[0]"})) {
			unless( $rows_to_keep{"$flag $cols[0]"} eq '' ) {
				$cols[0] = $rows_to_keep{"$flag $cols[0]"}; 
			}
			if( exists( $format_dispatch->{$cols[0]} ) ) {
				$cols[1] = $format_dispatch->{$cols[0]}->($cols[1]); 
				$cols[2] = $format_dispatch->{$cols[0]}->($cols[2]); 
			}
			if( exists( $keep_dac{$cols[0]} ) ) {
				if( exists( $format_dispatch->{$cols[0]} ) ) {
					$cols[3] = $format_dispatch->{$cols[0]}->($cols[3]) if( $cols[3] ); 
					$cols[5] = $format_dispatch->{$cols[0]}->($cols[5]) if( $cols[5] ); 
				}
				print OUT join("\t",@cols)."\n";
			} else {
				print OUT join("\t",@cols[0..2])."\n";
			}
		
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
			$da_snps = 1 if( $cols[3] );
			$snps{'percent'} = $cols[1];
		} elsif( $cols[0] eq 'ROI' ) {
			if( $cols[1] =~ /PGDXCCROIV4/ ) {
				print OUT join("\t", ("Target Region", "CPT203", "CPT203"))."\n";
			} elsif ( $cols[1] =~ /PGDXCpCS/ ) {
				print OUT join("\t",("Target Region", "CPT88", "CPT88"))."\n";
			}
		}

	}
	
	my $percent_pf = ($snps{'percent'} > .99) ? 'P' : 'F';
    $snps{'percent'} = int($snps{'percent'}*100);
    $snps{'percent'} .= "%";

	print OUT "\n";
	print OUT join("\t",("SNPs", $snps{'tumor'}, $snps{'normal'}))."\n";
	my @tn_matching = ("Tumor-Normal Matching",$snps{'percent'},"NA");
	if( $da_snps ) {
		push(@tn_matching, (">99%",$percent_pf)); 
	}
	print OUT join("\t",@tn_matching)."\n";

	close(IN);
	close(OUT);

}

sub reformat_msi_sheet {
	my ($in, $out) = @_;

	open(IN, "< $in") or die("Can't open $in: $!");
	open(OUT, "> $out") or die("Can't open $out for writing: $!");

	my $gt_ten = 0;
	my $gt_twenty = 0;
	while( my $line = <IN> ) {
		chomp($line);
		last if( $line =~ /^\s*$/ );

		if( $line =~ /^Sample/ ) {
			print OUT join("\t",("Sample Name","Microsatellite Marker","Fraction of tracts shorter than normal"))."\n";
		} else {

			my @cols = split("\t", $line);
			if( $cols[2] > 0.20 ) {
				$gt_twenty++;
			} 
			if( $cols[2] > 0.10 ) {
				$gt_ten++;
			}
			print OUT "$line\n";
		}
	}
	close(IN);

	print OUT "\n";
	## Should probably be done upstream. Currently, we only want this for ES sheets, which is why
	## it's here. Could possibly be added to all MSI sheets, in which case we could move this to 
	## pgdx_pare component.
	if( $gt_ten >= 4 ) {
		print OUT join("\t", ("MSI", "Microsatellite Instability", "$gt_ten of 5 markers positive") )."\n";
	} elsif( $gt_twenty >= 2 ) {
		print OUT join("\t", ("MSI", "Microsatellite Instability", "$gt_twenty of 5 markers positive"))."\n";
	} else {
		print OUT join("\t", ("MSS", "Microsatellite Stable", 
				"$gt_twenty of 5 markers positive"))."\n";
	}
	close(OUT)
}

1;
