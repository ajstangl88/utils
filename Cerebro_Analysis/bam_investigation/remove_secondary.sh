#!/usr/bin/env bash

input="$1"

samtools view -@ 20 -b -F 2048 "$input" > tiny.bam; mv tiny.bam $input
