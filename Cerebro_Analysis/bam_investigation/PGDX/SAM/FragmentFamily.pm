package PGDX::SAM::FragmentFamily;

use strict;
use warnings;

use File::Basename qw(dirname);
use File::Spec;

my ($cwd);
BEGIN {
    # Set the version for general version checking
    our $VERSION = 0.01;

    $cwd = File::Spec->rel2abs(__FILE__);
    # Remove path components for PGDX/Your/Module.pm
    $cwd = dirname($cwd);
    $cwd = dirname($cwd);
    $cwd = dirname($cwd);
}
# Add cwd to @INC, often required for use of PGDX::* modules
use lib "$cwd";

use List::MoreUtils qw{ indexes };

use constant ERR_CORRECT_TAG => 'dF:Z:EC';


#### Constructor

sub new {
    my $class = shift;
    my ($args) = @_;

    my $self = bless {
        map_info_tuple => $args->{map_info_tuple},
        fragment_ary => [],
        n => 0,
        modal_seq => '',
        m => 0,
        k => 0,
        representative_fragment => undef
    }, $class;

    return $self;
}


#### Getters

sub map_info_tuple {
    my $self = shift;
    return $self->{map_info_tuple};
}

sub fragment_ary {
    my $self = shift;
    return $self->{fragment_ary};
}

sub n {
    my $self = shift;
    return $self->{n};
}

sub modal_seq {
    my $self = shift;
    return $self->{modal_seq};
}

sub m {
    my $self = shift;
    return $self->{m};
}

sub k {
    my $self = shift;
    return $self->{k};
}

sub representative_fragment {
    my $self = shift;
    return $self->{representative_fragment};
}


#### Methods

sub add_fragments {
    my $self = shift;
    my @fragments = shift;

    $self->{n} = push(@{$self->{fragment_ary}}, @fragments);
}

# Alias for M
sub coverage {
    my $self = shift;
    return $self->m();
}

sub proportion {
    my $self = shift;
    return ($self->m() / $self->n());
}

sub dominance {
    my $self = shift;
    return (($self->m() - $self->k()) / $self->n());
}

# Return a string of SAM-formatted lines for all Reads found in all Fragments in this family
sub get_sam_lines {
    my $self = shift;

    my $sam_lines = '';
    for my $fragment (@{$self->{fragment_ary}}) {
        $sam_lines .= $fragment->mate1()->get_sam_line() . "\n";
        $sam_lines .= $fragment->mate2()->get_sam_line() . "\n";
    }

    return $sam_lines;
}

sub generate_consensus {
    my $self = shift;
    $self->_calc_modal_seq();
    $self->_calc_error_correction();
}

# Determine modal sequence and calculate M and K.  Assign representative fragment.
sub _calc_modal_seq {
    my $self = shift;
    my (%seq_map);

    for my $fragment (@{$self->{fragment_ary}}) {
        if (! $seq_map{$fragment->fragment_seq()}) {
            $seq_map{$fragment->fragment_seq()} = 1;
        } else {
            $seq_map{$fragment->fragment_seq()}++;
        }
    }

    # Sort in reverse order by frequency, then in ascending order by fragment sequence.
    # First key is the modal fragment sequence, first value is M, second value is K.
    my $i = 1;
    for my $seq (sort { $seq_map{$b} <=> $seq_map{$a} or $a cmp $b } keys %seq_map) {
        if ($i == 1) {
            $self->{modal_seq} = $seq;
            $self->{m} = $seq_map{$seq};
            $i++;
        } else {
            $self->{k} = $seq_map{$seq};
            last;
        }
    }

    # Collect fragments matching the modal sequence
    my @modal_fragment_ary = grep { $_->fragment_seq() eq $self->modal_seq() } @{$self->{fragment_ary}};
    if (@modal_fragment_ary > 1) {
        # Sort by highest aggregate base quality, lowest lexicographic QNAME
        @modal_fragment_ary = sort { $b->aggregate_quality() <=> $a->aggregate_quality() or $a->mate1()->qname() cmp $b->mate1()->qname() } @modal_fragment_ary;
    }
    $self->{representative_fragment} = $modal_fragment_ary[0];

    # Add dM:i:1 tag for fragments with modal sequence (regardless of representative nature)
    my $representative_qname = $modal_fragment_ary[0]->mate1()->qname();
    for my $fragment (@modal_fragment_ary) {
        $fragment->mate1()->set_tag('dM:i:1');
        $fragment->mate2()->set_tag('dM:i:1');
    }

    for my $fragment (@{$self->{fragment_ary}}) {
        # For all fragments, add dR:Z:QNAME tag to point to representative fragment
        $fragment->mate1()->set_tag('dR:Z:' . $representative_qname);
        $fragment->mate2()->set_tag('dR:Z:' . $representative_qname);

        # Set flags and tags (0x400 for non-representative, dC:i:N for representative)
        if ($fragment->mate1()->qname() eq $self->representative_fragment()->mate1()->qname()) {
            $fragment->mate1()->set_tag('dC:i:' . $self->{n});
            $fragment->mate2()->set_tag('dC:i:' . $self->{n});
        } else {
            $fragment->mate1()->set_flag_bit(0x400);
            $fragment->mate2()->set_flag_bit(0x400);
        }
    }
}

# Determine if family passes error correction, set flags and tags if not
sub _calc_error_correction {
    my $self = shift;

    my $pass = ($self->coverage() >= 3 && $self->proportion() >= 0.7 && $self->dominance() >= 0.5);
    if (! $pass) {
        for my $fragment (@{$self->{fragment_ary}}) {
            $fragment->mate1()->set_flag_bit(0x200);
            $fragment->mate1()->set_tag(ERR_CORRECT_TAG);
            $fragment->mate2()->set_flag_bit(0x200);
            $fragment->mate2()->set_tag(ERR_CORRECT_TAG);
        }
    }
}


1;
