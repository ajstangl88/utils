#!/usr/bin/env python
import sys, os, subprocess
from datetime import time
from os.path import join as osjoin

infile = "/mnt/user_data/astangl/sim_data_tools/cuidFiles/change_uids.txt"
rootPath = os.path.dirname(os.path.realpath(__file__))
outdir = osjoin(rootPath, 'output')
tempdir = os.path.join(rootPath, 'temp')
refdir = osjoin(rootPath, 'references')


def getFile(path, search):
    if search in os.listdir(path):
        retfile = osjoin(path, search)
        return retfile
    else:
        if Exception:
            raise BaseException("File: " + search + " Not Found in Directory: " + path)


def set_env():
    # Make the output directory
    runCommand(['mkdir', '-p', outdir])
    runCommand(['mkdir', '-p', tempdir])


def eprint(text):
    """
    Writes to standard error for python version 2.7 and less
    :param text: String to print to standard error
    :return: print statement to standard error.
    """

    message = text
    message = message
    sys.stderr.write(message + "\n")


def getFunction():
    functionDict = dict()
    functionDict['mason_materializer'] = os.path.join(rootPath, 'mason2', 'bin', 'mason_materializer')
    functionDict['mason_simulator'] = os.path.join(rootPath, 'mason2', 'bin', 'mason_simulator')
    functionDict['mason_variator'] = os.path.join(rootPath, 'mason2', 'bin', 'mason_variator')
    functionDict['novoalign'] = '/opt/opt-packages/novocraft-3.02.07/novoalign'
    functionDict['samtools'] = '/opt/samtools/samtools'
    functionDict['changes2vcf'] = os.path.join(rootPath, 'scripts', 'change2vcf.pl')
    functionDict['bcftools'] = os.path.join(rootPath, 'bcftools','bin', 'bcftools')
    return functionDict


def geReferences():
    refDict = dict()
    for elem in os.listdir('/mnt/user_data/astangl/simdataTool/references'):
        temp = '/mnt/user_data/astangl/simdataTool/references'
        refDict[elem] = os.path.join(temp, elem)
    return refDict


def runCommand(command):
    """
    Runs a Specified Command provided as an array
    :param command: An Arry of commands (Ex ['ls', '-la']
    :return: STDOUT from Subprocess (Returned in all once complete)
    """

    proc = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    proc.wait()

    if proc.returncode == 0:
        return proc.communicate()[0]
    else:
        raise Exception(proc.communicate()[1])

def runShell(command):
    """
    Runs a command string (unix systems) and operates in shell mode where stderr and stdout can be read during execution
    :param command: A Command String ("ls -lhtr")
    :return: Return Code
    """
    proc = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)


def generateVCF(tools, infile):
    """
    Generates the Basic VCF File used for Simulated Data Based on Reference VCF
    :param tools: The dict contianing paths to all utilities
    :param infile: The change_UID File
    :return: String of sorted VCF
    """
    # Get the Perl CUID2VCF Script
    perlvcf = tools['changes2vcf']

    # Set header column (Never Changes)
    header = "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tsimulated\n"

    # Run the perl script
    vcf = runCommand(['perl', perlvcf, infile])

    # Create namespace for temp vcf file and write it
    tempfile = osjoin(tempdir, 'temp.vcf')
    with open(tempfile, 'w') as f: f.write(vcf)

    # Sort the temp file
    sortedVCF = runCommand(["sort", "-k1,1", "-V", "-s", tempfile])

    # Read the ref VCF and gewt the header
    refVCF = getFile(refdir, 'reference.vcf')
    with open(refVCF, 'r') as f: sec_header = [line.replace("\n", "") for line in f.readlines() if line.startswith("##")]

    # Perform String Operations and create the final output string
    h1 = "\n".join(sec_header)
    h2 = "\n" + header
    h3 = sortedVCF
    fixedVCF = h1 + h2 + h3
    fixedVCF = fixedVCF.rstrip()

    # Set the namespace for the output
    outname = os.path.basename(infile)
    outname = outname.replace(".txt", ".vcf")
    outname = osjoin(outdir, outname)

    # Write the VCF File
    with open(outname, 'w') as f: f.write(fixedVCF)

    # Remove the Temp File
    runCommand(['rm', '-f', tempfile])

    return (outname, sortedVCF)


def normalizeVCF(vcf):
    bcftools = tools['bcftools']
    hg19 = refs['hg19.fa']
    output = osjoin(outdir, 'norm.vcf')
    command = bcftools + " norm " + "-f " + hg19 + " "  + vcf + " -o " + output
    command = command.split()
    runCommand(command)
    return output


def runMaterializer(vcf):
    """
    Runs the Mason materializer on the a sorted VCF given a sorted reference genome
    :param tools: The mason materializer tool path
    :param vcf: The vcf file produced by generateVCF
    :param refs: The path to the hg_19 genome (Located in ../references/hg19.fa)
    :return: None
    """
    print "\nRunning Mason Materializer Component\n\n"
    mason_materializer = tools['mason_materializer']
    reference_genome = refs['hg19.fa']
    output = os.path.basename(infile) + ".fa"
    output = osjoin(outdir, output)
    args = [mason_materializer, '-ir', reference_genome, '-iv', vcf, '-o', output]
    command = ' '.join(args)
    print "Command:\n" + command
    out = runCommand(args)
    print out

    print "Mason Materialzer Complete\nOutput:" + output
    return output





if __name__ == '__main__':

    # Set up the local enviroment (outdir, etc)
    set_env()

    # Get the tools tools['tool_name'] = /path_to/tool
    tools = getFunction()

    # Get Various references as in hash table
    refs = geReferences()

    # Step 1.) Generate the VCF to be used by the mason2 tool
    (vcf, sortedvcf) = generateVCF(tools, infile)

    # Step 1.5) Normalize the input VCF (Not sure why but was recommended)
    norm_vcf = normalizeVCF(vcf)

    # Step 2.) Run the mason_materializer
    inital_fa = runMaterializer(norm_vcf)

    # Step 3.) Remove .fa from inital_fA





