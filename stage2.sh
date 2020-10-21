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
##### Skript provádí následující operace:
#####   1. updatuje GIT submodul "script" s inicializačními skripty
#####   2. zinicializuje Help repo proti Artifactory
#####   3. vyrenderuje finální manifesty pro ArgoCD na základě vyplněných values, versions a secrets
#####   4. provede "git push"
##### Po každém kroku následuje GIT commit
##### Skript je znovuspustitelný
################################################################################################################################################################

CLUSTER_DIR="$(pwd)"

git reset HEAD
git submodule update --remote script/
git add script
if ! git diff --cached --exit-code &>/dev/null; then
  git commit -m "Updated scripts submodule"
fi

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

git push
