#!/usr/bin/env bash

#Set the Virtual Environment
source /opt/rh/python27/enable
source /opt/venv/cerebro/bin/activate

# For whatever reason this needs to be imported
bash -c "PYTHONPATH=/opt/venv/cerebro/lib64/python2.7/site-packages/sklearn/externals"

#normal1="/data23-pgdx-pod12/Raw_Data_Backups/H3_0097_102516_hg19_RR1/fastq/RDCSVA001N_Cp6_RR1_R1.fastq.gz"
#normal2="/data23-pgdx-pod12/Raw_Data_Backups/H3_0097_102516_hg19_RR1/fastq/RDCSVA001N_Cp6_RR1_R1.fastq.gz"
normal1=$1
normal2=$2
tumor1=$3
tumor2=$4



#echo "Running Alignments"
bash -c "/mnt/user_data/cerebro/runAll.py -n1 $normal1 -n2 $normal2 -t1 $tumor1 -t2 $tumor2"
#/mnt/user_data/cerebro/runAll.py -n1 $normal1 -n2 $normal2 -t1 $1 -t2 $2
