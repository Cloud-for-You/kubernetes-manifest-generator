#!/bin/bash

set -e
. $(dirname $0)/function/function-deploy.sh

label_cluster_resources
deploy_argo
wait_argo
