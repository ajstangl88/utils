#!/usr/bin/perl

use strict;
use Pod::Usage;
use Cwd 'abs_path';
use Cwd;
use File::Basename;
use Data::Dumper;
use File::Copy  "cp";
use File::Copy qw(move);
use Getopt::Long qw(:config no_ignore_case bundling);


my %options;
GetOptions (\%options,  'filepath:s', 'type:s','combined:s' );


my $file = $options{'filepath'};
my $mode = $options{'combined'};
my $type = $options{'type'};



# Detects if the sheet is CNA, Rear, or Changes
my $Filetype =  &detect_fileType();



# Test for Changes and Write Out Changes
if ($Filetype eq "changes") {
    &writeTopHeader();
    &writeChangesHeader();
    &writeMainHeader();
    &writeChangesVCF();
}

# Test for CNA and Write out CNA VCF
if ($Filetype eq "cna") {
    &writeTopHeader();
    &writeCNAHeader();
    &writeMainHeader();
    &writeCNAVCF();
}

# Test for Rearrangments and Write Rearrangments
if ($Filetype eq "rearrangements") {
    &writeTopHeader();
    &writeRearHeader();
    &writeMainHeader();
    &writeRearVCF();
}

##########################################
# Routines for Individual VCF Generation #
#########################################

sub writeMainHeader {
    my $headerString = "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\n";
    print $headerString;
}
sub writeTopHeader {
    my $str = "##fileformat=VCFv4.1\n##reference=hg19\n";
    print $str;
    return $str;
}

sub writeChangesHeader {
    my @header = (
        '##INFO=<ID=TD,Number=1,Type=Integer,Description="TOTAL DEPTH">',
        '##INFO=<ID=AF,Number=A,Type=Float,Description="ALLELE FREQUENCY">',
        '##INFO=<ID=GI,Number=A,Type=String,Description="GENE ID">',
        '##INFO=<ID=TI,Number=A,Type=String,Description="TRANSCRIPT ID">',
        '##INFO=<ID=FC,Number=A,Type=String,Description="FUNCTIONAL CONSEQUENCE">',
        '##INFO=<ID=MU,Number=A,Type=String,Description="MUTATION STRING">',
        '##INFO=<ID=DP,Number=A,Type=String,Description="DISTINCT PAIRS">',
    );
    my $string = '';
    foreach my $element (@header) {
        $string = $string."$element\n";
    }
    unless ($mode) {print $string;}

    return $string;
}
sub writeChangesVCF {
my $header_lookup;
$header_lookup = &getChangesHeaderIndex(
    { changes   => $file,
        headers =>
        [
            'ChangeUID',
            'GeneName',
            'Description',
            'Report: SupermutantMutPct',
            'Report: MutPct',
            'DistinctPairs',
            'DistinctCoverage',
            'Consequence',
            'Transcript',
            'VEP: HGVS AAChange',
            'VEP: HGVS Codon Change',
            'Report: AAChange',
            'Start',
            'End',
            'Chrom',
            'BaseFrom',
            'BaseTo',
            'dbSNP: Name',
            'MutPct',
            'VEP: HGVS AAChange'

        ]
    });


my @line;
open IN, "<", "$file" or do {print STDERR "Couldn't Open $file\n"; exit 0;};
my $h = <IN>;
my @row;
while (my $line = <IN>) {
    chomp $line;
    @row = split(/\t/, $line);

    my $chrom = $row[$header_lookup->{'Chrom'}] ? $row[$header_lookup->{'Chrom'}] : ".";
    $chrom =~ s/chr//g;
    $chrom =~ s/.fa//g;

    my $pos = $row[$header_lookup->{'Start'}] ? $row[$header_lookup->{'Start'}] : ".";

    my $id = $row[$header_lookup->{'dbSNP: Name'}] ? $row[$header_lookup->{'dbSNP: Name'}] : ".";

    my $ref = $row[$header_lookup->{'BaseFrom'}] ? $row[$header_lookup->{'BaseFrom'}] : ".";

    my $alt = $row[$header_lookup->{'BaseTo'}] ? $row[$header_lookup->{'BaseTo'}] : ".";

    my $qual = ".";

    my $filter = "PASS";

    my $info1 = $row[$header_lookup->{'DistinctCoverage'}] ? $row[$header_lookup->{'DistinctCoverage'}] : ".";

    my $info2;
    if ($type eq 'PlasmaSelect2') {
        $info2 = $row[$header_lookup->{'Report: SupermutantMutPct'}] ? $row[$header_lookup->{'Report: SupermutantMutPct'}] : ".";
        }
    else {
        $info2 = $row[$header_lookup->{'MutPct'}] ? $row[$header_lookup->{'MutPct'}] : ".";
    }

    my $info3 = $row[$header_lookup->{'GeneName'}] ? $row[$header_lookup->{'GeneName'}] : ".";

    my $info4 = $row[$header_lookup->{'Transcript'}] ? $row[$header_lookup->{'Transcript'}] : ".";

    my $info5 = $row[$header_lookup->{'Consequence'}] ? $row[$header_lookup->{'Consequence'}] : ".";
    $info5 = uc $info5;

    my $info6;
    if(lc($info5) =~ /splice/) {
        $info6 = $row[$header_lookup->{'Report: AAChange'}] ? $row[$header_lookup->{'Report: AAChange'}] : ".";
    }
    else {
        $info6 = $row[$header_lookup->{'VEP: HGVS AAChange'}] ? $row[$header_lookup->{'VEP: HGVS AAChange'}] : ".";
    }

    my $info7 = $row[$header_lookup->{'DistinctPairs'}] ? $row[$header_lookup->{'DistinctPairs'}] : ".";


    my $totalInfo = "TD=$info1;AF=$info2;GN=$info3;TI=$info4;FC=$info5;MU=$info6;DP=$info7;";

    my $str = "$chrom\t$pos\t$id\t$ref\t$alt\t$qual\t$filter\t$totalInfo";

    push @line, $str;
}

close IN;

unless($mode) {
    foreach my $elem (@line) {
        print "$elem\n";
    }
}
return @line;

}

sub writeCNAHeader {
    my @header = (
        '##ALT=<ID=CNV,Number=1,Type=String,Description="COPY NUMBER VARIABLE REGION">',
        '##INFO=<ID=GN,Number=A,Type=Integer,Description="GENE">',
        '##INFO=<ID=CN,Number=A,Type=Float,Description="FOLD">',
        '##INFO=<ID=END,Number=A,Type=Integer,Description="END POSITION OF THE VARIANT DESCRIBED IN THIS RECORD">'
    );
    my $string = '';
    foreach my $element (@header) {
        $string = $string."$element\n";
    }
    unless ($mode) {print $string;}

    return $string;
}
sub writeCNAVCF {
    my $header_lookup;
    $header_lookup = &getChangesHeaderIndex(
        {
            changes   => $file,
            headers =>
                [
                    'Lookup ID',
                    'AddlInfo',
                    'Name',
                    'Fold'
                ]
        });
    my @line;
    open IN, "<", "$file" or do {print STDERR "Couldn't Open $file\n"; exit 0;};
    my $h = <IN>;
    my @row;
    while (my $line = <IN>) {
        chomp $line;
        @row = split(/\t/, $line);

        my $chrom = $row[$header_lookup->{'Lookup ID'}] ? $row[$header_lookup->{'Lookup ID'}] : ".";
        $chrom = &parseChr($chrom);

        my $pos = $row[$header_lookup->{'Lookup ID'}] ? $row[$header_lookup->{'Lookup ID'}] : ".";
        $pos = parseStart($pos);

        my $id = ".";

        my $ref = ".";

        my $alt = "CNV";

        my $qual = ".";

        my $filter = "PASS";

        my $info1 = $row[$header_lookup->{'Name'}] ? $row[$header_lookup->{'Name'}] : ".";

        my $info2 = $row[$header_lookup->{'Fold'}] ? $row[$header_lookup->{'Fold'}] : ".";

        my $info3 = $row[$header_lookup->{'Lookup ID'}] ? $row[$header_lookup->{'Lookup ID'}] : ".";
        $info3 = &parseEnd($info3);

        my $totalInfo = "GN=$info1;CN=$info2;END=$info3;";
        my $str = "$chrom\t$pos\t$id\t$ref\t$alt\t$qual\t$filter\t$totalInfo";
        push @line, $str;
    }
    close IN;

    unless($mode) {
        foreach my $elem (@line) {
            print "$elem\n";
        }
    }
return @line;
}

sub writeRearHeader {
     my @header = (
         '##INFO=<ID=GN1,Number=A,Type=Integer,Description="GENE1 IN REARRANGMENT">',
         '##INFO=<ID=GN2,Number=A,Type=Integer,Description="GENE2 IN REARRANFMENT">',
         '##INFO=<ID=CIPOS,Number=2,Type=Integer,Description="Confidence interval around POS for imprecise variants">',
         '##INFO=<ID=END,Number=A,Type=Integer,Description="END POSITION OF THE VARIANT DESCRIBED IN THIS RECORD">',
         '##INFO=<ID=SVLEN,Number=.,Type=Integer,Description="Difference in length between REF and ALT alleles">',
         '##INFO=<ID=SVTYPE,Number=1,Type=String,Description="Type of structural variant">',
         '##ALT=<ID=DEL,Description="Deletion"',
         '##ALT=<ID=INV,Description="Inversion">'

     );
    my $string = '';
    foreach my $element (@header) {
        $string = $string."$element\n";
    }
    unless ($mode) {print $string;}

    return $string;
}
sub writeRearVCF {
    my $header_lookup;
    $header_lookup = &getChangesHeaderIndex({
            changes   => $file,
            headers =>
            [
                'Breakpoint_side_1',
                'Breakpoint_side_2',
                'Gene_side_1',
                'Gene_side_2',
                'Rearrangement_Type',
            ]
        });


    my @line;
    open IN, "<", "$file" or do {print STDERR "Couldn't Open $file\n"; exit 0;};
    my $h = <IN>;
    my @row;
    while (my $line = <IN>) {
        chomp $line;
        @row = split(/\t/, $line);
        my $chrom;
        my $pos;
        my $id;
        my $ref;
        my $alt;
        my $qual;
        my $filter;
        my $end;
        # Gene 1
        my $info1;
        # Gene 2
        my $info2;
        # SVTYPE
        my $info3;
        # SVLEN
        my $info4;
        # CIPOS or END
        my $info5;
        # END
        my $info6;

        $chrom = $row[$header_lookup->{'Breakpoint_side_1'}] ? $row[$header_lookup->{'Breakpoint_side_1'}] : ".";
        $chrom = &parseChr($chrom);

        $pos = $row[$header_lookup->{'Breakpoint_side_1'}] ? $row[$header_lookup->{'Breakpoint_side_1'}] : ".";
        $pos = &parseRearStart($pos);

        my $rearType = $row[$header_lookup->{'Rearrangement_Type'}] ? $row[$header_lookup->{'Rearrangement_Type'}] : ".";


        # Handle - Deletions
        if ($rearType eq 'Deletion') {
            $id = '.';
            $ref = '.';
            $alt = '<DEL>';
            $qual = '.';
            $filter = 'PASS';
            # Info Field
            #GN1
            $info1 = $row[$header_lookup->{'Gene_side_1'}] ? $row[$header_lookup->{'Gene_side_1'}] : ".";
            # GN2
            $info2 = $row[$header_lookup->{'Gene_side_2'}] ? $row[$header_lookup->{'Gene_side_2'}] : ".";
            # SVType
            $info3 = "DEL";
            # SVLEN
            $end = $row[$header_lookup->{'Breakpoint_side_2'}] ? $row[$header_lookup->{'Breakpoint_side_2'}] : ".";
            $end = &parseRearStart($end);
            $info4 = abs($end - $pos);
            # END
            $info5 = $end;

            my $totalInfo = "GN1=$info1;GN2=$info2;SVTYPE=$info3;SVLEN=$info4;END=$info5;";
            my $str = "$chrom\t$pos\t$id\t$ref\t$alt\t$qual\t$filter\t$totalInfo";
            push @line, $str;
        }

        # Handle Inversions - Similar to Deletions
        if ($rearType eq 'Inversion') {
            $id = 'INV0';
            $ref = '.';
            $alt = '<INV>';
            $qual = '.';
            $filter = 'PASS';
            # Info Field
            #GN1
            $info1 = $row[$header_lookup->{'Gene_side_1'}] ? $row[$header_lookup->{'Gene_side_1'}] : ".";
            # GN2
            $info2 = $row[$header_lookup->{'Gene_side_2'}] ? $row[$header_lookup->{'Gene_side_2'}] : ".";
            # SVType
            $info3 = "INV";
            # SVLEN
            $end = $row[$header_lookup->{'Breakpoint_side_2'}] ? $row[$header_lookup->{'Breakpoint_side_2'}] : ".";
            $end = &parseRearStart($end);
            $info4 = abs($end - $pos);
            # END
            $info5 = $end;
            my $totalInfo = "GN1=$info1;GN2=$info2;SVTYPE=$info3;SVLEN=$info4;END=$info5;";
            my $str = "$chrom\t$pos\t$id\t$ref\t$alt\t$qual\t$filter\t$totalInfo";
            push @line, $str;
        }

        # Handle the Other Case Where Inversions take place.
        else {
            my $chrom1 = $row[$header_lookup->{'Breakpoint_side_1'}] ? $row[$header_lookup->{'Breakpoint_side_1'}] : ".";
            $chrom1 = &parseChr($chrom1);

            my $chrom2 = $row[$header_lookup->{'Breakpoint_side_2'}] ? $row[$header_lookup->{'Breakpoint_side_2'}] : ".";
            $chrom2 = &parseChr($chrom2);

            my $pos1 = $row[$header_lookup->{'Breakpoint_side_1'}] ? $row[$header_lookup->{'Breakpoint_side_1'}] : ".";
            $pos1= &parseRearStart($pos1);

            my $pos2 = $row[$header_lookup->{'Breakpoint_side_2'}] ? $row[$header_lookup->{'Breakpoint_side_2'}] : ".";
            $pos2= &parseRearStart($pos2);

            my $id1 = 'bnd_v';
            my $id2 = 'bnd_u';

            my $ref1 = "N";
            my $ref2 = "N";

            my $alt1 = "N" . "]" . $chrom2 . ":" . $pos2 . "]";
            my $alt2 = "N" . "]" . $chrom1 . ":" . $pos1 . "]";

            my $qual1 = ".";
            my $qual2 = ".";

            my $filter1 = "PASS";
            my $filter2 = "PASS";

            #GN1
            $info1 = $row[$header_lookup->{'Gene_side_1'}] ? $row[$header_lookup->{'Gene_side_1'}] : ".";
            # GN2
            $info2 = $row[$header_lookup->{'Gene_side_2'}] ? $row[$header_lookup->{'Gene_side_2'}] : ".";
            # SV TYPE
            $info3 = "BND";
            # Mated 1
            my $info4_1 = 'bnd_U';
            # Mated 2
            my $info4_2 = 'bnd_V';
            # CIPOS
            my $info5_1 = ("$pos1");
			my $info5_1_2 = $pos1 + 1000;
			my $combinedInfo5_1 = ("$info5_1,$info5_1_2");
            my $info5_2 = ("$pos2");
			my $info5_2_2 = $pos2 + 1000;
			my $combinedInfo5_2 = ("$info5_2,$info5_2_2");
            my $totalInfo1 = "GN1=$info1;GN2=$info2;SVTYPE=$info3;MATED=$info4_1;CIPOS=$combinedInfo5_1";
            my $totalInfo2 = "GN1=$info1;GN2=$info2;SVTYPE=$info3;MATED=$info4_2;CIPOS=$combinedInfo5_2";
            my $str1 = "$chrom1\t$pos1\t$id1\t$ref1\t$alt1\t$qual1\t$filter1\t$totalInfo1\n";
            my $str2 = "$chrom2\t$pos2\t$id2\t$ref2\t$alt2\t$qual2\t$filter2\t$totalInfo2";
            my $str = $str1 . $str2;
            push @line, $str;
        }
    }
     close IN;

    unless($mode) {
        foreach my $elem (@line) {
            print "$elem\n";
        }
    }
return @line;

}


### Aux Functions ###
# Detects the File type (CNA Rearrangment or Changes)
sub detect_fileType {
    my $type = shift;

    # Handle the case where the file is changes
    if (lc $file =~ /[c]hanges|[C]hanges/) {
        $type = "changes";
        return $type;
    };

    # Handle the case where the CNA
    if (lc $file =~ /cna|CNA/) {
        $type = "cna";
        return $type
    };

    # handle the case where the file is rearrangment
    if (lc $file =~ /[r]earrangements|[R]earrangements|[r]earrangement|[R]earrangement/) {
        $type = "rearrangements";
        return $type;
    }
};

# Parses Chromosome for CNA
sub parseChr {
    my $CUID = shift;
    chomp $CUID;
    $CUID =~ /chr(\d+|w+):/;
    my $chr = $1;
    return $chr;

}

# Parses chrom for Start Position
sub parseStart {
    my $CUID = shift;
    chomp $CUID;
    $CUID =~ /\W(\d+)\W/;
    my $start = $1;
    return $start
}

# Parses Rearrangment Start Site
sub parseRearStart {
    my $CUID = shift;
    chomp $CUID;
    $CUID =~ /\W(\d+)/;
    my $start = $1;
    return $start;

}

# Parses End for CNA and Rearrangment
sub parseEnd {
    my $CUID = shift;
    chomp $CUID;
    $CUID =~ /-(\d+)/;
    my $end = $1;
    return $end;

}

# Main Function to get Header Index used for lookup
sub getChangesHeaderIndex {
    my $config = shift;
    my @headers = @{$config->{headers}};

    my $headerslookup;
    map {$headerslookup->{$_}='YES'}@headers;
    open IN, "<$config->{changes}";
    my $head = <IN>; close IN;
    if(!$head) {
        die "Couldn't get the header for $config->{changes} $head\n";
    }
    chomp $head;
    my @hvals = split(/\t/,$head);
    for(my $i =0;$i<@hvals;$i++) {
        if($headerslookup->{$hvals[$i]}) {
            $headerslookup->{$hvals[$i]} = $i;
        }
    }
    return $headerslookup;
}