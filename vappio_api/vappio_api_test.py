#!/usr/bin/env python

"""
SYNOPSIS

    A general purpose tool used for obtaining information from Pipelines running on a specified server

DESCRIPTION

    TODO This describes how to use this script. =

EXAMPLES

    TODO: Show some examples of how to use this script.

EXIT STATUS

    TODO: List exit codes

AUTHOR

    Alfred Stangl <astangl@personalgenome.com|mailto:astangl@personalgenome.com>

COPYRIGHT

    Personal Genome Diagnostics, 2017. All rights reserved.

VERSION
    :Version 

"""
from requests import get
from requests import post
import json
import sys, os
from os.path import join as osjoin
import readline
parentPath = os.path.dirname(os.path.realpath(__file__))


def getKeys():
    """
    Obtains a list of keys from 'dictkeys.txt' file used to access the values provided by each request to the specifed
    server
    :return: keys (list) containing all dict keys for the JSON dumped response.content object
    """
    dictKeys = [osjoin(parentPath,file) for file in os.listdir(parentPath) if file == 'dictkeys.txt'][0]
    with open(dictKeys, 'r') as f:
        keys = [line.replace("\n","") for line in f.readlines()]
        return keys


def promptForServer(text, state):
    servers = [osjoin(parentPath,file) for file in os.listdir(parentPath) if file == 'serverlist.txt'][0]
    with open(servers, 'r') as f:
        server_list = [line.replace("\n","") for line in f.readlines()]

    # user_input = raw_input("Enter Server: ")
    for server in server_list:
        if server.startswith(text):
            if not state:
                return server
            else:
                state -=1


def getServerInfo(serverName):
    """
    Obtains all pipeline information for a specified server
    :param serveName: A server name (pgdx-ft4)
    :return: The full response content for the specifed server
    """
    url = "http://%s/vappio/pipeline_list?request={%22cluster%22:%22local%22}" % serverName
    print url

if __name__ == '__main__':
    getKeys()




# url = "http://pgdx-ft4/vappio/pipeline_list?request={%22cluster%22:%22local%22}"
#
# r = post(url)
# r = r.content
# content = json.loads(r)['data']
#
#
#
#
# def filterComplete(data):
#     if data['state'] != 'completed' and data['state'] != 'failed':
#         return data
#     else:
#         return None
#
#
#
# notComplete = []
# for elem in content:
#     if filterComplete(elem) != None:
#         notComplete.append(elem)
#
#
#
# for item in notComplete:
#     print item
#
#
