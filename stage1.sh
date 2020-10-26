#!/bin/bash

set -e -u

CLUSTER_NAME=$1

################################################################################################################################################################
##### Inicializační skript ArgoCD deploymentu clusteru - STAGE 1
########################################
##### Skript má tyto vstupy:
#####   Povinné parametry:
#####   - jméno clusteru - použije se v adrese GIT repozitáře: ssh://git@sdf.csin.cz:2222/OCP4/ocp-${CLUSTER_NAME}-system.git
#####                      a ve jménu vytvořeného lokálního adresáře
########################################
##### Skript má tyto výstupy:
#####   Adresář: ocp-${CLUSTER_NAME}-system (jako podadresář v adresáři, ze kterého je skript spuštěn) - obsahuje lokální klon GIT repozitáře pro daný cluster
#####   Soubor:  ocp-${CLUSTER_NAME}-secrets.yaml (v adresáři, ze kterého je skript spuštěn) - obsahuje šablonu pro secrets daného clusteru
########################################
##### Skript provádí následující operace:
#####   1. naklonuje GIT repozitář daného clusteru z Bitbucket serveru
#####   2. naklonuje GIT repozitář s inicializačními skripty jako GIT submodul "script", případně jej updatuje
#####   3. připraví iniciální obsah v repozitáři a commitne
#####   4. připraví GIT branch "install"
#####   5. připraví soubor secrets
##### Skript je znovuspustitelný
################################################################################################################################################################

CLUSTER_DIR="ocp-${CLUSTER_NAME}-system"
SECRETS_FILE="ocp-${CLUSTER_NAME}-secrets.yaml"
CLUSTER_REPO="ssh://git@sdf.csin.cz:2222/OCP4/${CLUSTER_DIR}.git"
SCRIPT_REPO="../init-scripts.git"
ARGO_BRANCH="master"
INSTALL_BRANCH="install"

if [ ! -d "${CLUSTER_DIR}" ]; then
  git clone "${CLUSTER_REPO}" "${CLUSTER_DIR}" --recurse-submodules
fi

pushd "${CLUSTER_DIR}"

if ! git log &>/dev/null; then
  git commit --allow-empty -m "Initial empty commit"
fi

git checkout "${ARGO_BRANCH}"

if ! git submodule status script &>/dev/null; then
  git reset HEAD
  git submodule add -b master "${SCRIPT_REPO}" script
  git add .gitmodules script
  git commit -m "Scripts submodule"
else
  git reset HEAD
  git submodule update --remote script/
  git add script
  if ! git diff --cached --exit-code &>/dev/null; then
    git commit -m "Updated scripts submodule"
  fi
fi

[ -d values ] || cp -r script/init-values/ values
[ -d custom ] || cp -r script/init-custom/ custom
[ -f .gitignore ] || cp script/init/.gitignore ./
git reset HEAD
git add values custom .gitignore
if ! git diff --cached --exit-code &>/dev/null; then
  git commit -m "Initial content"
fi

if [ ! $(git merge-base --is-ancestor "${ARGO_BRANCH}" "${INSTALL_BRANCH}") ]; then
  git branch -D "${INSTALL_BRANCH}" &>/dev/null || true
  git checkout -b "${INSTALL_BRANCH}"
fi

git checkout "${INSTALL_BRANCH}"

popd

[ -f "${SECRETS_FILE}" ] || cp "${CLUSTER_DIR}/script/init-secrets/secrets.yaml" "${SECRETS_FILE}"
