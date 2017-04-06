import os, sys, shutil, time, re



def getInput(tsv):
    data = []
    with open(tsv, "U") as f:
        lines = f.readlines()
        for line in lines:
            line = line.split("\t")
            dat = {"name": line[0].replace("\n", ""), "exp_date": line[0].replace("\n", ""), "lot":""}
            data.append(dat)
    return data


def writeTSV(data):
    """
    Constructs a CSV to send to the printer
    :param data: A hash table of name, exp, lot, printer, and number of copies of the label
    :return: fname
    """
    fname = data['name'] + '.csv'
    fname = fname.replace(" ", "")

    with open(fname, 'w') as f:
        f.write('%BTW% /AF="C:\\limslabels\\reageants\\reagent.btw" /C=' + "1" + ' /D=%Trigger File Name% /PRN="pgdx-zebra' + "3" + '"' + ' /R=3 /P' + '\r')
        f.write('%END%' + '\r')
        f.write('barcode,name,exp_date,lot' + '\r')
        f.write(data['name'] + ',' + data['name'] + ',' + 'EXP:' + "" + ',' + 'LOT #' + "")
        f.close()
    return fname



def main():
    tsv = '/Users/astangl/Development/sampleNames.txt'
    data = getInput(tsv)
    source = os.getcwd()
    dest = '/Volumes/limslabels/'
    print data
    map(writeTSV, data)
    items = os.listdir(source)
    csv = [item for item in items if item.endswith(".csv")]
    newcsv = sorted(csv)
    for item in newcsv:
        mysource = source + "/" + item
        cmd = "mv %s %s" % (mysource, dest)
        os.system(cmd)
        print "Moving %s to %s" % (mysource, dest)
        time.sleep(5)


if __name__ == '__main__':
    main()