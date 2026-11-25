#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2025 Gregor Koporec
# Sandbox tests for scripts/update-proxy. No root needed: every path lives under $ROOT.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
UP="$HERE/../scripts/update-proxy"
EX="$HERE/../etc/proxy.conf.example"
fail=0
ok()  { echo "ok   - $1"; }
bad() { echo "FAIL - $1"; fail=1; }
t()   { if eval "$2"; then ok "$1"; else bad "$1"; fi; }

new_root() { ROOT="$(mktemp -d)"; export ROOT; mkdir -p "$ROOT/etc"; cp "$EX" "$ROOT/etc/proxy.conf"; }
run() { "$UP" "$@" >"$ROOT/out.txt" 2>"$ROOT/err.txt"; }

new_root
printf 'PATH="/usr/bin:/bin"\nHTTP_PROXY=http://old:1\nDOCKER_PROXY=http://old:1\n' > "$ROOT/etc/environment"
printf '[user]\n\tname = keep\n' > "$ROOT/etc/gitconfig"
SECRET="s3cret-$$"; mkdir -p "$ROOT/data/secrets"; echo "$SECRET" > "$ROOT/data/secrets/ad_pass"

run; t "apply succeeds" '[[ $? -eq 0 ]]'
t "profile.d written" 'grep -q "http://127.0.0.1:3128" "$ROOT/etc/profile.d/proxy.sh"'
t "docker drop-in written" 'grep -q "^Environment=\"HTTPS_PROXY=http://127.0.0.1:3128\"" "$ROOT/etc/systemd/system/docker.service.d/http-proxy.conf"'
t "apt written" 'grep -q "Acquire::https::Proxy" "$ROOT/etc/apt/apt.conf.d/95proxy"'
t "environment keeps unrelated lines" 'grep -q "^PATH=" "$ROOT/etc/environment"'
t "environment drops legacy proxy lines" '! grep -q "http://old:1" "$ROOT/etc/environment"'
t "environment has docker proxy for containers" 'grep -q "^DOCKER_PROXY=http://cntlm:3128" "$ROOT/etc/environment"'
t "git config proxy set, other keys kept" 'git config --file "$ROOT/etc/gitconfig" http.proxy | grep -q 127.0.0.1 && grep -q "name = keep" "$ROOT/etc/gitconfig"'
t "docker restart is only announced" 'grep -q "systemctl restart docker" "$ROOT/err.txt"'
t "secret never in derived files or output" '! grep -rq "$SECRET" "$ROOT/etc" "$ROOT/out.txt" "$ROOT/err.txt"'

run; t "second run is a no-op" 'grep -q "no changes" "$ROOT/out.txt"'
run --check; t "--check clean after apply" '[[ $? -eq 0 ]]'

sed -i 's/^PROXY_PORT=.*/PROXY_PORT=3129/' "$ROOT/etc/proxy.conf"
run --check; t "--check detects drift (exit 1)" '[[ $? -eq 1 ]]'
before="$(cat "$ROOT/etc/profile.d/proxy.sh")"
run --dry-run; t "--dry-run shows a diff" 'grep -q "^+.*3129" "$ROOT/out.txt"'
t "--dry-run changes nothing" '[[ "$(cat "$ROOT/etc/profile.d/proxy.sh")" == "$before" ]]'
run; t "apply follows config change" 'grep -q ":3129" "$ROOT/etc/profile.d/proxy.sh"'

run --off; t "--off removes generated files" '[[ ! -e "$ROOT/etc/profile.d/proxy.sh" && ! -e "$ROOT/etc/apt/apt.conf.d/95proxy" && ! -e "$ROOT/etc/systemd/system/docker.service.d/http-proxy.conf" ]]'
t "--off clears the environment block, keeps PATH" '! grep -q PROXY "$ROOT/etc/environment" && grep -q "^PATH=" "$ROOT/etc/environment"'
t "--off removes git proxy, keeps other keys" '! git config --file "$ROOT/etc/gitconfig" http.proxy >/dev/null && grep -q "name = keep" "$ROOT/etc/gitconfig"'
sed -i 's/^PROXY_ENABLED=.*/PROXY_ENABLED=false/' "$ROOT/etc/proxy.conf"; run
t "PROXY_ENABLED=false is a no-op once off" 'grep -q "no changes" "$ROOT/out.txt"'
rm -rf "$ROOT"

bad_conf() { new_root; printf '%s\n' "$2" >> "$ROOT/etc/proxy.conf"; run; rc=$?; [[ $rc -eq 2 && ! -e "$ROOT/etc/profile.d/proxy.sh" ]] && ok "$1" || bad "$1 (rc=$rc)"; rm -rf "$ROOT"; }
bad_conf "rejects unknown key" 'EVIL=1'
bad_conf "rejects spaces in value" 'NO_PROXY=a b'
bad_conf "rejects quotes" 'NO_PROXY="a"'
bad_conf "rejects command substitution" 'NO_PROXY=$(touch /tmp/pwned)'
bad_conf "rejects line continuation" 'NO_PROXY=a,\'
bad_conf "rejects non-key line" 'just text'
new_root; sed -i 's/^PROXY_PORT=.*/PROXY_PORT=99999/' "$ROOT/etc/proxy.conf"; run; t "rejects bad port" '[[ $? -eq 2 ]]'; rm -rf "$ROOT"
new_root; sed -i '/^PROXY_HOST=/d' "$ROOT/etc/proxy.conf"; run; t "rejects missing key" '[[ $? -eq 2 ]]'; rm -rf "$ROOT"
[[ ! -e /tmp/pwned ]] && ok "no command was executed" || bad "command was executed"

exit $fail
