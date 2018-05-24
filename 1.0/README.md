# fiabftw
Firecloud in a Box for the World

## Step 0: Prerequisites

You will need the following software installed on your workspace to run the set up scripts:
- [Docker](https://www.docker.com/community-edition)
- [Vault](https://www.vaultproject.io/downloads.html)
- [gcloud CLI](https://cloud.google.com/sdk/gcloud/)

Other requirements:
- A [Google Project](https://cloud.google.com/resource-manager/docs/creating-managing-projects) (hence referred to as `[google project]`) with a billing account linked to it and the following APIs enabled:
    - Admin SDK
    - Cloud Billing API
    - Google Drive API
    - Google Sheets API
    - Cloud Pub/Sub API
    - Identity and Access Management API
    - Genomics API
    - Cloud Dataproc API
- A [GSuite](https://gsuite.google.com/) account (hence referred to as `[google apps domain]`)
- An admin user (hence referred to as `[admin user]`) in the Apps Domain who has also been added to the google project with the "Project Owner" IAM role
- A DNS Domain for the project (hence referred to as `[dns domain]`) 
- SSL Certificates in PEM format with bundle/chain.  A wildcard SSL is preferred.

Authenticate with the gcloud CLI using your admin user:
```
gcloud auth login [admin user]
gcloud config set project [google project]
```

#### Environment variables
The following environment variables will be referenced in the remainder of this documentation: 
- `[google project]` - the name of your google project (i.e. `broad-dsp-fiabftw`)
- `[google apps domain]` - your GSuite account domain (i.e. `fiabftw.firecloud.org`)
- `[admin email]` - an admin account to act as script runner.  Should be in the google apps domain and a Project Owner in the google project.
- `[dns domain]` - the DNS domain with associated SSL certs (i.e. `fiabftw.broadinstitute.org`)
- `[env]` - This is an internal variable that allows for the possibility of standing up multiple fiab "environments" with their own service accounts, groups, and DNS domains.  Will default to a single env, `fiab`.
- `[vault token]` -  See Step 1 for details.  Will default to reading from `.vault-token-fiabftw` for all scripts. 

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
# This should also generate a root token which you store should at ".vault-token-fiabftw" at the root of this project
vault unseal
```

## Step 2: Generate credentials, users, and groups

### Create an acting service account

```
./initialize-script-runner.sh [admin email] [google project]
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

**Manual Step**: Give the following services accounts [Domain-wide Delegation](#manual-step-enable-domain-wide-delegation): agora, billing, firecloud, free-trial-billing-manager, leonardo, rawls, and sam.

**Manual Step**: [Create Oauth Credentials](./oauth/OauthCreds.md).

### Create groups and users in GSuite

```
# NOTE: [password] is a default password for the users who will be created in your apps domain
# NOTE: [admin email] must be in the apps domain 
./google-apps-domain/initialize-users-and-groups.sh [google apps domain] [admin email] [google project] [password] [env]
```

This will create the initial Firecloud groups and users, and add users and service accounts to groups.

**Manual Step**: [Add scopes](#manual-step-authorize-api-scopes) to the following services accounts in the Admin Console (remember that you have to use the service account `client_id` as the Client Name):

service | scopes
--- | ---
agora | https://www.googleapis.com/auth/admin.directory.groupmember.readonly <br> https://www.googleapis.com/auth/admin.directory.user
billing | https://www.googleapis.com/auth/admin.directory.user <br> https://www.googleapis.com/auth/cloud-billing <br> https://www.googleapis.com/auth/cloud-platform
rawls | https://www.googleapis.com/auth/admin.directory.group <br> https://www.googleapis.com/auth/admin.directory.user
firecloud | https://www.googleapis.com/auth/cloud-platform <br> https://www.googleapis.com/auth/devstorage.full_control <br> https://www.googleapis.com/auth/admin.directory.group <br> https://www.googleapis.com/auth/admin.directory.user <br> email <br> profile <br> openid
sam | https://www.googleapis.com/auth/admin.directory.group https://www.googleapis.com/auth/admin.directory.user

## Step 3: Billing

In order to create and use any resources in Firecloud, you will need to associate Firecloud with your Google billing account (this is the account that your project is linked to). This will allow you to create
a billing project in Firecloud, which will allow you to use Google resources.  To do this, you will need to add two users to your Google billing account: `billing@[google apps domain]` and your `[admin user]`. 

In the GCloud console, go to your organization -> Billing -> Manage billing accounts. Be sure that "Show subaccounts" is selected. 
Select the appropriate billing account.  Under "Permissions", in the "Add members" box add the billing user and your admin user with the role `Billing Account User`

![Alt text](./screenshots/billing-account.png "Add users to a billing account")

You can add additional users to the billing account, and they will be able to create/manage billing projects when they register with Firecloud.

## Step 4: Generate google buckets

```
./gce/create-buckets.sh [google proj] [env] [bucket-tag] [vault-token]
```
Note: the parameter `bucket-tag` is for giving a globally unique tag to Firecloud buckets.  It will default to `[google project]-[env]`

## Step 5: Networking and DNS

Populate SSL certs into vault:
```$xslt
./add-ssl-certs-to-vault.sh [cert path] [key path] [bundle path] [env]
```
where `[cert path]` is the path to an SSL Certificate PEM, `[key path]` is the path to an SSL Private Key PEM, and `[bundle path]` is the path to a certificate chain bundle PEM.

Generate leonardo Jupyter certs:
```
export ENV=[env]
sh fiab-configs/scripts/leonardo/generate_jupyter_secrets.sh
```
You will be prompted to create a password, after which run:
```aidl
vault write secret/dsde/firecloud/$ENV/leonardo/secrets client_cert_password=[passwd]
```

Create a firewall rules for FiaB:
```
./gce/create-firewall-rules.sh [google proj]
```

## Step 6: Generate remaining secrets

Pull the fiab configs and generate remaining secrets:
```$xslt
./initialize-secrets.sh [env]
```

For more about overwriting/editing vault secrets, see the Secrets.md document.

## Step 7: Set up a fiab allocator

```$xslt
./allocator/create-allocator.sh [google proj] [instance name] [env]
```
Where `[instance name]` is the name you wish to give to your GCE instance.  This will create a GCE instance and write out its IP, which should be used as the `[allocator url]` in Step 7.

## Step 8: Start a fiab

1. Create and provision the fiab host:
```$xslt
./create-fiab-instance.sh [google proj] [name] [allocator url] [env]
```
2. If you have not pulled the fiab-configs recently (Step 5), run the following script to update your configs and any vault secrets:
```
./initialize-secrets.sh [env]
```

3. If you want to run your fiab with a custom docker image for any service, edit `FiaB_images.env`.  Otherwise, all images will default to `dev`.

4. Start Firecloud on the host:
```
./fiab.sh start [fiab host] [allocator url] [google proj] [google apps domain] [dns domain] [admin email] [env]
```

5. TODO: basic populate

#### To stop a fiab
```
./fiab.sh stop [fiab host] [allocator url] [google proj] [google apps domain] [dns domain] [admin email] [env]
```

To perform more actions on your fiab host, use the Swagger API, accessible at `http://[allocator host]:80/apidocs/index.html`

## Running on multiple VMs
FIAB is not a scalable, production-ready installation. It's useful for development, troubleshooting and testing. In production, Firecloud should be run on multiple machines. 

 1. At this point you should have dockers, docker-composes and conf files. If you open the docker-compose files, you'll see where the confs are injected and other variables. 
 2. Docker-composes link all the containers together with Docker Networking. If you want to run on multiple nodes, you'll have to change the `link:` functions in the docker-compose and change conf files to point to "real" machines. That also means setting up DNS for each "real" machine.
 3. In practice, Broad sets this all up using Terraform. Here are our templates: https://github.com/broadinstitute/terraform-firecloud.  
   * In practice, this requires a bunch of prerequisites including Vault and Puppet. A user can use any Docker-enabled node to run any service that we run. 
   * The user is responsible for their own deployment process of getting conf files, certs, etc onto machines that are going to be mounted into the Dockers via docker-compose.
 6. There's a nuance in GCE in that VMs can't route to other VMs in the same project via their external address. So if serverA wants to talk to serverB, it has to do so through the private IP. That means 2 DNS names for each server (public and private) and the conf files have to point to the appropriate one.
   * In practice: If Rawls wants to talk to Cromwell, it has to use Cromwell-priv address.
   * Most of our services are usually deployed behind Google load-balancers. These face the outside world and provide a routable external address. This means that, in actuality, most of the microservices face the outside world. Cromwell doesn't, though, nor do things like Elastic Search and Mongo, so if those live on individual VMs, machines that talk to those services have to use the Priv address.
   3. This also means that the Apache Proxies that sit in front of each service have to be configured for SERVER_NAME as well as SERVER_NAME_ALIASES. 
     * This is also why we require a wildcard SSL cert -- so that a single cert can service all names.
     * Examples:
     * In the apache conf: https://github.com/broadinstitute/firecloud-develop/blob/dev/base-configs/agora/site.conf.ctmpl#L38
     * In the docker-compose: https://github.com/broadinstitute/firecloud-develop/blob/dev/run-context/live/configs/agora/proxy-compose.yaml.ctmpl#L27
 14. Cromwell "scaling"
   * Cromwell currently has a 1-1 relationship with a MySQL database. That means that if you want to run multiple Cromwells for load reasons, it's a "shard" approach. You can spin up another Cromwell but it won't have a shared database. Once a job is on one Cromwell it stays there in perpetuity.
   * Other than spinning up another Cromwell, rawls has to be told to use it: https://github.com/broadinstitute/firecloud-develop/blob/dev/base-configs/rawls/rawls.conf.ctmpl#L82 . These conf lines show an array full of Cromwells in Live Production environments. 
   * We have a beta going on (rolling into production 6/18) using Internal Google Load balancers and URL maps to have a Master-Read Cromwell scaling. This WILL enable Cromwell to have a single Writer and N readers so that if the Writer is overwhelmed, it won't break most of Firecloud/Rawls.
   * When Cromwell As A Service exists, one of its requirements is to have horizontal scalabiility across the board. The above are all stopgaps until that happens.
 19. Scaling everything else
   * As noted, most of our other functions can be scaled already but putting them behind Google load balancers with multiple instances. These include as of this writing: 
     * agora
     * thurloe
     * Orchestration
     * UI
     * rawls
     * sam
   * Leo has not been tested yet to be a Load Balanced service. We're pretty sure it works but unknown.
   * OpenDJ (part of the Sam suite) has it's own load balancing. It is not to be exposed to the outside world. Unless your load is very large, keep it on the Sam machine.
   * Elastic Search and Mongo have their own scaling/multi-node methodologies.
