#!/usr/bin/env bash

while IFS='' read -r line || [[ -n "$line" ]]; do

    # Do Stuff Here
    echo basename $line


done < "$1"