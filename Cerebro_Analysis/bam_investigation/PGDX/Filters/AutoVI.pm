package PGDX::Filters::AutoVI;

use strict;
use warnings;

## General idea here is to add an AutoVI column
## describing the AutoVI result.

# Valid Filter Opts:
#  - exclude_fail=1
#     Will not print the failed rows. By default, all rows are kept 
#     and an AutoVI column is added.

################################## handlers #####################################
sub header {
	my ($mod_name, $params) = @_;
	push(@{$params->{'headers'}}, "AutoVI");
	print join("\t", @{$params->{'headers'}})."\n";
}

sub on_pass {
	my ($mod_name, $params) = @_;
	push(@{$params->{'row'}}, "Yes");	
	print join("\t", @{$params->{'row'}})."\n";
}

sub on_fail {
	my ($mod_name, $params) = @_;
	my $opts = $params->{'filter_opts'};
	my $fail_string = join(", ", @{$params->{'failed_filters'}});
	push(@{$params->{'row'}}, "No: $fail_string");
	unless( exists( $params->{'filter_opts'}->{'exclude_fail'} ) && $params->{'filter_opts'}->{'exclude_fail'} ) {
		print join("\t",@{$params->{'row'}})."\n";
	} else {
		print STDERR join("\t", @{$params->{'row'}})."\n";
	}
}
######################################################################################


my %dispatch_table = (
	'NewPolyN.default' => \&new_polyn_default,
	'ThreeBPIndel.default' => \&three_bp_indel,
	'Germline.default' => \&germline,
	'OtherIndels.default' => \&other_indels,
	'AdjacentChanges.default' => \&adjacent_changes
);

## Method to call code based on filter name and filter part name
sub dispatch {
	my ($module_name, $filter_name, $filter_part_name, @args) = @_;
	my $dispatch_string = "$filter_name.$filter_part_name";
	my $ret = 1;
	if( exists( $dispatch_table{$dispatch_string} ) ) {
		$ret = $dispatch_table{$dispatch_string}->(@args);
	} else {
		die("Could not find $dispatch_string in dispatch table.");
	}

	return $ret;
}

########################## dispatched filters #####################################
sub new_polyn_default {
	my ($vals, $hIndex) = @_;
	my $indels_sameloc = $vals->[$hIndex->{'Indels_SameLocation'}];
	return 0 if( $indels_sameloc && $indels_sameloc > 3 );

	my $dust_region = $vals->[$hIndex->{'PolyN_Dust'}];
	return 0 if( $dust_region && $dust_region > 25 && $indels_sameloc > 0 );

	return 1;
}

sub three_bp_indel {
	my ($cols,$in) = @_;
	my $retval = 1;

	# Make sure it's an indel
	if( $cols->[$in->{'MutType'}] =~ /SBS/ ) {
		return 1;
	}
	my $indel_length = PGDX::get_indel_length( $cols->[$in->{'ChangeUID'}] );

	# Only 3bp handled here
	return 1 unless( $indel_length && $indel_length == 3 );

	## Keep good quality muts
	return 1 if( $cols->[$in->{'MutPct'}] > .2 && $cols->[$in->{'AutoVIScore'}] == 9 );

	## Remove any 3bp indel below .05
	my $polyMut = $cols->[$in->{'PolyMut'}];
	$polyMut-- if( $cols->[$in->{'MutType'}] =~ /DEL/i );
	if( $cols->[$in->{'MutPct'}] < .05 || $polyMut > 3 ) {
		$retval = 0;
	}
	return $retval;	
}
sub other_indels {
	my ($cols, $in) = @_;

	my $mut_type = $cols->[$in->{'MutType'}];

	# Make sure it's an indel
	if( $mut_type =~ /SBS/ ) {
		return 1;
	}

	# We handle 3bp indels differently.
	my $indel_length = &PGDX::get_indel_length( $cols->[$in->{'ChangeUID'}] );
	return 1 if( $indel_length && $indel_length == 3 );

	my $gmp  = $cols->[$in->{'GermlineNormMutPct'}];
	my $tnm  = $cols->[$in->{'TotalNormalMutCount'}];
	my $poly = $cols->[$in->{'PolyMut'}];

	## Subtract 1 from poly mut because error in calculating PolyMut for deletions
	## in variant caller.
	$poly-- if( $cols->[$in->{'MutType'}] =~ /DEL/i );

	my $maf = $cols->[$in->{'MutPct'}];

	## All this below is looking for polyN. If the indel
	## is longer than 4bp,  some of these rules break down.
	if( $indel_length < 5 ) {

		## If any indel is a long polyN tract, remove it.
		return 0 if( $poly > 7);
		return 0 if( $poly == 7 && $gmp >= .003 );

		my $poly_bp = $poly * $indel_length;

		## If an indel is less than 5%, be more strict
		return 0 if( $maf < .05 && ($poly > 5 || $poly_bp > 11) );

		## If indels in the same location and other signs present
		my $indels_sameloc = $cols->[$in->{'Indels_SameLocation'}];
		return 0 if( $indels_sameloc > 1 && $poly_bp > 6 );

	}

	return ( $gmp < 0.01 && $tnm < 9 );
}
sub germline {
	my ($cols, $in) = @_;
	return ($cols->[$in->{'GermlineNormMutPct'}] < 0.02);
}

sub adjacent_changes {
	my ($cols, $in) = @_;
	my $mutpct_cutoff = 0.5;

	## Lower mutpct cutoff for larger indels
	my $indel_length = PGDX::get_indel_length( $cols->[$in->{'ChangeUID'}] );
	if( $cols->[$in->{'MutType'}] !~ /SBS/ && $indel_length > 3) {
		$mutpct_cutoff = 0.1;
	}

	if( $cols->[$in->{'Changes_Adjacent'}] > 6 && $cols->[$in->{'MutPct'}] < $mutpct_cutoff ) {
		return 0;
	}
	return 1;
}
######################################################################################

1;
