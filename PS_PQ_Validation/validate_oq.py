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
import os, sys, csv, ConfigParser

config = ConfigParser.RawConfigParser()
config.readfp(open("config.ini"))
print config.items("seq_only")


def validate_seq_only(seq_file, mapping_file):
    pass

def check_msi(msifile, seq_msi_mapping):
    # Split row, read second to last index, count MSI
    # Return Positive Counts
    pass