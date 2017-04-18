#!/usr/bin/env python
import sys
myfile = "/Users/astangl/Desktop/runit_v2.txt"

with open(myfile, 'r') as f:
    lines = f.read().splitlines()

for line in lines[1:]:
    elts = line.split('\t')
    sample_location1 = elts[0]
    sample_name1 = elts[1]
    run_name1 = elts[2]
    sample_location2 = elts[3]
    sample_name2 = elts[4]
    run_name2 = elts[5]
    outdir = elts[6]
    mapping_file = "/mnt/user_data/astangl/staging/mappingfile_v2.txt"

    command = "perl comparePairMaker_Plasma.pl --sample_location1={} --sample_name1={} --run_name1={} --sample_location2={} --sample_name2={} --run_name2={} --outdir={} --mapping_file={}".format(
        elts[0],
        elts[1],
        elts[2],
        elts[3],
        elts[4],
        elts[5],
        elts[6],
        mapping_file)

    print(command)