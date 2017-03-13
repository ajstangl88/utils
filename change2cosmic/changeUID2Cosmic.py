#!/usr/bin/env python

import sys, os, subprocess, re, csv
from os import path
import tempfile


def set_env():
    # Set up Directories relative to the script
    parentPath = os.path.dirname(os.path.realpath(__file__))
    output = os.path.join(parentPath, 'output')
    temp = os.path.join(parentPath, 'output', 'temp')
    processed = os.path.join(parentPath, 'output', 'processed')
    hg19 = os.path.join(parentPath, 'output', 'hg19')
    complete = os.path.join(parentPath, 'output', 'complete')

    dir_to_make = [output, temp, processed, hg19, complete]
    for dir in dir_to_make:
        dirlist = os.listdir(dir)
        if "files" in dirlist and dir == processed:
            cmd = 'mkdir -p ' + dir
            os.system(cmd)

        else:
            cmd = 'mkdir -p ' + dir
            os.system(cmd)
            cmd2 = "touch " + processed + "/files"
            os.system(cmd2)







def process_id(combined_list):
    """
    Corrects HG18 coordinates to hg19 from a tuple of ('ChangeUID', 'LiftOver hg19 position')
    :param change_tuple: A tuple constructed from process_id
    :return: A HG19 Liftover Coordinate List
    """
    try:
        hg18 = combined_list[0]
        hg19 = combined_list[1]
        hg18 = hg18.replace("\n", "")
        hg19 = hg19.replace("\n", "")
        regex = re.compile(r'\d+(_.*_*)')
        change = re.search(regex, hg18).group(1)
        temp = hg19.split(":")
        new_hg19 = temp[0] + '.fa:' + temp[1] + change
        return new_hg19

    except Exception:
        new_hg19 = "CUID"
        return new_hg19


def extract_columns(filePath, index):
    with open(filePath, 'r') as f:
        retList = []
        index = index - 1
        tsvreader = csv.reader(f, delimiter="\t")
        for line in tsvreader:
            retList.append(line[index])
        return retList


def run_hg19_correction(infile):
    hg18Name = infile + '_ori.txt'
    hg19Name = infile + '_new.txt'


    # Check and Write to Log
    with open('/mnt/user_data/driley/VV_Plasma_Changes_092116/final_attempt/attempt_two/output/processed/files','r') as f:
        lines = f.readlines()
        fileCheck = infile + "\n"
        if fileCheck in lines:
            return
        else:
            write_processed(infile)

    # Write HG18 and HG19 coordinates to files
    cmd1 = "cat " + infile + " | " + "cut -f 1 > " + hg18Name
    os.system(cmd1)
    cmd2 = "cat " + infile + " | " + "cut -f 80 > " + hg19Name
    os.system(cmd2)


    with open(hg18Name, 'r') as a:
        hg18 = a.readlines()

    with open(hg19Name, 'r') as b:
        hg19 = b.readlines()

    # Replace the newlines because
    hg18 = [line.replace("\n", "") for line in hg18]
    hg19 = [line.replace("\n", "") for line in hg19]


    # Combine the results
    combined = zip(hg18, hg19)

    # Create the name for the temp file
    name = os.path.basename(infile)
    name = name + "_hg19.txt"
    out_path = os.path.join('/mnt/user_data/driley/VV_Plasma_Changes_092116/final_attempt/attempt_two/output/hg19', name)

    # Write the HG19 coordinate file
    with open(out_path, 'w') as o:
        for elem in combined:
            o.write(process_id(elem))
            o.write("\n")

    # Clean Up
    cmd3 = 'rm -f ' + hg18Name
    os.system(cmd3)
    cmd4 = 'rm -f ' + hg19Name
    os.system(cmd4)

    return out_path


def write_processed(name):
    out_path = os.path.join('/mnt/user_data/driley/VV_Plasma_Changes_092116/final_attempt/attempt_two/output/processed', 'files')
    with open(out_path, 'a') as f:
        f.write(name)
        f.write('\n')


def getPGDXtools(tool):
    """
    Finds the Path to a PGDX Tool
    :param tool: The script name
    :return: The absolute path to the available script
    """
    path = "/opt/pgs"
    dirs = os.listdir(path)
    for dir in dirs:
        dir = os.path.join(path, dir)
        if 'pgdxtools' in os.listdir(dir):
            toolsPath = os.path.join(dir, 'pgdxtools')
            tools = os.listdir(toolsPath)
            if tool in tools:
                specificTool = os.path.join(toolsPath, tool)
                return specificTool


def FixVars(test_vars, temp_vars):
    """
    Corrects any errors with the output file from command 2 and outputs temp_vars.vcf that is fed into cmd3
    :return: None
    """
    outlines = []
    with open(test_vars, 'r') as f:
        lines = f.readlines()
        for line in lines:
            line = line.split("\t")

            if re.findall(r"\d|\D", line[0]):
                outlines.append(line)

    with open(temp_vars, 'w') as o:
        for line in outlines:
            str = "\t".join(line)
            o.write(str)
        o.close()


def runVars(change_file):

    # Make the output file name -- The change_file is in ./output/hg19/*.hg19
    parentPath = os.path.dirname(os.path.realpath(__file__))

    # The Temp Dir
    temp_dir = os.path.join(parentPath, 'output', 'temp')

    # Base name of the file
    baseName = os.path.basename(change_file)

    # Append Cosmic
    fileName = baseName + "_Cosmic.txt"

    # Final Output File
    output_file = os.path.join(parentPath, "output", 'complete', fileName)

    # Make ./temp/*_test_vars.txt file
    test_vars = baseName + "_test_vars.txt"
    test_vars = os.path.join(temp_dir, test_vars)

    # Run the changeuid to vars script
    cmd = 'cat ' + change_file + ' | perl ' + parentPath + "/changeuidtovars" + ' > ' + test_vars
    os.system(cmd)

    # Make ./temp/*_test_vars.vcf
    test_vars_vcf = baseName + "_test_vars.vcf"
    test_vars_vcf = os.path.join(temp_dir, test_vars_vcf)

    # Run the changes to vcf component
    cmd2 = 'cat ' + test_vars + ' | ' + getPGDXtools('changestovcf') + ' --simple > ' + test_vars_vcf
    os.system(cmd2)


    # Fix the VARS VCF File
    temp_vars = os.path.join(temp_dir, baseName + '_temp_vars.vcf')
    FixVars(test_vars_vcf, temp_vars)

    # Format The VCF file
    temp_vars_2 = os.path.join(temp_dir, baseName + '_temp_vars_2.vcf')
    cmd = getPGDXtools('formatVEPInput') + ' --vcf=' + temp_vars + ' > ' + temp_vars_2
    os.system(cmd)

    # Make the Output VEP_ALL.txt
    VEP_all = os.path.join(temp_dir, baseName + '_VEP_all.txt')


    # Run the runVEP Component
    cmd3 = getPGDXtools('runVEP') + ' -i ' + temp_vars_2 + ' -o ' + VEP_all + ' --species hg19_nosplit --dir /mnt/staging/annotation/pgdx_hg19_CCDSRefseq_2016v5/VEP/ --db_version=75 --fasta=/mnt/staging/annotation/pgdx_hg19_CCDSRefseq_2016v5/VEP/hg19.fa --offline --hgvs --force_overwrite --no_progress --no_stats --fork=2 --buffer_size=5000 --cache_region_size=10000000000000'
    os.system(cmd3)

    # Run the Cosmic Hits Component
    cmd4 = getPGDXtools('findCosmicHits') + ' --nearby=/mnt/staging/cosmic/cosmic_v72_hg19/nearby_split --exact=/mnt/staging/cosmic/cosmic_v72_hg19/cosmic_v72_hg19.exact.txt --sameaa=/mnt/staging/cosmic/cosmic_v72_hg19/sameAA_split/ --bygene=/mnt/staging/cosmic/cosmic_v72_hg19/cosmic_v72_hg19.bygene.txt --sample_lookup=/mnt/staging/cosmic/cosmic_v72_hg19/cosmic_v72_hg19.lookup.txt --conseq=' + VEP_all + ' > ' + output_file
    os.system(cmd4)

    return output_file


def merge_files(infile, outfile):
    outName = outfile + "_Complete.txt"
    cmd = "paste -d'\\t' " + infile + " " + outfile + " > " + outName
    os.system(cmd)


if __name__ == '__main__':

    set_env()

    infile = sys.argv[1]
    outname = run_hg19_correction(infile)
    if outname:
        output_file = runVars(outname)
        merge_files(infile, output_file)

    else:
        print "Previously Completed " + infile












