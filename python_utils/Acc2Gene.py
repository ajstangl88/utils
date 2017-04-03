#!/usr/bin/env python

import requests, sys
# id = "CCDS5514.1"
import requests, sys, re

find = re.compile(r"<td><small>(.+?)</small></td>")

with open('/Users/astangl/PycharmProjects/utils/python_utils/id_list.txt', 'r') as f:
    lines = f.read().splitlines()

for id in lines:
    url = "https://www.ncbi.nlm.nih.gov/CCDS/CcdsBrowse.cgi?REQUEST=CCDS&DATA={}&ORGANISM=9606&BUILDS=CURRENTBUILDS".format(id)
    r = requests.get(url)

    ret =  r.content
    found = re.findall(find, ret)
    if found:
        print id + '\t' + found[3]
    else:
        print id  + '\t' + 'Not Found'