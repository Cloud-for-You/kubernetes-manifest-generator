#!/bin/bash

#for file in $(find .FINAL_RESOURCES/cluster-config/MachineConfigs/ -type f); do
#  oc create --save-config -f ${file} > /dev/null 2>&1 
#  echo $?
#done

oc apply -f .FINAL_RESOURCES/cluster-config/templates/RedHat/Cluster/MachineConfigs/ > /dev/null 2>&1

RED=`tput setaf 1`
GREEN=`tput setaf 2`
NC=`tput sgr0`        # No Color

ROOTDIR=$(pwd)

for function_file in `find $(dirname $0)/function/ -name *.func`; do
  . ${function_file}
done

deploy_argosys
deploy_argoapp
deploy_bootstrap
