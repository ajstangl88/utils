#!/usr/bin/env python
import os, sys, re
from os import path

outpath = "/mnt/user_data/cerebro/output"

# search_file = "/data23-pgdx-pod12/Testing/RDCSVA002T_S2_Cp6_RR1_121016_A/TN/RDCSVA002T_S2_Cp6_RR1_121016_A_TN.CombinedChanges.txt"
try:
    search_file = sys.argv[1]
except Exception:
    raise IndexError("No Input File Found")


def find_output(search_file):
    """
    Find the folder associated with the input and return path to
    output
    """
    # Parse the name to match the folder
    search_name = os.path.basename(search_file)
    search_name = search_name.split("_")[0]

    # Loop over output dirs to match the search file
    i = 0
    maxDepth = len(os.listdir(outpath)) - 1
    for dir in os.listdir(outpath):
        dir_name = os.path.join(outpath, dir)
        base_dir = os.path.basename(dir_name)
        if base_dir == search_name:
            return dir_name
        elif i != maxDepth:
            i = i + 1
            continue
        else:
            print "No Folder Found for {}".format(search_name)


def get_result_file(target_output):
    """
    Obtains the path of the Cerebro output
    Since I wrote how the outputs are stored the result should always be in
    output/TumorName/result/pre_coding_filter.txt

    Relative to the script location
    """

    # Assume the path follows the structure above
    result_file = os.path.join(target_output, 'result', 'pre_coding_filter.txt')
    if os.path.exists(result_file):
        return result_file
    else: print "No Result File Found for {}".format(os.path.basename(target_output))



def compare_output(search_file, result_file):
    """
    Simple comparison between the cerebro (result_file) and changes file (search_file)
    based on the CUID Column (First Column)
    """
    outstring = ""

    outstring = outstring + "Comparison Between\nPipeline output: {}\nCerebro output: {}\n".format(os.path.basename(search_file), os.path.basename(result_file))

    # Collect the IDs from the Changes File
    with open(search_file, 'r') as f:
        lines = f.read().splitlines()
        pipeline_ids = [line.split("\t")[0] for line in lines if line.split("\t")[0] != "ChangeUID"]

    # Collect the IDs from the Cerebro output
    with open(result_file, 'r') as r:
        lines = r.read().splitlines()
        cerebro_id = [line.split("\t")[0] for line in lines if line.split("\t")[0] != "ChangeUID"]


    outstring = outstring + "Total Cerebro Calls\t {}\n".format(len(cerebro_id))
    outstring = outstring + "Total Pipeline Calls\t {}\n".format(len(pipeline_ids))

    # Find the Count and Number of Cerebro Calls in the pipeline ID
    found_ids = []
    for id in pipeline_ids:
        if id in cerebro_id:
            found_ids.append(id)
    outstring = outstring + "Intersection of CUIDs\t {}\n".format(len(found_ids))


    outstring = outstring + "Common_CUIDs\n"

    for item in found_ids:
        outstring = outstring + item + "\n"


    outname = result_file.split("/")[-3] + "_Comparison.tsv"
    outpath = os.path.dirname(result_file)
    out_write = os.path.join(outpath, outname)
    with open(out_write, 'w') as o:
        o.write(outstring)


target_output = find_output(search_file)

result_file = get_result_file(target_output)

compare_output(search_file, result_file)