#!/usr/bin/env bash
#Set the Virtual Enviroment
source /opt/rh/python27/enable
source /opt/venv/cerebro/bin/activate

# For whatever reason this needs to be imported
bash -c "PYTHONPATH=/opt/venv/cerebro/lib64/python2.7/site-packages/sklearn/externals"

data_file=$1
model_dir=$2

./mnt/user_data/cerebro/cerebro_scripts/cerebro_train.py $1 $2