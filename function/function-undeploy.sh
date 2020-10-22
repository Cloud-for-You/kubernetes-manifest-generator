. $(dirname $0)/function/function-common.sh

# unprepare() {
#   echo '# Undeploy Image Mirror configuration'
#   echo oc delete -f "${ROOTDIR}/resources/cluster-config/default_machineconfiguration.openshift.io_v1_machineconfig_99-csas-mirror-registry.yaml"
# }

undeploy_bootstrap() {
cat <<EOF
oc delete -n csas-argocd-sys Application.argoproj.io/bootstrap
EOF
}

undeploy_content() {
  for app in $(oc get -n csas-argocd-sys Application.argoproj.io -o custom-columns='NAME:.metadata.name' --no-headers | grep -v -e argocd-sys -e bootstrap); do
cat <<EOF
oc patch -n csas-argocd-sys Application.argoproj.io ${app} -p '{"metadata": {"finalizers": ["resources-finalizer.argocd.argoproj.io"]}}' --type merge
oc delete -n csas-argocd-sys Application.argoproj.io ${app}
EOF
  done
cat <<EOF
oc delete -n csas-argocd-sys Application.argoproj.io argocd-sys
EOF
}

undeploy_argo() {
cat <<EOF
oc delete -f "${ROOTDIR}/resources/argocd-deployment-sys"
EOF
}

# unlabel_cluster_resources() {
#   for file in $(find ${ROOTDIR}/${FINALDIR}/cluster-config/ -type f); do
#     echo "Unlabel: ${file}"
#     echo oc label -f "${file}" argocd.argoproj.io/instance-sys-
#   done
#   for file in $(find ${ROOTDIR}/${FINALDIR}/cluster-config/ -type f); do
#     echo "Unannotate: ${file}"
#     echo oc annotate -f "${file}" argocd.argoproj.io/sync-options-
#   done
# }
