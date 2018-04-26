#!/usr/bin/env bash

VAULT_TOKEN=$1
VAULT_PATH_PREFIX=$2
ENV=$3

# pull image with configs & secrets path map
# for path in secrets path map: if no secret @ path then create & write secret

gsutil cp gs://fiab-configs/fiabftw-configs.zip .
unzip -o fiabftw-configs.zip -d fiab-configs

python parse-vault-paths.py $PWD/fiab-configs/vaultPaths.json $ENV

# for each key in json file:
#   key = printf with environment
#   if key not in vault:
#       create & create all fields
#   else:
#       for field in
