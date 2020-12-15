#!/bin/bash

RED=`tput setaf 1`
GREEN=`tput setaf 2`
NC=`tput sgr0`        # No Color

ROOTDIR=$(pwd)

helm repo update

for function_file in `find $(dirname $0)/function/ -name *.func`; do
  . ${function_file}
done
clean
[ -d ${ROOTDIR}/resources ] || mkdir -p ${ROOTDIR}/resources
[ -d ${ROOTDIR}/resources/_custom ] || mkdir -p ${ROOTDIR}/resources/_custom
[ -d ${ROOTDIR}/resources/bootstrap ] || mkdir -p ${ROOTDIR}/resources/bootstrap

getComponents

git reset HEAD
git add values/ resources/
git commit -a -m "ADD/Update values and resources from new version"
#git push -u origin master

# Provedeme release do GITu
while true; do
  read -p "${GREEN}Release resources to cluster?${NC} [y/n] " yn
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
