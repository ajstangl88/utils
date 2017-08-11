Compare Changes Somatics Guide - SSHAH

All of the scripts and packages needed to compare a batch of new Somatics Runs to older runs are contained in this folder.  All that is needed from the user is a tab delimited text file like the example provided in this folder.

##Input File:
"The input file must look like the example provided, and have 5 columns:"
oldfile_loc - This column should contain the full path to the old Samples' output folders
oldfile_name - This column should contain the actual name of the Sample. This will be the same as the name of the Sample's output directory
"newfile_loc, newfile_name - Same as the first 2, except for the new Samples' information"
outdir - The full path to the directory that you want the comparison results to be written to.

##Compare Wrapper

This is the script that you actually call. As input it takes in the user-made input file and a mapping file that helps it find equivalent files between different pipeline versions.  An example call would look like this:

nohup perl compare_wrapper.pl --input_file=<run_file> --mapping_file=<mapping_file>


This script will parse the input file and pass on the information and the mapping file to the comparePairMaker.pl script

##Compare Pair Maker
"This script takes the information from the Compare Wrapper and uses the information and the mapping file to identify which pairs of files need to be compared. For each pair it identifies, it feeds them into the compareChanges_Plasma.pl script."

##Compare Changes
"This is where the actual comparison gets done. It takes in two files and compares them. This particular version has been coded to only deal with very large files in manageable chunks, so as not to crash machines due to memory usage."

##End result
"The end result will be a folder at the output directory designated in the user-made input file. There will be a comparsion_summary.txt file and stderr file at the top level. There will also be a diffs and same folder, with the diffs conatining the individual comparisons between sheets that had differences, and same having those that did not."

##PGDX.pm
This is a perl module that the above scripts need to function.
