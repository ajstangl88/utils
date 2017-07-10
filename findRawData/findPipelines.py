#!/usr/bin/env python
import json, os, sys, subprocess, pprint, re


myPath = os.path.dirname(os.path.realpath(__file__))
# A Simple Utility to lookup pipeline information given
p = subprocess.Popen(["/usr/bin/perl", "/Users/astangl/PycharmProjects/utils/findRawData/get_run_info.pl"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
out, err = p.communicate()

mydict = json.loads(out)
pp = pprint.PrettyPrinter(indent=4)

# # pp.pprint(mydict)
# for key in mydict:
#     if re.findall(r"PGDXRD3P_925", key):
#         print key
with open("/Users/astangl/PycharmProjects/utils/findRawData/findthese.txt", "r") as f:
    keys = f.read().splitlines()
    for ori in keys:
        k = ori.split("_")
        temp = "_".join(k[0:2])
        for key in mydict:
            try:
                if re.findall(temp, key):
                    key = key.split(" ")
                    if len(key) > 1:
                        key = key[-1]
                        print ori
                        result = mydict[key]["fastq"]
                        for k in result:
                            retval = "\n".join(result[k])
                            print retval
                    else:
                        key = key[0]
                        print ori
                        result = mydict[key]["fastq"]
                        for k in result:
                            retval = "\n".join(result[k])
                            print retval
            except:
                continue
#
# try:
#     for key in keys:
#         print key
#         try:
#             result = mydict[key]["fastq"]
#             for k in result:
#                 retval = "\n".join(result[k])
#                 print retval
#         except KeyError:
#             continue
#
# except IndexError:
#     raise (BaseException("No Sample Name Found"))

# try:
#     key = sys.argv[1]
#     pp.pprint(mydict[key])
# except IndexError:
#     raise(BaseException("No Sample Name Found"))









