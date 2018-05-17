#!/usr/bin/env bash

# Before executing this script you must:
#   1. create a service account in your google proj with DwD
#   2. Add the client_id to Security -> Manage API client access with the scopes:
#       https://www.googleapis.com/auth/admin.directory.user
#       https://www.googleapis.com/auth/admin.directory.group
#       https://www.googleapis.com/auth/admin.directory.rolemanagement
#       https://www.googleapis.com/auth/admin.directory.customer

DOMAIN=$1
USERNAME=$2
GOOGLE_PROJ=$3
PASSWORD=$4
ENV=${5:-fiab}
VAULT_TOKEN=${6:-$(cat .vault-token-fiabftw)}
export VAULT_TOKEN=$VAULT_TOKEN

set -e

vault read -format=json secret/dsde/firecloud/admin-account.json | jq '.data' > admin-acct.json

python google-apps-domain/create-initial-groups-and-users.py ${DOMAIN} ${USERNAME} admin-acct.json ${ENV} ${GOOGLE_PROJ} ${PASSWORD}
python google-apps-domain/add-users-to-groups.py ${DOMAIN} ${USERNAME} admin-acct.json ${ENV} ${GOOGLE_PROJ} service-accts.txt

# Add the billing account user to IAM
gcloud beta projects add-iam-policy-binding ${GOOGLE_PROJ} \
    --member="user:billing@${DOMAIN}" \
    --role='roles/billing.projectManager'

