#!/usr/bin/env bash

GOOGLE_PROJ=$1
INSTANCE_NAME=$2
ENVIRONMENT=${3:-fiab}
VAULT_TOKEN=${4:-$(cat .vault-token-fiabftw)}
export VAULT_TOKEN=${VAULT_TOKEN}

./gce/create-instance.sh ${GOOGLE_PROJ} ${INSTANCE_NAME}
INSTANCE_IP=$(gcloud --format="value(networkInterfaces[0].accessConfigs[0].natIP)" compute instances --project ${GOOGLE_PROJ} list --filter="name:( ${INSTANCE_NAME} )")
echo "Sleeping for a minute during host instantiation"
sleep 60

gcloud compute --project ${GOOGLE_PROJ} scp ./gce/provision-instance.sh root@${INSTANCE_NAME}:/tmp
gcloud compute --project ${GOOGLE_PROJ} ssh root@${INSTANCE_NAME} --command="bash /tmp/provision-instance.sh"

# Render allocator configs
echo GOOGLE_PROJ=$GOOGLE_PROJ > allocator/proj.env
docker run -v $PWD/allocator:/app \
           -e VAULT_TOKEN=$VAULT_TOKEN \
           -e INPUT_PATH=/app/configs \
           -e OUT_PATH=/app \
           -e ENVIRONMENT=$ENVIRONMENT \
           -e GOOGLE_PROJ=$GOOGLE_PROJ \
           -e ALLOCATOR_URL=http://${INSTANCE_IP}:80 \
           -e CONSUL_CONFIG=/app/vault-config.json \
           broadinstitute/dsde-toolbox:dev render-templates.sh

# Copy configs onto host and start allocator
gcloud compute --project ${GOOGLE_PROJ} scp --recurse ./allocator root@${INSTANCE_NAME}:/
gcloud compute --project ${GOOGLE_PROJ} scp admin-acct.json root@${INSTANCE_NAME}:/allocator
gcloud compute --project ${GOOGLE_PROJ} ssh root@${INSTANCE_NAME} --command="bash /allocator/start-allocator.sh"

echo "The allocator can be reached at http://${INSTANCE_IP}:80/apidocs/index.html"
echo "Set ALLOCATOR_HOST=http://${INSTANCE_IP}:80/ for future scripts."
