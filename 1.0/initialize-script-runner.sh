#!/usr/bin/env bash

USERNAME=$1
GOOGLE_PROJ=$2
VAULT_TOKEN=${3:-$(cat .vault-token-fiabftw)}
export VAULT_TOKEN=$VAULT_TOKEN
echo $VAULT_TOKEN

name=$(echo $USERNAME | cut -d@ -f1)
domain=$(echo $USERNAME | cut -d@ -f2)


gcloud iam service-accounts create --project=${GOOGLE_PROJ} ${name} --display-name "${name}"
gcloud beta projects add-iam-policy-binding ${GOOGLE_PROJ} \
    --member="serviceAccount:${name}@${GOOGLE_PROJ}.iam.gserviceaccount.com" --role='roles/owner'
gcloud iam service-accounts keys create \
    $PWD/${name}-account.json \
    --iam-account "${name}@${GOOGLE_PROJ}.iam.gserviceaccount.com"
vault write secret/dsde/firecloud/admin-account.json @${PWD}/${name}-account.json
