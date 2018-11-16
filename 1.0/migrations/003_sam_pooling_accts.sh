#!/usr/bin/env bash

accounts=(1 2 3)
scopes="https://www.googleapis.com/auth/admin.directory.group,https://www.googleapis.com/auth/admin.directory.user,https://www.googleapis.com/auth/apps.groups.setting"

create_acct() {
    name=$1
    vault_name=$2
    vault_path=$3
    gcloud iam service-accounts create --project=${GOOGLE_PROJ} ${name} --display-name ${name}
    gcloud iam service-accounts keys create \
        $PWD/${vault_name}.json \
        --iam-account "${name}@${GOOGLE_PROJ}.iam.gserviceaccount.com"
    vault write ${vault_path} @${PWD}/${vault_name}.json

}

check_for_acct() {
    name=$1

    echo "Checking for $name@${GOOGLE_PROJ}.iam.gserviceaccount.com..."
    list_exit_code=0
    gcloud iam service-accounts list --project=${GOOGLE_PROJ} --no-user-output-enabled || list_exit_code=$?
    if [ $list_exit_code -ne 0 ]; then
        echo "Something went wrong during gcloud iam service-accounts list."
        exit 1
    else
        gcloud iam service-accounts list --project=${GOOGLE_PROJ} | grep $name
        acct_exists=$?
    fi


}

for acct in "${accounts[@]}"
do
    n=`expr $acct - 1`
    gcloud_name=directory-account-${acct}
    vault_name=service_account_$n
    acct_exists=0
    check_for_acct $gcloud_name

    if [ $acct_exists -ne 0 ]; then
        echo "$name not found. Creating..."

        create_acct $gcloud_name $vault_name secret/dsde/firecloud/$ENV/sam/service_accounts/${vault_name}

        read -r -p "$(echo -e "[MANUAL STEP] $(tput bold)Enable Domain-wide Delegation on $gcloud_name in the GCloud console.$(tput sgr0) \nFor further instructions, see https://github.com/broadinstitute/fiabftw/blob/master/1.0/README.md#manual-step-enable-domain-wide-delegation.  \nDone? [Y/n] ")" resp
        if [ "$resp" != "Y" ]; then
            exit 1
        fi

        client_id=$(cat $PWD/${vault_name}.json | jq -r '.client_id')
        read -r -p "$(echo -e "[MANUAL STEP] $(tput bold)In the GSuite Admin Console, give the below account client_id the following API scopes: \n$(tput setaf 1)$client_id: $scopes$(tput sgr0) \nFor futher instructions, see https://github.com/broadinstitute/fiabftw/tree/master/1.0#manual-step-authorize-api-scopes.  \nDone? [Y/n] ")" resp
        if [ "$resp" != "Y" ]; then
            exit 1
        fi

        echo "...done"
        printf "\n"
    fi

done
