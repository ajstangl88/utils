#!/usr/bin/env bash
#####################
# A Simple Script to package bowtie2 (2.2.9) into an RPM
# This script must be run on pgdx-pr5 or any pgdx server where fpm is installed
# Author: AJ Stangl
# Date: 2/28/17
# Project: Cerebro
#####################

# Move to mount and make the temp directory
cd /mnt/user_data;
mkdir -p tempDir;
cd tempDir;

# Pull down the repo
git clone https://github.com/lh3/bwa.git;

# Enter the BWA dir
cd bwa;

# Make (Can't Configure)
make;

# Move up one dir
cd ../;

# Copy the compiled BWA to /opt/opt-packages
cp -R bwa /opt/opt-packages/bwa;



# Remove the original Copy
rm -rf bwa;

# Chnage permissions
chmod -R 777 /opt/opt-packages/bwa;

# Make A Tarball from the Copy in /opt/opt-packages
tar cvfz bwa.tgz /opt/opt-packages/bwa/;

# Create a generic RPM for BWA
fpm -f -s tar -p ./ -t rpm -n bwa -v 0.5.9 --rpm-os linux bwa.tgz;

# Remove the installed Binary
rm -rf /opt/opt-packages/bwa/;

# Remove the tarball
rm -f bwa.tgz
