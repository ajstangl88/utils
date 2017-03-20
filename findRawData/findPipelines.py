#!/usr/bin/env python
import json, os, sys, subprocess, pprint


myPath = os.path.dirname(os.path.realpath(__file__))
# A Simple Utility to lookup pipeline information given
p = subprocess.Popen(["/usr/bin/perl", "/Users/astangl/PycharmProjects/utils/findRawData/get_run_info.pl"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
out, err = p.communicate()

mydict = json.loads(out)
pp = pprint.PrettyPrinter(indent=4)

try:
    key = sys.argv[1]
    pp.pprint(mydict[key])
except IndexError:
    raise(BaseException("No Sample Name Found"))









