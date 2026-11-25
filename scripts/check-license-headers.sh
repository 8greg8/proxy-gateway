#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2025 Gregor Koporec
#
# Every own file outside cntlm-gss/ must carry an SPDX license identifier.
set -euo pipefail
cd "$(dirname "$0")/.."
missing=0
while IFS= read -r f; do
  head -5 "$f" | grep -q 'SPDX-License-Identifier:' || { echo "missing SPDX header: $f"; missing=1; }
done < <(git ls-files 'scripts/*' 'tests/*' 'systemd/*' 'etc/*' 'compose.yml' '.github/workflows/*' | grep -v '\.md$')
exit $missing
