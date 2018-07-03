#!/usr/bin/env bash

COMMAND=$1
HOST_NAME=$2
ALLOCATOR_URL=$3
GOOGLE_PROJ=$4
GOOGLE_APPS_DOMAIN=$5
DNS_DOMAIN=$6
ADMIN_EMAIL=$7
ENV=${8:-fiab}
VAULT_TOKEN=${9:-$(cat .vault-token-fiabftw)}
export VAULT_TOKEN=$VAULT_TOKEN

ADMIN_ACCT_PATH=admin-acct.json
CONFIGS_DIR=$PWD/fiab-configs
BASE_PATH="/"
HOST_PATH="/FiaB"
POPULATE_PATH="${HOST_PATH}/fiab-populate"
VAULT_CONFIG_PATH=/w/vault/vault-config.json
SSHCMD="ssh -o UserKnownHostsFile=/dev/null -o CheckHostIP=no -o StrictHostKeyChecking=no"


pull_configs() {
    ./initialize-secrets.sh $ENV

}
render_configs() {
    # render configs and copy them to the host
    mkdir -p FiaB
    export GOOGLE_PROJ=$GOOGLE_PROJ
    export GOOGLE_APPS_DOMAIN=$GOOGLE_APPS_DOMAIN
    export GOOGLE_APPS_SUBDOMAIN=$GOOGLE_APPS_DOMAIN
    export DNS_DOMAIN=$DNS_DOMAIN
    export CUSTOM_VAULT_CONFIG=$VAULT_CONFIG_PATH
    export BUCKET_TAG=${GOOGLE_PROJ}-${ENV}
    cp -r $CONFIGS_DIR/run-context/fiab/scripts/. FiaB/
    bash $CONFIGS_DIR/run-context/fiab/scripts/FiaB_configs.sh $PWD/FiaB $CONFIGS_DIR $VAULT_TOKEN $HOST_PATH $ENV Fiab_images.env $HOST_NAME fiab $VAULT_ADDR

}

start_fiab() {
    # Make sure the fiab host exists
    docker run --rm -v $PWD/output:/output \
        -v $PWD/${ADMIN_ACCT_PATH}:/root/service-acct.json \
        -e SERVICE_ACCT=/root/service-acct.json \
        -e GOOGLE_PROJ=${GOOGLE_PROJ} \
        -e FIAB_HOST=${HOST_NAME} \
        -e ALLOCATOR_URL=${ALLOCATOR_URL} \
        broadinstitute/dsp-toolbox fiab list

    HOST_IP=$(cat output/host.json | jq '.ip' --raw-output)

    # Copy configs to fiab host
    $SSHCMD root@$HOST_IP "mkdir -p /FiaB"
    rsync -r -e "${SSHCMD}" FiaB/ root@$HOST_IP:$HOST_PATH
    $SSHCMD root@$HOST_IP "cp -rfp /etc/localtime $HOST_PATH"

    # sad hack
    $SSHCMD root@$HOST_IP "sudo chmod -R 777 $HOST_PATH/es || echo "cannot change file perms for $HOST_PATH/es/elasticsearch""
    $SSHCMD root@$HOST_IP "sudo sysctl -w vm.max_map_count=262144 || echo "cannot set vm.max_map_count""
    $SSHCMD root@$HOST_IP "bash $HOST_PATH/start_FiaB.sh $HOST_PATH"

    # Allocate fiab as "in use"
    docker run --rm -v $PWD/output:/output \
        -v $PWD/${ADMIN_ACCT_PATH}:/root/service-acct.json \
        -e SERVICE_ACCT=/root/service-acct.json \
        -e GOOGLE_PROJ=${GOOGLE_PROJ} \
        -e FIAB_HOST=${HOST_NAME} \
        -e ALLOCATOR_URL=${ALLOCATOR_URL} \
        broadinstitute/dsp-toolbox fiab start-fiab

}

stop_fiab() {
    # Make sure the fiab host exists
    docker run --rm -v $PWD/output:/output \
        -v $PWD/${ADMIN_ACCT_PATH}:/root/service-acct.json \
        -e SERVICE_ACCT=/root/service-acct.json \
        -e GOOGLE_PROJ=${GOOGLE_PROJ} \
        -e FIAB_HOST=${HOST_NAME} \
        -e ALLOCATOR_URL=${ALLOCATOR_URL} \
        broadinstitute/dsp-toolbox fiab listt 1
    HOST_IP=$(cat output/host.json | jq '.ip' --raw-output)

    $SSHCMD root@$HOST_IP "bash $HOST_PATH/stop_FiaB.sh $HOST_PATH"

    # Deallocate the fiab
    docker run --rm -v $PWD/output:/output \
        -v $PWD/${ADMIN_ACCT_PATH}:/root/service-acct.json \
        -e SERVICE_ACCT=/root/service-acct.json \
        -e GOOGLE_PROJ=${GOOGLE_PROJ} \
        -e FIAB_HOST=${HOST_NAME} \
        -e ALLOCATOR_URL=${ALLOCATOR_URL} \
        broadinstitute/dsp-toolbox fiab stop-fiab


}

clear_db() {
    $SSHCMD root@$HOST_IP "sudo rm -rf $HOST_PATH/mysqlstore/ $HOST_PATH/mongostore/ $HOST_PATH/es/ $HOST_PATH/opendjstore/ $HOST_PATH/ldapstore/"

}

populate_fiab() {
    $SSHCMD root@$HOST_IP "sudo bash $POPULATE_PATH/basic-populate-fiab.sh $POPULATE_PATH $VAULT_TOKEN $ENV $DNS_DOMAIN $GOOGLE_PROJ $VAULT_ADDR"
    $SSHCMD root@$HOST_IP "sudo bash $POPULATE_PATH/populate-consent-and-ontology.sh $POPULATE_PATH $VAULT_TOKEN $ENV $GOOGLE_APPS_DOMAIN $ADMIN_EMAIL $DNS_DOMAIN $VAULT_ADDR"

}

docker pull broadinstitute/dsp-toolbox
if [ $COMMAND = "start" ]; then
    echo "starting fiab"
    pull_configs
    render_configs
    start_fiab
    echo "Sleeping for 4 minutes during fiab start..."
    sleep 240
    populate_fiab

elif [ $COMMAND = "stop" ]; then
    echo "stopping fiab"
    stop_fiab
    clear_db

else
    echo "Not a valid command.  Try either 'start' or 'stop'"
fi
