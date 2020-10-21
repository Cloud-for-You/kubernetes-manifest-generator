#!/bin/bash

set -e -u
. $(dirname $0)/function/function-undeploy.sh

undeploy_bootstrap
