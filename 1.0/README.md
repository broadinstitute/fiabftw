# fiabftw
Firecloud in a Box for the World

## Step 0: Prerequisites

- google project with billing account linked
- IAM permissions on google proj
- machine with gcloud cli, docker, and vault
- authed with gcloud cli
- google apps domain owned by user
- APIs enabled: 
- define admin console/gcloud console

Set user@domain as project owner in google proj - admin email

explain "env"

## Step 1: Vault

Vault is a secure directory for storing secrets. 

To create a server running vault, run
```
./initialize-vault.sh [google project] [vault host name]
```

Initialize and unseal vault
```
# Set the VAULT_ADDR to point to your vault server
export VAULT_ADDR=http://<GCE IP>:80

# Initialize the server
vault init

# Follow steps to unseal vault
# This should also generate a root token which you should at ".vault-token-fiabftw" at the root of this project
vault unseal
```

## Step 2: Generate credentials, users, and groups

### Create an acting service account

```
./initialize-script-runner.sh [admin email] [google project] [env]
```
This will create a service account for your admin account, which will be used to authenticate with both GSuite and 
GCloud to run subsequent commands.

##### Manual Step: Enable Domain-wide Delegation 

- [ ] In the console of your google project, go to IAM -> Service Accounts. Find your newly created service 
account (it should have the same name as your admin email).  Click the "more options" button to the right of your service account.
![Alt text](./screenshots/edit_service_account.png "Edit Service Account")

- [ ] Click "edit" and then select "Enable G Suite Domain-wide Delegation."

![Alt text](./screenshots/enable_dwd.png "Enable DwD")

##### Manual Step: Authorize API scopes

- [ ] In the Admin Console, go to Security -> Advanced settings -> Manage API client access. 
- [ ] From the json of your service account, grab the `client_id`.  Enter it as "Client Name" and enter the following as
 comma-separated API Scopes and then click "Authorize": 
    * https://www.googleapis.com/auth/admin.directory.customer 
    * https://www.googleapis.com/auth/admin.directory.group 
    * https://www.googleapis.com/auth/admin.directory.rolemanagement
    * https://www.googleapis.com/auth/admin.directory.user 

![Alt text](./screenshots/grant_api_scopes.png "Grant API scopes")
    
### Create service accounts in google project

```
./gce/create-service-accts.sh [google project] [google apps domain] [env]
```
This will create service accounts for all firecloud services and give them the appropriate IAM roles in GCloud.
It will also generate a text file, `service-accts.txt`, which will be used in the following step to add the service
accounts to groups in GSuite. 

**Manual Step**: Give the following services accounts [Domain-wide Delegation](manual-step-enable-domain-wide-delegation): agora, billing, firecloud, free-trial-billing-manager, leonardo, rawls, and sam.

**Manual Step**: Create OAuth Credentials. (TODO)

### Create groups and users in GSuite

```
./google-apps-domain/initialize-users-and-groups.sh [google apps domain] [admin email] [google project] [env]
```

This will create the initial Firecloud groups and users, and add users and service accounts to groups.

**Manual Step**: [Add scopes](manual-step-authorize-api-scopes) to the following services accounts in the Admin Console:

service | scopes
--- | ---
agora | https://www.googleapis.com/auth/admin.directory.groupmember.readonly <br> https://www.googleapis.com/auth/admin.directory.user
billing | https://www.googleapis.com/auth/admin.directory.user <br> https://www.googleapis.com/auth/cloud-billing <br> https://www.googleapis.com/auth/cloud-platform
rawls | https://www.googleapis.com/auth/admin.directory.group <br> https://www.googleapis.com/auth/admin.directory.user
firecloud | https://www.googleapis.com/auth/cloud-platform <br> https://www.googleapis.com/auth/devstorage.full_control <br> https://www.googleapis.com/auth/admin.directory.group <br> https://www.googleapis.com/auth/admin.directory.user <br> email <br> profile <br> openid
sam | https://www.googleapis.com/auth/admin.directory.group https://www.googleapis.com/auth/admin.directory.user

## Step 3: Generate google groups

## Step 4: Generate remaining secrets

## Step 5: Networking and acquiring certs

## Step 6: Pull FiaB configs

TODO: package up configs; pull configs

