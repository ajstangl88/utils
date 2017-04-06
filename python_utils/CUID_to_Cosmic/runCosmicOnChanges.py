#!/usr/bin/env python
import sys, os, subprocess, re


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


def runVars():
    # path ="/mnt/user_data/driley/VV_Plasma_Changes_092116/change_files"
    path = sys.argv[1]
    files = os.listdir(path)
    for file in files:
        parentPath = os.path.dirname(os.path.realpath(__file__))
        print("Starting Cosmic Generation for: " + file)

        # Make the output file name
        fileName = os.path.basename(file)
        fileName = os.path.join(parentPath, "cosmicComplete", fileName)
        fileName = fileName + "_COSMIC.out"

        # Join the file paths
        file = os.path.join(path, file)

        test_vars = os.path.join(parentPath, 'test_vars.vcf')
        temp_vars = os.path.join(parentPath, 'temp_vars.vcf')

        # Create a directory for the output
        # os.system('mkdir -p cosmicComplete')
        cmd = 'cat ' + file + ' | perl ' + parentPath + "/changeuidtovars" + ' > test_vars.txt'
        cmd2 = 'cat test_vars.txt | ' + getPGDXtools('changestovcf') + ' --simple > test_vars.vcf'

        cmd3 = getPGDXtools(
            'runVEP') + ' -i temp_vars.vcf -o VEP_all.txt --species hg19_nosplit --dir /mnt/staging/annotation/pgdx_hg19_CCDSRefseq_2016v5/VEP/ --db_version=75 --fasta=/mnt/staging/annotation/pgdx_hg19_CCDSRefseq_2016v5/VEP/hg19.fa --offline --hgvs --force_overwrite --no_progress --no_stats --fork=2 --buffer_size=5000 --cache_region_size=10000000000000'
        cmd4 = getPGDXtools(
            'findCosmicHits') + ' --nearby=/mnt/staging/cosmic/cosmic_v72_hg19/nearby_split --exact=/mnt/staging/cosmic/cosmic_v72_hg19/cosmic_v72_hg19.exact.txt --sameaa=/mnt/staging/cosmic/cosmic_v72_hg19/sameAA_split/ --bygene=/mnt/staging/cosmic/cosmic_v72_hg19/cosmic_v72_hg19.bygene.txt --sample_lookup=/mnt/staging/cosmic/cosmic_v72_hg19/cosmic_v72_hg19.lookup.txt --conseq=VEP_all.txt > ' + fileName
        #
        proc = os.system(cmd)
        while proc != 0:
            continue

        proc = os.system(cmd2)
        while proc != 0:
            continue

        FixVars(test_vars, temp_vars)

        proc = os.system(cmd3)
        while proc != 0:
            continue

        proc = os.system(cmd4)
        while proc != 0:
            continue


runVars()