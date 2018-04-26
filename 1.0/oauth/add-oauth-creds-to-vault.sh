#!/usr/bin/env bash

SERVICE=$1
CREDS_FILE_PATH=$2
ENV=$3
VAULT_TOKEN=${4:-$(cat .vault-token-fiabftw)}
export VAULT_TOKEN=$VAULT_TOKEN

if [ $SERVICE = "common" ]; then
    echo "Special case"
    CLIENT_ID=$(cat $CREDS_FILE_PATH | jq -r '.web.client_id' | cut -d '-' -f 1)
    vault write secret/dsde/firecloud/${ENV}/common/refresh-token-oauth-credential.json @${CREDS_FILE_PATH}
    echo "{\"client_id\": {\"$ENV\": \"$CLIENT_ID\"}}" > client_id.json
    vault write secret/dsde/firecloud/common/oauth_client_id @client_id.json
    rm client_id.json
else
    vault write secret/dsde/firecloud/${ENV}/${SERVICE}/${SERVICE}-oauth-credential.json @${CREDS_FILE_PATH}
fi
