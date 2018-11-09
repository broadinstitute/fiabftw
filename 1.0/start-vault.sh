#!/usr/bin/env bash

GOOGLE_PROJ=$1
INSTANCE_NAME=$2
INSTANCE_IP=$3
ENV=${4:-fiab}

# Set permissions on rendered config file
chmod 755 $PWD/vault/vault-config.json

gcloud compute --project ${GOOGLE_PROJ} scp --recurse ./vault root@${INSTANCE_NAME}:/
gcloud compute --project ${GOOGLE_PROJ} ssh root@${INSTANCE_NAME} --command="LOCAL_IP=${INSTANCE_IP} bash /vault/start-vault.sh"
export VAULT_ADDR=http://${INSTANCE_IP}:9200

# Render vault config for use in later scripts
docker run -v $PWD/vault:/app \
           -e INPUT_PATH=/app \
           -e OUT_PATH=/app \
           -e VAULT_IP=$INSTANCE_IP \
           -e ENVIRONMENT=$ENV \
           -e VAULT_TOKEN=unset \
           broadinstitute/dsde-toolbox:latest render-templates.sh

# Copy the vault config for later use in rendering allocator configs
cp vault/vault-config.json allocator
chmod 755 $PWD/allocator/vault-config.json
