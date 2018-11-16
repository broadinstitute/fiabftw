#!/usr/bin/env bash

set -e

echo "Google apps: ${GOOGLE_APPS_DOMAIN}"
organization=$(gcloud organizations list | grep ${GOOGLE_APPS_DOMAIN} | awk '{print $2}')
echo "Org: ${organization}"
echo "Checking if Requestor Pays role exists..."
list_role=0
gcloud iam roles describe --organization=$organization RequestorPays --quiet || list_role=$?

if [ $list_role -ne 0 ]; then
    echo "Creating requestor pays role in $GOOGLE_APPS_DOMAIN organization..."
    gcloud iam roles create RequestorPays --quiet \
            --organization=$organization \
            --stage=GA \
            --permissions="serviceusage.services.use" \
            --description="requestor pays role" \
            --title="Requestor Pays"
    echo "...done"
else
    echo "Skipping migration 001_requestor_pays_role_create.sh"
    echo "DONE"
fi
