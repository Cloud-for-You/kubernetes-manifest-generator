# Ladění helm chartů
Pro ladění helm chartů je připravena možnost renderování nepublikovaných vývojových verzí helm chartů z lokálního disku. Prerekvizitou je následující postup.

## Příprava helm chartu
Příprava helm chartu probíhá standardním způsobem, jen lokálně (nikoliv v rámci CI pipeline). V adresáři s helm chartem (jedním či více) je potřeba vytvořit helm index pomocí příkazu `helm repo index <DIR>`.

## Spuštění lokálního helm repository
V adresáři v helm charty a indexem (`<DIR>`) je potřeba spustit HTTP server (na portu `<PORT>`) - např. `cd <DIR>; python -m SimpleHTTPServer <PORT>`

## Konfigurace lokálního helm repository
Vytvořené Helm repository je nakonec potřeba nastavit:
`helm repo add <REPONAME> http://localhost:<PORT>`

## Nastavení verze Helm chartu
V konfiguraci komponenty v souboru `values/components.yaml` je potřeba nastavit správnou verzi (podle souboru v adresáři `<DIR>`) a dále je potřeba nastavit: `repository: <REPONAME>`
