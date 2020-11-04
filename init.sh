#!/bin/bash

set -e -u
. $(dirname $0)/function/function-render.sh

#init_helm_repo
init_kustomize_netrc

#TODO init jfrog, pokud budou vyplnene secrets pro nej, jinak ne; vcetne stazeni certifikatu
