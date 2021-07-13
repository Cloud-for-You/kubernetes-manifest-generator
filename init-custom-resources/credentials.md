SealedSecret vytvorit takto:
```
export SEALED_SECRETS_CONTROLLER_NAMESPACE=csas-sealed-secrets
CRED="<credential v plain textu"
SECRET_NAME="<jmeno secretu>"
NAMESPACE="<jmeno namespace>"
oc create secret generic "${SECRET_NAME}" -n "${NAMESPACE}" --from-file=credential=<(echo -n ${CRED}) -o json --dry-run=client | kubeseal -o yaml
```

Samostatnou hodnotu vytvorit takto:
```
oc create secret generic "${SECRET_NAME}" -n "${NAMESPACE}" --from-file=credential=<(echo -n ${CRED}) -o json --dry-run=client | kubeseal -o yaml | yq r - spec.encryptedData.credential
```
a nasledne vlozit do SealedSecret manifestu do spec.encryptedData
