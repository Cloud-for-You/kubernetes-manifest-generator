#!/bin/bash

usage() { echo "Usage: $0 -n <CLUSTER NAME> -v <OPENSHIFT VERSION>" 1>&2; exit 1; }

RED=`tput setaf 1`
GREEN=`tput setaf 2`
NC=`tput sgr0`        # No Color

while getopts ":n:v:" opts; do
  case "${opts}" in
    n)
      CLUSTER_NAME=${OPTARG}
      ;;
    v)
      OPENSHIFT_VERSION=${OPTARG}
      ;;
    *)
      usage
      ;;
  esac
done
shift $((OPTIND-1))

if [ -z "${CLUSTER_NAME}" ] || [ -z "${OPENSHIFT_VERSION}" ]; then
    usage
fi

CLUSTER_DIR="ocp-${CLUSTER_NAME}-system"
SECRETS_FILE=".secrets/ocp-${CLUSTER_NAME}-secrets.yaml"
CLUSTER_REPO="ssh://git@sdf.csin.cz:2222/OCP4/${CLUSTER_DIR}.git"
SCRIPT_REPO="ssh://git@sdf.csin.cz:2222/OCP4/init-scripts.git"

# Naklonujeme repository
if [ ! -d "${CLUSTER_DIR}" ]; then
  git clone "${CLUSTER_REPO}" "${CLUSTER_DIR}" --recurse-submodules
fi

pushd "${CLUSTER_DIR}"

if ! git log &>/dev/null; then
    git commit --allow-empty -m "Initial empty commit"
fi

# Do repository pridame submodul se scriptama, ktere pouzivame v dalsich krosich a v budoucnu i pro praci
if ! git submodule status script &>/dev/null; then
  git reset HEAD
  git submodule add -b master "${SCRIPT_REPO}" script
  git add .gitmodules script
  git commit -m "Add submodule scripts"
else
  git reset HEAD
  git submodule update --remote script/
  git add script
  if ! git diff --cached --exit-code &>/dev/null; then
    git commit -m "Updated submodule scripts"
  fi
fi

if [ ! -d values ]; then
  mkdir values
  find ./script/init-values/ -type f -name "*.tmpl" -exec cp {} values/ \;
  rename -v '.tmpl' '' values/*.tmpl
fi
[ -d custom ] || cp -r script/init-custom/ custom
[ -d .secrets ] || mkdir .secrets
[ -f .gitignore ] || cp script/init/.gitignore ./
[ -d tmp ] || mkdir tmp

git reset HEAD
git add values custom .gitignore

if ! git diff --cached --exit-code &>/dev/null; then
  git commit -m "Initial content"
fi

[ -f "${SECRETS_FILE}" ] || cp "script/init-secrets/secrets.yaml" "${SECRETS_FILE}"

helm repo update
helm template csas-helmcharts/install-config --values ../values_init-cluster.yaml --version ${OPENSHIFT_VERSION} --output-dir install-config
if [ $? -ne 0 ]; then
  echo "${RED}"
  echo "Neexistujici verze helmchartu pro odpovidajici verzi OpenShiftu"
  echo "Podporovane verze zjistite prikazem"
  echo "  ${GREEN}$ helm search repo install-config -l${RED}"
  echo "${NC}"
  popd
  rm -rf ${CLUSTER_DIR}
  exit 1
fi
mv install-config/install-config/templates/install-config.yaml install-config/
rm -rf install-config/install-config/ 
yq delete -i values_init-cluster.yaml 'platform'
yq delete -i values_init-cluster.yaml 'azure'
yq delete -i values_init-cluster.yaml 'proxy'
yq delete -i values_init-cluster.yaml 'pullSecret'
yq delete -i values_init-cluster.yaml 'sshKey'
mv ../values_init-cluster.yaml values/global.yaml

git reset HEAD
git add install-config/ values/cluster-config.yaml 
if ! git diff --cached --exit-code &>/dev/null; then
  git commit -m "Add install-config.yaml"
fi

popd

echo "${RED}"
echo "1. Spustte instalaci clusteru."
echo "  ${GREEN}$ openshift-install create cluster --dir ${CLUSTER_DIR}/install-config/ --log-level debug${RED}"
echo ""
echo "Ostatni spusteni scriptu se musi provadet vzdy z adresare ${CLUSTER_DIR}"
echo "Upravte soubory v adresari  ${CLUSTER_DIR}/values a ${CLUSTER_DIR}/.secrets"
echo "Adresar  ${CLUSTER_DIR}/.secrets se neuklada do GITu a je vhodne jej i zalohovat na bezpecne misto"
echo ""
echo "Vygenerujte sablony pro cluster spustenim"
echo "  ${GREEN}$ bash scripts/stage2.sh${RED}"
echo "${NC}"
