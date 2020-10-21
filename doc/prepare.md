# Obecné prerekvizity
Pro všechny úkony související se správou ArgoCD deploymentu je nutné mít nakonfigurovaný GIT na pracovní stanici/bastion serveru. Jedná se o tato nastavení:
* Běžící SSH Agent s nahraným privátním klíčem
  * kontrola pomocí příkazu:
    `ssh-add -l`
* Registrovaný SSH klíč na svém účtu v Bitbucketu
* Nastavený Name a Email v GITu (Pozaor, je platný v celém kontextu daného uživatelského účtu na pracovní stanici/bastion serveru/pipeline)
  * kontrola nastavení pomocí příkazu:
    `git config --get-regex 'user\..*'`
  * nastavení:
    `git config --global user.name=USER_NAME`
    `git config --global user.email=EMAIL`

Pracovní stanice/bastion server/pipeline musejí mít tyto síťové prostupy i ArgoCD v OCP clusteru
* Bitbucket - SSH i HTTPS - TBD
* Artifactory - HTTPS - TBD

# Prerekvizity pro přípravu a instalaci clusteru
Nástroj Helm, který slouží k renderování finálních YAML manifestů z Helm chartů, ověřuje SSH certifikát Artifactory. Pokud není v systému zaregistrován odpovídající certifikát, je nutné jej nahrát (ve formátu PEM) do souboru `~/.config/helm/ocp-artifactory.crt`.

Dále jsou potřeba následující nástroje:
* `oc`
* `helm`
* `kustomize`
* `git`
* `yq` - [mikefarah yq ve verzi 3](https://github.com/mikefarah/yq)
