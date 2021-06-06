#!/bin/bash

FILENAME=$1

set -eu

RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
NC=`tput sgr0`        # No Color

NAMESPACE=$(yq read "${FILENAME}" "spec.template.metadata.namespace")
SECRET=$(yq read "${FILENAME}" "spec.template.metadata.name")

echo "${GREEN}Secret: ${SECRET} - Namespace: ${NAMESPACE}${NC}"

for cred in $(yq read "${FILENAME}" --printMode p "spec.encryptedData.*"); do
  val=$(yq read "${FILENAME}" "${cred}")
  if [ -z "${val}" ]; then
    while true; do
      read -s -p "${GREEN}Zadej credential pro ${cred##*.}${NC}: " val
      encrypted=$(oc create secret generic "${SECRET}" -n "${NAMESPACE}" --from-file=credential=<(echo -n ${val}) -o json --dry-run=client | kubeseal -o yaml | yq r - spec.encryptedData.credential)
      if [ -n "${encrypted}" ]; then
        yq write -i "${FILENAME}" "${cred}" "${encrypted}"
        echo "${GREEN}Credential uspesne nastaven${NC}"
        break
      else
        echo "${RED}Chyba, zadejte znovu${NC}"
      fi
    done
  else
    echo "${YELLOW}Heslo pro ${cred} je jiz vyplneno. Preskakuji.${NC}"
  fi
done
