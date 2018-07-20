#!/usr/bin/env bash

GOOGLE_PROJ=$1
GOOGLE_APPS_DOMAIN=$2
DNS_DOMAIN=$3
ADMIN_EMAIL=$4
ENV=${5:-fiab}
VAULT_TOKEN=${6:-$(cat .vault-token-fiabftw)}

for file in ./migrations/*.sh; do
    echo "migrating $file..."
    bash "$file"
done
