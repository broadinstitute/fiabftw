# fiabftw
Firecloud in a Box for the World

## Step 0: Prerequisites

- google project with billing account linked
- IAM permissions on google proj
- machine with gcloud cli, docker, and vault
- authed with gcloud cli

## Step 1: Vault

Vault is a secure directory for storing secrets. 

To create a server running vault, run
```
./initialize-vault.sh $GOOGLE_PROJ $VAULT_VM_NAME
```

Initialize and unseal vault
```
vault init
vault unseal
# Follow steps to unseal vault
```
Get a token.
