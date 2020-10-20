#!/bin/bash

set -e -u
. $(dirname $0)/function/function-render.sh

#TODO
if [ -d ".local" ]; then
  RENDER_LOCAL=1
  render_argocd_sys
  render_argocd_app
  render_sealed_secrets
  render_bootstrap
  render_cluster_config
  render_project_operator
  render_application_operator
  render_custom_resources
else
  prepare_local_render
fi
