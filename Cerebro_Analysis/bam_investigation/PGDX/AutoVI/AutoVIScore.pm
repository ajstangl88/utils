package PGDX::AutoVI::AutoVIScore;

use strict;
use warnings;
use Data::Dumper;

########## Default Cutoffs #############
my $criteria = {
	'Read1Dist' => sub { $_[0] >= 60 },
	'CycleDist' => sub { $_[0] >= 40  },
	'EORMutPct' => sub { $_[0] < .5 },
	'GermlineNormMutPct' => sub { $_[0] < 0.01 },
	'Supermutant' => sub { $_[0] > 0 },
	'AverageQualityScore' => sub { $_[0] > 29 },
	'MaskedMutPct' => sub { $_[0] <= 0.6 },
	'Changes_Adjacent' => sub { $_[0] = 0 if( !defined( $_[0] ) || $_[0] eq "" ); $_[0] < 9 },
	'PolyN_Dust' => sub { !defined( $_[0] ) || $_[0] eq "" || $_[0] eq 'No' }
};
########################################


## Returns and array of required header values
sub get_expected_headers {
	return keys %{$criteria};
}

## Expects a hashref with columns as keys
sub get_autovi_score {
	my ($row) = @_;

	my $total = 0;
	foreach my $col ( keys %{$criteria} ) {
		die("Could not find column $col in row") unless( exists( $row->{$col} ) );
		my $val = $row->{$col};
		$total++ if( $criteria->{$col}->($val) ); 
	}
	return $total;
}
1;
