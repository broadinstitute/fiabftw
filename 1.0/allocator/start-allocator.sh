#!/bin/bash
set -e

pushd /allocator >/dev/null

docker-compose -p allocator pull
docker-compose -p allocator stop
docker-compose -p allocator rm -vf
docker-compose -p allocator up -d

popd >/dev/null
