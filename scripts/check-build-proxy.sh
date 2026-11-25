#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2025 Gregor Koporec
#
# Show which proxy variables Docker passes into a build (uses the daemon and client proxy settings).
set -euo pipefail
docker build --no-cache --progress=plain - <<'DOCKERFILE'
FROM alpine
RUN env | grep -i _PROXY || echo "no proxy variables set"
DOCKERFILE
