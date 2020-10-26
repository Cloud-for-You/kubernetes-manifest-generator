#!/bin/bash

set -e -u

export SECRETS_FILE=$1

################################################################################################################################################################
##### Inicializační skript ArgoCD deploymentu clusteru - STAGE 2
########################################
##### Skript má tyto vstupy:
#####   Pracovní adresář: spouští se z top-level pracovního adresáře GIT repozitáře daného clusteru ocp-${CLUSTER_NAME}-system
#####                       naklonovaného z GIT repozitáře: ssh://git@sdf.csin.cz:2222/OCP4/ocp-${CLUSTER_NAME}-system.git
#####                       ve tvaru script/stage2.sh
#####                     - tento adresář je výstupem STAGE 1
#####   Povinné parametry:
#####   - soubor se secrets - ocp-${CLUSTER_NAME}-secrets.yaml
#####                           jedná se o sobor vytvořený ve STAGE 1 ve stejném adresáři, jako klon GIT repozitáře
########################################
##### Skript provádí následující operace (ve větvi install):
#####   1. připraví GIT branch "install"
#####   2. commitne upravené values / versions / custom
#####   3. zinicializuje Helm repo proti Artifactory, připraví netrc soubor pro kustomize
#####   4. vyrenderuje finální manifesty pro ArgoCD na základě vyplněných values, versions a secrets
#####   5. commitne vyrenderované manifesty
##### Skript je znovuspustitelný
################################################################################################################################################################

CLUSTER_DIR="$(pwd)"
ARGO_BRANCH="master"
INSTALL_BRANCH="install"

if [ ! $(git merge-base --is-ancestor "${ARGO_BRANCH}" "${INSTALL_BRANCH}") ]; then
  git checkout "${ARGO_BRANCH}"
  git branch -D "${INSTALL_BRANCH}" &>/dev/null || true
  git checkout -b "${INSTALL_BRANCH}"
fi

git checkout "${INSTALL_BRANCH}"

git reset HEAD
git add values custom
if ! git diff --cached --exit-code &>/dev/null; then
  git commit -m "Cluster configuration"
fi

script/init.sh
script/render.sh
git reset HEAD
git add resources
if ! git diff --cached --exit-code &>/dev/null; then
  git commit -m "Rendered deployment"
fi
