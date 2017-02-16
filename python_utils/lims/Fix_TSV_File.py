#!/usr/bin/env python
# -*- coding: utf-8 -*-
tsv = "/Users/astangl/Desktop/fixed.tsv"

with open(tsv, 'r') as f:
    lines = f.readlines()


pipeline = []

for line in lines:
    line = line.split("\t")
    print(line)

# fixed = []

# for line in lines:
#     if line != "\n":
#         fixed.append(line)
# with open('/Users/astangl/Desktop/fixed.tsv', 'w') as f:
#     for line in fixed:
#         f.write(line)
    # print(repr(line))
