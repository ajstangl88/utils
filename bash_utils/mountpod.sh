#!/usr/bin/env bash

#osascript -e 'mount volume "smb://pgdxuser:pgdx01@PGDX-NAS1/Samples/Users/astangl"'

echo "Enter Pod: "
read var
server="172.16.101.2$var/data26-pgdx-pod$var"

#osascript -e 'mount volumne "smb://pgdxuser:pgdx01@"'

singleQuote="'"
doubleQuote='"'

part0="mount volume "
part1="osascript -e $singleQuote"
part2='"'smb://pgdxuser:pgdx01@$server'"'
command=$part1$part0$part2$singleQuote

bash -c "$command"

open /Volumes/
