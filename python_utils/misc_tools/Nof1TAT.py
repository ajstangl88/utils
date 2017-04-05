#!/usr/bin/env python
from datetime import datetime, timedelta
import paramiko, os, sys, math


sftpURL   =  'integration.n-of-one.com'
sftpUser  =  'pgdx'
sftpPass  =  'Amje%kifRu7rKfFQ'
port = 2222

ssh = paramiko.SSHClient()

# automatically add keys without requiring human intervention
ssh.set_missing_host_key_policy( paramiko.AutoAddPolicy() )

ssh.connect(sftpURL, username=sftpUser, password=sftpPass, port=port)

ftp = ssh.open_sftp()

from_files = ftp.listdir(path='/FromNof1')

to_files = ftp.listdir(path='/ToNof1/archive')


# Array of received files
full_from = []

# Array of sent files
full_to = []

# Iterate through the files that we have received from  Nof1 and push to full_from array
for file in from_files:
    temp_path = os.path.join('/FromNof1', file)
    full_from.append(temp_path)

# Do the same thing for the files we sent to Nof1
for file in to_files:
    temp_path = os.path.join('/ToNof1/archive', file)
    full_to.append(temp_path)


def getDate(path):
    """
    Get the datestamp from a given file 
    :param path: The SFTP path to a file
    :return: None
    """
    utime = ftp.stat(path=path).st_mtime
    last_modified = datetime.fromtimestamp(utime)
    return last_modified

def inBoth(from_files):
    """
    Main Function that compares times and 
    :param from_files: Path to received Nof1 Files 
    :return: None
    """
    t_nof1 = []
    f_nof1 = []
    array_of_times = []
    for file in from_files:
        item = file.replace('_COMPLETE', '')
        if item in to_files:
            to = os.path.join('/ToNof1/archive', item)
            from_nof1 = os.path.join('/FromNof1', file)
            t_nof1.append(to)
            f_nof1.append(from_nof1)



    with open("TAT_From_Nof1.tsv", 'w') as f:
        i = 0
        myHeader = "Completed File\tCompleted Time\tSent File\tSent Time\tDelta\n"
        f.write(myHeader)
        while i < len(to_files):
            today = datetime.today()

            fName = os.path.basename(f_nof1[i])
            tName = os.path.basename(t_nof1[i])

            fTime = getDate(f_nof1[i])
            tTime = getDate(t_nof1[i])

            duration = (today - fTime)
            if duration.days < 90:
                delta = fTime - tTime
                seconds = (delta.total_seconds())
                minutes = seconds / 60.0
                hours = minutes / 60.0
                array_of_times.append(hours)
                delta = str(delta)
                fTime = str(fTime)
                tTime = str(tTime)
                myString = (fName + "\t" + fTime + "\t" + tName + "\t" + tTime + "\t" + delta + "\n")
                f.write(myString)








inBoth(from_files)

