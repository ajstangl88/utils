#!/usr/bin/env python
import os, sys, subprocess, math
from subprocess import Popen


def runCommand(command):
	"""Basic Implementation of Running Unix command through python"""
	proc = Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
	complete = False
	while not complete:
		status = proc.poll()
		if status is None:
			continue

		elif status is not 0:
			print("A Fatal Error Has Occurred")
			raise Exception(proc.communicate()[1])

		if status is 0:
			out, err = proc.communicate()
			out = out.splitlines()
			return out


def get_cuid_list(infile):
	command = "cut -f 1 {0}".format(infile)
	output = runCommand(command)
	return output[1:]


def combine_cuids(list1, list2):
	combined = []
	for item in list1:
		if item not in combined:
			combined.append(item)
	for item in list2:
		if item not in combined:
			combined.append(item)
	return combined

old = sys.argv[1]
new = sys.argv[2]


def percent_concordance(all, concord):
	try:
		num = float(concord) / float(all)
		percent = num * 100.00
		percent = "% " + str(percent)
		return percent
	except ZeroDivisionError:
		return "N/A"


def avergage(num1, num2):
	avg = float(sum([num1, num2])) / max(len([num1, num2]), 1)
	return avg


old_cuid_list = get_cuid_list(old)
new_cuid_list = get_cuid_list(new)
all_cuids = combine_cuids(old_cuid_list, new_cuid_list)

concordance = list(set(old_cuid_list) & set(new_cuid_list))
discord = list(set(old_cuid_list) - set(new_cuid_list))


total_discord = len(discord)
total_concordance = len(concordance)


total_old = len(old_cuid_list)
total_new = len(new_cuid_list)
total_all = len(all_cuids)

num_gained_in_new = len([item for item in new_cuid_list if item not in old_cuid_list])
num_gained_in_old = len([item for item in old_cuid_list if item not in new_cuid_list])


percent_concordance_cerebro = percent_concordance(total_new, total_concordance)
percent_concordance_plasma = percent_concordance(total_old, total_concordance)

name = os.path.basename(new)
name = name.split("_")
name = name[0] + "_" + name[1] + "_" + name[2]


print "Case:\t{0}".format(name)
print "Total Variants in Plasma_5:\t{0}".format(total_old)
print "Total Variants in Cerebro:\t{0}".format(total_new)
print "Total Concordant Variants:\t{0}".format(total_concordance)
print "Total Discordant Variants:\t{0}".format(total_discord)
print "Total Variants Gained in Cerebro:\t{0}".format(num_gained_in_new)
print "Total Variants Gained in Plasma_5:\t{0}".format(num_gained_in_old)
print "Percent Concordance Cerebro:\t{0}".format(percent_concordance_cerebro)
print "Percent Concordance Plasma:\t{0}".format(percent_concordance_plasma)

if total_discord > 0:
	for cuid in discord:
		print "Discordant Variant\t{0}".format(cuid)
print "\n"

