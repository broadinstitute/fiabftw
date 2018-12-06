#!/bin/bash

set -e

# Make FiaB dir where everything is stored.
ROOTDIR=~/FiaB
SOURCEDIR=~/firecloud-develop
ROOTDIR=${1:-$ROOTDIR}
mkdir -p $ROOTDIR
mkdir -p $ROOTDIR/mysqlstore
mkdir -p $ROOTDIR/mongostore
mkdir -p $ROOTDIR/mongostorerepl
mkdir -p $ROOTDIR/es
mkdir -p $ROOTDIR/ldapstore
cp -rfp /etc/localtime $ROOTDIR

SOURCEDIR=${2:-$SOURCEDIR}
VAULT_TOKEN=${3:-$(cat ~/.vault-token)}
FIAB_PATH=${4:-$ROOTDIR}  # absolute path for volumes in compose
ENV=${5:-dev}

ENV_FILE=${6:-run-context/fiab/scripts/FiaB_images.env}

HOST_TAG=${7:-fiab}

GCS_NAME_PREFIX=${8:-""}
VAULT_ADDR=${9:-https://clotho.broadinstitute.org:8200}

function get_image_name() {
    service=$(echo $1 | tr "-" "_")
    varname=${service}_img
    echo ${!varname}
}

function checkout_branch() {
    service=$1
    branch=$2
    if [ $branch != "dev" ] && [ $branch != "alpha" ] && [ $branch != "staging" ] && [ $branch != "prod" ]; then
        cd $service
        git checkout $branch
        cd ..
    fi

}

function timeout() { perl -e 'alarm shift; exec @ARGV' "$@"; }

function render_configs() {
    APP_NAME=$1
    INSTANCE_NAME=${APP_NAME}-fiab
    INSTANCE_TYPE=""
    if [ $CONFIG == "cromwell" ]; then
        INSTANCE_TYPE=cromwell1
    elif [ $CONFIG == "rawls" ]; then
        INSTANCE_TYPE=backend
    fi

    SERVICE_VERSION=""
    if [ $CONFIG == "bond" ]; then
        SERVICE_VERSION=2018-01-01r0
    fi

    retries=2
    exit_code=0
    while [ $retries -ge 0 ]; do
        # fail condition
        if [ $retries -eq 0 ]; then
            echo "[ERROR] Ran out of retries without successful config render for $APP_NAME."
            exit 1
        fi

        # Hack: Need to set TARGET_DOCKER_VERSION to something, but it's not currently used
        #       for fiab at this time (20180403)
        TARGET_DOCKER_VERSION="NOT_USED_FOR_FIAB_AS_OF_20180403"

        export VAULT_TOKEN="${VAULT_TOKEN}" \
            APP_NAME="${APP_NAME}" \
            ENV="${ENV}" \
            TARGET_DOCKER_VERSION="${TARGET_DOCKER_VERSION}" \
            INPUT_DIR="${SOURCEDIR}" \
            OUTPUT_DIR="${ROOTDIR}/${APP_NAME}" \
            RUN_CONTEXT="fiab" \
            FIAB_DIR="${FIAB_PATH}" \
            INSTANCE_TYPE="${INSTANCE_TYPE}" \
            INSTANCE_NAME="${INSTANCE_NAME}" \
            HOST_TAG="${HOST_TAG}" \
            IMAGE="${IMAGE}" \
            GCS_NAME_PREFIX="${GCS_NAME_PREFIX}" \
            VAULT_ADDR="${VAULT_ADDR}" \
            CUSTOM_VAULT_CONFIG="${CUSTOM_VAULT_CONFIG}" \
            GOOGLE_APPS_DOMAIN="${GOOGLE_APPS_DOMAIN}" \
            GOOGLE_APPS_ORGANIZATION_ID="${GOOGLE_APPS_ORGANIZATION_ID}" \
            GOOGLE_APPS_SUBDOMAIN="${GOOGLE_APPS_SUBDOMAIN}" \
            GOOGLE_PROJ="${GOOGLE_PROJ}" \
            DNS_DOMAIN="${DNS_DOMAIN}" \
            BUCKET_TAG="${BUCKET_TAG}" \
            SERVICE_VERSION="${SERVICE_VERSION}"
        timeout 60 $SOURCEDIR/configure.rb || exit_code=$?

        if [ $exit_code -eq 124 ]; then
            echo "[WARN] Timed out rendering configs for $APP_NAME.  Retrying..."
            sleep 5
            retries=$((retries-1))
        elif [ $exit_code -eq 0 ]; then
            echo "done rendering $APP_NAME configs"
            break
        else
            echo "[ERROR] Config rendering for $APP_NAME failed with exit code $exit_code."
            exit 1
        fi
    done

}
source $ENV_FILE

#go through each of the firecloud-develop:fiab_lite projects and build
for CONFIG in agora cromwell firecloud-ui firecloud-orchestration rawls thurloe elasticsearch consent-ui consent consent-ontology sam leonardo bond martha
do
    echo "running $CONFIG"
    mkdir -p $ROOTDIR/$CONFIG
    IMAGE=$(get_image_name $CONFIG)
    render_configs $CONFIG

    mkdir -p $ROOTDIR/mysqlstore/$CONFIG
    mkdir -p $ROOTDIR/mongostore/$CONFIG
    mkdir -p $ROOTDIR/mongostorerepl/$CONFIG
    mkdir -p $ROOTDIR/es/$CONFIG
    mkdir -p $ROOTDIR/ldapstore/$CONFIG

    if [ $CONFIG == "elasticsearch" ]
      then
        echo "Making elasticsearch files world-readable"
        chmod -R a+r $ROOTDIR/$CONFIG

    elif [ $CONFIG == "agora" ]
      then
        echo "Special $CONFIG Stuff"
        checkout_branch $CONFIG $IMAGE
        mkdir -p $ROOTDIR/$CONFIG/src
        cp -rfp $SOURCEDIR/$CONFIG/src/main/resources/db/migration $ROOTDIR/$CONFIG/src

    elif [ $CONFIG == "thurloe" ]
      then
        echo "Special $CONFIG Stuff"
        checkout_branch $CONFIG $IMAGE
        mkdir -p $ROOTDIR/$CONFIG/src
        cp -rfp $SOURCEDIR/$CONFIG/src/main/migrations $ROOTDIR/$CONFIG/src

    elif [ $CONFIG == "consent" ]
      then
        echo "Special $CONFIG stuff"
        checkout_branch $CONFIG $IMAGE
        mkdir -p $ROOTDIR/$CONFIG/src
        cp -rfp $SOURCEDIR/$CONFIG/src/main/resources $ROOTDIR/$CONFIG/src

    elif [ $CONFIG == "firecloud-ui" ]
      then
        echo "Making firecloud-ui files world-readable"
        chmod -R a+r $ROOTDIR/$CONFIG
      
    fi

done
