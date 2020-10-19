#!/bin/bash

set -e -u

########################################

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

script/render.sh
git reset HEAD
git add resources
if ! git diff --cached --exit-code &>/dev/null; then
  git commit -m "Rendered deployment"
fi




# if [ ! -d "${CLUSTER_DIR}" ]; then
#   git clone "${CLUSTER_REPO}" "${CLUSTER_DIR}"
# fi

# cd "${CLUSTER_DIR}"

# if ! git log &>/dev/null; then
#   git commit --allow-empty -m "Initial empty commit"
# fi

# if ! git submodule status script &>/dev/null; then
#   git reset HEAD
#   git submodule add -b master "${SCRIPT_REPO}" script
#   git add .gitmodules script
#   git commit -m "Scripts submodule"
# fi

# [ -d values ] || cp -r script/init-values/ values
# [ -d custom ] || cp -r script/init-custom/ custom
# [ -f .gitignore ] || cp script/init/.gitignore ./
# git reset HEAD
# git add values custom .gitignore
# if ! git diff --cached --exit-code &>/dev/null; then
#   git commit -m "Initial content"
# fi
