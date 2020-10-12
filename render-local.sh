#!/bin/bash

set -e
. $(dirname $0)/function/function-render.sh

if [ -d ".local" ]; then
  RENDER_LOCAL=1
  render_argocd_sys
  render_argocd_app
  render_bootstrap
  render_project_operator
  render_application_operator
else
  prepare_local_render
fi
