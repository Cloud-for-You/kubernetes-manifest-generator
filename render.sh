#!/bin/bash

set -e -u
. $(dirname $0)/function/function-render.sh

update_helm_repo
render_argocd_sys
render_argocd_app
render_sealed_secrets
render_bootstrap
render_project_operator
render_application_operator
render_custom_resources
#render_monitoring_stack
