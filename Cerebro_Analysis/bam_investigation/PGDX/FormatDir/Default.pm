package PGDX::FormatDir::Default;

use strict;
use warnings;
use Carp;
use Data::Dumper;
use PGDX::FormatDir;
use base qw(PGDX::FormatDir);

sub new {
	my ($class, $opts) = @_;	
	my $self = bless({}, $class);
	$self->_init( $opts );
}

sub format_dir {
	my ($self, $dir, $opts) = @_;

	if( $self->{'devel'} ) {
		my $backup_dir = "/mnt/scratch/formatdir_devel/$opts->{'sample'}";
		confess("Backup dir exists. Not overwritting. $backup_dir") if( -d $backup_dir );
		$self->run_cmd( "mkdir -p $backup_dir" );
		$self->run_cmd( "cp -R $dir $backup_dir/" );
	}

	$dir =~ s/\/$//;

	## Everything except these files go to misc
	my $stay = [qw(\.allchanges.txt \.changes.txt .Fcna_snps.txt .Fcna.txt .loh.txt PostBLAT\w+Changes.txt 
		summarysheet .bai .bam$ export.list CHECKSUM_ERROR CombinedChanges.txt viewer.txt 
		_nonormal.PostBLAT\w+.viewer.txt _nonormal.PostBLAT\w+Changes.txt 
		.Fcna_snps_nonormal.txt .Fcna_unadj.txt \.rearrangements.txt \.msi.txt \.ValidationChanges.txt \.ValidationChanges.viewer.txt)];
	my $nonormal_stay = ["$dir/nonormal"];

	## This contains data structure for moving the files.
	##    $name => {                           Name. Used only for debugging.
	##       'files_cmd' => $file_cmd,         A command, that when run, will produce a list of files to be moved.
	##       'dest' => $dest,                  Destination directory.
	##       'excl_regs' => $arrayref_reg      An arrayref of regular expressions. Will be concatenated 
	##                						   with a | and passed to grep -vP to filter the command results
	##       'incl_regs' => $arrayref_reg      An arrayref of regular expressions. Will only include files that 
	##               						   match these regexes (pass to grep -P, concatenated with |)
	##   }
	my @move = (
		{
			# Any nonormal files in the anywhere should be moved to
			# the nornomal directory.
			'name' => 'nonormal',
			'files_cmd' => "find $dir -name '*_nonormal*'",
			'dest' => "$dir/nonormal",
			'excl_regs' => $nonormal_stay,
			'incl_regs' => [],
		},
		{
			# Move specific files out of the nonormal directory
			'name' => "special nonormal",
			'files_cmd' => "find $dir/nonormal -type f",
			'incl_regs' => [qw(_nonormal.PostBLAT\w+.viewer.txt _nonormal.PostBLAT\w+Changes.txt _nonormal.Combined.viewer.txt
				_nonormal.CombinedChanges.txt .Fcna_snps_nonormal)],
			'excl_regs' => [qw(_realign_ _realigncomplex_)],
			'dest' => "$dir",
		},
		{
			# Find all the files with the word pipeline in the name (pipeline.config, pipeline.config.QC)
			# and move them to the pipeline directory  
			'name' => 'pipeline',
			'files_cmd' => "find $dir -type f -name '*pipeline*'",
			'dest' => "$dir/pipeline",
			'excl_regs' => ["$dir/pipeline"],
			'incl_regs' => []
		},
		{
			# And whatever is left in the top level, move to misc, sans
			# those that match the excl_regs and should stay in the top
			# level.
			'name' => 'misc',
			'files_cmd' => "find $dir -maxdepth 1 -type f",
			'dest' => "$dir/misc",
			'excl_regs' => $stay,
			'incl_regs' => []
		},
		{
			# Move the other allchanges files which aren't captured in the last command
			# because they include .allchanges.txt
			'name' => "misc allchanges",
			'files_cmd' => "find $dir -maxdepth 1 -type f",
			'incl_regs' => [qw(_noncoding.allchanges.txt _COSMIC.allchanges.txt _noncoding.PostBLAT\w+Changes\. _noncoding.PostBLAT\w+.viewer.txt \.normal.msi.txt)],
			'excl_regs' => [],
			'dest' => "$dir/misc",
		}
	);

	foreach my $move ( @move ) {
		my $name = $move->{'name'};
		my $info = $move;
		$self->debug("Processing $name");
		$self->run_mv_command($info->{'files_cmd'},$info->{'dest'},$info->{'excl_regs'},$info->{'incl_regs'});
	}

	if( -e "$dir/misc/$opts->{'sample'}.ValidationChanges.txt" ) {
		$self->run_mv_command("find $dir/misc -name '$opts->{'sample'}.ValidationChanges.txt'", $dir);
	}
	
 	## Make symlinks to original input files if input lists were passed.
	foreach my $list_type ( qw(normal_input_list tumor_input_list) ) {
		if( exists( $opts->{$list_type} ) ) {
			foreach my $list ( @{$opts->{$list_type}} ) {
				$self->debug("Making symlinks for $list");
				$self->make_symlinks( $list, $dir, $opts->{'sample'} );
			}
		}
	}
}

sub validation_sample {
	my ($self, $dir) = @_;
	$self->run_mv_command( "find $dir/misc -name '*.ValidationChanges*'", $dir );
}

## Does a copy and then delete. A bit safer in case the 
## disk fills up during the copy.
sub run_mv_command {
	my ($self, $files_cmd, $dest, $excl_regs,$incl_regs) = @_;

	$self->error("files_cmd is required and missing") unless( $files_cmd );
	$self->error("destination is required and missing") unless( $dest );

	## Make the directory if it doesn't exist
	unless( -d $dest ) {
		mkdir( $dest );
	}

	my $cmd = $files_cmd." | ";

	if( $incl_regs && @{$incl_regs} > 0 ) {
		my $grep = "'".join("|",@{$incl_regs})."'";
		$cmd .= "grep -P $grep | ";
	}

	if( $excl_regs && @{$excl_regs} > 0 ) {
		my $vgrep = "'".join("|",@{$excl_regs})."'";
		$cmd .= "grep -vP $vgrep | ";
	}
	my $mv_cmd = $cmd."xargs -I '{}' mv {} $dest";
	$self->run_cmd($mv_cmd);
}
1;
