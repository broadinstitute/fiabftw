# FiaB migrations

Document migrations here.  **This is only for fiabftw contributers and Firecloud developers, not fiabftw users!**

All migration scripts should begin with a number, incrementing from the last script.  
All migration scripts should be idempotent.

Migration scripts can utilize the following environment variables:
* `GOOGLE_PROJ`
* `GOOGLE_APPS_DOMAIN`
* `DNS_DOMAIN`
* `ADMIN_ACCT`
* `ENV`
* `VAULT_TOKEN`

## Migrations
* *001_requestor_pays_role_create* - create a RequestorPays role in the organzation with `serviceusage.services.use` permissions.
