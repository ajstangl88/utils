import os, ConfigParser
from apiutil import apiutil
import xml.etree.ElementTree as et
from apiutil import apiutil
from datetime import date
import os, json, re, sys, ConfigParser, subprocess, traceback, time

scriptPath = os.path.dirname(os.path.realpath(__file__))
credPath = "/Users/astangl/PycharmProjects/HomeProject/lims/lims.ini"
config = ConfigParser.RawConfigParser()
config.read(credPath)
host = config.get('Creds','host')
user = config.get('Creds', 'user')
password = config.get('Creds', 'password')
util = apiutil()

util.user = user
util.password = password
util.authHandler(util.user, util.password)



def getActiveProcess(artID):
    endpoint = "/processes?inputartifactid={}&type=Reporting%20Gateway".format(artID)
    xml = util.getRequest(host + endpoint)
    tree = et.fromstring(xml)
    for elem in tree:
        xml = util.getRequest(elem.attrib['uri'])
        # Do this check because if the sample has not been run it will not have this parameter
        if not re.findall(r'date-run',xml):
            tree = et.fromstring(xml)
            ioMap = util.mapIO(tree)
            for elem in ioMap:
                print elem['input']['limsid']
                print ioMap
                try:
                    currentArt = [elem for elem in ioMap if elem['input']['limsid'] == artID][0]
                    outputId = currentArt['output']['limsid']
                    return outputId
                except IndexError:
                    continue


print getActiveProcess('2-607663')