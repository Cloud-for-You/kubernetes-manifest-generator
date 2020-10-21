# STAGE 1
### Založit GIT repozitář pro konfiguraci clusteru a vyrenderovaný manifest
* Vytvořte GIT repozitář odpovídající jmenné konvenci na Bitbucket serveru:
  * `ssh://git@sdf.csin.cz:2222/OCP4/ocp-<CLUSTER_NAME>-system.git`
* Stáhněte inicializační skript a uložte jej jako `stage1.sh` (ideálně obsah zkopírujte z webu Bitbucketu přímo do souboru):
  * `https://sdf.csin.cz/stash/projects/OCP4/repos/init-scripts/raw/stage1.sh?at=refs%2Fheads%2Fmaster`
* Spusťte první část deploy procesu a jako parametr dejte jméno clusteru CLUSTER_NAME:
  ```
  bash stage1.sh CLUSTER_NAME
  ```

# STAGE 2
### Připravit konfiguraci daného clusteru
* Vyplňte hodnoty deploymentu v souboru `ocp-<CLUSTER_NAME>-system/values/values.yaml` podle popisu v něm uvedeném
* Vyplňte verze komponent v souboru `ocp-<CLUSTER_NAME>-system/values/versions.yaml`
* Vyplňte secrets v souboru `ocp-<CLUSTER_NAME>-secrets.yaml` podle popisu v něm uvedeném

### Vyrenderovat ArgoCD manifesty
* Spusťte druhou část deploy procesu z adresáře `ocp-<CLUSTER_NAME>-system` a jako parametr dejte jméno souboru se secrets:
  ```
  cd ocp-CLUSTER_NAME-system
  bash script/stage2.sh ../ocp-CLUSTER_NAME-secrets.yaml
  ```

### Uložit secrets
* Uložte na bezpečné místo soubor `ocp-<CLUSTER_NAME>-system.yaml`

# STAGE 3
### Nasadit ArgoCD SYS do clusteru
* Spusťte třetí část deploy procesu z adresáře `ocp-<CLUSTER_NAME>-system` a jako parametr dejte jméno souboru se secrets:
  ```
  cd ocp-CLUSTER_NAME-system
  bash script/stage3.sh ../ocp-CLUSTER_NAME-secrets.yaml
  ```
* Tímto je v OCP clusteru nasazeno ArgoCD SYS včetně jeho credentials. Zatím bez obsahu, tj. bez komponent, aplikací a cluster konfigurace

# STAGE 4
### Nasadit obsah ArgoCD SYS do clusteru
* Spusťte čtvrtou část deploy procesu z adresáře `ocp-<CLUSTER_NAME>-system` a jako parametr dejte jméno souboru se secrets:
  ```
  cd ocp-CLUSTER_NAME-system
  bash script/stage4.sh ../ocp-CLUSTER_NAME-secrets.yaml
  ```
* Tímto je v OCP clusteru nasazen obsah pro ArgoCD SYS, tj.
  * ArgoCD APP včetně jeho credentials
  * Cluster konfigurace dle deklarace v GITu
  * Komponenty clusteru
* Tímto je dokončen deployment na OCP cluster. O zbytel se již postarají jednotlivé kontrolery (ArgoCD, CSAS Project Operator, atd.).
