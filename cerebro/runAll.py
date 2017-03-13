#!/usr/bin/env python
import os, sys, argparse, subprocess, time
from subprocess import Popen
from os import path
"""
Automates the creation of input bam files

For Testing:

Normal: RDCSVA001N_Cp6_RR1
normal1 = /data23-pgdx-pod12/Raw_Data_Backups/H3_0097_102516_hg19_RR1/fastq/RDCSVA001N_Cp6_RR1_R1.fastq.gz
normal2 = /data23-pgdx-pod12/Raw_Data_Backups/H3_0097_102516_hg19_RR1/fastq/RDCSVA001N_Cp6_RR1_R2.fastq.gz

Tumor: RDCSVA002T_S2_Cp6_RR1
tumor1 = /data22-pgdx-pod11/Raw_Data_Backups/H_0907_111016_hg19_RR1/fastq/RDCSVA002T_S2_Cp6_RR1_R1.fastq.gz
tumor2 = /data22-pgdx-pod11/Raw_Data_Backups/H_0907_111016_hg19_RR1/fastq/RDCSVA002T_S2_Cp6_RR1_R2.fastq.gz

"""

def runCommand(command):
    """Basic Implementation of Running Unix command through python"""
    proc = Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    complete = False
    while not complete:
        status = proc.poll()
        if status is None:
            continue

        elif status is not 0:
            print("A Fatal Error Has Occurred")
            raise Exception(proc.communicate()[1])

        if status is 0:
            out, err = proc.communicate()
            return out


def process_name(bam1, bam2, type):
    """Simple Method to get the name of the bam"""
    name = path.basename(bam1)
    name = "_".join(name.split(".")[0].split("_")[:-1])
    name = type + "_" + name
    return name


def run_bt2(bam1, bam2, type):
    """Run the Bow tie Alignmen given 2 paired fastq files"""

    # Take the base name of the input files
    name = process_name(bam1, bam2, type)
    name = "BT2_" + name

    # BT2 - Align the Normal FQ Files
    bowtie_aln = "{} -x {} -1 {} -2 {} -S {}.sam -p 24".format(bowtie2, ref_genome, bam1, bam2, name)
    runCommand(bowtie_aln)


    # BT2 Normal - Convert SAM into BAM and Delete SAM
    sam2bam = "samtools view -@ 20 -bS {}.sam > {}.bam".format(name, name)
    runCommand(sam2bam)


    # BT2 - Remove SAM File
    remove_sam = "rm -f {}.sam".format(name)
    runCommand(remove_sam)


    # BT2 - Sort the BAM File
    sort_bam = "samtools sort -@ 20 {}.bam {}.sorted".format(name, name)
    runCommand(sort_bam)


    # BT2 - Index The Sorted Bam FIle
    index_bam = "samtools index {}.sorted.bam".format(name)
    runCommand(index_bam)

    # BT2 - Remove Old Bam
    remove_bam = "rm -f {}.bam".format(name)
    runCommand(remove_bam)

    return name + ".sorted.bam"


def run_bwa(bam1, bam2, type):
    """Run BWA MEM on Tumor or Normal"""
    # Take the base name of the input files
    name = process_name(bam1, bam2, type)
    name = "BWA_" + name

    # BWA Normal - Align the Normal FQ Files
    bwa_aln = "{} mem -t 24 {} {} {} > {}.sam".format(bwa, ref_genome, bam1, bam2, name)
    runCommand(bwa_aln)


    # BWA - Convert SAM into BAM
    sam2bam = "samtools view -@ 20 -bS {}.sam > {}.bam".format(name, name)
    runCommand(sam2bam)


    # BWA - Remove SAM File
    remove_sam = "rm -f {}.sam".format(name)
    runCommand(remove_sam)


    # Sort BAM File
    sort_bam = "samtools sort -@ 20 {}.bam {}.sorted".format(name, name)
    runCommand(sort_bam)

    # Remove Unsorted BAM File
    remove_bam = "rm -f {}.bam".format(name)
    runCommand(remove_bam)


    # BWA - Index BAM File
    index_bam = "samtools index {}.sorted.bam".format(name)
    runCommand(index_bam)

    return name + ".sorted.bam"


def make_outdirs(normal1, normal2, tumor1, tumor2):
    """
    Set the path for output of the alignments by making an output dir and then makes a subdir based on the first
    tumor name.
    """

    # Get the local path of the script
    localPath = path.dirname(os.path.abspath(__file__))

    # Make the output directory relative to the script path
    aln_out = path.join(localPath, "output")

    # Set the command for making the primary directly
    mkdir_out = "mkdir -p {}".format(aln_out)

    # Construct the name of the secondary directory
    name = path.basename(tumor1)
    outdir = name.split("_")[0]
    outdir = path.join(aln_out, outdir)

    # Set the command for making the secondary directly
    mkdir = "mkdir -p {}".format(outdir)

    # Make the primary out dir if it doesnt exist
    runCommand(mkdir_out)

    # Make the secondary data dir in the primary dir
    runCommand(mkdir)

    return outdir


def move_outputs(outpath, bamfile):
    """Moves the bam and bai files to the output dir"""

    # Make the name for the index file
    bai_file = bamfile + ".bai"

    # Set the commands to move the files
    move_bam = "mv {} {}".format(bamfile, outpath)
    move_bai = "mv {} {}".format(bai_file, outpath)


    # Run the move commands
    runCommand(move_bam)
    runCommand(move_bai)

    # Return the path to the final output
    return path.join(outpath, bamfile)


def runVarient(tumor_bam, normal_bam, dir_name, aligner):
    """ Simple python wrapper for the variant caller """
    print("Running Variant Caller on {} for {}".format(path.basename(tumor_bam).split(".")[0].split("_")[2], aligner))
    varient_caller = "/mnt/user_data/cerebro/runVarientCaller.sh"
    caller_cmd = "{} {} {} {} {}".format(varient_caller, tumor_bam, normal_bam, dir_name, aligner)

    # We use os.system here because run command redirects stderr
    os.system(caller_cmd)




def runCerebro(output_dir):
    """Simple Wrapper for running Cerebro"""
    print("Running Cerebro")

    # Set the internal path to avoid error
    os.system("PYTHONPATH=/opt/venv/cerebro/lib64/python2.7/site-packages/sklearn/externals")
    run_cerebro = "/mnt/user_data/cerebro/cerebro_scripts/run_cerebro.sh"
    bwa_vars = path.join(output_dir, "all_BWA.txt")
    bt2_vars = path.join(output_dir, "all_BT2.txt")
    sample_name = output_dir.split("/")[-1]
    output_dir = path.join(output_dir, "result")
    cerebro_cmd = "{} {} {} {} {}".format(run_cerebro, bwa_vars, bt2_vars, sample_name, output_dir)
    os.system(cerebro_cmd)



def main():
    # Make the outpath
    outpath = make_outdirs(normal1, normal2, tumor1, tumor2)

    print("Running Bowtie2 on Normal")
    normal_BT2 = run_bt2(normal1, normal2, "Normal")

    print ("Moving {} to {}".format(normal_BT2, outpath))
    normal_BT2 = move_outputs(outpath, normal_BT2)

    print("Running Bowtie2 on Tumor")
    tumor_BT2 = run_bt2(tumor1, tumor2, "Tumor")

    print("Moving {} to {}".format(tumor_BT2, outpath))
    tumor_BT2 = move_outputs(outpath, tumor_BT2)

    print("Running BWA on Nornmal")
    normal_bwa = run_bwa(normal1, normal2, "Normal")

    print("Moving {} to {}".format(normal_bwa, outpath))
    normal_bwa = move_outputs(outpath, normal_bwa)

    print("Running BWA on Tumor")
    tumor_bwa = run_bwa(tumor1, tumor2, "Tumor")

    print("Moving {} to {}".format(tumor_bwa, outpath))
    tumor_bwa = move_outputs(outpath, tumor_bwa)

    print("Running Varient Caller")
    bt2_varients = runVarient(tumor_BT2, normal_BT2, outpath, "BT2")
    bwa_varients = runVarient(tumor_bwa, normal_bwa, outpath, "BWA")

    runCerebro(outpath)




if __name__ == '__main__':

    # Set up the variables for the binaries required. Hardcoded but with RPM should  work
    bowtie2 = "/opt/opt-packages/bowtie2-2.2.9/bowtie2"
    bowtie2_build = "/opt/opt-packages/bowtie2-2.2.9/bowtie2-build"
    bowtie2_inspect = "/opt/opt-packages/bowtie2-2.2.9/bowtie2-inspect"
    bwa = "/opt/opt-packages/bwa/bwa"
    ref_genome = "/data26-pgdx-pod13/Custom/Cerebro_testing/hg19_pgdx"
    bwa = "/opt/opt-packages/bwa/bwa"

    # Set up the Argument Parser...
    parser = argparse.ArgumentParser()
    parser.add_argument('-n1', action='store', dest='normal1', help='Normal Fastq File R1')#, default="/data23-pgdx-pod12/Raw_Data_Backups/H3_0097_102516_hg19_RR1/fastq/RDCSVA001N_Cp6_RR1_R1.fastq.gz")
    parser.add_argument('-n2', action='store', dest='normal2', help='Normal Fastq File R2')#, default="/data23-pgdx-pod12/Raw_Data_Backups/H3_0097_102516_hg19_RR1/fastq/RDCSVA001N_Cp6_RR1_R2.fastq.gz")
    parser.add_argument('-t1', action='store', dest='tumor1', help='Tumor Fastq File R1')#, default="/data22-pgdx-pod11/Raw_Data_Backups/H_0907_111016_hg19_RR1/fastq/RDCSVA002T_S2_Cp6_RR1_R1.fastq.gz")
    parser.add_argument('-t2', action='store', dest='tumor2', help='Tumor Fastq File R1')#, default="/data22-pgdx-pod11/Raw_Data_Backups/H_0907_111016_hg19_RR1/fastq/RDCSVA002T_S2_Cp6_RR1_R2.fastq.gz")
    opts = parser.parse_args()

    # Paths for the Normal Fastq
    normal1 = opts.normal1
    normal2 = opts.normal2

    # Paths to the Tumor Files
    tumor1 = opts.tumor1
    tumor2 = opts.tumor2

    # We are to time this to see how long it takes
    start_time = time.time()
    main()
    print("--- %s seconds ---" % (time.time() - start_time))




