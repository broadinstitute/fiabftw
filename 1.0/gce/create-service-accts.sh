#!/usr/bin/env bash

GOOGLE_PROJ=$1
ENV=$2
VAULT_TOKEN=${3:-$(cat .vault-token-fiabftw)}
export VAULT_TOKEN=$VAULT_TOKEN

# TODO: add svc acct email to fc-admins group
# TODO: add dwd to svc acct

function create_svc_acct() {
    service=$1
    vault_path=${2:-"secret/dsde/firecloud/${ENV}/${service}/${service}-account.json"}
    gcloud iam service-accounts create --project=${GOOGLE_PROJ} ${sevice}-${ENV} --display-name "${service}-${ENV}"
    gcloud beta projects add-iam-policy-binding ${GOOGLE_PROJ} \
        --member="serviceAccount:${service}-${ENV}@${GOOGLE_PROJ}.iam.gserviceaccount.com" --role='roles/editor'
    gcloud iam service-accounts keys create \
        $PWD/${service}-account.json \
        --iam-account "${service}-${ENV}@${GOOGLE_PROJ}.iam.gserviceaccount.com"
    vault write ${vault_path} @${PWD}/${service}-account.json

}

create_svc_acct agora
create_svc_acct consent
create_svc_acct cromwell
create_svc_acct leonardo
create_svc_acct rawls
create_svc_acct thurloe
create_svc_acct sam
create_svc_acct firecloud secret/dsde/firecloud/${ENV}/common/firecloud-account.json
create_svc_acct billing secret/dsde/firecloud/${ENV}/common/billing-account.json
create_svc_acct free-trial-billing-manager secret/dsde/firecloud/${ENV}/common/trial-billing-account.json


# Create oauth credentials
# consent, rawls, refresh token, leo
