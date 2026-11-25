# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-11-25

First public state of the monorepo. It combines the former `cntlm-gss` fork and a private deployment setup.

### Added

- Release install: CI publishes a multi-arch image (`linux/amd64`, `linux/arm64`) to `ghcr.io/8greg8/proxy-gateway` on each `v*` tag, with provenance and SBOM, and attaches image tarballs and `SHA256SUMS` to the GitHub release for networks that cannot reach GHCR.
- `scripts/create-builder`: a BuildKit builder on `cntlm-net` that builds any image through the running gateway.
- README: two install paths (release, from source) and a Bootstrap section for the first image on a restricted network.
- `compose.yml` and `.env.example`: run the Cntlm container bound to `127.0.0.1`, from the release image or built from `cntlm-gss/`.
- `./scripts/update-proxy`: renders shell, `/etc/environment`, apt, Docker daemon and git proxy settings from `/etc/proxy.conf`,
  with `--dry-run`, `--check`, `--off` and `--apply-services`. Sandbox tests in `tests/`.
- `./scripts/setup`: guided three-step setup (account and password, proxy and bypass list, root CA fetched with `openssl s_client`).
- `./scripts/init`: creates the per-host files from `*.example` templates and the `cntlm-net` network without overwriting anything.
- `systemd/update-proxy.service`, `./scripts/check-build-proxy.sh`, `./scripts/check-license-headers.sh`.
- Documentation and community files: README with acknowledgments and GPL compliance notes, CONTRIBUTING, SECURITY, CODE_OF_CONDUCT
  (Contributor Covenant 3.0), NOTICE, issue and pull request templates, CI with a secret scan.

### Changed

- Default Alpine base image is now 3.23 (was 3.17, which is end of life). Override with `ALPINE_VERSION`.
- `cntlm-gss/Dockerfile`: the ticket renewal job runs every five hours (`0 */5 * * *`); before, it ran every minute during those hours.
- `compose.yml`: `no-new-privileges` is set for the container.
- `./scripts/update-proxy`: values are validated (host names, `NO_PROXY` characters), files are written atomically, and a one-time backup of `/etc/environment` and `/etc/gitconfig` is kept.
- CI: GitHub Actions are pinned to commit SHAs; ShellCheck runs at its default severity.
- `cntlm-gss/Dockerfile`: certificates in `certs/` are trusted before the first `apk` call, so builds behind a TLS-inspecting proxy work without the HTTP downgrade.
- `cntlm-gss/Dockerfile`: the switch of the Alpine package repositories to HTTP is now opt-in (`APK_USE_HTTP=1`); it was always on.
- Example IP addresses in the Cntlm documentation replaced with example host names and documentation addresses.

### Removed

- Per-host configuration, credentials, certificates and internal host names from the repository and its history.
- Leftover patch backups (`*.orig`) and editor files.

## Before 0.1.0: history of the imported fork

The `cntlm-gss/` folder keeps the history of the former `cntlm-gss` fork. Its old tags are kept with a `cntlm-gss-` prefix and are
not releases of this project (releases are the tags that start with `v`):

| Tag | Meaning |
|---|---|
| `cntlm-gss-0.92.3` | Baseline: Cntlm 0.92.3 with the Kerberos patch applied |
| `cntlm-gss-v2.3` | Image version 2.3 of the former fork |
| `cntlm-gss-v3.0.0` | Image version 3.0.0 of the former fork |

[Unreleased]: https://github.com/8greg8/proxy-gateway/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/8greg8/proxy-gateway/releases/tag/v0.1.0
