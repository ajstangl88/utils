#!/usr/bin/env bash
bash -c `osascript -e 'mount volume "smb://astangl:Guitar!01@PGDX-Indesign/Reporting"'`
myfile=$1
dest="/Volumes/Reporting"
`cp -r $myfile $dest`
umount /Volumes/Reporting
