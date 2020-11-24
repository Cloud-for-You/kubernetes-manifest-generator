#!/bin/bash

RED=`tput setaf 1`
GREEN=`tput setaf 2`
NC=`tput sgr0`        # No Color

ROOTDIR=$(pwd)

helm repo update

for function_file in `find $(dirname $0)/function/ -name *.func`; do
  . ${function_file}
done

[ -d ${ROOTDIR}/resources ] || mkdir -p ${ROOTDIR}/resources

clean
getComponents

#getComponentInfo cluster-config 0.1.0 kustomize

