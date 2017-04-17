#!/bin/bash
echo "Enter Pgdx Server: ";
read varname;
echo "Installing Plasma Package on: $varname";

ssh -i /Users/astangl/vappio_00 root@$varname "yum clean metadata && yum --enablerepo=*devel* clean metadata && yum -y --enablerepo=*devel* install pipeline-plasma41.x86_64;"
