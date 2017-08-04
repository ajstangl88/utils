#!/usr/bin/env python
import sys, os, csv
paths = []
infile = sys.argv[1]


def add_column(infile, filename):
	new_name = str
	my_new_array = []
	with open(infile, 'r') as f:
		lines = f.read().splitlines()
		for line in lines:
			new_line = line.split("\t")
			if "" in new_line:
				continue
			if "ChangeUID" in new_line:
				new_line.append("CaseName")
			else:
				new_line.append(filename)
			my_new_string = "\t".join(new_line)
			my_new_array.append(my_new_string)
			new_name = infile + "_altered.txt"
			with open(new_name, 'w') as o:
				for elem in my_new_array:
					o.write(elem)
					o.write("\n")
	return new_name


def add_header(infile):
	with open(infile, 'U') as f:
		reader = csv.reader(f, delimiter='\t')
		header = next(reader)
		return header

def get_datalines(infile):
	outlist = []
	with open(infile, 'U') as f:
		reader = csv.reader(f, delimiter='\t')
		header = next(reader)
		for row in reader:
			line = "\t".join(row)
			outlist.append(line)
	retval = "\n".join(outlist)
	return retval

with open(infile, 'r') as f:
	lines = f.read().splitlines()
	for line in lines:
		line = line.split("\t")
		old = line[0]
		new = line[1]
		file_name = new.split("_")[0:3]
		dir_name = os.path.split(new)[0]
		dir_name = dir_name.split("_")[-1]
		file_name = "_".join(file_name)
		file_name = file_name.split("/")[-1]

		os.system("mkdir -p {0}".format(dir_name))
		print "Comparing: {0} and {1}".format(os.path.basename(old), os.path.basename(new))

		command = "perl compareFiles.pl -o {0} -n {1} > {2}/{3} 2>/dev/null".format(old, new, dir_name, file_name)
		os.system(command)
		outdir = "{0}/{1}".format(dir_name, file_name)
		paths.append(outdir)

	new_paths = []
	for elem in paths:
		filename = os.path.basename(elem)
		new_file = add_column(elem, filename)
		new_paths.append(new_file)
		os.system("rm -f {0}".format(elem))


with open(infile, 'r') as f:
	lines = f.read().splitlines()
	my_dir_name = []
	for line in lines:
		line = line.split("\t")
		old = line[0]
		new = line[1]
		file_name = new.split("_")[0:3]
		dir_name = os.path.split(new)[0]
		dir_name = dir_name.split("_")[-1]
		my_dir_name.append(dir_name)
		command = "touch {0}/all_counts_{1}.txt".format(dir_name, dir_name)
		os.system(command)
		command = "python get_numbers.py {0} {1} >> {3}/all_counts_{2}.txt".format(old, new, dir_name, dir_name)
		os.system(command)


header_line = []
data_line = []
for elem in os.listdir(my_dir_name[0]):
	if elem.endswith("_altered.txt"):
		myfile = os.path.join(my_dir_name[0], elem)
		header = add_header(myfile)
		if header not in header_line:
			header_line.append(header)
		data_line.append(get_datalines(myfile))

header = "\t".join(header_line[0])
header = header + "\n"
outlines = "\n".join(data_line)

outfile = os.path.join(my_dir_name[0], "all_variant_counts_{0}.txt".format(my_dir_name[0]))
with open(outfile, 'w') as out:
	out.write(header)
	out.write(outlines)

with open(infile, 'r') as f:
	lines = f.read().splitlines()
	my_dir_name = []
	for line in lines:
		line = line.split("\t")
		old = line[0]
		new = line[1]
		dir_name = os.path.split(new)[0]
		dir_name = dir_name.split("_")[-1]
		my_dir_name.append(dir_name)
		command = "perl /mnt/user_data/astangl/cerebro_testing/run_compare_changes.pl {0} {1} {2}".format(old, new, dir_name)
		os.system(command)