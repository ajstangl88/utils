import sys
import os

infile = sys.argv[1]


def write_xml(infile, xml):
    """
    Takes a TSV and transforms it into a LIMs XML that can be used to upload reagents to LIMs
    """
    f = open(infile, "U")
    o = open("xml_index.xml", "wb")
    lines = f.readlines()
    names = []
    seqs = []
    for line in lines:
        reagent = line.split("\n")[0]
        name = reagent.split("\t")[0]
        seq = reagent.split("\t")[1]
        names.append(name)
        seqs.append(seq)
    f.close()

    head = '<config ApiVersion="v2,r20" ConfigSlicerVersion="3.0-compatible">\n<ReagentTypes>\n'
    close = "</ReagentTypes>\n</config>"
    nameseq = zip(names, seqs)

    o.write(head)
    for elem in nameseq:
        body = '<rtp:reagent-type xmlns:rtp="http://genologics.com/ri/reagenttype" name="myname">\n<special-type name="Index">\n<attribute value="myseq" name="Sequence"/>\n</special-type>\n<reagent-category>TruSeq Adapter Index</reagent-category>\n</rtp:reagent-type>\n'.replace(
            "myname", elem[0]).replace("myseq", elem[1])
        o.write(body)

    o.write(close)
    o.close()


if __name__ == '__main__':
    write_xml(infile, xml="/Users/astangl/Desktop/new_index.xml")

