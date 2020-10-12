. $(dirname $0)/function/function-common.sh

unprepare() {
	echo '# Undeploy Image Mirror configuration'
  echo oc delete -f "${ROOTDIR}/resources/cluster-config/default_machineconfiguration.openshift.io_v1_machineconfig_99-csas-mirror-registry.yaml"
}

undeploy_argo() {
	echo '# Undeploy ArgoCD SYS cluster roles'
	echo oc delete -f "${ROOTDIR}/resources/argocd-deployment-sys/rbac.authorization.k8s.io_v1_clusterrole_argocd-sys-application-controller.yaml"
	echo oc delete -f "${ROOTDIR}/resources/argocd-deployment-sys/rbac.authorization.k8s.io_v1_clusterrole_argocd-sys-server.yaml"
	echo oc delete -f "${ROOTDIR}/resources/argocd-deployment-sys/rbac.authorization.k8s.io_v1_clusterrolebinding_argocd-sys-application-controller.yaml"
	echo oc delete -f "${ROOTDIR}/resources/argocd-deployment-sys/rbac.authorization.k8s.io_v1_clusterrolebinding_argocd-sys-server.yaml"

	echo '# Undeploy ArgoCD SYS namespace'
	echo oc delete -f "${ROOTDIR}/resources/argocd-deployment-sys/~g_v1_namespace_csas-argocd-sys.yaml"

	echo '# Undeploy ArgoCD CRD'
	echo oc delete -f "${ROOTDIR}/resources/argocd-deployment-sys/apiextensions.k8s.io_v1beta1_customresourcedefinition_applications.argoproj.io.yaml"
	echo oc delete -f "${ROOTDIR}/resources/argocd-deployment-sys/apiextensions.k8s.io_v1beta1_customresourcedefinition_appprojects.argoproj.io.yaml"
}

unlabel_cluster_resources() {
  for file in $(find ${ROOTDIR}/${FINALDIR}/cluster-config/ -type f); do
    echo "Unlabel: ${file}"
    echo oc label -f "${file}" argocd.argoproj.io/instance-sys-
  done
  for file in $(find ${ROOTDIR}/${FINALDIR}/cluster-config/ -type f); do
    echo "Unannotate: ${file}"
    echo oc annotate -f "${file}" argocd.argoproj.io/sync-options-
  done
}
