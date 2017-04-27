__Author__ = 'AJ Stangl'
__Date__ = 'April 17, 2016'
import os, sys, shutil, time

"""
Generates barcode labels for reagents
"""


def getInput():
    name = raw_input("Enter Name of Reagent: ")
    exp_date = raw_input("Enter Expiration (MMDDYYYY): ")
    lot = raw_input("Lot Number: ")
    copies = raw_input("Number of Copies of Label: ")
    printer = raw_input(
        "Possible Printer Destinations:\n1 = Sample Prep\n2 = Library Prep\n3 = Plasma Lab\nEnter Choice: ")
    name = name.upper()
    data = {"name": name, "exp_date": exp_date, "lot": lot, "printer": printer, "copies": copies}
    return data


def writeTSV(data):
    """
    Constructs a CSV to send to the printer
    :param data: A hash table of name, exp, lot, printer, and number of copies of the label
    :return: fname
    """
    encoded = data['name'] + '_DT' + data['exp_date'] + '_#' + data['lot']
    fname = data['name'] + '.csv'
    fname = fname.replace(" ", "")
    with open(fname, 'w') as f:
        f.write('%BTW% /AF="C:\\limslabels\\reageants\\reagent.btw" /C=' + data['copies'] + ' /D=%Trigger File Name% /PRN="pgdx-zebra' + data['printer'] + '"' + ' /R=3 /P' + '\r')
        f.write('%END%' + '\r')
        f.write('barcode,name,exp_date,lot' + '\r')
        f.write(encoded + ',' + data['name'] + ',' + 'EXP:' + data['exp_date'] + ',' + 'LOT #' + data['lot'])
        f.close()
    return fname


def main():
    print
    print "Welcome to Label Printing 2.0\nMounting File System"
    os.system(r"NET USE \\pgdx-lims\limslabels /U:glsai glsai2010#")
    data = getInput()
    source = os.getcwd()
    fname = writeTSV(data)
    source = os.path.join(source, fname)
    dest = "\\\pgdx-lims\limslabels"

    try:
        shutil.move(source, dest)
        print("Unmount File System\n")
        os.system(r"NET USE /delete \\pgdx-lims\limslabels")
        raw_input("Label Printing Complete\n\nHave a Nice Day = )\n\nPress Any Key to Exit:")

    except:
        os.system(r"NET USE /delete \\pgdx-lims\limslabels")
        raw_input("An Error Has Occured. Failed to Print Label\nContact AJ Stangl For Assistance\nPress Enter to Exit")


        # source = source + '/' + fname
        # dest = '/Volumes/limslabels/'
        # dest = os.path.normpath("P:/")
        # dest = "\\\pgdx-lims\limslabels"
        # print(dest)
        # dest = "\\pgdx-lims\limslabels"
        # shutil.move(source, dest)
        # print 'Label Printing Complete'
        # os.system(r"NET USE P: /delete /y")


if __name__ == "__main__":
    main()
