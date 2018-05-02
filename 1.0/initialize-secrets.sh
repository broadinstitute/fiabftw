#!/usr/bin/env bash

ENV=${1:-fiab}
VAULT_TOKEN=${2:-$(cat .vault-token-fiabftw)}
#VAULT_PATH_PREFIX=$3


# pull image with configs & secrets path map
# for path in secrets path map: if no secret @ path then create & write secret

#gsutil cp gs://fiab-configs/fiabftw-configs.zip .
#unzip -o fiabftw-configs.zip -d fiab-configs

python parse-vault-paths.py --fromFile $PWD/fiab-configs/vaultPaths.json --env $ENV
