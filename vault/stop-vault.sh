#!/bin/bash

pushd /app >/dev/null

docker-compose -p vault stop
docker-compose -p vault rm -vf

popd >/dev/null
