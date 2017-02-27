#!/usr/bin/env python

import sys, os, time
import subprocess
from subprocess import Popen


def runCommand(command):
    proc = Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    complete = False
    while not complete:
        status = proc.poll()
        if status is None:
            continue

        elif status is not 0:
            print("A Fatal Error Has Occurred")
            raise Exception(proc.communicate()[1])


        if status is 0:
            out, err = proc.communicate()
            return out


def sendMessage(tty, msg):
    for elem in tty:
        myCommand = "echo {} > {}".format(msg, elem)
        runCommand(myCommand)
        # print(myCommand)

def getUsers():

    myUserDict = dict()
    myID = runCommand('tty').replace("\n", "")

    allUsers = runCommand("last | head | grep logged | awk '{print $2,$3}'")
    myIP = []
    ips = []
    terms = []
    temp = allUsers.split("\n")
    for elem in temp:
        try:
            splitted = elem.split()
            term = splitted[0]
            term = '/dev/' + term
            ip = splitted[1]
            if term == myID:
                myIP.append(ip)
            ips.append(ip)
            terms.append(term)

        except IndexError:
            continue

    combined = zip(ips, terms)

    for item in combined:
        ip = item[0]

        myUserDict[ip] = []


    for item in combined:
        term = item[1]
        ip = item[0]
        myUserDict[ip].append(term)

    some_dict = {key: value for key, value in myUserDict.items() if key is not myIP[0]}


    return(some_dict)


def menuSelection(users):
    ips = users.keys()
    selections = []
    print("ID\tIP")
    for ip in enumerate(ips):
        string = (str(ip[0]) + "\t" + ip[1])
        print(string)
        selections.append(string)
    selection = raw_input("Enter Selection (Use ID): ")
    for elem in selections:
        temp = elem.split('\t')
        sel = temp[0]
        ip = temp[1]
        if selection == sel:
            msg = raw_input("Enter Message to Send: ")
            sendMessage(users[ip], msg)

user = getUsers()



menuSelection(user)