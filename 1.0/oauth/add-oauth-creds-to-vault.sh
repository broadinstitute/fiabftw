#!/usr/bin/env bash

SERVICE=$1
CREDS_FILE_PATH=$2
ENV=${3:-fiab}
VAULT_TOKEN=${4:-$(cat .vault-token-fiabftw)}
export VAULT_TOKEN=$VAULT_TOKEN

if [ $SERVICE = "common" ]; then
    echo "Special case: common.  Writing additional secrets."
    CLIENT_ID=$(cat $CREDS_FILE_PATH | jq -r '.web.client_id')
    CLIENT_ID_PREFIX=$(echo $CLIENT_ID | cut -d '-' -f 1)
    vault write secret/dsde/firecloud/${ENV}/common/refresh-token-oauth-credential.json @${CREDS_FILE_PATH}
    echo "{\"client_ids\": {\"$ENV\": \"$CLIENT_ID_PREFIX\"}}" > client_id.json
    vault write secret/dsde/firecloud/common/oauth_client_id @client_id.json
    vault write secret/dsde/firecloud/${ENV}/agora/secrets swagger_client_id=${CLIENT_ID}
    rm client_id.json
else
    vault write secret/dsde/firecloud/${ENV}/${SERVICE}/${SERVICE}-oauth-credential.json @${CREDS_FILE_PATH}
fi
