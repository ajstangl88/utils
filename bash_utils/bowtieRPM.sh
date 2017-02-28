#####################
# A Simple Script to package bowtie2 (2.2.9) into an RPM
# This script must be run on pgdx-pr5 or any pgdx server where fpm is installed
# Author: AJ Stangl
# Date: 2/28/17
# Project: Cerebro
#####################

# Go to the Staging Area
cd /mnt/user_data;

# Make temp dir if not avail
mkdir -p tempDir;
cd tempDir;

# Download bowtie2
wget https://ufpr.dl.sourceforge.net/project/bowtie-bio/bowtie2/2.2.9/bowtie2-2.2.9-linux-x86_64.zip;

# Unzip Bowtie 2
unzip bowtie2-2.2.9-linux-x86_64.zip;

# Remove the ZIP File
rm -f bowtie2-2.2.9-linux-x86_64.zip;

# Copy the binary over to /opt/opt-packages
cp -R bowtie2-2.2.9 /opt/opt-packages;

# Open Up Permissions (Affects the RPM)
chmod -R 777 /opt/opt-packages/bowtie2-2.2.9;

# Remove Local Copy
rm -rf bowtie2-2.2.9;

# Make A Tarball from the Copy in
tar cvfz bowtie2-2.2.9.tgz /opt/opt-packages/bowtie2-2.2.9/;

# Create a generic RPM for Bowtie2
fpm -f -s tar -p ./ -t rpm -n bowtie2 -v 2.2.9 --rpm-os linux bowtie2-2.2.9.tgz;

# Remove the installed python
rm -rf /opt/opt-packages/bowtie2-2.2.9/;

# Remove the Tarball
rm -rf bowtie2-2.2.9.tgz;
