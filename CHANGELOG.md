# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-11-25

First public state of the monorepo. It combines the former `cntlm-gss` fork and a private deployment setup.

### Added

- `compose.yml` and `.env.example`: run the Cntlm container bound to `127.0.0.1`, built from `cntlm-gss/`.
- `scripts/update-proxy`: renders shell, `/etc/environment`, apt, Docker daemon and git proxy settings from `/etc/proxy.conf`,
  with `--dry-run`, `--check`, `--off` and `--apply-services`. Sandbox tests in `tests/`.
- `scripts/setup`: guided three-step setup (account and password, proxy and bypass list, root CA fetched with `openssl s_client`).
- `scripts/init`: creates the per-host files from `*.example` templates and the `cntlm-net` network without overwriting anything.
- `systemd/update-proxy.service`, `scripts/check-build-proxy.sh`, `scripts/check-license-headers.sh`.
- Documentation and community files: README with acknowledgments and GPL compliance notes, CONTRIBUTING, SECURITY, CODE_OF_CONDUCT
  (Contributor Covenant 3.0), NOTICE, issue and pull request templates, CI with a secret scan.

### Changed

- `cntlm-gss/Dockerfile`: certificates in `certs/` are trusted before the first `apk` call, so builds behind a TLS-inspecting proxy work without the HTTP downgrade.
- `cntlm-gss/Dockerfile`: the switch of the Alpine package repositories to HTTP is now opt-in (`APK_USE_HTTP=1`); it was always on.
- Example IP addresses in the Cntlm documentation replaced with example host names and documentation addresses.

### Removed

- Per-host configuration, credentials, certificates and internal host names from the repository and its history.
- Leftover patch backups (`*.orig`) and editor files.

[Unreleased]: https://github.com/8greg8/proxy-gateway/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/8greg8/proxy-gateway/releases/tag/v0.1.0
