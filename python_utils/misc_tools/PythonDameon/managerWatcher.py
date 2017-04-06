#!/usr/local/bin/python2.7

import sys, time, os, subprocess
from datetime import date
from Daemon import Daemon
from time import sleep

class MyDaemon(Daemon):
    def run(self):
        """
        Opens a file specified in the "dir", read the file and performs an action in the file
        :return:
        """
        while True:
            dir = "/root/managerNotifications"
            files = os.listdir(dir)
            for item in files:
                trueFile = os.path.join(dir, item)
                if os.path.isdir(trueFile):
                    continue
                else:

                    with open(trueFile,'r') as f:
                        cmd = f.read()
                        proc = os.system(cmd)
                        if proc == 0:
                            cmd2 = "mv {} /root/managerNotifications/processed".format(trueFile)
                            os.system(cmd2)


            sleep(60)



def pathJoin(handle):
    path = os.path.dirname(os.path.realpath(__file__))
    return os.path.join(path, handle)


if __name__ == "__main__":

    daemon = MyDaemon(pathJoin('daemon.pid'))
    if len(sys.argv) == 2:
        if 'start' == sys.argv[1]:
            daemon.start()
        elif 'stop' == sys.argv[1]:
            daemon.stop()
            print("Daemon Killed")
        elif 'restart' == sys.argv[1]:
            daemon.restart()
            print("Daemon Restarted")
        else:
            print("Unknown command")
            sys.exit(2)
        sys.exit(0)
    else:
        print("Usage: {} start|stop|restart").format(sys.argv[0])
        sys.exit(2)
