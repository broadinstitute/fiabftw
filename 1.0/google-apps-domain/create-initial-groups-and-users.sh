#!/usr/bin/env bash

# TODO: pull svc acct json from gcloud
# Authorize in admin console - manual step

# Before executing this script you must:
#   1. create a service account in your google proj with DwD
#   2. Add the client_id to Seucioryt-> Manage API client access with the scopes:
#       https://www.googleapis.com/auth/admin.directory.user
#       https://www.googleapis.com/auth/admin.directory.group

python google-apps-domain/create-initial-groups-and-users.py jroberti@fiabftw.firecloud.org dsp-fiabftw-svc-acct.json
