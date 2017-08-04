package PGDX::DAC::DataAcceptanceCriteria;

use strict;
use warnings;
use Carp;
use Spreadsheet::ParseXLSX;

use Data::Dumper;

########################################################################################
# Data Structures (Mapping and defaults)                                               #
########################################################################################
my @summary_tab_defaults = (
    {'header' => 'Case Type', 'default' => 'CPT88'},
    {'header' => 'Instrument', 'default' => 'MiSeq'},
    {'header' => 'Tumor/Normal', 'tumor_default' => 'Tumor', 'normal_default' => 'Normal'},
    {'header' => 'Lane Ratio', 'tumor_default' => '0.33', 'normal_default' => 0.17 },
    {'header' => 'QC Parameter', 'default' => 'Lower'},
    {'header' => 'Bases Seq (Filtered)', 'tumor_default' => 800000000, 'normal_default' => 500000000, 'map' => 'Bases Sequenced'},
    {'header' => 'Total Mapped Seq (bp)', 'tumor_default' => 600000000, 'normal_default' => 300000000 },
    {'header' => '% Mapped to Genome', 'default' => 0.75},
    {'header' => 'Mapped to ROI (bp)', 'tumor_default' => 250000000, 'normal_default' => 150000000 },
    {'header' => '% Mapped to ROI', 'default' => 0.2, 'map' => '% Mapped to Regions of Interest'},
    {'header' => 'Targeted bases with 10 reads', 'default' => 450000},
    {'header' => 'Targeted bases with at least 10 reads (%)', 'default' => .9},
    {'header' => 'Total Coverage', 'tumor_default' => 500, 'normal_default' => 250, 'map' => 'Total Coverage'},
    {'header' => 'Distinct Coverage', 'tumor_default' => 300, 'normal_default' => 150, 'map' => 'Distinct Coverage'},
    {'header' => '% T/N SNP matches', 'default' => 0.99},
    {'header' => 'Cluster Density', 'default' => ""},
    {'header' => 'R1 % Bases >= Q30 (SAV)', 'default' => ""},
    {'header' => 'R2 (I) % Bases >= Q30 (SAV)', 'default' => ""},
    {'header' => 'R3 % Bases >= Q30 (SAV)', 'default' => ""},
    {'header' => 'Total % Bases >= Q30 (SAV)', 'default' => "" },
    {'header' => '% Reads identified (PF) (SAV)', 'default' => "" },
    {'header' => 'FASTQC', 'default' => "" }
);

my @autoqc_tab_defaults = (
    {'header' => 'Instrument', 'default' => 'MiSeq' },
    {'header' => 'Index', 'default' => 2 },
    {'header' => 'CaseType', 'default' => 'CLIA' },
    {'header' => 'Suffix', 'default' => '_T88' },
    {'header' => 'TN', 'tumor_default' => 'T', 'normal_default' => 'N' },
    {'header' => 'LaneRatio', 'tumor_default' => 0.33, 'normal_default' => 0.17 },
    {'header' => 'ClusterDensity', 'default' => '700-1000', 
        'map_coderef' => sub { &min_max('Cluster Density (Min)', 'Cluster Density (Max)', @_) } },
    {'header' => 'ClusterPctPF', 'default' => 'NA' },
    {'header' => 'R1pct', 'default' => 90, 'map' => 'Read 1 (R1) % Bases >= Q30', 'display' => 'percent'},
    {'header' => 'R2pct', 'default' => 90, 'map' => 'Index i7 (R2) % Bases >= Q30', 'display' => 'percent'},
    {'header' => 'R3pct', 'default' => 90, 'map' => 'Index i5 (R3)  % Bases >= Q30', 'display' => 'percent'},
    {'header' => 'R4pct', 'default' => 85, 'map' => 'Read 2 (R4) % Bases >= Q30', 'display' => 'percent'},
    {'header' => 'Totalpct', 'default' => 90, 'map' => 'Total % Bases >= Q30', 'display' => 'percent'},
    {'header' => 'totReadsPctPF', 'default' => 'NA' },
    {'header' => 'readsPctPF', 'tumor_default' => '23-43', 'normal_default' => '7-27', 'display' => 'percent', 
        'map_coderef' => sub { &min_max('% Reads Identified (PF) (Min)', '% Reads Identified (PF) (Max)', @_) } }, 
    {'header' => 'fqcPct', 'default' => 90, 'map' => 'FASTQC (% of bases with mean quality >Q30)', 'display' => 'percent'},
    {'header' => 'fqcCut', 'default' => 30 },
    {'header' => 'fqcLen', 'default' => 'ALL' },
    {'header' => 'BasesSequencedFiltered', 'tumor_default' => 800000000, 'normal_default' => 500000000, 'map' => 'Bases Sequenced' },
    {'header' => 'BasesMappedToGenomeFiltered', 'tumor_default' => 560000000, 'normal_default' => 350000000 },
    {'header' => 'PercentMappedToGenome', 'default' => 0.7 },
    {'header' => 'BasesMappedToROI', 'tumor_default' => 200000000, 'normal_default' => 150000000 },
    {'header' => 'PercentMappedToROI', 'default' => 0.2, 'map' => '% Mapped to Regions of Interest' },
    {'header' => 'TargetedBasesWithAtLeast10Reads', 'default' => 350000 },
    {'header' => 'TargetedBasesWithAtLeast10ReadsPct', 'default' => .9 },
    {'header' => 'TotalCoverage', 'tumor_default' => 500, 'normal_default' => 250, 'map' => 'Total Coverage' },
    {'header' => 'DistinctCoverage', 'tumor_default' => 300, 'normal_default' => 150, 'map' => 'Distinct Coverage' }
);

my %display_dispatch = (
    'percent' => sub { $_[0]*100 }
);

########################################################################################

sub new {
    my ($class, $opts) = @_;
    my $self = {};
    bless($self, $class);
    return $self;
}

sub parse_xlsx {
    my ($self, $file) = @_;

    my $parser = new Spreadsheet::ParseXLSX();
    my $workbook = $parser->parse($file);

    for my $worksheet ( $workbook->worksheets() ) {
        my $name = $worksheet->get_name();
        if( $name eq 'Data Acceptance Criteria') {
            $self->{'data_acceptance_criteria'} = &process_dac( $worksheet );
        } elsif( $name eq 'Analysis Settings' ) {
            $self->{'analysis_settings'} = &process_analysis_settings( $worksheet );
        }
    }

    my @req = qw(data_acceptance_criteria analysis_settings);
    for my $r ( @req ) {
        croak("Did not find worksheet with name $r") unless( exists( $self->{$r} ) && $self->{$r} );
    }
    $self->{'parsed'} = 1;
}

sub to_summary_sheet_tab_file {
    my ($self, $outfile) = @_;
    croak("Need to parse file before printing tab file") unless( $self->{'parsed'} );
    print STDERR "Calling it: $outfile\n";
    $self->to_tab_file( $outfile, \@summary_tab_defaults );
}

sub to_autoqc_tab_file {
    my ($self, $outfile) = @_;
    croak("Need to parse file before printing tab file") unless( $self->{'parsed'} );
    $self->to_tab_file( $outfile, \@autoqc_tab_defaults );
}


sub to_tab_file {
    my ($self, $outfile, $defaults) = @_;

    open(my $outfh, ">", $outfile) or die("Could not open file: $outfile for writing ($!)");

    my $data = $self->{'data_acceptance_criteria'};

    ## Print the headers
    my @headers = map { $_->{'header'} } @{$defaults};
    print $outfh join("\t", @headers)."\n";

    ## One for tumor and one for normal
    for my $tn (qw(Tumor Normal)) {
        my @row;
        foreach my $d ( @{$defaults} ) {
            my $val;
            if( $d->{'header'} eq 'Tumor/Normal' ) {
                $val = $tn;
                push(@row, $val);
                next;
            } 

            if( exists( $d->{'map'} ) ) {
               croak("Could not find map header [$d->{'map'}] in dac lookup") unless( exists( $data->{$d->{'map'}} ) );
               $val = $data->{$d->{'map'}}->{lc($tn)};
            } elsif( exists( $d->{'map_coderef'} ) ) {
               $val = $d->{'map_coderef'}->($data, $d, $tn)
            }

            if( !defined( $val ) || $val eq 'NA' ) {
                my $key = lc($tn)."_default";
                if( exists( $d->{$key}) ) {
                    $val = $d->{$key};
                } elsif( exists( $d->{'default'} ) ) {
                    $val = $d->{'default'};
                } else {
                    croak("Could not find default for $d->{'header'}");
                }
            } elsif( exists( $d->{'display'} ) && !exists( $d->{'map_coderef'})) {
                if( exists( $display_dispatch{$d->{'display'}} ) ) {
                    $val = $display_dispatch{$d->{'display'}}->($val);
                }
            }
            push(@row, $val);
        }
        print $outfh join("\t", @row)."\n";
    }

    close($outfh);

}

sub min_max {
    my ($key1, $key2, $data, $defaults, $tn) = @_;
    croak("Could not find $key1 in data") unless( exists( $data->{$key1} ) );
    croak("Could not find $key2 in data") unless( exists( $data->{$key2} ) );

    my $tn_key = lc($tn)."_default";
    my $def_val;
    if( exists( $defaults->{$tn_key} ) ) {
        $def_val = $defaults->{$tn_key};
    } elsif( exists( $defaults->{'default'} ) ) {
        $def_val = $defaults->{'default'};
    } else {
        croak("Could not find default for $defaults->{'header'}");
    }

    my ($def_min, $def_max) = split(/-/, $def_val);

    my $min = $data->{$key1}->{lc($tn)};
    if( !defined( $min ) || $min eq "" || $min eq 'NA' ) {
        $min = $def_min;

    ## If we need to reformat the input value for display.
    } elsif( exists( $defaults->{'display'} ) ) {
        if( exists( $display_dispatch{$defaults->{'display'}} ) ) {
            $min = $display_dispatch{$defaults->{'display'}}->($min)
        }
    }
    my $max = $data->{$key2}->{lc($tn)};
    if( !defined( $max ) || $max eq "" || $max eq "NA" ) {
        $max = $def_max;
    } elsif( exists( $defaults->{'display'} ) ) {
        if( exists( $display_dispatch{$defaults->{'display'}} ) ) {
            $max = $display_dispatch{$defaults->{'display'}}->($max)
        }
    }

    return join("-", ($min,$max));

}


########################################################################################
# Internal                                                                             #
########################################################################################
sub process_dac {
    my ($ws) = @_;

    my ($row_min, $row_max) = $ws->row_range();
    my ($col_min, $col_max) = $ws->col_range();

    my $data = {};

    my $tumor_col;
    my $normal_col;
    for my $row ( $row_min .. $row_max ) {

        ## Determine tumor and normal column numbers
        unless( $tumor_col ) {
            for my $col ( $col_min .. $col_max ) {
                my $cell = $ws->get_cell($row, $col);
                next unless( $cell );
                my $header_val = $cell->unformatted();
                if( $header_val =~ /tumor/i ) {
                    $tumor_col = $col;
                } elsif( $header_val =~ /normal/i ) {
                    $normal_col = $col;
                }
            }

            ## Make sure we've found both normal and tumor columns
            croak("Could not find normal column in Data Acceptance Criteria worksheet")
            unless( defined( $normal_col ) );
            croak("Could not find tumor column in Data Acceptance Criteria worksheet")
            unless( defined( $tumor_col ) );
        }

        my $criteria_cell = $ws->get_cell( $row, $col_min );

        ## Skip the row if there is no criteria label.
        next unless( $criteria_cell );

        my $criteria = $criteria_cell->unformatted();
        next unless( $criteria && $criteria ne "" );

        my $tumor_value_cell = $ws->get_cell( $row, $tumor_col );
        my $normal_value_cell = $ws->get_cell( $row, $normal_col );

        my $tumor_value = "NA";
        my $normal_value = "NA";
        $tumor_value = $tumor_value_cell->unformatted() if( $tumor_value_cell );
        $normal_value = $normal_value_cell->unformatted() if( $normal_value_cell );

        $data->{$criteria} = {
            'tumor' => $tumor_value,
            'normal' => $normal_value
        };
    }

    return $data;
}

sub process_analysis_settings {
    my ($ws) = @_;

    my ($row_min, $row_max) = $ws->row_range();
    my ($col_min, $col_max) = $ws->col_range();

    my $retval = {};

    my $section;
    for my $row ( $row_min .. $row_max ) {
        my $cell = $ws->get_cell( $row, $col_min + 1 );

        if( $cell ) {
            my $val = $cell->unformatted();
            if( $val && $val ne "" ) {
                ## We should already be in a section
                croak("Could not find section header [$val]") unless( $section );

                ## Check the label column and store label => value;
                my $label_cell = $ws->get_cell( $row, $col_min );
                croak("Could not find a label for value: $val") unless( $label_cell );
                my $label = $label_cell->unformatted();
                $retval->{$section}->{$label} = $val;
            } else {
                my $section_cell = $ws->get_cell( $row, $col_min );
                unless( $section_cell ) {
                    undef( $section );
                    next;
                }
                $section = $section_cell->unformatted();
            }
        } else {
            my $section_cell = $ws->get_cell( $row, $col_min );
            unless( $section_cell ) {
                undef( $section );
                next;
            }
            $section = $section_cell->unformatted();
        }
    }

    return $retval;
}


1;
