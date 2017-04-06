#!/bin/bash

#Set the Virtual Environment
source /opt/rh/python27/enable
source /opt/venv/cerebro/bin/activate

# For whatever reason this needs to be imported
bash -c "PYTHONPATH=/opt/venv/cerebro/lib64/python2.7/site-packages/sklearn/externals"


## Added this to allow relative script paths
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname $SCRIPT)

bwa_vars="$1"
bt2_vars="$2"
sample_name="$3"
output_dir="$4"

CEREBRO_CALLER="$SCRIPTPATH/cerebro_call.py"
CEREBRO_MODEL="/data26-pgdx-pod13/Custom/Cerebro_testing/latest_Ex_model"
CEREBRO_REWRITE="$SCRIPTPATH/rewrite.pl"
CEREBRO_MERGER="$SCRIPTPATH/merge_nearby_mutations.pl"


mkdir -p $output_dir
#
awk -F $'\t' '$17 >= 3 && $18 >= 0.02 && $32 >= 10' $bwa_vars > $output_dir/displayable_bwa.txt
awk -F $'\t' '$17 >= 3 && $18 >= 0.02 && $32 >= 10' $bt2_vars > $output_dir/displayable_bt2.txt
cut -f1 $output_dir/displayable_{bwa,bt2}.txt | sort | uniq -c | awk '$1 > 1 { print $2 }' > $output_dir/common_cuids.txt
$CEREBRO_REWRITE --list-filename $output_dir/common_cuids.txt $output_dir/displayable_bwa.txt | \
  grep -v nan | sort -k1,1 > $output_dir/filtered_bwa.txt
$CEREBRO_REWRITE --no-first-run --list-filename $output_dir/common_cuids.txt $output_dir/displayable_bt2.txt | \
  grep -v nan | sort -k1,1 > $output_dir/filtered_bt2.txt
join -t $'\t' $output_dir/filtered_bwa.txt $output_dir/filtered_bt2.txt > $output_dir/combined_data.txt
$CEREBRO_CALLER $output_dir/combined_data.txt $CEREBRO_MODEL > $output_dir/score_data.txt
join -t $'\t' $output_dir/score_data.txt $output_dir/combined_data.txt > $output_dir/scored_vars.txt
awk -F $'\t' '$2 >= 0.75' $output_dir/scored_vars.txt > $output_dir/passing_vars.txt
cut -f 1,2,3,15,16,17,18,19,20 $output_dir/passing_vars.txt > $output_dir/tiny_passing_vars.txt
$CEREBRO_MERGER $output_dir/tiny_passing_vars.txt > $output_dir/tiny_merged_vars.txt
echo "ChangeUID	Score	MutType	T_Cov	T_Alt	T_MAF	N_Cov	N_Alt	N_MAF	SampleName" > $output_dir/pre_coding_filter.txt
cat $output_dir/tiny_merged_vars.txt | perl -ple 'BEGIN { $name = shift } $_ .= "\t$name"' $sample_name >> $output_dir/pre_coding_filter.txt
### NEED Coding filter here
### coding_filter $output_dir/pre_coding_filter.txt > $output_dir/final_output.txt

