=head1 NAME

PGDX::AlignmentUtil.pm

=head1 DESCRIPTION

Functions to parse and process Illumina Samplesheets

=head1 AUTHOR

David Riley

driley@personalgenome.com

=cut

package PGDX::AlignmentUtil;
use strict;
use File::Basename;

sub get_fastqs_from_fastq_list {
    my $key = shift;
    my $read1 = shift;
    my $read2 = shift;
    
    my @good_read1;
    my @good_read2;
    for(my $i=0;$i<scalar @$read1; $i++) {
        chomp $read1->[$i];
        chomp $read2->[$i] if scalar defined($read2->[$i]);
        if($read1->[$i] =~ /($key)_[^_]+[^\/]*_L\d+_R\d_\d+.fastq/) {
            my $out1 = $1;
            push(@good_read1, $read1->[$i]);
            $key = $out1;            
            if($read2->[$i] =~ /($key)_[^_]+[^\/]*_L\d+_R\d_\d+.fastq/) {
                my $out2 = $1;
                push(@good_read2, $read2->[$i]);
            }
        }   
    }
    
    my @srted_read1;
    my @srted_read2;
    
    if(@$read1 && @$read2 && (!@good_read1 || !@good_read2)) {
        print STDERR scalar @$read1."\n".scalar @$read2."\n";
        die "Read1 and Read2 lists are different lengths!\n";
    
    }
    elsif(@good_read1 || @good_read2) {
        @srted_read1 = sort { my $namea=basename $a; my $nameb = basename $b; return $namea cmp $nameb; } @good_read1;
        @srted_read2 = sort { my $namea=basename $a; my $nameb = basename $b; return $namea cmp $nameb; } @good_read2;
        print STDERR join("\n",@srted_read1)."\n";
        print STDERR join("\n",@srted_read2)."\n";
    }
    return (\@srted_read1,\@srted_read2);
}

sub merge_fastq_noconvert {
	use Parallel::ForkManager;
	my $pm = Parallel::ForkManager->new(2);
    my $key = shift;
    my $read1 = shift;
    my $read2 = shift;
    my $output_dir = shift;
    my $doAddIndex = shift;

    my ($srted_read1,$srted_read2) = &get_fastqs_from_fastq_list($key,$read1,$read2);

    if(@$srted_read1 && @$srted_read2) {
        my $cat = "cat";
        if($srted_read1->[0] =~ /\.gz/) {
            $cat = "zcat";
        }
        FQLOOP:
		foreach my $fqread (1 .. 2){
			# Merge read1 files
			my $pid = $pm->start and next FQLOOP;
			if($fqread == 1) {
				`rm -f $output_dir/$key\_R1.fastq.gz`;
				foreach my $srtFile (@$srted_read1){
					my $addIndex = '';
					if($doAddIndex){
						my $index = $srtFile;
						$index =~ s/.*_([^_]+)_L\d+_R\d_\d+.fastq.*/$1/;
						$addIndex = 'perl -nE "if(($.+1)%4==0){print \"+'.$index.'\n\"}else{print}" |';
					}
					my $cmd = "$cat $srtFile | $addIndex gzip -1 >> $output_dir/$key\_R1_tmp.fastq.gz";
					print `$cmd`;
					if($?) {
						die "Died running cat\n";
					}
				}
				#Sometimes other programs don't support concatenated gzipped files. This enables their bugs instead of enforcing the spec
				`zcat $output_dir/$key\_R1_tmp.fastq.gz | gzip -1 > $output_dir/$key\_R1.fastq.gz`;
				`rm $output_dir/$key\_R1_tmp.fastq.gz`;
			}
			# Merge read2 files
			if($fqread == 2) {
				`rm -f $output_dir/$key\_R2.fastq.gz`;
				foreach my $srtFile (@$srted_read2){
					my $addIndex = '';
					if($doAddIndex){
						my $index = $srtFile;
						$index =~ s/.*_([^_]+)_L\d+_R\d_\d+.fastq.*/$1/;
						$addIndex = 'perl -nE "if(($.+1)%4==0){print \"+'.$index.'\n\"}else{print}" |';
					}
					my $cmd = "$cat $srtFile | $addIndex gzip -1 >> $output_dir/$key\_R2_tmp.fastq.gz";
					print `$cmd`;
					if($?) {
						die "Died running cat\n";
					}
				}
				#Sometimes other programs don't support concatenated gzipped files. This enables their bugs instead of enforcing the spec
				`zcat $output_dir/$key\_R2_tmp.fastq.gz | gzip -1 > $output_dir/$key\_R2.fastq.gz`;
				`rm $output_dir/$key\_R2_tmp.fastq.gz`;
			}
			$pm->finish;
		}
		$pm->wait_all_children;
    }elsif(@$srted_read1 || @$srted_read2) {
        my $cat = "cat";
        if($srted_read1->[0] =~ /\.gz/) {
            $cat = "zcat";
        }

        # Merge read1 files
        if(@$srted_read1) {
            `rm -f $output_dir/$key\_R1.fastq.gz`;
			foreach my $srtFile (@$srted_read1){
				my $addIndex = '';
				if($doAddIndex){
					my $index = $srtFile;
					$index =~ s/.*_([^_]+)_L\d+_R\d_\d+.fastq.*/$1/;
					$addIndex = 'perl -nE "if(($.+1)%4==0){print \"+'.$index.'\n\"}else{print}" |';
				}
				my $cmd = "$cat $srtFile | $addIndex gzip -1 >> $output_dir/$key\_R1_tmp.fastq.gz";
				print `$cmd`;
				if($?) {
					die "Died running cat\n";
				}
			}
			#Sometimes other programs don't support concatenated gzipped files. This enables their bugs instead of enforcing the spec
			`zcat $output_dir/$key\_R1_tmp.fastq.gz | gzip -1 > $output_dir/$key\_R1.fastq.gz`;
			`rm $output_dir/$key\_R1_tmp.fastq.gz`;
        }
        
        # Merge read2 files
        if(@$srted_read2) {
			`rm -f $output_dir/$key\_R2.fastq.gz`;
			foreach my $srtFile (@$srted_read2){
				my $addIndex = '';
				if($doAddIndex){
					my $index = $srtFile;
					$index =~ s/.*_([^_]+)_L\d+_R\d_\d+.fastq.*/$1/;
					$addIndex = 'perl -nE "if(($.+1)%4==0){print \"+'.$index.'\n\"}else{print}" |';
				}
				my $cmd = "$cat $srtFile | $addIndex gzip -1 >> $output_dir/$key\_R2_tmp.fastq.gz";
				print `$cmd`;
				if($?) {
					die "Died running cat\n";
				}
			}
			#Sometimes other programs don't support concatenated gzipped files. This enables their bugs instead of enforcing the spec
			`zcat $output_dir/$key\_R1_tmp.fastq.gz | gzip -1 > $output_dir/$key\_R1.fastq.gz`;
			`rm $output_dir/$key\_R1_tmp.fastq.gz`;
        }
    }
    else {
        die "Didn't have any reads!\n";
    }    
}
1;

sub get_other_flowcells {
	
	my ($exp_name, $out_dir, $fc_pos, $pid) = @_;
	my @other_flowcells;
	
	my $seen_exp_fcs = {};
	
	####### Instead check running or queued pipelines
	my @pipes = `vp-describe-pipeline | grep -P 'running|idle' | cut -f3`;
	foreach my $pipe (@pipes) {
	    chomp $pipe;
	    my @pipe_config = `vp-describe-pipeline -p $pipe | grep -P \'params.OUTPUT_NAME|input.INPUT_TAG|input.FLOWCELL|output.OUTPUT_DIRECTORY\'`;
	    my $pipe_conf = {};
	    
	    # Create a config lookup
	    foreach my $conf_line (@pipe_config) {
	        chomp $conf_line;
	        my ($pref,$key,$val) = split(/\s+/,$conf_line);
	        $pipe_conf->{$key} = $val;
	    }
	    # If this pipeline has the same run ID and a different flowcell then we're good.
	    my $this_exp = $pipe_conf->{'params.OUTPUT_NAME'};
	    my $this_exp2;
	    my $this_od = $pipe_conf->{'output.OUTPUT_DIRECTORY'}."/".$this_exp;
	    my $this_dir = $pipe_conf->{'output.OUTPUT_DIRECTORY'}."/".$this_exp."/".$pipe_conf->{"input.INPUT_TAG"};
	    my $this_fc;
	    if($pipe_conf->{'input.FLOWCELL'}){
			$this_fc = $pipe_conf->{'input.FLOWCELL'};
		}else{
			my $thisRC = `find $this_dir -name runParameters.xml`;
			chomp $thisRC;
			next if($thisRC eq "");
			($this_fc,$this_exp2) = &get_run_params($thisRC, $pid);
		}
	    if(!$seen_exp_fcs->{"$this_exp\_$this_fc"} && $this_exp eq $exp_name && $this_od eq $out_dir && $this_fc ne $fc_pos) {
			print STDERR "FOUND OTHER FC: $this_fc\n";
            push(@other_flowcells, {
                FC => $this_fc,
                experiment => $this_exp,
                dir => $this_dir
            });
            $seen_exp_fcs->{"$this_exp\_$this_fc"} = 1;
        }
    }
	
	return \@other_flowcells;
}

sub get_run_params {
	my $runparams = shift;
	my $pid = shift;

    my $dir = dirname($runparams);
    
    my $FCpos = `grep FCPosition $runparams | perl -p -e 's/\s*<.?FCPosition>\s*//g'`;
    $FCpos =~ s/^\s*//g;
    $FCpos =~ s/\s*$//g;
    my $exp_name = `grep ExperimentName $runparams | perl -p -e 's/\s*<.?ExperimentName>\s*//g'`;
    $exp_name =~ s/^\s*//;
    $exp_name =~ s/\s*$//;

    # Now also check for a runinfo file. If present this overrides the xml file.
    my $runinfo;
    
    if(-e "$dir/$pid/runinfo") {
        $runinfo = "$dir/$pid/runinfo";
    }
    # Take the most recent runinfo if there is one
    else {
        my @ri = `find $dir -maxdepth 3 -name runinfo`;
        foreach my $r (sort @ri) {
            $runinfo = $r;
        }
    }
    if($runinfo) {
        open IN, "<$runinfo" or die "Couldn't open $runinfo file\n";
        while(my $line = <IN>) {
            chomp $line;
            my @fields = split(/\t/,$line);
            if($fields[0] eq 'name' && $fields[1]) {
                $exp_name = $fields[1];
            }
            elsif($fields[9] eq 'FC' && $fields[1]) {
                $FCpos = $fields[1];
            }
        }
    }
    
	return $FCpos,$exp_name;
}
1;
