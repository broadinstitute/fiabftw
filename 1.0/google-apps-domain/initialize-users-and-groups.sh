#!/usr/bin/env bash

# TODO: pull svc acct json from gcloud
# Authorize in admin console - manual step

# Before executing this script you must:
#   1. create a service account in your google proj with DwD
#   2. Add the client_id to Seucioryt-> Manage API client access with the scopes:
#       https://www.googleapis.com/auth/admin.directory.user
#       https://www.googleapis.com/auth/admin.directory.group
#       https://www.googleapis.com/auth/admin.directory.rolemanagement
#       https://www.googleapis.com/auth/admin.directory.customer

DOMAIN=${1:-fiabftw.firecloud.org}
USERNAME=${2:-jroberti@${DOMAIN}}
SVC_ACCT=${3:-dsp-fiabftw-svc-acct.json}
GOOGLE_PROJ=${4:-dsp-fiabftw}
ENV=${5:-fiab}

python google-apps-domain/create-initial-groups-and-users.py ${DOMAIN} ${USERNAME} ${SVC_ACCT} ${ENV} ${GOOGLE_PROJ}
python google-apps-domain/add-users-to-groups.py ${DOMAIN} ${USERNAME} ${SVC_ACCT} ${ENV} service-accts.txt
