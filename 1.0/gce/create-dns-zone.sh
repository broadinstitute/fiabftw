#!/usr/bin/env bash

GOOGLE_PROJ=$1
DNS_DOMAIN=$2

gcloud dns managed-zones create fiabftw --project=${GOOGLE_PROJ} \
    --description=${DNS_DOMAIN} --dns-name=${DNS_DOMAIN}
