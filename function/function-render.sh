. $(dirname $0)/function/function-common.sh

HELM_ARTIFACTORY='ocp-artifactory'

init_helm_repo() {
  ARTIF_URL=$(yq read -X ${ROOTDIR}/values/values.yaml 'argocd-deployment-sys.argocd-config.helm.url')
  ARTIF_USER=$(yq read -X ${SECRETS_FILE} 'argocd-deployment-sys.helm.user')
  ARTIF_PASSWORD=$(yq read -X ${SECRETS_FILE} 'argocd-deployment-sys.helm.password')

  CAOPTS=''
  CAFILE="$(readlink -f ~/.config/helm/${HELM_ARTIFACTORY}.crt)"
  if [ -f "${CAFILE}" ]; then
    CAOPTS="--ca-file ${CAFILE}"
  fi

  helm repo add ${CAOPTS} "${HELM_ARTIFACTORY}" "${ARTIF_URL}" --username "${ARTIF_USER}" --password "${ARTIF_PASSWORD}"
  #TODO vyresit, kdyz nebudu mit secrets, pripadne z cmdline jako read (a bude personalni ucet a nebudu brat ze secrets) - bude se spoustet z bastion
}

update_helm_repo() {
  init_helm_repo || true
  helm repo update
}

get_component_version() {
  COMP=$1
  VERSION=$(yq r "${ROOTDIR}/values/versions.yaml" "${COMP}")
  printf "%s" "${VERSION}"
}

prepare_local_render() {
  echo mkdir -p "${ROOTDIR}/.local"
  echo ln -s XXXXX/argocd-deployment-sys "${ROOTDIR}/.local/argocd-deployment-sys"
  echo ln -s XXXXX/argocd-deployment-app "${ROOTDIR}/.local/argocd-deployment-app"
  echo ln -s XXXXX/sealed-secrets "${ROOTDIR}/.local/sealed-secrets"
  echo ln -s XXXXX/bootstrap "${ROOTDIR}/.local/bootstrap"
  echo ln -s XXXXX/deploy/ "${ROOTDIR}/.local/csas-project-operator"
  echo ln -s XXXXX/deploy/ "${ROOTDIR}/.local/csas-application-operator"
  echo ln -s XXXXX/ "${ROOTDIR}/.local/cluster-config"
}

render_helm() {
  RENDER_NAME=$1
  RENDER_VERSION=$2

  RENDER_LOCAL=${RENDER_LOCAL:-""}

  rm -rf "${ROOTDIR}/${TEMPDIR}/${RENDER_NAME}"
  mkdir -p "${ROOTDIR}/${TEMPDIR}/${RENDER_NAME}"
  rm -rf "${ROOTDIR}/${FINALDIR}/${RENDER_NAME}"
  mkdir -p "${ROOTDIR}/${FINALDIR}/${RENDER_NAME}"

  if [ -z "${RENDER_LOCAL}" ]; then
    helm pull "${HELM_ARTIFACTORY}/${RENDER_NAME}" --version "${RENDER_VERSION}" --destination "${ROOTDIR}/${TEMPDIR}/"
    HELM_CHART="${ROOTDIR}/${TEMPDIR}/${RENDER_NAME}-${RENDER_VERSION}.tgz"
  else
    HELM_CHART="${ROOTDIR}/.local/${RENDER_NAME}"
    RENDER_VERSION=v0.0.0
  fi

  echo "Rendering ${RENDER_NAME} - ${RENDER_VERSION}"

  yq read -X "${ROOTDIR}/values/values.yaml" "${RENDER_NAME}" > "${ROOTDIR}/${TEMPDIR}/values_${RENDER_NAME}.yaml"
  helm lint "${HELM_CHART}" -f "${ROOTDIR}/${TEMPDIR}/values_${RENDER_NAME}.yaml" --strict --skip-headers --with-subcharts | grep -v "0 chart(s) failed" | grep -v "icon is recommended" | grep .
  helm template "${HELM_CHART}" -f "${ROOTDIR}/${TEMPDIR}/values_${RENDER_NAME}.yaml" --include-crds > "${ROOTDIR}/${TEMPDIR}/${RENDER_NAME}/${RENDER_NAME}.yaml"

  cat <<EOF > "${ROOTDIR}/${TEMPDIR}/${RENDER_NAME}/kustomization.yaml"
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ${RENDER_NAME}.yaml
EOF
  kustomize build "${ROOTDIR}/${TEMPDIR}/${RENDER_NAME}" -o "${ROOTDIR}/${FINALDIR}/${RENDER_NAME}"

  echo "Rendered ${RENDER_NAME} - ${RENDER_VERSION}"
}

render_custom() {
  RENDER_NAME=$1

  rm -rf "${ROOTDIR}/${FINALDIR}/custom-${RENDER_NAME}"

  echo "Rendering custom-${RENDER_NAME}"
  cp -r "custom/${RENDER_NAME}" "${ROOTDIR}/${FINALDIR}/custom-${RENDER_NAME}"
  echo "Rendered custom-${RENDER_NAME}"
}

render_argocd_sys() {
  VERSION=$(get_component_version ARGOCD_DEPLOYMENT)
  render_helm argocd-deployment-sys "${VERSION}"
}

render_argocd_app() {
  VERSION=$(get_component_version ARGOCD_DEPLOYMENT)
  render_helm argocd-deployment-app "${VERSION}"
}

render_sealed_secrets() {
  VERSION=$(get_component_version SEALED_SECRETS)
  render_helm sealed-secrets "${VERSION}"
}

render_bootstrap() {
  VERSION=$(get_component_version BOOTSTRAP)
  render_helm bootstrap "${VERSION}"
}

render_project_operator() {
  #TODO change to kustomize in new version of operator
  VERSION=$(get_component_version PROJECT_OPERATOR)
  render_helm csas-project-operator "${VERSION}"
  cat > "${ROOTDIR}/${FINALDIR}/csas-project-operator/namespace.yaml" <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: csas-project-operator
EOF
}

render_application_operator() {
  #TODO change to kustomize in new version of operator
  VERSION=$(get_component_version APPLICATION_OPERATOR)
  render_helm csas-application-operator "${VERSION}"
  cat > "${ROOTDIR}/${FINALDIR}/csas-application-operator/namespace.yaml" <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: csas-application-operator
EOF
}

render_custom_resources() {
  render_custom 'resources'
}

render_cluster_config() {
  #TODO resource files using find
  RENDER_NAME=cluster-config
  RENDER_VERSION=$(get_component_version CLUSTER_CONFIG)

  rm -rf "${ROOTDIR}/${TEMPDIR}/${RENDER_NAME}"
  mkdir -p "${ROOTDIR}/${TEMPDIR}/${RENDER_NAME}"
  rm -rf "${ROOTDIR}/${FINALDIR}/${RENDER_NAME}"
  mkdir -p "${ROOTDIR}/${FINALDIR}/${RENDER_NAME}"

  if [ -z "${RENDER_LOCAL}" ]; then
    helm pull "${HELM_ARTIFACTORY}/${RENDER_NAME}" --version "${RENDER_VERSION}" --destination "${ROOTDIR}/${TEMPDIR}/"
    HELM_CHART="${ROOTDIR}/${TEMPDIR}/${RENDER_NAME}-${RENDER_VERSION}.tgz"
  else
    HELM_CHART="${ROOTDIR}/.local/${RENDER_NAME}"
    RENDER_VERSION=v0.0.0
  fi

  echo "Rendering ${RENDER_NAME} - ${RENDER_VERSION}"

  yq read -X "${ROOTDIR}/values/values.yaml" "${RENDER_NAME}" > "${ROOTDIR}/${TEMPDIR}/values_${RENDER_NAME}.yaml"
  helm lint "${HELM_CHART}" -f "${ROOTDIR}/${TEMPDIR}/values_${RENDER_NAME}.yaml" --strict --skip-headers --with-subcharts | grep -v "0 chart(s) failed" | grep -v "icon is recommended" | grep .
  helm template "${HELM_CHART}" -f "${ROOTDIR}/${TEMPDIR}/values_${RENDER_NAME}.yaml" --output-dir "${ROOTDIR}/${TEMPDIR}/${RENDER_NAME}/"

  cat <<EOF > "${ROOTDIR}/${TEMPDIR}/${RENDER_NAME}/kustomization.yaml"
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - init-cluster/templates/cluster-config/99-chrony.yaml
  - init-cluster/templates/cluster-config/99-mirror-registry.yaml
EOF
  kustomize build "${ROOTDIR}/${TEMPDIR}/${RENDER_NAME}" -o "${ROOTDIR}/${FINALDIR}/${RENDER_NAME}"

  rm -rf "${ROOTDIR}/install"
  cp -r "${ROOTDIR}/${TEMPDIR}/${RENDER_NAME}/init-cluster/templates/install-config" "${ROOTDIR}/install"

  echo "Rendered ${RENDER_NAME} - ${RENDER_VERSION}"
}
