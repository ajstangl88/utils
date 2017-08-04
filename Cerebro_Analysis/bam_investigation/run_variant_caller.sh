#!/usr/bin/env bash

set -e
export tumor_bam="$1"
export max_procs=16
export variant_caller=/opt/pgs/pipeline-plasma-Plasma-Cerebro-Merge-5.0.0b6/pgdxtools/pgdxtools_DEV.Cerebro_20170301
export reference_fasta=/mnt/staging//hg19/hg19.fa
export roi_file=/mnt/staging//ROI/hg19PGDXPS_Seq2_v2_020717/hg19PGDXPS_Seq2_v2_020717.bed
export header=/mnt/user_data/astangl/cerebro_testing/bam_investigation/cerebro_vars_headers_plasma.txt
export somatics_flags="-R -d 5000000 -D 350 -w -X 0 -K 1 -U 2 -z 0 -k 1 -S 1 -W 3 -Z 4 -Y -y 2 -p 0 -i 1 -j 1 -N 0 -T 30 -n 0 -t 3"
export region="chr7.fa:50000000-150000000"

somatics_run() {
region="$1"
("${variant_caller}" pgdxsomatics ${somatics_flags} -l "${roi_file}" -f "${reference_fasta}" -r ${region} "${tumor_bam}" | grep '\$$' > "${tumor_bam}.vars" 2> /dev/null; cat "${header}" "${tumor_bam}.vars" > "${tumor_bam}._header.vars"; rm -f "${tumor_bam}.vars")

}

export -f somatics_run
somatics_run $region
