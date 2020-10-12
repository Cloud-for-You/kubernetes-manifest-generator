#!/bin/bash

set -e
. $(dirname $0)/function/function-deploy.sh

setup_argo_admin_password app "$@"
setup_argo_dex_secret app
