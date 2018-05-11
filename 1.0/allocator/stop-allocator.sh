#!/bin/bash

pushd /allocator >/dev/null

docker-compose -p allocator stop
docker-compose -p allocator rm -vf

popd >/dev/null
