#!/bin/bash

set -e
. $(dirname $0)/function/function-undeploy.sh

undeploy_argo
unprepare
unlabel_cluster_resources
