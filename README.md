# proxy-gateway

[![CI](https://github.com/8greg8/proxy-gateway/actions/workflows/ci.yml/badge.svg)](https://github.com/8greg8/proxy-gateway/actions/workflows/ci.yml)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)](https://docs.docker.com/compose/)
[![License](https://img.shields.io/badge/License-Apache%202.0%20%2F%20GPL--2.0--or--later-blue.svg)](#license)

A local proxy for machines and containers behind a corporate NTLM or Kerberos proxy, packaged for Docker, with one
file that keeps every proxy setting on the host in sync.

Sign in once with your Active Directory account. `git`, `apt`, `pip`, `npm`, `curl` and Docker image pulls then work
through the corporate proxy without a password in any of them.

> **Note:** This is an independent, community-maintained packaging of [Cntlm](http://cntlm.sourceforge.net) with
> Kerberos support. It is not affiliated with or endorsed by the Cntlm project or any proxy vendor.

---

## Why proxy-gateway?

### Without it

- ❌ Most developer tools cannot sign in to NTLM or Kerberos proxies and fail with `407 Proxy Authentication Required`.
- ❌ Passwords end up in `~/.gitconfig`, shell profiles, `apt` configuration and Docker daemon files, and go stale after every password change.
- ❌ The same proxy address and bypass list is copied by hand into five or more places, and they drift apart.
- ❌ Upstream Cntlm has no Kerberos support: the patch exists only as an attachment in a discussion thread, and there is no ready-made container build.
- ❌ Behind a TLS-inspecting proxy, image builds fail with `certificate verify failed` and there is no guided way to trust the company root CA.
- ❌ A shared, always-on proxy for several machines or containers means hand-writing compose files, networks and ticket renewal.

### With it

- ✅ One local proxy (`http://localhost:3128`) that signs in for your tools using a Kerberos ticket, renewed automatically every five hours.
- ✅ The password lives in exactly one file, `data/secrets/ad_pass` (mode `0600`), mounted read-only into one container. No tool ever sees it.
- ✅ One file, `/etc/proxy.conf`, is the single source of truth. `update-proxy` derives shell, `apt`, Docker daemon and `git` settings from it, with `--dry-run`, `--check` and `--off`.
- ✅ Kerberos out of the box: Cntlm 0.92.3 with the GSSAPI patch, built from source in a small Alpine image.
- ✅ `./scripts/setup` asks three groups of questions (account, proxy, root CA) and fetches and verifies the root certificate for you.
- ✅ Safe defaults: the port is bound to `127.0.0.1`, per-host files are git-ignored, and CI scans the whole history for secrets.
- ✅ Containers on the `cntlm-net` network reach the same proxy by name.

---

## Overview

proxy-gateway combines a Docker build of Cntlm with Kerberos support and a small set of shell scripts. The container
listens on the local machine, signs in to the corporate proxy with a Kerberos ticket for your account, and forwards
requests from tools that cannot authenticate themselves. The scripts create all per-host configuration from templates
and keep the machine's proxy settings consistent.

```text
 your tools and containers  -->  proxy-gateway (Cntlm, Docker)  -->  corporate proxy  -->  internet
   plain http://localhost:3128      Kerberos sign-in with your account      authenticated
```

---

## Functionalities

### Proxy container

| Feature | Detail |
|---|---|
| Authentication | Kerberos (GSSAPI); the container turns `data/secrets/ad_pass` into a ticket and renews it every five hours |
| Network | Port bound to `127.0.0.1`; other containers join the `cntlm-net` network and use `http://cntlm:3128` |
| Configuration | `data/conf/cntlm.conf` (parent proxies, bypass list), `data/conf/krb5.conf` (realm), all read-only |
| TLS inspection | Corporate root certificates in `cntlm-gss/certs/` are trusted during the image build |

### Guided setup: `./scripts/setup`

| Step | Does |
|---|---|
| 1. Account | Active Directory user, Kerberos realm, hidden password prompt |
| 2. Proxy | Corporate proxy, bypass list and, if needed, a proxy for the image build, then writes and applies `/etc/proxy.conf` |
| 3. Root CA | Fetches a certificate chain with `openssl`, shows fingerprints, saves the root after your confirmation |

### Host settings: `./scripts/update-proxy`

Writes `/etc/profile.d/proxy.sh`, a managed block in `/etc/environment`, the `apt` configuration, a Docker daemon
drop-in and `/etc/gitconfig` from `/etc/proxy.conf`. It never reads the password file and never touches
`~/.docker/config.json`. Details are in [Host settings](#host-settings-etcproxyconf-and-update-proxy).

---

## Repository structure

```text
proxy-gateway/
├── compose.yml, .env.example        # proxy container, bound to 127.0.0.1          (Apache-2.0)
├── scripts/
│   ├── setup, init                  # guided setup and per-host templates          (Apache-2.0)
│   └── update-proxy                 # host settings from /etc/proxy.conf           (Apache-2.0)
├── config/, etc/, systemd/          # templates and the boot-time unit             (Apache-2.0)
├── tests/                           # sandbox tests for update-proxy               (Apache-2.0)
├── data/                            # per-host files, git-ignored                  (n/a)
└── cntlm-gss/                       # Cntlm fork with Kerberos and its Docker build (GPL-2.0-or-later)
```

## Tech stack

- **Runtime:** Docker, Docker Compose, Alpine Linux
- **Proxy:** Cntlm 0.92.3 with the Kerberos (GSSAPI) patch, MIT Kerberos client
- **Tooling:** `bash`, `openssl`, `systemd`
- **Quality:** ShellCheck, sandbox tests, betterleaks secret scan, GitHub Actions

## Bootstrap: the first build needs the internet

proxy-gateway exists to give a machine access through the corporate proxy, but the first `docker compose build` has to
download the Alpine base image and packages, before that proxy exists. This is the chicken-and-egg problem of every
proxy tool on a network that blocks direct access.

```text
 docker compose build  -->  needs internet (Alpine, apk packages)
        ^                              |
        |                              v
 proxy-gateway running  <--  needs the image   (blocked: no proxy yet)
```

Two separate things can stop the build, and they need different fixes:

| Blocker | Typical error | Fix |
|---|---|---|
| **TLS inspection** (the proxy re-signs HTTPS with a company root CA) | `certificate verify failed` | Step 3 of `./scripts/setup` fetches the root CA into `cntlm-gss/certs/`, and the Dockerfile trusts it during the build |
| **No network path** (direct DNS and internet are blocked for containers) | `DNS: transient error`, `could not connect to server`, `temporary error` | One of the mitigations below. A certificate does not help here |

### Mitigations, from easiest

| # | Mitigation | How |
|---|---|---|
| 1 | **Use a proxy that already works for Docker** (another running Cntlm, a colleague's gateway, a package mirror) | Answer "Proxy for building the image" in `./scripts/setup`, or set `BUILD_PROXY=http://host:port` in `.env`. If that proxy runs on this machine also `BUILD_NETWORK=host`. With a `docker-container` builder (`docker buildx ls`) use `BUILDX_BUILDER=default docker compose build` |
| 2 | **Fix container DNS** when only name resolution fails | Docker may fall back to public DNS servers that your network blocks. Set your company DNS server in `/etc/docker/daemon.json` as `{"dns": ["<company-dns-ip>"]}`, then `sudo systemctl restart docker` |
| 3 | **Build on another network and copy the image** | On a machine or network with direct access (home, phone hotspot, a build server): `docker compose build && docker save proxy-gateway/cntlm-gss:local \| gzip > proxy-gateway-image.tgz`. Copy the file over, then on the target: `docker load < proxy-gateway-image.tgz && docker compose up -d --no-build`. The image contains no passwords, no certificates and no company names |
| 4 | **Bootstrap through a temporary direct route** | Run the build once while connected without the corporate restriction (VPN off, guest network), where your policy allows it |

After the first start, the container is the proxy: later rebuilds (`docker compose build --pull`) can use it. Set
`BUILD_PROXY=http://localhost:3128` and `BUILD_NETWORK=host` in `.env` for that.

**Why not ship a builder image with the company certificate inside?** The certificate only solves TLS inspection, not the
missing network path, and a company root CA must not be baked into an image that anyone can download. The local build
already includes your certificate from `cntlm-gss/certs/` (git-ignored), and the image you build stays on your machine.

---

---

## Quick start

**You need:** Linux with Docker and Docker Compose, `bash`, `openssl`, `sudo`, and your Active Directory
account name and password.

```bash
git clone https://github.com/8greg8/proxy-gateway.git
cd proxy-gateway
./scripts/setup                     # 1. answer three groups of questions (below)
docker compose up -d --build      # 2. build and start the proxy container
curl -sI -x http://localhost:3128 https://example.com | head -1     # 3. verify: any HTTP status line means it works
```

From now on the tools on this machine use the proxy (step 1 configured them). To use it from a container, attach the
container to the `cntlm-net` network and set `HTTPS_PROXY=http://cntlm:3128` (compose service name `cntlm`).

### What `./scripts/setup` asks

| Step | Question | What the script does with it |
|---|---|---|
| **1. Account** | Active Directory user name, Kerberos realm (for example `EXAMPLE.COM`), password (typed hidden) | Writes `.env`, `data/conf/krb5.conf` (domain controllers found through DNS) and `data/secrets/ad_pass` (mode `0600`) |
| **2. Proxy** | Corporate proxy `host:port` (several: comma separated), hosts that bypass the proxy (one list: names, `.domain` suffixes, IPs and CIDR ranges; it is translated to Cntlm wildcards for you) | Writes `data/conf/cntlm.conf`, then `/etc/proxy.conf`, then applies it to this machine with `sudo ./scripts/update-proxy` |
| **3. Root CA** | Any HTTPS site you reach through the proxy (empty = skip) | Fetches its certificate chain with `openssl s_client`, shows subject, issuer and SHA-256 of each certificate, and after your confirmation saves the root to `cntlm-gss/certs/<site>.crt` |

Notes:

- Step 3 is only needed when your network inspects TLS, which shows up as `certificate verify failed` during the image
  build. The fetch trusts whatever the network presents the first time: compare the fingerprint with the one your IT
  department publishes. If the proxy does not send the root, the script takes it from this machine's trust store.
- Re-run `./scripts/setup` any time. It offers the current values as defaults and asks before replacing the password.
- The password never leaves `data/secrets/ad_pass`. It is mounted read-only into the container, which turns it into a
  Kerberos ticket and renews it every five hours.

### `./scripts/setup` options

| Option or variable | Effect |
|---|---|
| `--yes` | No prompts: use the current values, or the `SETUP_*` variables below |
| `--skip-host` | Do not write `/etc/proxy.conf` (no `sudo` needed) |
| `--skip-ca` | Do not fetch a certificate |
| `SETUP_AD_USER`, `SETUP_REALM`, `SETUP_PARENT_PROXY`, `SETUP_NO_PROXY_LIST`, `SETUP_CA_HOST`, `SETUP_CA_YES=1` | Answers for unattended runs |
| `SETUP_PASSWORD_FILE` | A file whose content becomes `data/secrets/ad_pass` |
| `./scripts/init` | Only creates the per-host files from the templates; `setup` calls it for you |

---

## Host settings: `/etc/proxy.conf` and `update-proxy`

`./scripts/setup` already created and applied `/etc/proxy.conf`. This section is for changing it later. The file is the
single source of truth for the proxy settings of this machine; `update-proxy` derives everything else from it, so you
never edit the generated files.

```ini
# false removes all derived settings
PROXY_ENABLED=true
# where the proxy container listens on this host, and the port
PROXY_HOST=127.0.0.1
PROXY_PORT=3128
# name under which containers on cntlm-net reach it
DOCKER_PROXY_HOST=cntlm
# hosts that bypass the proxy
NO_PROXY=localhost,127.0.0.1,.example.com
```

One `KEY=value` per line, no spaces, quotes or `$` in values, comments on their own lines: the file is parsed, never executed.

| `update-proxy` writes | Effect |
|---|---|
| `/etc/profile.d/proxy.sh` and a managed block in `/etc/environment` | `http_proxy`, `https_proxy`, `no_proxy` for shells and sessions |
| `/etc/apt/apt.conf.d/95proxy` | `apt` uses the proxy |
| `/etc/systemd/system/docker.service.d/http-proxy.conf` | The Docker daemon pulls images through the proxy |
| `/etc/gitconfig` | `git` uses the proxy (`http.proxy`, `https.proxy`) |

It never reads the password file and never touches `~/.docker/config.json` (your registry logins). Before it first edits
`/etc/environment` or `/etc/gitconfig` it saves a copy next to the file as `*.update-proxy.bak`. Note that it removes
`HTTP_PROXY`, `HTTPS_PROXY`, `NO_PROXY` and `DOCKER_PROXY` lines from `/etc/environment`, also ones you wrote by hand.

| Command | Effect |
|---|---|
| `sudoedit /etc/proxy.conf && sudo ./scripts/update-proxy` | Change a setting and apply it |
| `./scripts/update-proxy --dry-run` | Show what would change, change nothing |
| `./scripts/update-proxy --check` | Exit 1 if the machine differs from `/etc/proxy.conf` |
| `sudo ./scripts/update-proxy --off` | Remove all derived settings (for example when leaving the corporate network) |
| `sudo ./scripts/update-proxy --apply-services` | Also reload systemd and restart Docker if its drop-in changed (running containers restart) |

To apply the file at every boot, before Docker starts:

```bash
sudo install -m 0755 ./scripts/update-proxy /usr/local/sbin/update-proxy
sudo install -m 0644 systemd/update-proxy.service /etc/systemd/system/
sudo systemctl enable update-proxy
```

---

## Troubleshooting

| Symptom | Cause and fix |
|---|---|
| Image build: `certificate verify failed` | The network inspects TLS. Run `./scripts/setup` and answer step 3 (or copy the root certificate as `.crt` into `cntlm-gss/certs/`), then `docker compose build --no-cache` |
| Image build: `DNS: transient error`, `could not connect to server` or `temporary error` | No network path from the build container. See [Bootstrap](#bootstrap-the-first-build-needs-the-internet) for the mitigations |
| Image build only works over plain HTTP | Last resort for broken TLS: `APK_USE_HTTP=1` in `.env`. Prefer fixing step 3 |
| Container exits at start, `kinit` fails | Wrong user, realm or password. Check `.env`, `data/conf/krb5.conf`, `data/secrets/ad_pass`; `docker compose logs cntlm` shows the error. Realm names are upper case |
| `407 Proxy Authentication Required` through the proxy | The ticket is missing or expired, or the parent proxy needs another method. Restart (`docker compose restart cntlm`), then check `Proxy` in `data/conf/cntlm.conf` |
| Password changed | Put the new one in `data/secrets/ad_pass` (or re-run `./scripts/setup`), then `docker compose restart cntlm` |
| Port 3128 already in use | Set `PROXY_PORT` in `.env` and `PROXY_PORT` in `/etc/proxy.conf` to the same value, then `docker compose up -d` and `sudo ./scripts/update-proxy` |
| Docker pulls ignore the proxy | Run `sudo ./scripts/update-proxy --apply-services` once so the daemon picks up its drop-in |
| A site must not use the proxy | Add it to the bypass list in `data/conf/cntlm.conf` (`NoProxy`) and to `NO_PROXY` in `/etc/proxy.conf`, then restart and re-apply |
| Reporting a problem | Remove credentials, host names and IP addresses from logs first, see [CONTRIBUTING.md](CONTRIBUTING.md) |

Developers: checks, tests and conventions are in [CONTRIBUTING.md](CONTRIBUTING.md).

---

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
- Everything at the root is new: compose file, `update-proxy`, `./scripts/init`, config templates, tests, CI and the docs.

---

## Roadmap

No fixed roadmap yet. Ideas and requests are welcome as issues or discussions.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). By taking part you agree to the [Code of Conduct](CODE_OF_CONDUCT.md).

---

## Security

Please report vulnerabilities privately, see [SECURITY.md](SECURITY.md). Never put real credentials, host names or IP
addresses in issues or pull requests.

---

## License

- Root files, `scripts/`, `tests/`, `compose.yml`, docs: **Apache-2.0**, see [LICENSE](LICENSE).
- `cntlm-gss/`: **GPL-2.0-or-later**, see [cntlm-gss/LICENSE](cntlm-gss/LICENSE) and `NOTICE`.
