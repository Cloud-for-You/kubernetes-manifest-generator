SealedSecret vytvorit takto (Jmeno secretu a namespace musi odpovidat):
```
export SEALED_SECRETS_CONTROLLER_NAMESPACE=csas-sealed-secrets
CRED="<credential v plain textu>"
SECRET_NAME="<jmeno secretu>"
NAMESPACE="<jmeno namespace>"
oc create secret generic "${SECRET_NAME}" -n "${NAMESPACE}" --from-file=credential=<(echo -n ${CRED}) -o json --dry-run=client | kubeseal -o yaml
```

Samostatnou hodnotu vytvorit takto:
```
oc create secret generic "${SECRET_NAME}" -n "${NAMESPACE}" --from-file=credential=<(echo -n ${CRED}) -o json --dry-run=client | kubeseal -o yaml | yq r - spec.encryptedData.credential
```
a nasledne vlozit do SealedSecret manifestu do spec.encryptedData

Take je mozne pouzit script `script/fill_sealed_secrets.sh` s jednim parametrem - jmeno souboru, ze ktereho se ziskaji patricne vstupy (namespace + secret name) a zapisi se do nej zasifrovane credentials (pouze ty, ktere jeste nemaji hodnotu - viz. `spec.encryptedData`)
