#!/usr/bin/env bash
set -e

GOOGLE_PROJ=$1
INSTANCE_NAME=$2

./gce/create-instance.sh ${GOOGLE_PROJ} ${INSTANCE_NAME} n1-standard-4
INSTANCE_IP=$(gcloud --format="value(networkInterfaces[0].accessConfigs[0].natIP)" compute instances --project ${GOOGLE_PROJ} list --filter="name:( ${INSTANCE_NAME} )")
echo "Sleeping for a minute during host instantiation"
sleep 60

gcloud compute --project ${GOOGLE_PROJ} scp ./gce/provision-instance.sh root@${INSTANCE_NAME}:/tmp
gcloud compute --project ${GOOGLE_PROJ} ssh root@${INSTANCE_NAME} --command="bash /tmp/provision-instance.sh"

./start-vault.sh $GOOGLE_PROJ $INSTANCE_NAME $INSTANCE_IP
