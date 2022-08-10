#!/bin/bash

set -eu

RED=`tput setaf 1`
GREEN=`tput setaf 2`
NC=`tput sgr0`        # No Color

ROOTDIR=$(pwd)

helm repo update

for function_file in `find $(dirname $0)/function/ -name *.func`; do
  . ${function_file}
done
clean
[ -d ${ROOTDIR}/.FINAL_RESOURCES ] || mkdir -p ${ROOTDIR}/.FINAL_RESOURCES
[ -d ${ROOTDIR}/.FINAL_RESOURCES/custom-.FINAL_RESOURCES ] || mkdir -p ${ROOTDIR}/.FINAL_RESOURCES/custom-.FINAL_RESOURCES
[ -d ${ROOTDIR}/.FINAL_RESOURCES/bootstrap ] || mkdir -p ${ROOTDIR}/.FINAL_RESOURCES/bootstrap

getComponents
renderBootstrap

# Provedeme GIT commit
while true; do
  read -p "${GREEN}Commit .FINAL_RESOURCES changes?${NC} [y/n] " yn
  case $yn in
    [Yy]* )
      prepareVersion
      break
      ;;
    [Nn]* )
      echo "Commit nebyl proveden"
      exit 0
      ;;
    * )
      echo "${RED}Please answer yes or no.${NC}"
      ;;
  esac
done

# Provedeme release do GITu
while true; do
  read -p "${GREEN}Release .FINAL_RESOURCES to cluster?${NC} [y/n] " yn
  case $yn in
    [Yy]* )
      releaseVersion
      break
      ;;
    [Nn]* )
      echo "Verze nebude nasazena na cluster"
      exit 0
      ;;
    * )
      echo "${RED}Please answer yes or no.${NC}"
      ;;
  esac
done
