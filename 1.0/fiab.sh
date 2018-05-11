#!/usr/bin/env bash

COMMAND=$1
HOST_NAME=$2
ALLOCATOR_URL=$3
GOOGLE_PROJ=$4
GOOGLE_APPS_DOMAIN=$5
DNS_DOMAIN=$6
ENV=${7:-fiab}
VAULT_TOKEN=${8:-$(cat .vault-token-fiabftw)}
export VAULT_TOKEN=$VAULT_TOKEN

CONFIGS_DIR=$PWD/fiab-configs
BASE_PATH="/"
HOST_PATH="/FiaB"
POPULATE_PATH="${HOST_PATH}/fiab-populate"
VAULT_CONFIG_PATH=/w/vault-config.json
SSHCMD="ssh -o UserKnownHostsFile=/dev/null -o CheckHostIP=no -o StrictHostKeyChecking=no"


render_configs() {
    # render configs and copy them to the host
    mkdir -p FiaB
    export GOOGLE_PROJ=$GOOGLE_PROJ
    export GOOGLE_APPS_DOMAIN=$GOOGLE_APPS_DOMAIN
    export GOOGLE_APPS_SUBDOMAIN=$GOOGLE_APPS_DOMAIN
    export DNS_DOMAIN=$DNS_DOMAIN
    export CUSTOM_VAULT_CONFIG=$VAULT_CONFIG_PATH
    cp -r $CONFIGS_DIR/run-context/fiab/scripts/. FiaB/
    bash $CONFIGS_DIR/run-context/fiab/scripts/FiaB_configs.sh $PWD/FiaB $CONFIGS_DIR $VAULT_TOKEN $HOST_PATH $ENV Fiab_images.env $HOST_NAME fiab $VAULT_ADDR

}

start_fiab() {
    # Make sure the fiab host exists
    response=$(curl -X GET --write-out "%{http_code}\n" --silent --output "allocator-get.json" $ALLOCATOR_URL/resources/$HOST_NAME)
    if [ $response -ne 200 ]; then
        echo "FiaB host not found!"
        cat allocator-get.json
        exit 1
    fi
    HOST_IP=$(cat allocator-get.json | jq '.ip' --raw-output)

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
        -e GOOGLE_PROJ=${GOOGLE_PROJ} \
        -e FIAB_HOST=${HOST_NAME} \
        -e ALLOCATOR_URL=${ALLOCATOR_URL} \
        broadinstitute/dsp-toolbox:allocator fiab start-fiab

}

if [ $COMMAND = "start" ]; then
    render_configs
    start_fiab

elif [ $COMMAND = "stop" ]; then
    echo "stopping fiab"
    # TODO

else
    echo "Not a valid command.  Try either 'start' or 'stop'"
fi
