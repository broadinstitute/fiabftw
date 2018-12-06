#!/bin/bash

set -e

# Parameters
WORKING_DIR=${1:-$PWD}
VAULT_TOKEN=${2:-$(cat $HOME/.vault-token)}
ENV=${3:-dev}
DNS_DOMAIN=${4:-dsde-${ENV}.broadinstitute.org}
GOOGLE_PROJ=${5:-broad-dsde-${ENV}}
VAULT_ADDR=${6:-https://clotho.broadinstitute.org:8200}

# Predefined Parameters
DOCKERHOST=`docker network inspect FiaB-Lite | jq --raw-output '.[0].IPAM.Config | .[0].Gateway'`
MYSQLPASS=globochem

# Create the TOS data entities required for the TOS app to work properly.
docker run --rm -e FC_ORCH_URL=$ORCH_URL -e JSON_CREDS="${JSON_CREDS}" -e TOKEN="${TOKEN}" \
    -e HOST_NAME="${HOST_NAME}" -e TOS_VERSION=${TOS_VERSION} -e DOCKERHOST="${DOCKERHOST}" -e ENV="${ENV}" -e GOOGLE_PROJ="${GOOGLE_PROJ}" \
    -v $WORKING_DIR:/app/populate --name CreateTos -w /app/populate \
    broadinstitute/dsp-toolbox python create_tos.py

# Create the ontology index. We set 'number_of_replicas' to 0 (instead of the default 1) so that FiaBs' single-node clusters accurately report Green health.
docker exec firecloud_elasticsearch_1 curl -X PUT "http://elasticsearch5a1-priv.${DNS_DOMAIN}:9200/ontology/" -H 'Content-Type: application/json' -d '{"settings":{"index":{"number_of_replicas":0}}}'

# Add permissions to Sam
sh $WORKING_DIR/sam_google_extensions_security.sh $ENV $VAULT_TOKEN $WORKING_DIR $DNS_DOMAIN $VAULT_ADDR
