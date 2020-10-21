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

git push
