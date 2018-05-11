#!/usr/bin/env bash

GOOGLE_PROJ=$1
DOMAIN=$2
ENV=${3:-fiab}
VAULT_TOKEN=${4:-$(cat .vault-token-fiabftw)}
export VAULT_TOKEN=$VAULT_TOKEN


function create_svc_acct() {
    service=$1
    vault_path=${2:-"secret/dsde/firecloud/${ENV}/${service}/${service}-account.json"}
    name=${3:-"${service}-${ENV}"}
    role=${4:-roles/editor}
    gcloud iam service-accounts create --project=${GOOGLE_PROJ} ${name} --display-name ${name}
    gcloud beta projects add-iam-policy-binding ${GOOGLE_PROJ} \
        --member="serviceAccount:${name}@${GOOGLE_PROJ}.iam.gserviceaccount.com" --role="${role}"
    gcloud iam service-accounts keys create \
        $PWD/${service}-account.json \
        --iam-account "${name}@${GOOGLE_PROJ}.iam.gserviceaccount.com"
    vault write ${vault_path} @${PWD}/${service}-account.json
    echo "${name}@${GOOGLE_PROJ}.iam.gserviceaccount.com" >> service-accts.txt

}

function give_firecloud_role() {
    echo $DOMAIN
    organization=$(gcloud organizations list | grep ${DOMAIN} | awk '{print $2}')
    echo $organization
    gcloud alpha organizations add-iam-policy-binding $organization \
        --member="serviceAccount:firecloud-${ENV}@${GOOGLE_PROJ}.iam.gserviceaccount.com" \
        --role='roles/iam.serviceAccountUser'

    gcloud alpha organizations add-iam-policy-binding $organization \
        --member="serviceAccount:firecloud-${ENV}@${GOOGLE_PROJ}.iam.gserviceaccount.com" \
        --role='roles/iam.serviceAccountKeyAdmin'

    gcloud alpha organizations add-iam-policy-binding $organization \
        --member="serviceAccount:firecloud-${ENV}@${GOOGLE_PROJ}.iam.gserviceaccount.com" \
        --role='roles/storage.admin'


}

rm -f service-accts.txt
touch service-accts.txt

create_svc_acct agora
create_svc_acct consent
create_svc_acct cromwell
create_svc_acct leonardo
create_svc_acct rawls
create_svc_acct thurloe
create_svc_acct sam
create_svc_acct firecloud secret/dsde/firecloud/${ENV}/common/firecloud-account.json
create_svc_acct billing secret/dsde/firecloud/${ENV}/common/billing-account.json billing
create_svc_acct free-trial-billing-manager secret/dsde/firecloud/${ENV}/common/trial-billing-account.json free-trial-billing-manager
create_svc_acct bigquery secret/dsde/firecloud/${ENV}/common/bigquery-account.json roles/bigquery.jobUser

# Give additional roles to firecloud-${ENV} svc acct
give_firecloud_role

# Extra vault secrets
vault write secret/dsde/firecloud/${ENV}/cromwell/secrets service_auth_service_account_id=cromwell-${ENV}@${GOOGLE_PROJ}.iam.gserviceaccount.com
