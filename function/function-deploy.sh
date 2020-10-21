. $(dirname $0)/function/function-common.sh

prepare() {
	# Deploy Image Mirror configuration
  oc create -f "${ROOTDIR}/resources/cluster-config/default_machineconfiguration.openshift.io_v1_machineconfig_99-csas-mirror-registry.yaml"
}

deploy_argo() {
	# Create ArgoCD CRD
  for FILE in $(find resources/argocd-deployment-sys -type f | grep "apiextensions.k8s.io_v1beta1_customresourcedefinition_"); do
    cat "${FILE}"
    echo "---"
  done | oc create --save-config -n csas-argocd-sys -f-

	# Create ArgoCD SYS namespace
  for FILE in $(find resources/argocd-deployment-sys -type f | grep "~g_v1_namespace_"); do
    cat "${FILE}"
    echo "---"
  done | oc create --save-config -n csas-argocd-sys -f-

	# Deploy ArgoCD SYS
  for FILE in $(find resources/argocd-deployment-sys -type f | grep -v -e "~g_v1_namespace_" -e "apiextensions.k8s.io_v1beta1_customresourcedefinition_"); do
    cat "${FILE}"
    echo "---"
  done | oc create --save-config -n csas-argocd-sys -f-
}

wait_argo() {
  for deployment in argocd-{server,application-controller,repo-server,dex-server,redis}; do
    oc rollout status -n csas-argocd-sys deployment/${deployment} -w
  done
}

deploy_bootstrap() {
	# Bootstrap
	oc create --save-config -n csas-argocd-sys -R -f "${ROOTDIR}/resources/bootstrap/"
}

setup_argo_admin_password() {
  INSTANCE=$1
  METHOD=${2:-}

  PASSWD=$(yq read -X ${SECRETS_FILE} "argocd-deployment-${INSTANCE}.admin_password")

  if [ -z "${METHOD}" ]; then
    which python3 &>/dev/null && python3 -c "import crypt; crypt.METHOD_BLOWFISH" &>/dev/null && METHOD=python3
    which htpasswd &>/dev/null && METHOD=htpasswd
    which mkpasswd &>/dev/null && METHOD=mkpasswd
  fi

  #TODO Upravit tak, ze pokud nenalezne ani jeden z nastroju, tak fail
  PWDSTR=''
  case "${METHOD}" in
    # mkpasswd) PWDSTR=`mkpasswd -m bcrypt-a "${PASSWD}"`;;
    # htpasswd) PWDSTR=`htpasswd -bnBC 10 "" "${PASSWD}" | tr -d ':\n'`;;
    # python3)  PWDSTR=`PASSWD="${PASSWD}" python3 -c "import crypt; import os; print(crypt.crypt(os.environ['PASSWD'], crypt.METHOD_BLOWFISH))"`;;
    *)        PWDSTR="${PASSWD}"
  esac

  MTIMESTR=$(TZ=GMT date +'%Y-%m-%dT%H:%M:%SZ')

  if [ -z "${PWDSTR}" ]; then
    echo "Can't setup empty argocd admin password (method ${METHOD})" && return 1
  fi

  if [ -z "${MTIMESTR}" ]; then
    echo "Can't setup empty argocd admin password mtime" && return 1
  fi

  oc patch secret/argocd-secret -n "csas-argocd-${INSTANCE}" -p="{ \"stringData\": { \"admin.password\": \"${PWDSTR}\", \"admin.passwordMtime\": \"${MTIMESTR}\" } }"
}

setup_argo_dex_secret() {
  INSTANCE=$1
  DEXSECRET=$(oc -n "csas-argocd-${INSTANCE}" serviceaccounts get-token argocd-dex-server)

  if [ -z "${DEXSECRET}" ]; then
    echo "Can't setup empty dex secret" && return 1
  fi

  oc patch secret/argocd-secret -n "csas-argocd-${INSTANCE}" -p="{ \"stringData\": { \"dex.openshift.secret\": \"${DEXSECRET}\" } }"
}

setup_argo_repo_git_secret() {
  INSTANCE=$1

  GIT_USER=$(yq read -X ${SECRETS_FILE} "argocd-deployment-${INSTANCE}.git.user")
  GIT_PASS=$(yq read -X ${SECRETS_FILE} "argocd-deployment-${INSTANCE}.git.password")
  GIT_SSHK=$(yq read -X ${SECRETS_FILE} "argocd-deployment-${INSTANCE}.git.sshkey")

  if [ -n "${GIT_SSHK}" ]; then
    oc set data -n "csas-argocd-${INSTANCE}" secret/repo-cs-argo --from-literal=git-ssh="${GIT_SSHK}"
  else
    oc set data -n "csas-argocd-${INSTANCE}" secret/repo-cs-argo git-ssh-
  fi

  if [ -n "${GIT_USER}" ]; then
    oc set data -n "csas-argocd-${INSTANCE}" secret/repo-cs-argo --from-literal=git-user="${GIT_USER}"
  else
    oc set data -n "csas-argocd-${INSTANCE}" secret/repo-cs-argo git-user-
  fi

  if [ -n "${GIT_PASS}" ]; then
    oc set data -n "csas-argocd-${INSTANCE}" secret/repo-cs-argo --from-literal=git-pass="${GIT_PASS}"
  else
    oc set data -n "csas-argocd-${INSTANCE}" secret/repo-cs-argo git-pass-
  fi
}

# deploy_secrets() {
#   INSTANCE=$1

#   GIT_USER=$(yq read ${SECRETS_FILE} "argocd-deployment-${INSTANCE}.git.user")
#   GIT_PASS=$(yq read ${SECRETS_FILE} "argocd-deployment-${INSTANCE}.git.password")
#   GIT_SSHK=$(yq read ${SECRETS_FILE} "argocd-deployment-${INSTANCE}.git.sshkey")

#   HELM_USER=$(yq read ${SECRETS_FILE} "argocd-deployment-${INSTANCE}.helm.user")
#   HELM_PASS=$(yq read ${SECRETS_FILE} "argocd-deployment-${INSTANCE}.helm.password")

#   [ -n "${GIT_USER}" ] && oc patch secret/repo-cs-argo -n "csas-argocd-${INSTANCE}" -p="{ \"stringData\": { \"git-user\": \"${GIT_USER}\" } }"
#   [ -n "${GIT_PASS}" ] && oc patch secret/repo-cs-argo -n "csas-argocd-${INSTANCE}" -p="{ \"stringData\": { \"git-pass\": \"${GIT_PASS}\"} }"
#   [ -n "${GIT_SSHK}" ] && oc patch secret/repo-cs-argo -n "csas-argocd-${INSTANCE}" -p="{ \"stringData\": { \"git-ssh\": \"${GIT_SSHK}\" } }"

#   [ -n "${HELM_USER}" ] && oc patch secret/repo-cs-argo -n "csas-argocd-${INSTANCE}" -p="{ \"stringData\": { \"helm-user\": \"${HELM_USER}\" } }"
#   [ -n "${HELM_PASS}" ] && oc patch secret/repo-cs-argo -n "csas-argocd-${INSTANCE}" -p="{ \"stringData\": { \"helm-pass\": \"${HELM_PASS}\" } }"
# }

label_cluster_resources() {
  for file in $(find ${ROOTDIR}/${FINALDIR}/cluster-config/ -type f); do
    echo "Label: ${file}"
    oc label -f "${file}" argocd.argoproj.io/instance-sys=cluster-config
  done
}
