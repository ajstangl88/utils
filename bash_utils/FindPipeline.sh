#!/usr/bin/env bash
# This script will take in a txt file for pipeline names (take them from the process log) and write a list of paths
# To the desired pipeline names

#FILE=$1 #file containing list of pipeline names
CurrPath=$PWD #to save the output file in whatever directory the script is run from

pods=$(ls -la /mnt/user_data/ | grep "PGDX-DATA*" | cut -d' ' -f 15 | xargs -i readlink -f {})
#while read line; do #for each pipeline name in the input file

for pod in $pods #for each pod, starting with data18 and moving down
do
    if [ -e $pod/Samples/$line/ ]; then
        echo "$pod/Samples/$line/" >> $CurrPath/paths.txt
        break
    fi
done
	
#done < $FILE
