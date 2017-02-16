#!/bin/bash
# FILE is a list of pipeline names that you would like to search for a specific value in the plasmachanges sheet. Gene, ENSG #, Etc.
FILE=$1;
echo "Enter gene name: "
read gene

pods=$(ls -la /mnt/user_data/ | grep "PGDX-DATA*" | cut -d' ' -f 15 | xargs -i readlink -f {})

while read line; do
    for pod in $pods;
    do
        if [ -e $pod/Samples/$line/*PlasmaChanges.txt ];
        then
            grep -r -l -w $gene $pod/Samples/$line/*PlasmaChanges.txt
        fi
    done
done < $FILE