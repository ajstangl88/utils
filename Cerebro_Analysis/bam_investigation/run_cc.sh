#!/usr/bin/env bash

script=/mnt/user_data/astangl/cerebro_testing/bam_investigation/generate_reduced_file.sh
perlScript=/mnt/user_data/astangl/cerebro_testing/bam_investigation/supermutant_consensus.pl
bam=$1

$script $bam $bam.converted.bam 5 $perlScript tempdir > $bam.converted 2> $bam.stderr
