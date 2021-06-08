#!/bin/bash

usage() {
 echo "Usage: $0 -n <NAMESPACE>" 1>&2; exit 1;
}

while getopts ":n:" opts; do
  case "${opts}" in
    n)
      NAMESPACE=${OPTARG}
      ;;
    *)
      usage
      ;;
  esac
done
shift $((OPTIND-1))

echo -n "Enter your password for 'admin' user [ENTER]: "
read PASSWORD

if [ -z "${NAMESPACE}" ]; then
    usage
fi

if [ -z "${PASSWORD}" ]; then
  echo "Password is empty"
  exit
fi

MTIMESTR=$(TZ=GMT date +'%Y-%m-%dT%H:%M:%SZ')
PWDSTR=$(htpasswd -bnBC 10 "" $PASSWORD | tr -d ':\n')

oc patch secret/argocd-secret -n ${NAMESPACE} -p="{ \"stringData\": { \"admin.password\": \"${PWDSTR}\", \"admin.passwordMtime\": \"${MTIMESTR}\" } }"
