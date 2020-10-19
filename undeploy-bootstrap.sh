#!/bin/bash

set -e -u
. $(dirname $0)/function/function-deploy.sh

#deploy_bootstrap



!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! TBD !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
oc delete Application -n csas-argocd-sys --all - ale jinak
