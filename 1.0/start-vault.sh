#!/usr/bin/env bash

GOOGLE_PROJ=$1
INSTANCE_NAME=$2
INSTANCE_IP=$3

gcloud compute --project ${GOOGLE_PROJ} scp --recurse ./vault root@${INSTANCE_NAME}:/
gcloud compute --project ${GOOGLE_PROJ} ssh root@${INSTANCE_NAME} --command="LOCAL_IP=${INSTANCE_IP} bash /vault/start-vault.sh"
export VAULT_ADDR=http://${INSTANCE_IP}:9200
