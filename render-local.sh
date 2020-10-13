#!/bin/bash

set -e
. $(dirname $0)/function/function-render.sh

#TODO
if [ -d ".local" ]; then
  RENDER_LOCAL=1
  render_argocd_sys
  render_argocd_app
  render_bootstrap
  render_cluster_config
  unset RENDER_LOCAL
  render_project_operator
  render_application_operator
  render_custom_resources
else
  prepare_local_render
fi
