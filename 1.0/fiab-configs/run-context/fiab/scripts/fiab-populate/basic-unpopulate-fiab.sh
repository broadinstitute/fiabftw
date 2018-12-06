#!/bin/bash

set -e

# Parameters
WORKING_DIR=${1:-$PWD}
VAULT_TOKEN=${2:-$(cat $HOME/.vault-token)}
ENV=${3:-dev}
DNS_DOMAIN=${4:-dsde-${ENV}.broadinstitute.org}
GOOGLE_PROJ=${5:-broad-dsde-${ENV}}
VAULT_ADDR=${6:-https://clotho.broadinstitute.org:8200}

docker run --rm -e JSON_CREDS="${JSON_CREDS}" \
    -e HOST_NAME="${HOST_NAME}" -e TOS_VERSION=${TOS_VERSION} -e ENV="${ENV}" -e GOOGLE_PROJ="${GOOGLE_PROJ}" \
    -v $WORKING_DIR:/app/populate --name UnregisterToS -w /app/populate \
    broadinstitute/dsp-toolbox python unregister_tos.py
