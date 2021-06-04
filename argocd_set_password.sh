#!/bin/bash

usage() {
 echo "Usage: $0 -n <NAMESPACE> -p <PASSWORD>" 1>&2; exit 1;
}

while getopts ":n:p:" opts; do
  case "${opts}" in
    n)
      NAMESPACE=${OPTARG}
      ;;
    p)
      PASSWORD=${OPTARG}
      ;;
    *)
      usage
      ;;
  esac
done
shift $((OPTIND-1))

if [ -z "${NAMESPACE}" ] || [ -z "${PASSWORD}" ]; then
    usage
fi

MTIMESTR=$(TZ=GMT date +'%Y-%m-%dT%H:%M:%SZ')
PWDSTR=$(htpasswd -bnBC 10 "" $PASSWORD | tr -d ':\n')

oc patch secret/argocd-secret -n ${NAMESPACE} -p="{ \"stringData\": { \"admin.password\": \"${PWDSTR}\", \"admin.passwordMtime\": \"${MTIMESTR}\" } }"
