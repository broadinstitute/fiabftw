#!/bin/bash
set -e

pushd /vault >/dev/null

docker-compose -p vault pull
docker-compose -p vault stop
docker-compose -p vault rm -vf
docker-compose -p vault up -d

popd >/dev/null

echo
echo "IMPORTANT! In order for vault to be usable by anyone - you must unseal vault "
echo "  using 3 of the 5 unseal keys!!"
echo
