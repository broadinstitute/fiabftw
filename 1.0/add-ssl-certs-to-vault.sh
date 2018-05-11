#!/usr/bin/env bash

CERT_PATH=$1
KEY_PATH=$2
BUNDLE_PATH=$3
ENV=${4:-fiab}
VAULT_TOKEN=${5:-$(cat .vault-token-fiabftw)}
export VAULT_TOKEN=$VAULT_TOKEN


write_to_vault() {
    cert_path=$1
    vault_path=$2
    vault_key=${3:-value}
    CERT_STR=$(cat $cert_path |  perl -0777 -pe 's/\n/\\n/g')
    echo {\"${vault_key}\": \"${CERT_STR}\"} > cert.json
    vault write $vault_path @cert.json
    rm cert.json

}

write_to_vault ${CERT_PATH} secret/dsde/firecloud/${ENV}/common/server.crt
write_to_vault ${KEY_PATH} secret/dsde/firecloud/${ENV}/common/server.key
write_to_vault ${BUNDLE_PATH} secret/common/ca-bundle.crt chain
