Popis instalace oaz-dev clusteru z bastion hostu, argo deploy
## PŘIPRAVA KONFIGURAČNÍCH SOUBORŮ
### CERTIFIKÁTY pro *.APPS, API
```sh
# mame certifikaty ve formatu p12 potrebujeme convert na pkcs#1 format
# check
openssl pkcs12 -info -in INFILE.p12 -nodes
# cert:
openssl pkcs12 -in INFILE.p12 -out OUTFILE.crt -nokeys
#private key ve formatu pkcs#1
openssl pkcs12 -in INFILE.p12 -nodes -nocerts | openssl rsa -out OUTFILE.key
```

### KONFIGURACE HELM REGISTRY
```sh
cd ~/.config/helm/
cat <<EOF > repositories.yaml
apiVersion: ""
generated: "0001-01-01T00:00:00Z"
repositories:
- caFile: ""
  certFile: ""
  insecure_skip_tls_verify: false
  keyFile: ""
  name: csas-openshift-helm-local 
  password: **supertajneheslo**
  url: https://artifactory.csin.cz/artifactory/csas-openshift-helm-local/
  username: ocp
EOF

# helm repo test
helm repo update
helm repo search 
helm search repo csas-openshift-helm-local 
```

### SSH
```sh
# vygenerovat ssh klice
ssh-keygen -t rsa
# generated keys
#~/.ssh/id_rsa, id_rsa.pub -> klice pridat do repa init-config ve stash
#zalozit repository ocp-oaz-dev-system a pridat do nej klice
```

```sh
cat << EOF >~/.ssh/config
Host sdf.csin.cz
    Hostname sdf.csin.cz
    IdentityFile ~/.ssh/id_rsa
    IdentitiesOnly yes
EOF
```

### GIT
```sh
# zalozit repository ocp-jmenoclusteru-system a pridat do nej vygenerovane ssh klice pro trust

# jmeny git
cat <<EOF > ~/.gitconfig
[user]
        email = oaz-dev@ipocpbas01.vs.csin.cz
        name = oaz-dev
[push]
        default = simple
EOF
```

### INSTALL-CONFIG VALUES
```sh
#vygenerovat values.yaml a jako sshKey klic pouzit ten co jsme vygenerovali, slouzi k pristupu na uzivatele core na OCP nody
---
#values.yaml
platform: azure
baseDomain: ocp4.azure.csint.cz
clusterName: oaz-dev

azure:
  region: westeurope
  networkResourceGroupName: openshift_az-test-net-rg
  virtualNetwork: oaz-test-vnet
  controlPlaneSubnet: Master2
  computeSubnet: App2
  outboundType: UserDefinedRouting
  baseDomainResourceGroupName: openshift_az-dev-shared-rg
  cloudName: AzurePublicCloud
  controlPlane:
    type: Standard_D4s_v3
    diskSize: 256
  computePlane:
    type: Standard_D4s_v3
    diskSize: 128
  machineNetworkCIDR: 10.88.232.0/23

proxy:
  httpProxy: http://ngproxy-test.csint.cz:8080
  httpsProxy: http://ngproxy-test.csint.cz:8080
  noProxy: 10.88.232.0/23,login.microsoftonline.com,management.azure.com,.blob.core.windows.net,.cs-test.cz,.csin.cz,.csint.cz

pullSecret: '{"auths":{"artifactory.csin.cz":{"auth":"b2NwOlRyZTVaaXpxbEdKT1NZdzhCUVZ5ZGFXbjk0eVZNZg==","email":"myemail"}}}'
sshKey: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCcfX0yJYv1cEATag3CDuGyKtNWrLAquvXbrO2n5i557aWzOADUapEBAfKqvpnqT7Px6AS6ILbPoOBmgbTMywdV3gTjO3PofKsOX2oTtlYe6T0pAkicgaIlcYfzEBzDR9muftimLhxI8e3XFBZ580ChaVaKYSeo5JYYelVOAmGPqWm6DrRwtVJeb2sYqUvfYg5q/Q36lyf2NOu5zstHa2uTvKGrsFKpMwYNoNQjbSYcTeqtPyxRaxuPQbnJa94amim7lmUfzk5Vu8osWPLarhtd9IZ1dWcUK5t5o9LGdZI34SRVLSwivFO1s3b7VPFFVeyv3piPzet7dZz9vabzAot9 oaz-dev@ipocpbas01.vs.csin.cz' 
```

### AZURE PROFILE
```sh
mkdir ~/.azure
# mel by obsahovat nasledujici soubory:
accessToken.json  azureProfile.json  osServicePrincipal.json
```

## INSTALACE CLUSTERU
```sh
# init cluster stahneme z init-cluster repa a do stejneho adresare pridame values.yaml
# spustime instalaci
./init-cluster.sh -n oaz-dev -v 4.6.1
```
```sh
#zaloha install-config.yaml protoze ho instalator smaze
cp install-config/install-config.yaml ~/git
```
```sh
#spustit instalator clusteru
openshift-install create cluster --dir ocp-oaz-dev-system/install-config/ --log-level debug

INFO Access the OpenShift web-console here: https://console-openshift-console.apps.oaz-dev.ocp4.azure.csint.cz
INFO Login to the console with user: "kubeadmin", and password: "xqCDi-uanPN-IQAFt-YpSAL"
```

## RENDER RESOURCES
```sh
# render vychazi z definice helm template
# values/components.yaml
# run render
./render_resources.sh
```

## INSTALL RESOURCES
```sh
./deploy.sh
```
