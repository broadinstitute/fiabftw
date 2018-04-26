# OAuth Credentials

Oauth credentials need to be manually created in gcloud (due to security vulnerabilities of exposing that API)

## Create credentials in gcloud

In the google console, go to APIs & Services -> Credentials. Click "Create credentials" and select "OAuth client ID"

![Alt text](../screenshots/create_oauth_credentials.png "Create Oauth Credentials")

For application type select "Web application".  Then for each required credential, you will create a name and add the required Authorized JavaScript origins and Authorized redirect URIs.  

Service | Name | Authorized Javascript Origins | Authorized redirect URIs
--- | --- | --- | ---
rawls | Rawls Oauth Credential | https://rawls-fiab.[domain] <br> https://rawls-fiab.[domain]:24443 | https://rawls-fiab.[domain]/oauth2callback <br> https://rawls-fiab.[domain]/o2c.html <br> https://rawls-fiab.[domain]:24443/oauth2callback <br> https://rawls-fiab.[domain]:24443/o2c.html
consent | Consent Oauth Credential | https://duos-fiab.[domain] <br> https://duos-fiab.[domain]:26443 <br> https://consent-fiab.[domain] <br> https://consent-fiab.[domain]:27443 | https://duos-fiab.[domain]/oauth2callback <br> https://duos-fiab.[domain]:26443/oauth2callback <br> https://consent-fiab.[domain]/oauth2callback <br> https://consent-fiab.[domain]:27443/oauth2callback <br> https://consent-fiab.[domain]:27443/api <br> https://consent-fiab.[domain]:27443/swagger/o2c.html <br> https://consent-fiab.[domain]:27443
leonardo | Leonardo Oauth Credential | https://leonardo-fiab.[domain] <br> https://leonardo-fiab.[domain]:30443 | https://leonardo-fiab.[domain]/oauth2callback <br> https://leonardo-fiab.[domain]:30443/oauth2callback <br> https://leonardo-fiab.[domain]/o2c.html <br> https://leonardo-fiab.[domain]:30443/o2c.html
common refresh token | Refresh Token Oauth Credential | https://firecloud.[domain] <br> https://firecloud-fiab.[domain] <br> https://firecloud-fiab.[domain]:22443 | https://firecloud-orchestration.[domain]/oauth2callback <br> https://firecloud-orchestration.[domain]/o2c.html <br> https://firecloud.[domain]/ <br> https://firecloud-fiab.[domain]/ <br> https://firecloud-fiab.[domain]:22443



## Store credentials in Vault

In the gcloud API Credentials UI, download the json client secret for each credential.  Pass the absolute path of the json file to the script below.

```$xslt
./oauth/add-oauth-creds-to-vault.sh rawls [path-to-json] [env]
./oauth/add-oauth-creds-to-vault.sh consent [path-to-json] [env]
./oauth/add-oauth-creds-to-vault.sh leonardo [path-to-json] [env]
./oauth/add-oauth-creds-to-vault.sh common [path-to-json] [env]
```

