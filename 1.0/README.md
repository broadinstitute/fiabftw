# fiabftw
Firecloud in a Box for the World

## Step 0: Prerequisites

- google project with billing account linked
- IAM permissions on google proj
- machine with gcloud cli, docker, and vault
- authed with gcloud cli
- google apps domain owned by user

Set user@domain as project owner in google proj

## Step 1: Vault

Vault is a secure directory for storing secrets. 

To create a server running vault, run
```
./initialize-vault.sh $GOOGLE_PROJ $VAULT_VM_NAME
```

Initialize and unseal vault
```
# Set the VAULT_ADDR to point to your vault server
export VAULT_ADDR=http://<GCE IP>:80

# Initialize the server
vault init

# Follow steps to unseal vault
# This should also generate a root token which you should store securely
vault unseal
```

## Step 2: Generate secrets

* Create service acct for user@domain, put in vault (./initialize-script-runner.sh)
* ./creat-service-accts.sh
* ./google-apps-domain/create-initial-groups-and-users.sh
* ./google-apps-domain/add-users-to-groups.py
* manual step: create oauth credentials

* for remaining secrets: ./initialize-secrets.sh

## Step 3: Get configs

TODO: package up configs; pull configs

