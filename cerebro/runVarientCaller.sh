#!/bin/bash

# NOTE: this is just provided as an example of how to run the variant caller,
# runs on my EC2 instance but may have issues elsewhere.

set -e

export tumor_bam="$1"
export normal_bam="$2"
export dir_name="$3"
export aligner="$4"

export max_procs=16

export roi_file=/mnt/staging/ROI/hg19PGDXCp6_122115/hg19PGDXCp6_122115.bed
# Use each file in this dir
export regions_file=$(find . /mnt/staging/ROI/hg19PGDXCp6_122115/hg19PGDXCp6_122115_regions | grep .regions.txt)
export variant_caller=/mnt/user_data/cerebro/pgdxtools_DEV.Cerebro_20170301
export reference_fasta=/mnt/staging/hg19/hg19.fa
export somatics_flags="-z2 -k1 -w -D600 -K1 -U1 -Z9 -W3 -S1 -y2 -p0 -i1 -j1 -N20 -T30 -n100 -t6"


mkdir -p "${dir_name}/${aligner}"

somatics_run() {
  region="$1"
  ("${variant_caller}" pgdxsomatics ${somatics_flags} \
    -l "${roi_file}" -f "${reference_fasta}" -r ${region} \
    "${tumor_bam}" "${normal_bam}" | grep '\$$') > "${dir_name}/${aligner}/${region}.txt" \
    2> "${dir_name}/${aligner}/${region}.err"
  xz "${dir_name}/${aligner}/${region}.err"
}

export -f somatics_run

cat /mnt/staging/ROI/hg19PGDXCp6_122115/hg19PGDXCp6_122115_regions/*.txt | parallel -P 20  somatics_run {}
cat ${dir_name}/${aligner}/*.txt > "${dir_name}/all_${aligner}.txt"
ls ${dir_name}/${aligner}/*.txt | xargs -n4 -P4 xz



