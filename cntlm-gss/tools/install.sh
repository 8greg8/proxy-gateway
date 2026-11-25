#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-or-later
# install.sh
#
# This script copies the necessary files
# into another project so you can use the cntlm there.
#
# Usage:
#   ./tools/install.sh /path/to/target/project
#
# Notes:
# - Run this script from inside the repo.
# - The script will NOT overwrite files unless you pass --force.

set -euo pipefail

# --- Functions ---
usage() {
    echo "Usage: $0 [--force] <target_project_path>"
    exit 1
}

# --- Parse arguments ---
FORCE=false
if [[ $# -eq 0 ]]; then
    usage
fi

if [[ "$1" == "--force" ]]; then
    FORCE=true
    shift
fi

TARGET_DIR="${1:-}"
if [[ -z "$TARGET_DIR" ]]; then
    usage
fi

if [[ ! -d "$TARGET_DIR" ]]; then
    echo "❌ Target directory '$TARGET_DIR' does not exist."
    exit 1
fi

# --- Paths ---
SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_SRC="$SRC_DIR/data"
DOCKER_SRC="$SRC_DIR/docker-compose.yml"
ENV_SRC="$SRC_DIR/.env"

# --- Copy logic ---
copy_file_or_dir() {
    local src=$1
    local dest=$2

    if [[ -e "$dest" && $FORCE == false ]]; then
        echo "⚠️  Skipping $dest (already exists, use --force to overwrite)"
    else
        if [[ -d "$src" ]]; then
            echo "📂 Copying directory $src -> $dest"
            rsync -a --delete "$src/" "$dest/"
        else
            echo "📄 Copying file $src -> $dest"
            cp -f "$src" "$dest"
        fi
    fi
}

echo "🚀 Setting up wheel-builder in project: $TARGET_DIR"

copy_file_or_dir "$DATA_SRC" "$TARGET_DIR/data"
copy_file_or_dir "$DOCKER_SRC" "$TARGET_DIR/docker-compose.yml"
copy_file_or_dir "$ENV_SRC" "$TARGET_DIR/.env"

echo "✅ Done! cntlm-gss has been set up in '$TARGET_DIR'"
echo "👉 Next steps: adjust .env, data/secrets/ad_pass, and start with `docker compose up -d` ."
