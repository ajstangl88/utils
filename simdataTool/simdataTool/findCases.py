#!/usr/bin/env python

import os, sys, re

try:
    search = sys.argv[1]
except:
    pass

rootDir = "/"
all_data_paths = []
for elem in os.listdir(rootDir):
    temp = os.path.join(rootDir, elem)
    if re.findall(r"data", temp):
        raw = os.path.join(temp, "Raw_Data_Backups")
        all_data_paths.append(raw)



for path in all_data_paths:
    if os.path.exists(path):
        dir_list = os.listdir(path)
        if search in dir_list:
            found = os.path.join(path, search, 'fastq')
            print(found)




