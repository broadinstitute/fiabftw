#!/usr/bin/env bash

GOOGLE_PROJ=$1
NAME=$2
ALLOCATOR_URL=$3
ENV=${4:-fiab}
MACHINE_TYPE=${MACHINE_TYPE:-n1-standard-8}
DISK_SIZE=${DISK_SIZE:-100}

set -e

# Fetch admin acct credentials
vault read -format=json secret/dsde/firecloud/admin-account.json | jq '.data' > admin-acct.json

# use dsp-toolbox to create fiab host
docker pull broadinstitute/dsp-toolbox
docker run --rm -v $PWD/output:/output \
    -v $PWD/admin-acct.json:/root/service-acct.json \
    -e SERVICE_ACCT=/root/service-acct.json \
    -e ALLOCATOR_URL=${ALLOCATOR_URL} \
    -e GOOGLE_PROJ=${GOOGLE_PROJ} \
    -e USERNAME=${NAME} \
    -e MACHINE_TYPE=${MACHINE_TYPE} \
    -e DISK_SIZE=${DISK_SIZE} \
    broadinstitute/dsp-toolbox fiab create

# Get data from newly-created host
SSH_HOST=$(jq --raw-output '.ip' output/host.json)
HOST_NAME=$(jq --raw-output '.name' output/host.json)

echo "Now sleeping for 5 minutes during host instantiation."
sleep 240

# Provision host
gcloud compute --project ${GOOGLE_PROJ} scp ./gce/provision-instance.sh root@${HOST_NAME}:/tmp
gcloud compute --project ${GOOGLE_PROJ} ssh root@${HOST_NAME} --command="bash /tmp/provision-instance.sh"

# make fiab run-able
docker run --rm -v $PWD/output:/output \
    -v $PWD/admin-acct.json:/root/service-acct.json \
    -e SERVICE_ACCT=/root/service-acct.json \
    -e GOOGLE_PROJ=${GOOGLE_PROJ} \
    -e FIAB_HOST=${HOST_NAME} \
    -e ALLOCATOR_URL=${ALLOCATOR_URL} \
    broadinstitute/dsp-toolbox fiab start
