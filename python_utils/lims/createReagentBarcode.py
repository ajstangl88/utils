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
    printer = raw_input("Enter Printer destination(1 = Sample Prep, 2 = Library Prep, 3 = Plasma Lab): ")
    name = name.upper()
    data = {"name": name, "exp_date": exp_date, "lot":lot, "printer": printer, "copies": copies}
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
    print 'Mounting File System'
    # os.system(r"NET USE P: \\PGDX-BARTENDER\limslabels /U:pgdx\rs-limslabels PrintMyL@be1!")
    data = getInput()
    source = os.getcwd()
    fname = writeTSV(data)

    source = source + '/' + fname
    dest = '/Volumes/limslabels/'
    # dest = os.path.normpath("P:/")
    shutil.move(source, dest)
    print 'Label Printing Complete'
    # os.system(r"NET USE P: /delete /y")


if __name__ == "__main__":
    main()

