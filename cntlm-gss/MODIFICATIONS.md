# Modifications to the upstream sources

This directory is a fork of <https://github.com/maksteel/cntlm-gss-docker> (Manish Kukreja, GPLv2, November 2019), which
combines Cntlm 0.92.3 (<http://cntlm.sourceforge.net>, David Kubicek and contributors) with the Kerberos (GSSAPI)
authentication patch `201211-cntlm-kerberos-authentication.patch`. As GPLv2 section 2(a) requires, this file states what was
changed, by whom and when. Authors and dates come from the git history. The changes are by **Gregor Koporec** unless stated otherwise.

The fork point is the commit "moving OBJS above, to make patch compatible" ... "steps to run" (`5e2fde5` in the original
repository, 2019-11-22 to 2019-11-25). Nothing from the original repository's final commit (adding the LICENSE file, which is
identical to the one here) is missing.

## Changes to upstream files

| File | When | Change |
|---|---|---|
| `cntlm-0.92.3/Makefile` | 2023-04-26 | Build `kerberos.o` and link `-lgssapi_krb5` when `ENABLE_KERBEROS` is set in `config/config.h`; add a default `all` target; a commented `-g` flag |
| `cntlm-0.92.3/configure` | 2023-04-26 | Print "Enabling kerberos" for `--enable-kerberos` |
| `cntlm-0.92.3/doc/cntlm.1` | 2026-11-25 | Two example subnet addresses replaced by addresses from the documentation range `192.0.2.0/24` |
| `cntlm-0.92.3/doc/cntlm.conf` | 2026-11-25 | Example addresses replaced by host names `proxy1.example.com` and `proxy2.example.com`; `127.0.0.1` replaced by `localhost` |
| `cntlm-0.92.3/rpm/cntlm.init` | 2026-11-25 | `127.0.0.1` replaced by `localhost` in the default listen address |
| `201211-cntlm-kerberos-authentication.patch` | 2026-11-25 | The same example address replacement inside the patch text (the patch is kept for reference; the tree already has it applied) |

## Files by the fork author, derived from the original repository (GPL-2.0-or-later)

| File | When | Change |
|---|---|---|
| `Dockerfile` | 2023-04-26 to 2025-12-05, 2026-11-25 | Rewritten for a small Alpine-based image, Cntlm built with Kerberos, keytab creation and ticket renewal, `conf/` and `certs/` copied in. On 2026-11-25 the switch of the Alpine package repositories to HTTP was made opt-in (`APK_USE_HTTP=1`), and the custom certificates are added to the trust store before the first `apk` call |
| `README.md` | 2023-04-26 to 2023-05-22, 2026-11-25 | Adapted; on 2026-11-25 a note pointing to the root README was added |
| `.gitignore` | 2023-04-26 to 2023-05-22 | Ignore local configs, logs, certificates and archives |

## New files by the fork author

| File | When | Purpose |
|---|---|---|
| `scripts/docker-entrypoint.sh` | 2025-12-05 | Create a keytab from the mounted password file, `kinit`, start the renewal cron job and Cntlm |
| `scripts/renew_ticket.sh` | 2025-12-05 | Renew the Kerberos ticket from the keytab |
| `tools/build.sh`, `tools/export.sh`, `tools/install.sh` | 2025-12-05 | Build, export and install the image |
| `conf/.gitkeep` | 2026-11-25 | Keeps the directory that the Dockerfile copies into the image |

## Third-party additions kept as received

| File | Note |
|---|---|
| `cntlm-0.92.3/README.md` | Text describing Cntlm with the Kerberos patch applied; added to this tree on 2023-04-26. Not written by the fork author. |
| `cntlm-0.92.3/debian/`, `rpm/`, `win/` | Part of the Cntlm release tree |

## Removed from the original tree

Editor and patch leftovers: `.DS_Store`, `._.DS_Store`, `Makefile.orig`, `main.c.orig`, `forward.c.orig`.
