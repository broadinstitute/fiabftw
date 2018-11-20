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
SSHCMD="gcloud compute --project ${GOOGLE_PROJ} ssh root@${HOST_NAME}"


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
    bash $CONFIGS_DIR/run-context/fiab/scripts/FiaB_configs.sh $PWD/FiaB $CONFIGS_DIR $VAULT_TOKEN $HOST_PATH $ENV FiaB_images.env $HOST_NAME fiab $VAULT_ADDR

}

start_fiab() {
    # Make sure the fiab host exists
    echo "Name: ${HOST_NAME}"
    # Copy configs to fiab host
    echo "Copying FiaB directory to host"
    gcloud compute --project ${GOOGLE_PROJ} scp --recurse --scp-flag='-q' FiaB root@${HOST_NAME}:/

    echo "Localtime & ES hacks..."
    $SSHCMD --command="cp -rfp /etc/localtime $HOST_PATH"

    # sad hack
    $SSHCMD --command="sudo chmod -R 777 $HOST_PATH/es || echo 'cannot change file perms for $HOST_PATH/es/elasticsearch'"
    $SSHCMD --command="sudo sysctl -w vm.max_map_count=262144 || echo 'cannot set vm.max_map_count'"
    
    echo "Running start_FiaB.sh on host"
    $SSHCMD --command="bash $HOST_PATH/start_FiaB.sh $HOST_PATH"

    echo "Running dsp-toolbox start-fiab"
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
        broadinstitute/dsp-toolbox fiab list
    HOST_IP=$(cat output/host.json | jq '.ip' --raw-output)

    
    $SSHCMD --command="bash $HOST_PATH/stop_FiaB.sh $HOST_PATH"

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
    echo "Clearing DB on host"
    $SSHCMD --command="sudo rm -rf $HOST_PATH/mysqlstore/ $HOST_PATH/mongostore/ $HOST_PATH/es/ $HOST_PATH/opendjstore/ $HOST_PATH/ldapstore/"

}

populate_fiab() {
    echo "Running basic-populate-fiab.sh on host"
    $SSHCMD --command="sudo bash $POPULATE_PATH/basic-populate-fiab.sh $POPULATE_PATH $VAULT_TOKEN $ENV $DNS_DOMAIN $GOOGLE_PROJ $VAULT_ADDR"
    echo "Running populate-consent-and-ontology.sh on host"
    $SSHCMD --command="sudo bash $POPULATE_PATH/populate-consent-and-ontology.sh $POPULATE_PATH $VAULT_TOKEN $ENV $GOOGLE_APPS_DOMAIN $ADMIN_EMAIL $DNS_DOMAIN $VAULT_ADDR"

}

unpopulate_fiab() {
    echo "Running basic-unpopulate-fiab.sh on host"
    $SSHCMD --command="sudo bash $POPULATE_PATH/basic-unpopulate-fiab.sh $POPULATE_PATH $VAULT_TOKEN $ENV"

}

docker pull broadinstitute/dsp-toolbox
if [ $COMMAND = "start" ]; then
    echo "fiab.sh start"
    echo "Rendering configs"
    render_configs
    echo "Starting fiab"
    start_fiab
    echo "Sleeping for 4 minutes during fiab start..."
    sleep 240
    echo "Populating fiab"
    populate_fiab

elif [ $COMMAND = "stop" ]; then
    echo "fiab.sh stop"
    stop_fiab

elif [ $COMMAND = "stopclear" ]; then
    echo "fiab.sh stopclear"
    echo "Unpopulating fiab"
    unpopulate_fiab
    echo "Stopping fiab"
    stop_fiab
    echo "Clearing DB"
    clear_db
else
    echo "Not a valid command.  Try either 'start' or 'stop'"
fi
