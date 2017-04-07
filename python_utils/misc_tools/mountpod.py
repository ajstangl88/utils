#!/usr/bin/env python

import sys, os, subprocess

def runCommand(command):
    """Unix Style Run Command that returns the STDOUT of the call to a python variable"""
    proc = subprocess.Popen(command,stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    out, err = proc.communicate()
    if out:
        return out


pod = input("Enter Pod #: ")

# osascript -e 'mount volume "smb://pgdxuser:pgdx01@172.16.101.213/data26-pgdx-pod13"'

command = "osascript " + "-e " + "'mount volumne " + '"smb://pgdxuser:pgdx01@172.16.101.2{}/data26-pgdx-pod{}"'.format(pod, pod) + "'"

print runCommand(command)