#!/bin/bash

set -e -u

CLUSTER_NAME=$1

########################################

CLUSTER_DIR="ocp-${CLUSTER_NAME}-system"
VALUES_FILE="ocp-${CLUSTER_NAME}-values.yaml"
CLUSTER_REPO="ssh://git@sdf.csin.cz:2222/OCP4/${CLUSTER_DIR}.git"
SCRIPT_REPO="../init-scripts.git"

if [ ! -d "${CLUSTER_DIR}" ]; then
  git clone "${CLUSTER_REPO}" "${CLUSTER_DIR}"
fi

pushd "${CLUSTER_DIR}"

if ! git log &>/dev/null; then
  git commit --allow-empty -m "Initial empty commit"
fi

if ! git submodule status script &>/dev/null; then
  git reset HEAD
  git submodule add -b master "${SCRIPT_REPO}" script
  git add .gitmodules script
  git commit -m "Scripts submodule"
fi

[ -d values ] || cp -r script/init-values/ values
[ -d custom ] || cp -r script/init-custom/ custom
[ -f .gitignore ] || cp script/init/.gitignore ./
git reset HEAD
git add values custom .gitignore
if ! git diff --cached --exit-code &>/dev/null; then
  git commit -m "Initial content"
fi

popd

[ -f "${VALUES_FILE}" ] || cp "${CLUSTER_DIR}/script/init-secrets/secrets.yaml" "${VALUES_FILE}"
