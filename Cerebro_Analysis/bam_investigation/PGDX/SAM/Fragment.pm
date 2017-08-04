package PGDX::SAM::Fragment;

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


#### Constructor

sub new {
    my $class = shift;
    my ($args) = @_;

    my $self = bless {
        map_info_tuple => '',
        fragment_seq => ''
    }, $class;

    # For some reason, assigning object reference causes issues when included in bless block
    # mate1 and mate2 should be instances of PGDX::SAM:Read
    $self->{mate1} = $args->{mate1} || die "Parameter 'mate1' is required!";
    $self->{mate2} = $args->{mate2} || die "Parameter 'mate2' is required!";

    $self->{map_info_tuple} = $self->{mate1}->get_map_info_tuple() . '|' . $self->{mate2}->get_map_info_tuple() . '|' . $self->{mate1}->get_tag('BC');
    $self->{fragment_seq} = $self->{mate1}->seq() . '-' . $self->{mate2}->seq();

    return $self;
}


#### Getters

sub mate1 {
    my $self = shift;
    return $self->{mate1};
}

sub mate2 {
    my $self = shift;
    return $self->{mate2};
}

sub map_info_tuple {
    my $self = shift;
    return $self->{map_info_tuple};
}

sub fragment_seq {
    my $self = shift;
    return $self->{fragment_seq};
}


#### Methods

sub aggregate_quality {
    my $self = shift;
    return ($self->mate1()->aggregate_quality() + $self->mate2()->aggregate_quality());
}


1;
