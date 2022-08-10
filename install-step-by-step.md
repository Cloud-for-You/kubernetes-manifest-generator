## Azure
### POTŘEBNÉ PREREQUSITIES
Všechny tyto objekty by měli být v Azure vytvořeny
**ClusterName: LAB1 (oaz-lab1)**  
**VNET: oaz-test-vnet**  
**Subnet Master: Master-lab1 (10.88.214.176/28)**  
**Subnet Worker: App-lab1 (10.88.214.128/27)**  
  
**VM Profile Master**  
type: Standard_D8as_v4  
disk: P30 (1TiB)  
  
**VM Profile Worker**  
type: Standard_D4as_v4  
disk: E15 (256GiB)  
  
**VM Profile Infra**  
type: Standard_D8as_v4  
disk: P30 (1TiB)  
  
**AZURE RESOURCE-GROUP:**  
openshift_az-lab1-rg (openshift_az-${cluster_name})  

### Vytvoření Azure RG pro install 
**RG by měla být předvytvořena a instalaci provést do ní, samozřejmě je možné ji vytvořit přez SP použitý dále.**
>You do not have permissions to create resource groups under subscription 
```sh
az account set --subscription d0c32b5f-c345-4bec-a129-bbc01fe24097
az account show
az login --service-principal --username 126501b0-ae03-4aad-aff2-19ced106b169 --password VSB~O6ezhO.BJXF45C5dC1~9zY403b~144 --tenant d2480fab-7029-4378-9e54-3b7a474eb327
az group create -l westeurope -n openshift_az-lab1-rg
# SP ma prava Manage apps that this app creates or owns ale tim se neda priradit assignment pro usera, prave proto je potreba mit 
# predvytvorenou RG s pridelenymi pravy pro uzivatele
```

## PŘIPRAVA KONFIGURAČNÍCH SOUBORŮ a prostředí na Bastion hostu
### CERTIFIKÁTY pro *.APPS, API
Certifikáty si zažádat https://kms.csin.cz/KMS/login/auth   
Potřebujeme dva certifikáty
```sh
#apps cert pro routu
CN = apps.oaz-lab1.ocp4.azure.csint.cz
SAN = email:openshift@csas.cz, DNS:*.apps.oaz-lab1.ocp4.azure.csint.cz DNS:apps.oaz-lab1.ocp4.azure.csint.cz

#api cert
CN = api.oaz-lab1.ocp4.azure.csint.cz
SAN = email:openshift@csas.cz, DNS:api-int.oaz-lab1.ocp4.azure.csint.cz, DNS:api.oaz-lab1.ocp4.azure.csint.czCN = apps.oaz-lab1.ocp4.azure.csint.cz

Issuer: C=CZ, O=\xC4\x8Cesk\xC3\xA1 spo\xC5\x99itelna a.s., OU=Spr\xC3\xA1va PKI, CN=CAIMS2        Issuer: C=CZ, O=\xC4\x8Cesk\xC3\xA1 spo\xC5\x99itelna a.s., OU=Spr\xC3\xA1va PKI, CN=CAIMS2
```
KMS nám dodá certifikáty v P12
```sh
# check
openssl pkcs12 -info -in INFILE.p12 -nodes
# cert:
openssl pkcs12 -in INFILE.p12 -out OUTFILE.crt -nokeys
#private key ve formatu pkcs#1
openssl pkcs12 -in INFILE.p12 -nodes -nocerts | openssl rsa -out OUTFILE.key
```
### KONFIGURACE HELM REGISTRY
```sh
mkdir -p ~/.config/helm/
cd ~/.config/helm/
cat <<EOF > repositories.yaml
apiVersion: ""
generated: "0001-01-01T00:00:00Z"
username: &username <USERNAME>
password: &password <PASSWORD>
repositories:
- caFile: ""
  certFile: ""
  insecure_skip_tls_verify: false
  keyFile: ""
  name: csas-openshift-helm
  password: *password
  url: https://artifactory.csin.cz/artifactory/csas-openshift-helm/
  username: *username
- caFile: ""
  certFile: ""
  insecure_skip_tls_verify: false
  keyFile: ""
  name: github-com-Dynatrace-dynatrace-oneagent-operator-releases
  password: *password
  url: https://artifactory.csin.cz/artifactory/github-com-Dynatrace-dynatrace-oneagent-operator-releases/
  username: *username
- caFile: ""
  certFile: ""
  insecure_skip_tls_verify: false
  keyFile: ""
  name: redhat-cop-github-io-egressip-ipam-operator
  password: *password
  url: https://artifactory.csin.cz/artifactory/redhat-cop-github-io-egressip-ipam-operator/
  username: *username
- caFile: ""
  certFile: ""
  insecure_skip_tls_verify: false
  keyFile: ""
  name: redhat-cop-github-io-group-sync-operator
  password: *password
  url: https://artifactory.csin.cz/artifactory/redhat-cop-github-io-group-sync-operator/
  username: *username
- caFile: ""
  certFile: ""
  insecure_skip_tls_verify: false
  keyFile: ""
  name: redhat-cop-github-io-cert-utils-operator
  password: *password
  url: https://artifactory.csin.cz/artifactory/redhat-cop-github-io-cert-utils-operator/
  username: *username
EOF

# helm repo test
helm repo update
helm search repo
helm search repo csas-openshift-helm 
```

### konfigurace SSH
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
Vygenerované klíče přidat pro access do git https://sdf.csin.cz/stash/projects/OCP4/ repository init-config pro s právy READ.  

### NETRC
```sh
cat << EOF > ~/.netrc
machine artifactory.csin.cz
  login ocp
  password ${PASSWORD}
EOF
```
### GIT

Zalozit repository ocp-${jmenoclusteru}-system (ocp-oaz-lab1-system) a pridat do nej vygenerovane ssh klice jako CONTRIBUTOR.  
```sh

# jmeny git
cat <<EOF > ~/.gitconfig
[user]
        email = oaz-lab1@ipocpbas01.vs.csin.cz
        name = oaz-lab
[push]
        default = simple
EOF
```

### INSTALL-CONFIG.yaml VALUES templating
```sh
#vytvořit values.yaml 
#hodnoty upravit dle PREREQISITIES
#sshKey: klic pouzit ten co jsme vygenerovali, slouzi k pristupu na uzivatele core na OCP nody

---
#example values.yaml
platform: azure
baseDomain: ocp4.azure.csint.cz
clusterName: lab1

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
  resourceGroupName: openshift_az-lab1-rg

proxy:
  httpProxy: http://ngproxy-test.csint.cz:8080
  httpsProxy: http://ngproxy-test.csint.cz:8080
  noProxy: 10.88.232.0/23,login.microsoftonline.com,management.azure.com,.blob.core.windows.net,.cs-test.cz,.csin.cz,.csint.cz

pullSecret: '{"auths":{"artifactory.csin.cz":{"auth":"b2NwOlRyZTVaaXpxbEdKT1NZdzhCUVZ5ZGFXbjk0eVZNZg==","email":"myemail"}}}'
sshKey: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCcfX0yJYv1cEATag3CDuGyKtNWrLAquvXbrO2n5i557aWzOADUapEBAfKqvpnqT7Px6AS6ILbPoOBmgbTMywdV3gTjO3PofKsOX2oTtlYe6T0pAkicgaIlcYfzEBzDR9muftimLhxI8e3XFBZ580ChaVaKYSeo5JYYelVOAmGPqWm6DrRwtVJeb2sYqUvfYg5q/Q36lyf2NOu5zstHa2uTvKGrsFKpMwYNoNQjbSYcTeqtPyxRaxuPQbnJa94amim7lmUfzk5Vu8osWPLarhtd9IZ1dWcUK5t5o9LGdZI34SRVLSwivFO1s3b7VPFFVeyv3piPzet7dZz9vabzAot9 oaz-lab1@ipocpbas01.vs.csin.cz' 
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
https://sdf.csin.cz/stash/projects/OCP4/repos/init-scripts/browse/init-cluster.sh
# spustime instalaci pro verzi clusteru 4.8
./init-cluster.sh -n oaz-lab1 -v 4.8
```
```sh
#zaloha install-config.yaml protoze ho instalator smaze
cp install-config/install-config.yaml ~/git
```
```sh
#pripadne nastavit systemovou proxy kvuli azcli
export https_proxy=http://ngproxy-test.csint.cz:8080
export http_proxy=http://ngproxy-test.csint.cz:8080
#pristup na api chceme bez proxy (oaz-dev je jmeno naseho clusteru)
export no_proxy='127.0.0.1,localhost,10.88.232.0/23,.csin.cz,.csint.cz'
#nebo
setproxy #alias na lokalni masine


#spustit instalator clusteru
openshift-install create cluster --dir ocp-oaz-lab1-system/install-config/ --log-level debug

INFO Access the OpenShift web-console here: https://console-openshift-console.apps.oaz-dev.ocp4.azure.csint.cz
INFO Login to the console with user: "kubeadmin", and password: "xqCDi-uanPN-IQAFt-YpSAL"
```

## PREPARE VALUES and SECRETS
Render vychazi z definic komponent helm templates **/value/components.yaml**  
kde je i definováno jakým způsobem se komponenta nasadí (helm,kustomize,plain).  
Konkrétní nastavení komponenty pak z jejího yaml souboru v **/values/${component}.yaml**  
tento soubor je v podstatě konfigurační soubor a hodnoty z něj jsou použity jako templating
values.  




## RENDER RESOURCES
PWD musí být v adresáři se systémovým GIT repository (ex. ocp-oaz-lab1-system).
```sh
# render vychazi z definice helm template
# values/components.yaml
# run render
# 
./script/render_.FINAL_RESOURCES.sh
```

## INSTALL RESOURCES
```sh
./script/deploy.sh
```
