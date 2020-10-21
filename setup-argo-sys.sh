#!/bin/bash

set -e -u
. $(dirname $0)/function/function-deploy.sh

export SECRETS_FILE

setup_argo_admin_password sys
setup_argo_dex_secret sys
setup_argo_repo_git_secret sys
