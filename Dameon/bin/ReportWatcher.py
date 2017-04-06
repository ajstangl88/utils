#!/usr/local/bin/python2.7

import sys, time, os, subprocess
from datetime import date
from Daemon import Daemon

class MyDaemon(Daemon):
    def run(self):
        while True:
            retval = subprocess.call(["/usr/local/bin/python2.7", "/mnt/user_data/aj_dev/RemoteReporting/scripts/monitorLims.py"])
            if retval == 0:
                continue
            else:
                subprocess.call(["/usr/local/bin/python2.7", "/mnt/user_data/aj_dev/RemoteReporting/scripts/sendEmail.py", "An_Error_Has_Occured", "Error", "astangl@personalgenome.com"])
                continue
        time.sleep(30)

def pathJoin(handle):
    path = os.path.dirname(os.path.realpath(__file__))
    return os.path.join(path, handle)


if __name__ == "__main__":

    daemon = MyDaemon(pathJoin('daemon.pid'))
    if len(sys.argv) == 2:
        if 'start' == sys.argv[1]:
            print
            daemon.start()
        elif 'stop' == sys.argv[1]:
            daemon.stop()
            print "Daemon Killed"
        elif 'restart' == sys.argv[1]:
            daemon.restart()
            print "Daemon Restarted"
        else:
            print "Unknown command"
            sys.exit(2)
        sys.exit(0)
    else:
        print "usage: %s start|stop|restart" % sys.argv[0]
        sys.exit(2)
