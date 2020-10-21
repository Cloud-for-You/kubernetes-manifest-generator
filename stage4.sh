#!/bin/bash

set -e -u

export SECRETS_FILE=$1

################################################################################################################################################################
##### Inicializační skript ArgoCD deploymentu clusteru - STAGE 4
########################################
##### Skript má tyto vstupy:
#####   Pracovní adresář: spouští se z top-level pracovního adresáře GIT repozitáře daného clusteru ocp-${CLUSTER_NAME}-system
#####                       naklonovaného z GIT repozitáře: ssh://git@sdf.csin.cz:2222/OCP4/ocp-${CLUSTER_NAME}-system.git
#####                       ve tvaru script/stage2.sh
#####                     - tento adresář je výstupem STAGE 1
#####   Povinné parametry:
#####   - soubor se secrets - ocp-${CLUSTER_NAME}-secrets.yaml
#####                           jedná se o sobor vytvořený ve STAGE 1 ve stejném adresáři, jako klon GIT repozitáře
########################################
##### Skript provádí následující operace:
#####   1. nadeployuje obsah pro ArgoCD SYS, což zajistí rozběhnutí všech komponent
#####   2. nadeployuje credentias pro ArgoCD APP
#####      - heslo účtu "admin"
#####      - integrace OIDC s OCP
#####      - credentials GIT a HELM pro ArgoCD SYS
##### Skript není znovuspustitelný
################################################################################################################################################################

CLUSTER_DIR="$(pwd)"

script/deploy-bootstrap.sh
script/setup-argo-app.sh
