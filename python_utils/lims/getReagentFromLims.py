#!/usr/bin/env python

"""
SYNOPSIS

    TODO Invocation

DESCRIPTION

    TODO This describes how to use this script. This docstring
    will be printed by the script if there is an error or
    if the user requests help (-h or --help).

EXAMPLES

    TODO: Show some examples of how to use this script.

EXIT STATUS

    TODO: List exit codes

AUTHOR

    Alfred Stangl <astangl@personalgenome.com|mailto:astangl@personalgenome.com>

COPYRIGHT

    Personal Genome Diagnostics, 2012. All rights reserved.

VERSION
    :Version 

"""
from apiutil import apiutil
import xml.etree.ElementTree as et

util = apiutil()
# Global Variables

reagents = dict()
util.user = "admin"
util.password = "Pgdx!01"
util.authHandler(util.user, util.password)
host = "https://pgdx-lims.ad.personalgenome.com/api/v2/"

endpoint = 'reagenttypes'
# url2 = 'https://pgdx-lims.ad.personalgenome.com/api/v2/reagenttypes?start-index=500'
url1 = host + endpoint


xml = util.getRequest(url1)
tree = et.fromstring(xml)
catagories = []
for item in tree.getiterator('reagent-type'):

    seqs = []
    xml = util.getRequest(item.attrib['uri'])
    tree = et.fromstring(xml)

    for reagent in tree.getiterator('reagent-category'):
        if reagent.text == 'TruSeq Adapter Index':
            for attrib in tree.getiterator('special-type'):
                for x in attrib:

                    # print tree.attrib['name']
                    # print  x.attrib['value']
                    temp = {tree.attrib['name'] : x.attrib['value']}
                    catagories.append(temp)
                    # reagents['type'] = 'TruSeq Adapter Index'

for elem in catagories:
    for k,v in elem.iteritems():
        print k + "\t" + v


