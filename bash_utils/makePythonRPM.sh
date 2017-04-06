#####################
# A Simple Script to package Python-2.7.12 into an RPM
# This script must be run on pgdx-pr5 or any pgdx server where fpm is installed
# Author: AJ Stangl
# Date: 2/28/17
# Project: Cerebro
#####################


# Move to mount and make the temp directory
cd /mnt/user_data;
mkdir -p tempDir;
cd tempDir;

# Make the directory where you want to install python for the target machine
mkdir -p /opt/opt-packages/Python-2.7.12;

# Download the version of Python we need
wget https://www.python.org/ftp/python/2.7.12/Python-2.7.12.tgz;

# Un Tar the download
tar xzf Python-2.7.12.tgz;

# Move into the dir
cd Python-2.7.12;

# Make Side Install to prevent conflict with Existing Python
./configure --prefix=/opt/opt-packages/Python-2.7.12;

# Make the alt Install
make altinstall;

# Go Up One level
cd ../;

# Clean up source
rm -f Python-2.7.12.tgz;
rm -f Python-2.7.12;

# Get the PIP Dependancy
wget --no-check-certificate https://bootstrap.pypa.io/get-pip.py;

# Install the Dependancies for Cerebro
/opt/opt-packages/Python-2.7.12/bin/python2.7 get-pip.py
/opt/opt-packages/Python-2.7.12/bin/pip2.7 install scikit-learn;
/opt/opt-packages/Python-2.7.12/bin/pip2.7 install numpy;
/opt/opt-packages/Python-2.7.12/bin/pip2.7 install scipy;

# We need to alter the permissions of the RPM
chmod -R 777 /opt/opt-packages/Python-2.7.12/;

# Tar the Installation
tar cvfz python-2.7.12.tgz /opt/opt-packages/Python-2.7.12/;

# Create a generic RPM for Pyhthon
fpm -f -s tar -p ./ -t rpm -n python27 -v 2.7.12 --rpm-os linux python-2.7.12.tgz;

# Remove the installed python
rm -rf /opt/opt-packages/Python-2.7.12/;
rm -rf /mnt/user_data/tempDir/get-pip.py;
rm -rf /mnt/user_data/tempDir/Python-2.7.12;
rm -rf /mnt/user_data/tempDir/python-2.7.12.tgz;
