#!/usr/bin/env bash

# Creates a general gce instance in a google project that has docker
# TODO: this needs to be suitable for hosting vault and also hosting a fiab

GOOGLE_PROJ=$1
INSTANCE_NAME=$2
MACHINE_TYPE=${3:-n1-standard-8}

gcloud compute instances --project ${GOOGLE_PROJ} create ${INSTANCE_NAME} \
    --boot-disk-type pd-standard \
    --boot-disk-size 50 \
    --image-project ubuntu-os-cloud \
    --image-family ubuntu-1810 \
    --machine-type ${MACHINE_TYPE} \
    --tags http-server \
    --zone us-central1-a
