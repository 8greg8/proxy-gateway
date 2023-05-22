#!/bin/bash
VERSION=2.3

:'
docker build \
    --no-cache \
    --progress=plain \
    --network=host \
    --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
    --build-arg BUILD_VERSION=$VERSION \
    -t cntlm-gss:$VERSION . \
    &> build.log
'
docker build \
    --no-cache \
    --network=host \
    --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
    --build-arg BUILD_VERSION=$VERSION \
    -t cntlm-gss:$VERSION .