#!/bin/bash

set -euo pipefail

RED=`tput setaf 1`
GREEN=`tput setaf 2`
NC=`tput sgr0`        # No Color

ROOTDIR=$(pwd)

echo """Minimum versions of binaries tested with:
yq:        4.34.1 (https://artifactory.csin.cz:443/artifactory/github-com-releases-download-cache/mikefarah/yq/releases/download/v4.34.1/yq_linux_amd64.tar.gz)
helm:      3.11.3 (https://artifactory.csin.cz:443/artifactory/get-helm-sh-cache/helm-v3.11.3-linux-amd64.tar.gz)
kustomize: 3.8.5  (https://artifactory.csin.cz:443/artifactory/github-com-releases-download-cache/kubernetes-sigs/kustomize/releases/download/kustomize/v3.8.5/kustomize_v3.8.5_linux_amd64.tar.gz)
"""

helm repo update

for function_file in `find $(dirname $0)/function/ -name *.func`; do
  . ${function_file}
done
clean
[ -d ${ROOTDIR}/.FINAL_RESOURCES ] || mkdir -p ${ROOTDIR}/.FINAL_RESOURCES
[ -d ${ROOTDIR}/.FINAL_RESOURCES/custom-resources ] || mkdir -p ${ROOTDIR}/.FINAL_RESOURCES/custom-resources
[ -d ${ROOTDIR}/.FINAL_RESOURCES/bootstrap ] || mkdir -p ${ROOTDIR}/.FINAL_RESOURCES/bootstrap

getComponents
renderBootstrap

## Provedeme GIT commit
#while true; do
#  read -p "${GREEN}Commit .FINAL_RESOURCES changes?${NC} [y/n] " yn
#  case $yn in
#    [Yy]* )
#      prepareVersion
#      break
#      ;;
#    [Nn]* )
#      echo "Commit nebyl proveden"
#      exit 0
#      ;;
#    * )
#      echo "${RED}Please answer yes or no.${NC}"
#      ;;
#  esac
#done

## Provedeme release do GITu
#while true; do
#  read -p "${GREEN}Release .FINAL_RESOURCES to cluster?${NC} [y/n] " yn
#  case $yn in
#    [Yy]* )
#      releaseVersion
#      break
#      ;;
#    [Nn]* )
#      echo "Verze nebude nasazena na cluster"
#      exit 0
#      ;;
#    * )
#      echo "${RED}Please answer yes or no.${NC}"
#      ;;
#  esac
#done
