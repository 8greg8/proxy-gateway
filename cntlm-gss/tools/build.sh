#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later

# -----------------------------------------------------
# Copyright (C) 2025 Gregor Koporec
# 
# Unauthorized copying of this file, via any medium is strictly prohibited.
# Proprietary and confidential.
# -----------------------------------------------------

# -----------------------------------------------------
# Build Python wheels
#
# Author: Gregor Koporec
# Date: 2025-12-05
#
# Usage:
#	cd <project_root>
#	.tools/build.sh
# Notes:
#
# ----------------------------------------------------
# Change Log:
# 2023-04-26: Initial fork
# 2024-05-22: v2.4
# 2025-12-05: v3.0
# ----------------------------------------------------

# Configurable variables
# ----------------------------------------------------
DOCKER_VERSION=3.0.0        # Docker version
BUILD_ARCH=amd64            # Options: amd64 or arm64
TRUSTED_INTERNAL_HOST="github.com"
#INTERNAL_CERTS="corporate_root_ca.crt ciscoproxy.crt" # folder of certificates
# ----------------------------------------------------

# Derived variables
# ----------------------------------------------------
# Convert BUILD_ARCH to platform-compatible architecture
case "$BUILD_ARCH" in
  amd64)
    TARGET_PLATFORM="linux/amd64"
    ;;
  arm64)
    TARGET_PLATFORM="linux/arm64"
    ;;
  *)
    echo "Unsupported BUILD_ARCH: $BUILD_ARCH"
    exit 1
    ;;
esac
IMAGE_NAME=cntlm-gss:$DOCKER_VERSION-$BUILD_ARCH

# Step 0: Build docker image
echo "Building Docker image for project $(pwd)..." &&
docker build \
    --platform $TARGET_PLATFORM \
    --network=host \
    --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
    --build-arg BUILD_VERSION=$DOCKER_VERSION \
    --build-arg BUILD_ARCH=$BUILD_ARCH \
    --build-arg TRUSTED_INTERNAL_HOST=$TRUSTED_INTERNAL_HOST \
    --build-arg INTERNAL_CERTS=$INTERNAL_CERTS \
    --build-arg HTTP_PROXY=$http_proxy --build-arg http_proxy=$http_proxy \
    --build-arg HTTPS_PROXY=$http_proxy --build-arg https_proxy=$http_proxy \
    --build-arg NO_PROXY="$no_proxy" --build-arg no_proxy="$no_proxy" \
    -t $IMAGE_NAME -f ./Dockerfile . &&

echo "✅ Build process completed successfully."

# Old code
# ----------------------------------------------------
# docker build \
#     --no-cache \
#     --progress=plain \
#     --network=host \
#     --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
#     --build-arg BUILD_VERSION=$VERSION \
#     -t cntlm-gss:$VERSION . \
#     &> build.log

# docker build \
#     --no-cache \
#     --network=host \
#     --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
#     --build-arg BUILD_VERSION=$VERSION \
#     -t cntlm-gss:$VERSION .

# docker buildx build \
#     --platform=linux/amd64 \
#     --allow network.host \
#     --network=host \
#     --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
#     --build-arg BUILD_VERSION=$VERSION \
#     -t cntlm-gss:$VERSION-amd64 -o type=docker,name=cntlm-gss:$VERSION-amd64,dest=cntlm-gss_$VERSION-amd64.tar .

# docker buildx build \
#     --platform=linux/arm64 \
#     --allow network.host \
#     --network=host \
#     --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
#     --build-arg BUILD_VERSION=$VERSION \
#     -t cntlm-gss:$VERSION-arm64 -o type=docker,name=cntlm-gss:$VERSION-arm64,dest=cntlm-gss_$VERSION-arm64.tar .

