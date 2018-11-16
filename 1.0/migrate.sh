#!/usr/bin/env bash

GOOGLE_PROJ=$1
GOOGLE_APPS_DOMAIN=$2
DNS_DOMAIN=$3
ADMIN_EMAIL=$4
ENV=${5:-fiab}
VAULT_TOKEN=${6:-$(cat .vault-token-fiabftw)}

export GOOGLE_PROJ=${GOOGLE_PROJ}
export GOOGLE_APPS_DOMAIN=${GOOGLE_APPS_DOMAIN}
export DNS_DOMAIN=${DNS_DOMAIN}
export ENV=${ENV}
export VAULT_TOKEN=${VAULT_TOKEN}

for file in ./migrations/*.sh; do
    echo "migrating $file..."
    bash "$file"
done
