#!/usr/bin/perl
use strict;
#use warnings FATAL => 'all';
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev);
use Pod::Usage;
use Cwd 'abs_path';
use File::Basename;
use Data::Dumper;
use IPC::Open3 ();
use IO::Handle (); #not required but good for portabilty
use File::Copy  "cp";
use File::Copy qw(move);



my %options;
GetOptions (\%options,  'filepath:s', 'changes', 'loci_changes', 'rearrangements','cna', 'test');



my $CURRENT_PATH =dirname(abs_path($0));
$CURRENT_PATH =~ s/\w:.*//;
$CURRENT_PATH =~ s/\/scripts$//;

my $path = $options{filepath};
my $samplename = basename($path);


my @files = &getFiles($path);#opendir my $dir, "$path" or die "Cannot open Directory: $!";
#my @files = readdir $dir;


&detectFiles();



my $changes = $options{changes};
my $loci_changes = $options{loci_changes};
my $rearrangements = $options{rearrangements};
my $cna = $options{cna};

if( -e $changes || -e $loci_changes) {

    # Generate the Changes VCF File
    if (-e $changes) { &generateVCF($changes); }

    # Generate the loci_Changes VCF FIle
    if (-e $loci_changes) { &generateVCF($loci_changes) }
}

# Generate CNA VCF
if( -e $cna) { if (-e $cna) { &generateVCF($cna)}; }


# Generate Rearrangement VCF
if( -e $rearrangements) { if (-e $rearrangements) { &generateVCF($rearrangements) } }

&consolidateVCF();

################################
######## Sub-Routines ##########
################################
sub detectFiles {
    foreach my $file (@files) {

        # Set option for changes
        if ($file =~/change/i) { if (-e "$path/$file") { $options{changes} = "$path/$file"; } }

        # Set Option for LOCI
        if ($file =~/LOCI/i) { if (-e "$path/$file") {$options{loci_changes} = "$path/$file"; } }

        #  Set Option for CNA
        if ($file =~/CNA/i) { if (-e "$path/$file") {$options{cna} = "$path/$file"; } }

        # Set Option for Rearrangment
        if ($file =~/rearrangements/i) { if (-e "$path/$file") { $options{rearrangements} = "$path/$file"; } }

        # Set the Test Type (Specifically for Plasma)
        if ($file =~/PS/i) { $options{test} = "PlasmaSelect"; }
        else {$options{test} = "CancerSelect88"; }
    }
}

sub getFiles {
    my $searchPath = shift;
    opendir my $dir, "$searchPath" or die "Cannot open Directory: $!";
    my @files = readdir $dir;
    return @files;
}

sub uniq {
    my %seen;
    grep !$seen{$_}++, @_;
}

sub generateVCF {
    my $testname = $options{test};
    my $scriptPath = "$CURRENT_PATH/generateVCF.pl";
    my $file = shift;
    my $outfile = basename($file);
    $outfile =~ s/.txt/.vcf/;
    $outfile = "$path/$outfile";
    my $cmd = "/usr/bin/perl \"$scriptPath\" --filepath=\"$file\" --type=$testname";
    my $str = qx($cmd);
    open(my $fh, "+>", $outfile);
    print $fh $str;
    close $fh;
}

sub consolidateVCF {
#    mkdir "$path/VCF_Files";
#    my $outdir = "$path/VCF_Files";
    my $outfile = "$samplename.vcf";
    my @vcf = &getFiles($path);
    @vcf = grep {/.vcf/} @vcf;

    # Sort the files by#  time created
    my @sorted;

    if (-e $changes) {
        my $temp = basename($changes);
        $temp =~ s/.txt/.vcf/g;
        $temp = $path . "/$temp";
        push @sorted, $temp;
    }

     if (-e $loci_changes) {
        my $temp = basename($loci_changes);
        $temp =~ s/.txt/.vcf/g;
        $temp = $path . "/$temp";
        push @sorted, $temp;
    }

    if (-e $cna) {
        my $temp = basename($cna);
        $temp =~ s/.txt/.vcf/g;
        $temp = $path . "/$temp";
        push @sorted, $temp;
    }

    if (-e $rearrangements) {
        my $temp = basename($rearrangements);
        $temp =~ s/.txt/.vcf/g;
        $temp = $path . "/$temp";
        push @sorted, $temp;
    }

    # Sort the Files by name
    open (my $out, '+>', $outfile);
    print $out "##fileformat=VCFv4.3\n";
    my @Infolines;
    my @Datalines;
    foreach my $file (@sorted) {
        print "\n\n$file\n\n";
        open (my $fh, "+<", $file) or die "Cannot open file: $file";
        while (my $line = <$fh>) {
            unless ($line =~ /##fileformat=VCFv4.1/ or $line =~ /##reference=hg19/ or $line =~ /#CHROM/) {
                if ($line =~/#/) { push @Infolines, $line; }
                else { push @Datalines, $line; }
            }
        }
        close $fh;
        `rm -f $file`;
#        move $file, $outdir;

    }

    @Infolines = &uniq(@Infolines);
    foreach my $info (@Infolines) { print $out $info }
    print $out "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\n";
    foreach my $data (@Datalines) { print $out $data }
    close $out;
    move $outfile, $path;
}

