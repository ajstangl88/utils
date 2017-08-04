#!/usr/bin/env python

"""
SYNOPSIS

    coverage_comp.py <old_summary_table> <new_summary_table> [-p1, --percent_1][-p2, --percent_2][-o, --output][-h, --help]

DESCRIPTION

    This script takes in an old and new summary file to compare, as well as two percent parameters (in decimal form) that represent allowable
    differences between the two tables. It then compares the appropriate values to and assigns PASS/FAIL and the percent difference. The output
    for this is a txt file that shows the old/new values, PASS/FAIL/percent differences for both tumor and normal samples

EXAMPLES

    ./coverage_comp.py -f1 old_summary.txt -f 2 new_summary.txt -p1 .02 -p2 .02 -o comp_summary.txt

AUTHOR

    James Hernandez
    Updated: AJ Stangl

VERSION

    coverage_comp.py v1.2
"""

import argparse, os, sys

def locate_summary(inpath):
    """
    Takes in a filepath specified by the -f1 and -f2 flags and find the summarysheey
    :param inpath: 
    :return: Absolute Path to Summarysheet or Error and Exit  
    """
    files = os.listdir(inpath)
    for f in files:
        if f.endswith(".summarysheet.txt"):
            found = os.path.join(inpath, f)
            return found


def parse_table(file_name):
    """
    This function parses through the user defined summary files (new or old) and then extracts relevant information 
    to be compared.
     
    The lists are split into tumor and normal
    :param file_name: The Name of the file to parse. *.Summarysheet 
    :return: None
    """
    # Initialize dictionary to store values from tables -- Divided into Tumor and Normal KV pairs
    # TODO: Can't this be turned into a config file?
    table = {
        'tumor': {
            'Database': None,
            'Sample': None,
            'Bases in Target Region': None,
            'Read Length': None,
            'Bases Sequenced (Filtered)': None,
            'Bases Mapped to Genome (filtered)': None,
            'Percent Mapped to Genome': None,
            'Bases Mapped to ROI': None,
            'Percent Mapped to ROI': None,
            'Targeted bases with at least 10 reads': None,
            'Targeted bases with at least 10 reads (%)': None,
            'Targeted bases with at least 10 distinct reads': None,
            'Targeted bases with at least 10 distinct reads (%)': None,
            'Average Raw Coverage (Total)': None,
            'Average High Quality Coverage (Total)': None,
            'Average Raw Coverage (Distinct)': None,
            'Average High Quality Coverage (Distinct)': None,
            'SNPs in Tumor ( > 0.4, Cov > 20 in both)': None,
            'Present in Normal': None
        },

        'normal': {
            'Database': None,
            'Sample': None,
            'Bases in Target Region': None,
            'Read Length': 0,
            'Bases Sequenced (Filtered)': None,
            'Bases Mapped to Genome (filtered)': None,
            'Percent Mapped to Genome': None,
            'Bases Mapped to ROI': None,
            'Percent Mapped to ROI': None,
            'Targeted bases with at least 10 reads': None,
            'Targeted bases with at least 10 reads (%)': None,
            'Targeted bases with at least 10 distinct reads': None,
            'Targeted bases with at least 10 distinct reads (%)': None,
            'Average Raw Coverage (Total)': None,
            'Average High Quality Coverage (Total)': None,
            'Average Raw Coverage (Distinct)': None,
            'Average High Quality Coverage (Distinct)': None,
            'SNPs in Tumor ( > 0.4, Cov > 20 in both)': None,
            'Present in Normal': None
        }
    }

    # Used for differentiating between total and distrinct coverage.
    Total = False

    for line in open(file_name, 'r'):

        line = line.strip()
        line_sep = line.split('\t')

        if line_sep[0] == 'Sample':
            table['tumor']['Sample'] = line_sep[1]

            if len(line_sep) > 2:
                table['normal']['Sample'] = line_sep[2]

        elif line_sep[0] == 'Average Raw Coverage':
            if Total == False:
                table['tumor']['Average Raw Coverage (Total)'] = float(line_sep[1].strip())
                table['normal']['Average Raw Coverage (Total)'] = float(line_sep[2].strip())
            else:
                table['tumor']['Average Raw Coverage (Distinct)'] = float(line_sep[1].strip())
                table['normal']['Average Raw Coverage (Distinct)'] = float(line_sep[2].strip())

        elif line_sep[0] == 'Average High Quality Coverage':
            if Total ==False:
                table['tumor']['Average High Quality Coverage (Total)'] = float(line_sep[1].strip())
                table['normal']['Average High Quality Coverage (Total)'] = float(line_sep[2].strip())
                Total = True
            else:
                table['tumor']['Average High Quality Coverage (Distinct)'] = float(line_sep[1].strip())
                table['normal']['Average High Quality Coverage (Distinct)'] = float(line_sep[2].strip())

        if line_sep[0] in table['tumor']:
            table['tumor'][line_sep[0]] = line_sep[1].strip()

        if line_sep[0] in table['normal'] and len(line_sep) > 2:
            table['normal'][line_sep[0]] = line_sep[2].strip()

    return(table)


def compare_tables(old_table, new_table, percent_1, percent_2):
    """
    This function compares the two tables and reports whether they pass or fail, based on user defined percent
    allowable differences between the new and old summary sheets
        :param old_table: The hash table representing the old summary sheet tumor/normal key/value pairs   
        :param new_table: The hash table representing the new summary sheet tumor/normal key/value pairs 
        :param percent_1: The allowable difference (Typically .02)
        :param percent_2: The allowable difference (Typically .02)
        :return: comparison_table data structure 
    """

    comparison_table = {
        'tumor': {
                'Bases in Target Region': None,
                'Read Length': None,
                'Bases Sequenced (Filtered)': None,
                'Bases Mapped to Genome (filtered)': None,
                'Percent Mapped to Genome': None,
                'Bases Mapped to ROI': None,
                'Percent Mapped to ROI': None,
                'Targeted bases with at least 10 reads': None,
                'Targeted bases with at least 10 reads (%)': None,
                'Targeted bases with at least 10 distinct reads': None,
                'Targeted bases with at least 10 distinct reads (%)': None,
                'Average Raw Coverage (Total)': None,
                'Average High Quality Coverage (Total)': None,
                'Average Raw Coverage (Distinct)': None,
                'Average High Quality Coverage (Distinct)': None,
                'SNPs in Tumor ( > 0.4, Cov > 20 in both)': None,
                'Present in Normal': None
            },

        'normal': {
                'Bases in Target Region': None,
                'Read Length': None,
                'Bases Sequenced (Filtered)': None,
                'Bases Mapped to Genome (filtered)': None,
                'Percent Mapped to Genome': None,
                'Bases Mapped to ROI': None,
                'Percent Mapped to ROI': None,
                'Targeted bases with at least 10 reads': None,
                'Targeted bases with at least 10 reads (%)': None,
                'Targeted bases with at least 10 distinct reads': None,
                'Targeted bases with at least 10 distinct reads (%)': None,
                'Average Raw Coverage (Total)': None,
                'Average High Quality Coverage (Total)': None,
                'Average Raw Coverage (Distinct)': None,
                'Average High Quality Coverage (Distinct)': None,
                'SNPs in Tumor ( > 0.4, Cov > 20 in both)': None,
                'Present in Normal': None
            }
    }

    # Get the keys from the normal portion of this array (This assumes that this is correct)
    key_list = list(comparison_table['normal'].keys())

    percent1_min = 1 - percent_1
    percent1_max = 1 + percent_1

    percent2_min = 1 - percent_2
    percent2_max = 1 + percent_2

    print("1..34")

    test_count = 1

    # Items that we want to compare a percentage
    for index in key_list:

        # Since we have two percent allowable difference parameters, we need to analyze the appropriate
        # sections independently this compares the values to the first percentage given (percent_1)

        if index == 'Bases Mapped to ROI' or \
           index == 'Percent Mapped to ROI' or \
           index == 'Targeted bases with at least 10 reads' or \
           index == 'Targeted bases with at least 10 distinct reads':

            if old_table['tumor'][index] == "":

                old_table['tumor'][index] = 0

            if old_table['normal'][index] == "":

                old_table['normal'][index] = 0

            tumor_min_value = float(old_table['tumor'][index]) * percent1_min
            tumor_max_value = float(old_table['tumor'][index]) * percent1_max
            normal_min_value = float(old_table['normal'][index]) * percent1_min
            normal_max_value = float(old_table['normal'][index]) * percent1_max

            if float(new_table['tumor'][index]) >= tumor_min_value and float(new_table['tumor'][index]) <= tumor_max_value:

                diff = calculate_difference(old_table['tumor'][index], new_table['tumor'][index])
                result = 'Pass / ' + str(round(diff, 2))
                comparison_table['tumor'][index] = result

                print(str('ok ' + str(test_count) + " - " + str(index) + " - Tumor"))
                test_count += 1


            else:

                diff = calculate_difference(old_table['tumor'][index], new_table['tumor'][index])
                result = 'Fail / ' + str(round(diff, 2))
                comparison_table['tumor'][index] = result

                print(str('not ok ' + str(test_count) + " - " + str(index) + " - Tumor"))
                test_count += 1

            if float(new_table['normal'][index]) >= normal_min_value and float(new_table['normal'][index]) <= normal_max_value:

                diff = calculate_difference(old_table['normal'][index], new_table['normal'][index])
                result = 'Pass / ' + str(round(diff, 2))
                comparison_table['normal'][index] = result

                print(str('ok ' + str(test_count) + " - " + str(index) + " - Normal"))
                test_count += 1

            else:

                diff = calculate_difference(old_table['normal'][index], new_table['normal'][index])
                result = 'Fail / ' + str(round(diff, 2))
                comparison_table['normal'][index] = result

                print(str('not ok ' + str(test_count) + " - " + str(index) + " - Normal"))
                test_count += 1


        # This compares the first percentage but since these values are in percentages already, it requires a different calculation
        # TODO: Not always a safe assumption for plasma
        elif index == 'Targeted bases with at least 10 reads (%)' or \
             index == 'Targeted bases with at least 10 distinct reads (%)':

            tumor_min_value = float(old_table['tumor'][index]) - percent_1
            tumor_max_value = float(old_table['tumor'][index]) + percent_1


            # We have to do this because in plasma the normal column is always 0
            if old_table['normal'][index]:
                normal_min_value = float(old_table['normal'][index]) - percent_1
                normal_max_value = float(old_table['normal'][index]) + percent_1

            else:
                normal_min_value = float(0) - percent_1
                normal_max_value = float(0) + percent_1


            if float(new_table['tumor'][index]) >= tumor_min_value and float(new_table['tumor'][index]) <= tumor_max_value:

                diff = calculate_difference(old_table['tumor'][index], new_table['tumor'][index])
                result = 'Pass / ' + str(round(diff, 2))
                comparison_table['tumor'][index] = result

                print(str('ok ' + str(test_count) + " - " + str(index) + " - Tumor"))
                test_count += 1

            else:

                diff = calculate_difference(old_table['tumor'][index], new_table['tumor'][index])
                result = 'Fail / ' + str(round(diff, 2))
                comparison_table['tumor'][index] = result


                print(str('not ok ' + str(test_count) + " - " + str(index) + " - Tumor"))
                test_count += 1

            # Check to ensure that this has a value
            if new_table['normal'][index]:

                if float(new_table['normal'][index]) >= normal_min_value and float(new_table['normal'][index]) <= normal_max_value:

                    diff = calculate_difference(old_table['normal'][index], new_table['normal'][index])
                    result = 'Pass / ' + str(round(diff, 2))
                    comparison_table['normal'][index] = result
                    print(str('ok ' + str(test_count) + " - " + str(index) + " - Normal"))
                    test_count += 1

                else:

                    diff = calculate_difference(old_table['normal'][index], new_table['normal'][index])
                    result = 'Fail / ' + str(round(diff, 2))
                    comparison_table['normal'][index] = result


                    print(str('not ok ' + str(test_count) + " - " + str(index) + " - Normal"))
                    test_count += 1
            else:
                old_table['normal'][index] = 0.0
                new_table['normal'][index] = 0.0

                if float(new_table['normal'][index]) >= normal_min_value and float(new_table['normal'][index]) <= normal_max_value:
                    diff = calculate_difference(old_table['normal'][index], new_table['normal'][index])
                    result = 'Pass / ' + str(round(diff, 2))
                    comparison_table['normal'][index] = result
                    print(str('ok ' + str(test_count) + " - " + str(index) + " - Normal"))
                    test_count += 1

                else:
                    diff = calculate_difference(old_table['normal'][index], new_table['normal'][index])
                    result = 'Fail / ' + str(round(diff, 2))
                    comparison_table['normal'][index] = result
                    print(str('not ok ' + str(test_count) + " - " + str(index) + " - Normal"))
                    test_count += 1


        #this does the calculations and pass/fail analysis using the second percentage given
        elif index == 'Average Raw Coverage (Total)' or \
             index == 'Average High Quality Coverage (Total)' or \
             index == 'Average Raw Coverage (Distinct)' or \
             index == 'Average High Quality Coverage (Distinct)':

            tumor_min_value = old_table['tumor'][index] * percent2_min
            tumor_max_value = old_table['tumor'][index] * percent2_max
            normal_min_value = old_table['normal'][index] * percent2_min
            normal_max_value = old_table['normal'][index] * percent2_max

            if new_table['tumor'][index] >= tumor_min_value and new_table['tumor'][index] <= tumor_max_value:

                diff = calculate_difference(old_table['tumor'][index], new_table['tumor'][index])
                result = 'Pass / ' + str(round(diff, 2))
                comparison_table['tumor'][index] = result


                print(str('ok ' + str(test_count) + " - " + str(index) + " - Tumor"))
                test_count += 1

            else:

                diff = calculate_difference(old_table['tumor'][index], new_table['tumor'][index])
                result = 'Fail / ' + str(round(diff, 2))
                comparison_table['tumor'][index] = result

                print(str('not ok ' + str(test_count) + " - " + str(index) + " - Tumor"))
                test_count += 1

            if new_table['normal'][index] >= normal_min_value and new_table['normal'][index] <= normal_max_value:

                diff = calculate_difference(old_table['normal'][index], new_table['normal'][index])
                result = 'Pass / ' + str(round(diff, 2))
                comparison_table['normal'][index] = result

                print(str('ok ' + str(test_count) + " - " + str(index) + " - Normal"))
                test_count += 1

            else:

                diff = calculate_difference(old_table['normal'][index], new_table['normal'][index])
                result = 'Fail / ' + str(round(diff, 2))
                comparison_table['normal'][index] = result

                #ok(0, str(index) + " - Normal")
                print(str('not ok ' + str(test_count) + " - " + str(index) + " - Normal"))
                test_count += 1

        # Test the parameters that require exact matches
        else:

            if float(new_table['tumor'][index]) == float(old_table['tumor'][index]):
                comparison_table['tumor'][index] = 'Pass'

                print(str('ok ' + str(test_count) + " - " + str(index) + " - Tumor"))
                test_count += 1

            else:
                comparison_table['tumor'][index] = 'Fail'

                #ok(0, str(index) + " - Tumor")
                print(str('not ok ' + str(test_count) + " - " + str(index) + " - Tumor"))
                test_count += 1

            if float(new_table['normal'][index]) == float(old_table['normal'][index]):
                comparison_table['normal'][index] = 'Pass'

                print(str('ok ' + str(test_count) + " - " + str(index) + " - Normal"))
                test_count += 1

            else:
                comparison_table['normal'][index] = 'Fail'


                print(str('not ok ' + str(test_count) + " - " + str(index) + " - Normal"))
                test_count += 1

    return(comparison_table)


def calculate_difference(old_value, new_value):

    if float(old_value) == 0:
        diff = 0

    else:
        diff = (float(new_value) - float(old_value))/float(old_value)

    return(diff)


def build_summary_table(old_table, new_table, comparison_table, output_file, old_file, new_file):
    """
    This function prints out the report to the user defined or default output file
    :param old_table: 
    :param new_table: 
    :param comparison_table: 
    :param output_file: 
    :param old_file: 
    :param new_file: 
    :return: 
    """

    report_order = ['Bases in Target Region', 'Read Length', 'Bases Sequenced (Filtered)', 'Bases Mapped to Genome (filtered)', \
                    'Percent Mapped to Genome', 'Bases Mapped to ROI', 'Percent Mapped to ROI', 'Targeted bases with at least 10 reads', \
                    'Targeted bases with at least 10 reads (%)', 'Targeted bases with at least 10 distinct reads', \
                    'Targeted bases with at least 10 distinct reads (%)', 'Average Raw Coverage (Total)', 'Average High Quality Coverage (Total)', \
                    'Average Raw Coverage (Distinct)', 'Average High Quality Coverage (Distinct)', 'SNPs in Tumor ( > 0.4, Cov > 20 in both)', 'Present in Normal']

    report = open(output_file, 'w')

    report.write("Old File:\t" + str(old_file) + "\n" + "New file:\t" + str(new_file) + "\n")

    report.write("\tOld Tumor Values\tNew Tumor Values\tTumor Pass/Fail\tOld Normal Values\tNew Normal Values\tNormal Pass/Fail\n")

    report.write("Sample\t" + str(old_table['tumor']['Sample']) + "\t" + str(new_table['tumor']['Sample']) + "\t\t" + str(old_table['normal']['Sample']) + "\t" + str(new_table['normal']['Sample']) + "\n")

    key_list = list(comparison_table['normal'].keys())

    for index in report_order:

        report.write(str(index) + "\t" + str(old_table['tumor'][index]) + "\t" + str(new_table['tumor'][index]) + "\t" + \
                     str(comparison_table['tumor'][index]) + "\t" + str(old_table['normal'][index]) + "\t" + \
                     str(new_table['normal'][index]) + "\t" + str(comparison_table['normal'][index]) + "\n")


def main():

    parser = argparse.ArgumentParser()

    parser.add_argument("-f1", "--old_file", type=str, help="Enter the old file to compare")

    parser.add_argument("-f2", "--new_file", type=str, help="Enter the new file to compare")

    parser.add_argument("-p1", "--percent_1", type=float, help="Enter the percent allowable difference for: "
                                                               "Bases Mapped ROI, Percent Mapped to ROI, "
                                                               "Targeted bases with at least 10 reads, "
                                                               "Targeted bases with at least 10 reads (percent), "
                                                               "Targeted bases with at least 10 distinct reads, "
                                                               "and Targeted bases with atleast 10 distinct reads "
                                                               "(percent)")

    parser.add_argument("-p2", "--percent_2", type=float, help="Enter the percent allowable difference for Raw "
                                                               "Coverage and High Quality Coverage values")

    parser.add_argument("-o", "--output", type=str, help="Name your desired output file name. "
                                                         "Default is 'comparison.txt'")

    args = parser.parse_args()

    # Pass in the directory where the summary sheets are located and reset the varible to the path.
    args.old_file = locate_summary(args.old_file)
    args.new_file = locate_summary(args.new_file)


    if not args.output:
        output_file = str(args.new_file) + "_comparison_summary.txt"
    else:
        output_file = args.output

    if not os.path.exists(args.old_file):
        raise Exception("Error: passed file ({0}) doesn't exist.".format(args.old_file))

    if not os.path.exists(args.new_file):
        raise Exception("Error: passed file ({0}) doesn't exist.".format(args.new_file))

    if not args.percent_1:
        raise Exception("Please enter percent value for --percent_1")

    if not args.percent_2:
        raise Exception("Please enter percent value for --percent_2")

    if args.percent_1 > 1 or args.percent_2 > 1:
        raise Exception("Please enter a valid percent value (between 0 and 1)")

    # Parse the old summary file
    old_table = parse_table(args.old_file)

    # Parse the new summary file
    new_table = parse_table(args.new_file)

    # Compare the old and new table with allowable percentages
    comparison_table = compare_tables(old_table, new_table, args.percent_1, args.percent_2)

    build_summary_table(old_table, new_table, comparison_table, output_file, args.old_file, args.new_file)

if __name__ == '__main__':
    sys.exit(main())

