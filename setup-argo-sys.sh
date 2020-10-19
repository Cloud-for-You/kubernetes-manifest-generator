#!/bin/bash

set -e
. $(dirname $0)/function/function-deploy.sh

setup_argo_admin_password sys
setup_argo_dex_secret sys
setup_argo_repo_git_secret sys
#TODO helm
