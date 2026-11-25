# proxy-gateway

[![CI](https://github.com/8greg8/proxy-gateway/actions/workflows/ci.yml/badge.svg)](https://github.com/8greg8/proxy-gateway/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/License-Apache%202.0%20%2F%20GPL--2.0--or--later-blue.svg)](#license)

A local proxy for machines and containers behind a corporate NTLM or Kerberos proxy, packaged for Docker, plus one small
tool that keeps every proxy setting on the host in sync from a single file.

## Why proxy-gateway?

Corporate proxies that need Windows (NTLM) or Kerberos authentication do not work with most developer tools. This repo runs
[Cntlm](http://cntlm.sourceforge.net) with Kerberos support in a container. Your tools talk to a plain local proxy
(`http://localhost:3128`), and Cntlm authenticates upstream for them. `update-proxy` then writes the matching settings
(shell environment, apt, the Docker daemon, git) from **one** file, `/etc/proxy.conf`, so there is exactly one place to change.

```text
 your tools / containers --> cntlm (this repo, Docker) --> corporate proxy --> internet
        no password             Kerberos ticket              authenticated
```

## Structure

| Path | What | License |
|---|---|---|
| `compose.yml`, `.env.example` | Runs the proxy container, bound to `127.0.0.1` | Apache-2.0 |
| `scripts/update-proxy`, `etc/proxy.conf.example`, `systemd/` | Renders host proxy settings from `/etc/proxy.conf` | Apache-2.0 |
| `scripts/setup`, `scripts/init`, `config/*.example` | Guided setup (account, proxy, root CA) and the per-host templates | Apache-2.0 |
| `tests/` | Sandbox tests for `update-proxy` (no root needed) | Apache-2.0 |
| `cntlm-gss/` | The Cntlm fork with Kerberos support and its Docker build | GPL-2.0-or-later |
| `data/` | Per-host files (git-ignored): configs and the password file | n/a |

## Quick start

Requirements: Docker with Compose, `bash`, `openssl`, `sudo`, and a directory (Active Directory or Kerberos) account.

```bash
git clone https://github.com/8greg8/proxy-gateway.git && cd proxy-gateway
scripts/setup                  # three steps, about two minutes
docker compose up -d --build
curl -sI -x http://localhost:3128 https://example.com | head -1     # answers through the corporate proxy
```

`scripts/setup` asks for:

1. **Your account**: directory user name, Kerberos realm and password. The password is typed hidden and stored in
   `data/secrets/ad_pass` (mode `0600`). Domain controllers are found through DNS.
2. **Your proxy**: the corporate proxy (`host:port`) and the hosts that bypass it. It writes `data/conf/cntlm.conf`, then
   `/etc/proxy.conf`, and applies the settings to this host with `sudo scripts/update-proxy`.
3. **Your root CA**: if your network inspects TLS, name any HTTPS site you reach through the proxy. The script fetches its
   certificate chain with `openssl s_client`, shows subject, issuer and SHA-256 fingerprint of each certificate, and
   after your confirmation saves the last one to `cntlm-gss/certs/<site>.crt`. It is trust-on-first-use, so compare the
   fingerprint with the one your IT department publishes. By hand this is
   `openssl s_client -connect SITE:443 -showcerts </dev/null | sed -e '/-----BEGIN/,/-----END/!d'`.

Re-run it any time; current values are offered as defaults. Options: `--yes` (take defaults or `SETUP_*` variables),
`--skip-ca`, `--skip-host` (no sudo). Without a TLS-inspecting network, answer the third question with an empty line.

If the image build cannot reach the internet directly, set `BUILD_PROXY` (and `BUILD_NETWORK=host` when that proxy runs
on this machine) in `.env`. `scripts/init` alone only creates the files from the templates.

### One file for all host settings

```bash
sudo install -m 0644 etc/proxy.conf.example /etc/proxy.conf   # scripts/setup does this for you
sudoedit /etc/proxy.conf          # proxy host and port, NO_PROXY list
sudo scripts/update-proxy --dry-run   # show what would change
sudo scripts/update-proxy             # write the files
scripts/update-proxy --check          # exit 1 if files differ from /etc/proxy.conf
```

It manages `/etc/profile.d/proxy.sh`, a managed block in `/etc/environment`, `/etc/apt/apt.conf.d/95proxy`, the Docker
daemon drop-in and the system git proxy. It never restarts Docker unless you pass `--apply-services`, never reads the
password file, and never touches `~/.docker/config.json`. `--off` removes everything it wrote. To apply
the file at boot, install the script and the unit (the unit runs before `docker.service`):
`sudo install -m 0755 scripts/update-proxy /usr/local/sbin/update-proxy` and
`sudo install -m 0644 systemd/update-proxy.service /etc/systemd/system/ && sudo systemctl enable update-proxy`.

The first `docker compose build` may itself need the proxy. Build once with direct access, or pass `--build-arg` proxy
variables, then run `update-proxy`.

## Development commands

```bash
tests/test_update_proxy.sh            # sandbox tests
shellcheck scripts/* tests/*.sh
docker compose config                 # validate the compose file
scripts/check-license-headers.sh
betterleaks git . -c .betterleaks.toml --confidence low   # secret scan
```

## Acknowledgments and derivations

This project stands on the work of others. Everything under `cntlm-gss/` is derived from the following, in this order:

1. **Cntlm**, by **David Kubicek** and contributors: the authenticating HTTP proxy this repo is built around
   (<http://cntlm.sourceforge.net>, version 0.92.3, Copyright 2007-2010 David Kubicek, GPL-2.0-or-later). The
   authors named in each source file and in `cntlm-gss/cntlm-0.92.3/COPYRIGHT` keep their copyright.
2. **The Kerberos (GSSAPI) authentication patch** `201211-cntlm-kerberos-authentication.patch`, published as an attachment
   in the Cntlm project's feature-request discussion on SourceForge (a source header credits "luca"). It adds
   `kerberos.c`/`kerberos.h`; parts of that code derive from sample code by **OpenVision Technologies** (1994, permissive
   notice kept in the file). The `debian/` packaging files inside the Cntlm tree carry the Debian maintainers' work.
3. **Manish Kukreja**, who combined Cntlm 0.92.3 and the patch in a Docker build:
   <https://github.com/maksteel/cntlm-gss-docker> (GPLv2, November 2019). The first nine commits of the `cntlm-gss/`
   history are his, and his authorship stays in the git history.
4. **This repository**: the changes listed below and in `cntlm-gss/MODIFICATIONS.md`, and the deployment layer at the root.

If you believe someone is missing from this list, please open an issue.

### GPL-2.0-or-later compliance

- The license texts are in `LICENSES/` and `cntlm-gss/LICENSE`; the full corresponding source is this repository. No binaries
  or container images are distributed.
- Modified files under `cntlm-gss/` carry a notice "Modified by Gregor Koporec" with the years, as GPLv2 section 2(a)
  requires, and `cntlm-gss/MODIFICATIONS.md` lists every change against Manish Kukreja's repository.
- The program comes with **no warranty**, as stated in the license.
- Files under the root (compose, scripts, tests, docs) are separate works under Apache-2.0 and are shipped next to, not
  linked into, the GPL code.

### What I changed

Against <https://github.com/maksteel/cntlm-gss-docker> (details and dates in `cntlm-gss/MODIFICATIONS.md`):

- `Dockerfile` rewritten: small Alpine image, Cntlm built with Kerberos, keytab creation and ticket renewal, a build option
  for HTTP package repositories that is **off** by default.
- New: `scripts/docker-entrypoint.sh` and `scripts/renew_ticket.sh` (inside `cntlm-gss/`), and `tools/{build,export,install}.sh`.
- `cntlm-0.92.3/Makefile` and `configure`: build the Kerberos objects when enabled, a default `all` target, and a message.
- `cntlm-0.92.3/README.md`, `.gitignore`, README: added or adapted.
- Repository move into this monorepo: example IP addresses in the upstream docs were replaced with example host names and
  documentation addresses, leftover patch backups (`*.orig`) and editor files were removed.
- Everything at the root is new: compose file, `update-proxy`, `scripts/init`, config templates, tests, CI and the docs.

## Roadmap

No fixed roadmap yet. Ideas and requests are welcome as issues or discussions.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). By taking part you agree to the [Code of Conduct](CODE_OF_CONDUCT.md).

## Security

Please report vulnerabilities privately, see [SECURITY.md](SECURITY.md). Never put real credentials, host names or IP
addresses in issues or pull requests.

## License

- Root files, `scripts/`, `tests/`, `compose.yml`, docs: **Apache-2.0**, see [LICENSE](LICENSE).
- `cntlm-gss/`: **GPL-2.0-or-later**, see [cntlm-gss/LICENSE](cntlm-gss/LICENSE) and `NOTICE`.
