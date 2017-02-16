#!/usr/bin/env python
import os, sys, subprocess

dir = r"/mnt/user_data/testing/scratch"


full_path = []
for elem in os.listdir(dir):
    temp = os.path.join(dir, elem)
    if os.path.exists(temp) and os.path.isdir(temp):
        full_path.append(temp)



for dir in full_path:
    args = ["/mnt/user_data/testing/secondVA/vcfGen/getPaths.sh", dir]
    print args
    p = subprocess.Popen(args)
    print p.communicate()

