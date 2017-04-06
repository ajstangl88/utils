=head1 NAME

PGDX::SampleSheet.pm

=head1 DESCRIPTION

Functions to parse and process Illumina Samplesheets

=head1 AUTHOR

David Riley

driley@personalgenome.com

=cut

package PGDX::SampleSheet;
use strict;
use File::Temp;
use File::Basename;

my $MISEQ_FIELDS_TO_KEYS = {
    'Lane' => 'lane',
    'Sample_ID' => 'sample',
    'SampleID' => 'sample',
    'Sample_Name' => 'alt_samplename',
    'Sample_Plate' => 'plate',
    'Sample_Well' => 'well',
    'Sample_Project' => 'project',
    'SampleProject' => 'project',
    'Operator' => 'operator',
    'index' => 'index',
    'Index' => 'index',
    'index2' => 'index2',
    'Index2' => 'index2',
    'I7_Index_ID' => 'index_id',
    'I5_Index_ID' => 'index_id2',
    'Description' => 'description'
};

################################################
# Call this function with the following config:
# { file => '/path/to/samplesheet.csv',
#   [include => 'CpCS,CpBR',
#    exclude => 'Cp4']
# }
################################################
sub new {
    my ($class, $config) = @_;

    my $self = {};
    my @includes;
    @includes = split(/,/,$config->{include});
    my @excludes;
    @excludes = split(/,/,$config->{exclude});

    $self->{'file'} = $config->{'file'};
    $self->{'include'} = \@includes;
    $self->{'exclude'} = \@excludes;
    $self->{'adapter_fasta'} = $config->{adapter_fasta};
    $self->{'samples'} = {};
    $self->{'rows'} = [];
    $self->{'adapter_type'} = $config->{adapter_type} ? $config->{adapter_type} : 'Mask';

    ## Make a temp directory to write to.
    my $temp_dir = File::Temp->newdir(
        'DIR' => '/mnt/scratch',
        'TEMPLATE' => 'sampleSheetXXXXXXXX'
    );
    $self->{'temp_dir'} = $temp_dir;

    bless $self;

    if($self->{'file'}) {
        $self->parse();
    }

    return $self;
}


sub parse {
    my $self = shift;

    my $file = $self->{file};

    my $type = $self->detect_type();
    if($type eq 'hiseq') {
        $self->process_hiseq();
    }
    elsif($type eq 'miseq') {
        $self->process_miseq();
    }
}

sub detect_type {
    my $self = shift;

    my $file = $self->{file};

    ## Copy the file to a temporary directory
    my $tdir = $self->{'temp_dir'};
    system("cp $file $tdir");
    my $basename = basename( $file );
    my $new_file = $tdir."/".$basename;
    die("Could not copy SampleSheet [$file] to temporary directory [$tdir]")
    unless( -e $new_file );

    `dos2unix $new_file &> /dev/null`;
    my $fl = `head -1 $file`;

    my $type;
    # iF this samplesheet is already reformatted we'll just reprint.
    if($fl =~ /^FCID/) {
        $type = 'hiseq';
    }
    else {
        $type = 'miseq';
    }
}

sub get_samplenames {
    my $self = shift;
    if($self->{samplenames}) {
        return sort keys %{$self->{samplenames}};
    }
    else {
        return sort keys %{$self->{samples}};
    }
}

# Parse a hiseq samplesheet
sub process_hiseq {

    my $self = shift;

    my $file = $self->{file};

    open IN, "<$file" or die "Couldn't open the samplsheet!\n";
    my %s;
    while(my $line = <IN>) {
        $line =~ s/\r\n//g;    
        chomp $line;
        next if $line =~ /^FCID/;
        my @f = split(/,/,$line);
        my $sample = $f[2];
        my $orig_sample = $sample;
        next if !$sample;
        $sample = &_fix_names($sample);
        $f[2] = $sample;
        $f[9] =~ s/ /_/g; # Take out spaces in the project name.
        if($self->_check_sample_filters($sample)) {        
            if(!$self->{samples}->{$sample}->{$f[1]}->{$f[4]}) {
                my $tmp = {
                    'flowcell' => $f[0],
                    'lane' => $f[1],
                    'sample' => $sample,
                    'reference' => $f[3],
                    'index' => $f[4],                    
                    'description' => $f[5],
                    'control' => $f[6],
                    'recipe' => $f[7],
                    'operator' => $f[8],
                    'project' => $f[9],
                    'row' => \@f
                };
                $self->{samplenames}->{$sample} = 1;

                $self->{'samples'}->{$sample}->{$f[1]}->{$f[4]} = $tmp;

                ## I don't think this ever did anything. self->{samples}->{$sample} never
                ## existed (although it does now).
                # Deal with the description field
                #my $desc = $f[5];
                #&_parse_description($desc,$self->{samples}->{$sample});
            }
            push(@{$self->{'rows'}}, \@f);
        }
    }
}


sub get_header {
    my $self = shift;

    my @headers;

    foreach my $key (keys %{$self->{header}}) {
        push(@headers,join(',',($key,$self->{header}->{$key})));
    }
    return join("\n",("[Header]",@headers))."\n";
}

sub get_reads {
    my $self = shift;
    return join("\n",("[Reads]",@{$self->{reads}}))."\n";
}

sub get_settings {
    my $self = shift;
    my @settings;

    foreach my $key (keys %{$self->{settings}}) {
        push(@settings,join(',',($key,$self->{settings}->{$key})));
    }
    return join("\n",("[Settings]",@settings))."\n";
}

sub get_data_header {
    my $self = shift;

    return "[Data]\n".join(',',(@{$self->{data_header}}))."\n";

}

sub get_adapter {
    my $self = shift;
    $self->set_adapter();

    return {
        adapter1 => $self->{adapter1},
        adapter2 => $self->{adapter2}
    };
}

sub set_adapter {
    my $self = shift;
    if(!$self->{adapter1} && $self->{adapter_fasta}) {
        open IN, "<$self->{adapter_fasta}" or die "Couldn't open adapter fasta file $self->{adapter_fasta}\n";
        my $readnum;
        my $seq = '';
        while(my $line = <IN>) {
            chomp $line;
            if($line =~ /^>Read(\d+)/) {

                if($readnum && $seq) {
                    $self->{"adapter$readnum"} = $seq;
                }
                $readnum = $1;
                $seq = '';
            }
            elsif($line) {
                $seq .= $line;

            }
        }
        if($readnum && $seq) {
            $self->{"adapter$readnum"} = $seq;
        }
    }
    close IN;
}

# Parse a miseq samplesheet
sub process_miseq {

    my $self = shift;

    my $file = $self->{file};

    my $project;
    my $experiment;
    my $section;
    my $columns;
    my $sampleindex = 0;

    open IN, "<$file" or die "Couldn't open the samplsheet!\n";
    while(my $line = <IN>) {
        $line =~ s/\r\n//g;
        chomp $line;
        if($line =~ /^\[(\w+)\]/) {
            $section=$1;
            next;
        }
        if($section eq 'Header') {
            my @f = split(/,/,$line);
            if($f[0] eq 'Experiment Name') {
                $f[1] =~ s/\s/_/g;
                #                $metadata .= " -m experiment_name='$f[1]'";
                $experiment = $f[1];
            }
            elsif($f[0] eq 'Project Name') {
                $f[1] =~ s/\s/_/g;
                $project = $f[1];
                #                $metadata .= " -m project_name='$f[1]'";
            }
            if($f[0]) {
                $self->{header}->{$f[0]} = $f[1];
            }
        }
        elsif($section eq 'Reads') {
            if($line) {
                push(@{$self->{reads}},$line);
            }
        }
        elsif($section eq 'Settings') {
            my @f = split(/,/,$line);
            if($f[0] =~ /Adapter/) {
                #$f[0] = "$self->{adapter_type}$f[0]";
            }
            elsif($f[0]) {
                $self->{settings}->{$f[0]} = $f[1];
            }
        }
        elsif($section eq 'Data') {
            my @f = split(/,/,$line,-1);

            if($f[0] && ($f[0] eq 'Sample_ID' || $f[0] eq 'SampleID' || $f[0] eq 'Lane')) {
                $self->{data_header} = \@f;
                for (my $i=0;$i < @f;$i++) {
                    $columns->{$f[$i]} = $i;
                }
            }
            elsif($f[0] && ($f[0] ne 'Sample_ID' && $f[0] ne 'Lane')) {

                my $sample = {};
                foreach my $c (keys %$columns) {
                    if($MISEQ_FIELDS_TO_KEYS->{$c}) {
                        if($MISEQ_FIELDS_TO_KEYS->{$c} eq 'sample') {
                            $sampleindex = $columns->{$c};
                        }
                        $sample->{$MISEQ_FIELDS_TO_KEYS->{$c}} = $f[$columns->{$c}];
                        $sample->{rawfields}->{$c} = $f[$columns->{$c}];
                    }
                    else {
                        print STDERR "Didn't find a field name for $c\n";
                    }
                }
                $sample->{'sample'} = &_fix_names($sample->{'sample'});
                $f[$sampleindex] = $sample->{'sample'}; # Assumes the first field is the sample
                if($self->_check_sample_filters($sample->{'sample'})) {
                    my $index = $sample->{index};
                    if($sample->{index2}) {
                        $index = $sample->{index}.'-'.$sample->{index2};
                    }
                    $sample->{row} = \@f;
                    $sample->{'lane'} = 1 unless( exists( $sample->{'lane'} ) );
                    $self->{samples}->{$sample->{'sample'}}->{$sample->{lane}}->{$index} = $sample;
                    push(@{$self->{rows}}, \@f);
                }
            }
        }
    }

    my $adapters = $self->get_adapter();
    if($adapters) {
        $self->{settings}->{"$self->{adapter_type}Adapter"} = $adapters->{adapter1};
        if($adapters->{adapter2}) {
            $self->{settings}->{"$self->{adapter_type}AdapterRead2"} = $adapters->{adapter2};
        }
    }


    $self->{project} = $project;
    $self->{experiment} = $experiment;
}

sub get_tags {
    my $self = shift;
    my $filter = shift;
    my $suffix = shift;

    my $tags;

    my $samples = $self->{samples};
    my $project = $self->{project};
    my $experiment = $self->{experiment};
    my $metadata = $self->{metadata} ? $self->{metadata} : {};
    $filter = $filter ? $filter : '.'; # If there is no filter then we'll take anything
    my @patterns = split(/,/,$filter);

    # Loop through all the patterns     
    foreach my $sample (keys %$samples) {
        foreach my $lane (keys %{$samples->{$sample}}) {
            foreach my $index (keys %{$samples->{$sample}->{$lane}}) {
                my $sobj = $samples->{$sample}->{$lane}->{$index};

                foreach my $p (@patterns) {
                    if($sample =~ /$p/) {
                        my $ntag = $sample.$suffix;
                        $tags->{$ntag} = {
                            tag_name => $ntag,
                            files => [],
                            metadata => $metadata
                        };
                        if($experiment) {
                            $tags->{$ntag}->{metadata}->{'experiment_name'} = $experiment;
                        }
                        if($project) {
                            $tags->{$ntag}->{metadata}->{'project_name'} = $project;
                        }
                        if($sobj->{'project'}) {
                            $tags->{$ntag}->{metadata}->{'sample_project'} = $sobj->{'project'};
                        }
                        if($sample) {
                            $tags->{$ntag}->{metadata}->{'sample_name'} = $sample;
                        }                
                    }
                }
            }
        }
    }
    my $ret_tags = [];
    map {
        push(@$ret_tags,$tags->{$_});
    }keys %$tags;

    return $ret_tags;
}


sub _parse_description {
    my ($desc,$sample) = @_;


    my @fields = split(/;/,$desc);
    my $tumor_purity;
    my $match_sample;
    my $validation = 0;
    foreach my $q (@fields) {
        if($q =~ /([^=]+)=([^=]+)/) {
            my $k = $1;
            my $v = $2;
            if($k eq 'TP') {
                $tumor_purity = $v;
            }
            elsif($k eq 'TN') {
                $match_sample = $v;
            }
            elsif($k eq 'VAL') {
                $validation = 'Yes';
            }
        }
    }
    if($tumor_purity) {
        $sample->{'tumor_purity'} = $tumor_purity;
    }
    if($match_sample) {
        $sample->{'match_sample'} = $match_sample;
    }
    if($validation) {
        $sample->{'validation'} = $validation;
    }
}

# Generic subroutine to correct samplenames.
sub _fix_names {
    my $samplename = shift;
    my $updatedname = $samplename;

    #PlasmaSelect Seq.
    #    if($samplename =~ /^(.*)_PS_Seq_\d+_(PS_Seq.*)$/) {
    #        $updatedname="$1\_$2";
    #    }
    #    elsif($samplename =~ /^(.*)_\d+_(PS_Seq.*)$/) {
    #        $updatedname="$1\_$2";
    #    }
    #    #PlasmaSelect Str.
    #    elsif($samplename =~ /^(.*)_PS_Str_\d+_(PS_Str.*)$/) {
    #        $updatedname="$1\_$2";
    #    }    
    #    elsif($samplename =~ /^(.*)_\d+_(PS_Str.*)$/) {
    #        $updatedname="$1\_$2";
    #    }    
    # Anything with _[digits]i like PGDX1234P_PS_Seq_8i
    if($samplename =~ /^(.*)_\d+i(.*)/) {
        $updatedname = "$1$2";
    }
    return $updatedname;
}

sub _check_sample_filters {
    my $self = shift;
    my $sample = shift;

    my $keep = 1;
    # If we have an includes list then we will default to remove
    if($self->{include} && scalar @{$self->{include}}) {
        $keep =0;
        foreach my $inc (@{$self->{include}}) {
            if($sample =~ /$inc/i) {
                $keep = 1;
            }
        }
    }

    # If we have an excludes list we'll remove any matches.
    if($self->{exclude} && scalar @{$self->{exclude}}) {
        foreach my $exc (@{$self->{exclude}}) {
            if($sample =~ /$exc/i) {
                $keep = 0;
            }
        }
    }
    return $keep;
}

1;
