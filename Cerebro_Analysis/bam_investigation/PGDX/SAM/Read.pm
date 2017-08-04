package PGDX::SAM::Read;

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

use constant KEEP_INIT_LINE => 0;


#### Constructor

sub new {
    my $class = shift;
    my ($args) = @_;

    my $self = bless {
        line => $args->{line},
        line_ary => [],
        aggregate_quality => 0
    }, $class;

    @{$self->{line_ary}} = split(/\t/, $self->{line});
    if (! KEEP_INIT_LINE) {
        undef $self->{line};
    }

    return $self;
}


#### Getters

sub qname {
    my $self = shift;
    return $self->{line_ary}->[0];
}

sub flag {
    my $self = shift;
    return $self->{line_ary}->[1];
}

sub rname {
    my $self = shift;
    return $self->{line_ary}->[2];
}

sub pos {
    my $self = shift;
    return $self->{line_ary}->[3];
}

sub mapq {
    my $self = shift;
    return $self->{line_ary}->[4];
}

sub cigar {
    my $self = shift;
    return $self->{line_ary}->[5];
}

sub rnext {
    my $self = shift;
    return $self->{line_ary}->[6];
}

sub pnext {
    my $self = shift;
    return $self->{line_ary}->[7];
}

sub tlen {
    my $self = shift;
    return $self->{line_ary}->[8];
}

sub seq {
    my $self = shift;
    return $self->{line_ary}->[9];
}

sub qual {
    my $self = shift;
    return $self->{line_ary}->[10];
}

# Sum of Phred quality score of each base from QUAL, subtract 33 from each ASCII char value
sub aggregate_quality {
    my $self = shift;

    if (! $self->{aggregate_quality}) {
        for (unpack("C*", $self->qual())) {
            $self->{aggregate_quality} += ($_ - 33);
        }
    }

    return $self->{aggregate_quality};
}


#### Methods

sub get_sam_line {
    my $self = shift;
    return join("\t", @{$self->{line_ary}});
}

# Expects flag to be specified as a hex literal.  E.g., 0x200
sub is_flag {
    my $self = shift;
    my $flag = shift;
    return ($self->{line_ary}->[1] & $flag);
}

# Expects flag to be specified as a hex literal.  E.g., 0x200
sub set_flag_bit {
    my $self = shift;
    my $flag = shift;

    $self->{line_ary}->[1] |= $flag;

    return;
}

# Expects flag to be specified as a hex literal.  E.g., 0x200
sub unset_flag_bit {
    my $self = shift;
    my $flag = shift;

    $self->{line_ary}->[1] &= ~$flag;

    return;
}

# For each read/contig in a SAM file, it is required that one and only one line associated with the read satisfies
# 'FLAG & 0x900 == 0'.  This line is called the primary line of the read.
sub is_primary_line {
    my $self = shift;
    return (($self->{line_ary}->[1] & 0x900) == 0);
}

# If RNEXT would be identical to RNAME, it is set as '=', generally indicating the mate is from the same chromosome.
sub is_rnext_equal {
    my $self = shift;
    return ($self->{line_ary}->[6] eq '=');
}

sub get_tag_ary {
    my $self = shift;
    return (@{$self->{line_ary}}[11..$#{$self->{line_ary}}]);
}

sub get_tag {
    my $self = shift;
    my $key = shift;
    my @key_tag_ary = grep { /^$key:/ } $self->get_tag_ary();
    return $key_tag_ary[0];
}

# Adds or updates a tag with the supplied value
sub set_tag {
    my $self = shift;
    my $tag = shift;

    $tag =~ m/^(.*?):/;
    my $key = $1;

    my $key_tag = $self->get_tag($key);
    if (! $key_tag) {
        push(@{$self->{line_ary}}, $tag);
    } else {
        s/$key_tag/$tag/ for @{$self->{line_ary}}[11..$#{$self->{line_ary}}];
    }
}

sub get_map_info_tuple {
    my $self = shift;
    my $map_info_tuple = $self->rname() . '|' . $self->pos() . '|';
    $map_info_tuple .= ($self->is_flag(0x10)) ? 'rev' : 'fwd';
    $map_info_tuple .= '|' . $self->cigar();
}

# TODO: Evaluate accuracy of PNEXT claim in other aligners
sub is_mate {
    my $self = shift;
    my $potential_mate = shift;    

    my $is_mate = 0;

    if ($potential_mate->qname() eq $self->qname() &&
        (($potential_mate->is_flag(0x40) && $self->is_flag(0x80)) || ($potential_mate->is_flag(0x80) && $self->is_flag(0x40))) &&
        $self->pnext() == $potential_mate->pos() && $self->pos() == $potential_mate->pnext()) {
        $is_mate = 1;
    }

    return $is_mate;    
}


1;
