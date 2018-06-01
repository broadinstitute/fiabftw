#!/usr/bin/env bash

GOOGLE_PROJ=$1
ENV=${2:-fiab}

gcloud compute --project=$GOOGLE_PROJ firewall-rules create fiab --target-tags=fiab --allow tcp:23800,tcp:22800, tcp:20443, tcp:21443, tcp:22443,tcp:23443,tcp:24443,tcp:25443,tcp:26443,tcp:27443,tcp:28443,tcp:29443,tcp:30443
