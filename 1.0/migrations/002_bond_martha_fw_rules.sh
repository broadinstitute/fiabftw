#!/usr/bin/env bash

ifContainsFwRule() {
    port=$1
    command=$(gcloud compute --project=${GOOGLE_PROJ} firewall-rules describe fiab --format=json | jq '.allowed' | grep $port)
    echo $?
}

if_bond_port=$(ifContainsFwRule 31443)
if_martha_port=$(ifContainsFwRule 32443)

if [[ $if_bond_port != 0 || $if_martha_port != 0 ]]; then
    echo "Updating firewall rules to include bond (tcp:31443) and martha (tcp:32443)..."
    gcloud compute --project=${GOOGLE_PROJ} firewall-rules update fiab --allow tcp:23800,tcp:22800,tcp:20443,tcp:21443,tcp:22443,tcp:23443,tcp:24443,tcp:25443,tcp:26443,tcp:27443,tcp:28443,tcp:29443,tcp:30443,tcp:31443,tcp:32443
    echo "...done."
else
    echo "Skipping migration 002_bond_martha_fw_rules"
    echo "DONE"
fi
