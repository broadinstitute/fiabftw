#!/usr/bin/env bash

GOOGLE_PROJ=$1
ENV=$2
BUCKET_TAG=${3:-$GOOGLE_PROJ-$ENV}
VAULT_TOKEN=${4:-$(cat .vault-token-fiabftw)}

gsutil mb storage-logs-${GOOGLE_PROJ}
gsutil mb cromwell-auth-${GOOGLE_PROJ}

gsutil mb cromwell-ping-me-${BUCKET_TAG}
cromwell_sa=$(vault read -field client_email secret/dsde/firecloud/$ENV/cromwell/cromwell-account.json)
gsutil acl ch -u $cromwell_sa:R gs://cromwell-ping-me-${BUCKET_TAG}

gsutil mb firecloud-alerts-${BUCKET_TAG}

gsutil mb ${GOOGLE_PROJ}-consent
consent_sa=$(vault read -field client_email secret/dsde/firecloud/$ENV/consent/consent-account.json)
gsutil acl ch -u ${consent_sa}:O gs://${GOOGLE_PROJ}-consent
