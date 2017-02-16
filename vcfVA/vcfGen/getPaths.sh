#!/usr/bin/bash
# This script will take in a path through STDIN, iterate over directories and produce a VCF file for each directory in
# The parent directory.

# The path to the shell script
SCRIPT=$(readlink -f "$0")
# The Directory of the shell script
SCRIPTPATH=$(dirname "$SCRIPT")
# The path to the perl script
PERLSCRIPT=("$SCRIPTPATH/VCFCombiner.pl")
# STDIN for the directory containing desired directories.
FILE=$1

files=$(ls $1)
for f in $files
do
	bash -c "$PERLSCRIPT --filepath=$1$f/"
done