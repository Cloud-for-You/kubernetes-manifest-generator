#!/bin/bash

set -e -u
. $(dirname $0)/function/function-render.sh

#TODO
if [ -d ".local" ]; then
  RENDER_LOCAL=1
  [ -d .local/argocd-deployment-sys ] && render_argocd_sys
  [ -d .local/argocd-deployment-app ] && render_argocd_app
  [ -d .local/bootstrap ] && render_bootstrap
  # render_cluster_config
  [ -d .local/csas-project-operator ] && render_project_operator
  [ -d .local/csas-application-operator ] && render_application_operator
  # render_custom_resources
else
  prepare_local_render
fi
