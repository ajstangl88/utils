#!/usr/bin/env python

"""
SYNOPSIS

    TODO Invocation

DESCRIPTION

    TODO This describes how to use this script. This docstring
    will be printed by the script if there is an error or
    if the user requests help (-h or --help).

EXAMPLES

    TODO: Show some examples of how to use this script.

EXIT STATUS

    TODO: List exit codes

AUTHOR

    Alfred Stangl <astangl@personalgenome.com|mailto:astangl@personalgenome.com>

COPYRIGHT

    Personal Genome Diagnostics, 2012. All rights reserved.

VERSION
    :Version 

"""

import sys, subprocess, glob, argparse


def runCommand(command):
    """Unix Style Run Command that returns the STDOUT of the call to a python variable"""
    proc = subprocess.Popen(command,stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    out, err = proc.communicate()
    if out:
        return out


def findPipeline(type):
    """ Basic Unix style find specific to the PGDx Server data storage"""
    command = "find / -maxdepth 3 -type d | grep '{}' | grep -vi 'VALIDATION' | grep -vi 'raw_data_backups' | grep -vi 'testing'".format(type)
    retval = runCommand(command)
    if retval:
        pipelines = retval.split("\n")
        return pipelines
    else:
        print "Nothing Found"
        sys.exit(0)


def findChangesSheets(pipeline):
    """Given an array of pipelines return those which a changes sheet in TN Folder"""

    # Set the array that will contain the path to all changes sheet
    changesSheets = []

    # Loop over the pipelines and collect the ChangesSheet
    for pipe in pipeline:

        # myGlob = pipe + "/TN/*TN.CombinedChanges.txt"
        myGlob = pipe + "/{}/*{}.CombinedChanges.txt".format(folder, folder)

        ret = glob.glob(myGlob)

        # Only append a result if glob has found a file
        if len(ret) > 0:
            changesSheets.append(ret[0])

    return changesSheets


def grepChanges(changessheet, search_term):
    """
    Simple Unix Style Grep looking for a specified value
    :param changessheet: An Array of paths to changes sheet
    :return: An Array of paths which contain positive results 
    """
    result = []

    # Grep for the thing you are looking for with run command and append to result array
    for f in changessheet:
        command = "grep -l '{}' {}".format(search_term, f)
        retval = runCommand(command)
        if retval:
            retval = retval.replace("\n", "")
            result.append(retval)

    return result


def main():
    # An array of pipelines
    pipelines = findPipeline(casetype)

    # An array of changes sheets
    changes = findChangesSheets(pipelines)

    # An array of positive results
    foundChanges = grepChanges(changes, search_term=search)

    # Print the result to stdout
    for item in foundChanges:
        print item


if __name__ == '__main__':
    # Set up the Argument Parser...
    parser = argparse.ArgumentParser()
    parser.add_argument('-type', action='store', dest='casetype', help='Type of Case (Cp6, Cp4, PS, CpCS, all)',
                        default="all")

    parser.add_argument('-folder', action='store', dest='foldertype', help='Type of Folder(TN, TN_TO, UN)',
                        default="TN_TO")
    parser.add_argument('-search', action='store', dest='searchTerm', help='Value to grep for',
                        default="chr5.fa:1295228-1295228_G_A")
    opts = parser.parse_args()

    # Types of Cases
    caseDict = {
        'CpCs': 'CpCs',
        'Cp6': 'Cp6',
        'Cp4': 'Cp4',
        'PS': 'PS',
        'all': 'CpCS\|Cp4\|Cp6'
    }

    # Types of Folders
    folders = {
        'UN': 'UN',
        'TN_TO': 'TN_TO',
        'TN': 'TN'
    }

    # Set the global for folder to search for
    foldertype = opts.foldertype
    folder = folders[foldertype]

    # Set the global for the case type
    casetype = opts.casetype
    casetype = caseDict[casetype]

    # Set the global search term
    search = opts.searchTerm

    main()
