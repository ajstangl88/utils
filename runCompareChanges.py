#!/usr/bin/env python
import sys
import os
import re
compare_script = "/mnt/user_data/astangl/compareChanges/compareChanges_plasma/compareChanges_Plasma"

oldfile = ""
newfile = ""

try:
	oldfile = sys.argv[1]
except IndexError as err:
	errmessage = "No Old File Specified"
	raise IndexError(errmessage)

try:
	newfile = sys.argv[2]
except IndexError as err:
	errmessage = "No New File Specified"
	raise IndexError(errmessage)

regex = r'\w+.+Seq2'
out_dir = re.findall(regex, newfile)[0]
out_dir = os.path.basename(out_dir)

make_dir = "mkdir -p {0}".format(out_dir)
os.system(make_dir)

compare_changes = "perl {0} --oldfile={1} --newfile={2} --oldversion=Old --newversion=New --printsummary  --outdir={3}".format(compare_script, oldfile, newfile, out_dir)
os.system(compare_changes)

copy_original = "cp {0} {1} {2}".format(oldfile, newfile, out_dir)
os.system(copy_original)

old_location = os.path.dirname(oldfile)
new_location = os.path.dirname(newfile)

specify_location = "echo Old\t{0} > {1}/location.txt".format(old_location, out_dir)
os.system(specify_location)

specify_location = "echo New\t{0} >> {1}/location.txt".format(new_location, out_dir)
os.system(specify_location)