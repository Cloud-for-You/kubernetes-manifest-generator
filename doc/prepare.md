# Oprávnění
### Prerekvizity pro runtime
Veškerý obsah a konfigurace clusteru je uložena v GIT repozitářích na Bitbucket serveru. Pro korektní běh GitOps deploymentu jsou nutné tyto prerekvizity:
##### GIT
Každý OCP cluster má pro systémové i aplikační ArgoCD po jednom SSH klíči, jež je přiřazen konkrétním repozitářům či projektům na Bitbucketu:
* ArgoCD SYS
  * repository: `OCP4/ocp-<CLUSTER_NAME>-system  ` - R/O
  * repository: `OCP4/ocp-<CLUSTER_TYPE>-projects` - R/O
  * repository: `OCP4/init-scripts               ` - R/O
* ArgoCD APP
  * project: `JESTE_NENI_SPECIFIKOVANO` - R/O
##### HELM
Systémové ArgoCD nasazuje pouze z vyrenderovaných plain manifestů, Helm tedy napřímo napoužívá.
Aplikační ArgoCD může nasazovat aplikační workloud buď z GITu nebo jako HELM chart z Artifactory. Každý OCP cluster má pro aplikační ArgoCD vytvořen technický účet a heslo s těmito právy:
* ArgoCD APP
  * repository: `JESTE_NENI_SPECIFIKOVANO` - R/O

### Prerekvizity pro přípravu deploymentu
Při přípravě deploymentu (stage1 / stage2) pro nový cluster nebo při přerenderování manifestů pro cluster stávající se používá personální účet pracovníka (v případě manuálního zásahu) nebo technický účet pipeline (v případě automtizovaného zásahu). V obou případech jsou nutná stejná oprávnění.
##### GIT
* repository: `OCP4/ocp-<CLUSTER_NAME>-system` - R/W
* repository: `OCP4/init-scripts             ` - R/O
##### HELM
* repository: `JESTE_NENI_SPECIFIKOVANO` - R/O
Pro práci s nainstalovaným clusterem je zapotřebí mít aktivní kontext (`oc login`) vůči správnému clusteru

### Prerekvizity pro deployment
Při deploymentu (stage3+stage4) ArgoCD do nového clusteru (provádí se pouze při instalaci clusteru, případně při obnově poskozeného ArgoCD deploymentu) se použije vždy personální účet pracovníka mající tato oprávnění:
##### GIT
* repository: `OCP4/ocp-<CLUSTER_NAME>-system` - R/O
* repository: `OCP4/init-scripts             ` - R/O
##### OCP
* oprávnění cluster admin
* TBD: není nutné pro stage4 (pouze pro stage3), takře je případně možné dodefinovat
Pro práci s nainstalovaným clusterem je zapotřebí mít aktivní kontext (`oc login`) vůči správnému clusteru

### Prerekvizity pro správu aplikací
Seznam aplikací nasazených v OCP clusteru se spravuje výhradně přes GIT repozitář `OCP4/ocp-<CLUSTER_TYPE>-projects`, kde jsou manifesty `Projects.ops.csas.cz`. Požadovaná oprávnění na personální účet pracovníka, případně technický účet pipeline je:
* `ocp-<CLUSTER_TYPE>-projects` - R/W

### Prerekvizity pro vývoj
TBD

# Nastavení GIT personálního účtu
Pro všechny úkony související se správou ArgoCD deploymentu je nutné mít nakonfigurovaný GIT na pracovní stanici/bastion serveru. Jedná se o tato nastavení:
* Běžící SSH Agent s nahraným privátním klíčem
  * kontrola pomocí příkazu:
    `ssh-add -l`
* Registrovaný SSH klíč na svém účtu v Bitbucketu
* Nastavený Name a Email v GITu (Pozor, je platný v celém kontextu daného uživatelského účtu na pracovní stanici/bastion serveru/pipeline)
  * kontrola nastavení pomocí příkazu:
    `git config --get-regex 'user\..*'`
  * nastavení:
    `git config --global user.name=USER_NAME`
    `git config --global user.email=EMAIL`

# SÍťové prostupy
### ArgoCD
* Bitbucket - SSH + HTTPS - TBD
* Artifactory - HTTPS - TBD
### Pracovní stanice / bastion server / pipeline
* Bitbucket - SSH i HTTPS - TBD
* Artifactory - HTTPS - TBD
* Openshift API server - TBD
Nástroj Helm, který slouží k renderování finálních YAML manifestů z Helm chartů, ověřuje SSH certifikát Artifactory. Pokud není v systému zaregistrován odpovídající certifikát, je nutné jej nahrát (ve formátu PEM) do souboru `~/.config/helm/ocp-artifactory.crt`.

# Toolset
### Pracovní stanice / bastion server / pipeline
Pro správu deploymentu jsou potřeba tyto nástroje:
* `oc`
  * pro přístup do OCP clusteru
* `helm` - v3
  * pro stahování helm chartů z artifactory / pro generování finálních manifestů / pro sestavování helm chartů
* `kustomize`
  * pro rozpad YAML manifestu na jednotlivé zdroje a zajištění unikátní jmenné konvence / pro generování finálních manifestů
* `git`
  * pro správu deploymentu
* `yq` - [mikefarah yq ve verzi 3](https://github.com/mikefarah/yq)
  * pro parsování a strojovou úpravu YAML manifestů
