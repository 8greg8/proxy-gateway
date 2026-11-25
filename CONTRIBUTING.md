# Contributing to proxy-gateway

Thank you for your interest in contributing! This document outlines the process.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) with Docker Compose v2
- `bash` 4+, `git`
- [ShellCheck](https://www.shellcheck.net/)
- Optional: [betterleaks](https://github.com/betterleaks/betterleaks) for the secret scan

## Getting Started

1. Fork the repository on GitHub.
2. Clone your fork locally.
3. Run `./scripts/init` to create your local, git-ignored files.
4. Create a branch from `develop`:
   - For features: `feat/<short-description>`
   - For bug fixes: `bugfix/<short-description>`
   - For hotfixes: `hotfix/<short-description>` (targets `main` directly)

## Project Structure

- **`scripts/`, `tests/`, `systemd/`, `etc/`, `config/`, `compose.yml`**: the deployment layer (Apache-2.0).
- **`cntlm-gss/`**: the Cntlm fork and its Docker build (GPL-2.0-or-later). See `cntlm-gss/MODIFICATIONS.md`.
- **`data/`**: per-host files, git-ignored. **Never commit anything from `data/`**, `.env` or real certificates.

## Development Workflow

### Checks

Run these **in order** before opening a pull request and fix problems before moving on. CI runs the same checks and a build of the image.

| Order | Command | What it checks |
|---|---|---|
| 1 | `shellcheck scripts/* tests/*.sh` | Shell lint |
| 2 | `./tests/test_update_proxy.sh` | `update-proxy` in a sandbox (`ROOT=` directory), no root needed |
| 3 | `./scripts/check-license-headers.sh` | SPDX header on every own file outside `cntlm-gss/` |
| 4 | `cp .env.example .env && docker compose config --quiet` | The compose file is valid |
| 5 | `betterleaks git . --redact --confidence low -c .betterleaks.toml` | Secret scan over the whole history |
| 6 | `docker compose build` | The image builds (needs the root CA step behind a TLS-inspecting proxy) |

### Working on the scripts

- `./scripts/setup` and `./scripts/init` only write git-ignored files. Test them in a scratch clone with
  `SETUP_*` variables and `--yes --skip-host`, never against your real `/etc`.
- `./scripts/update-proxy` reads `ROOT` (a prefix for every system path) and `PROXY_CONF`, so the tests never touch the machine.
- `update-proxy --dry-run` and `--check` must stay free of side effects.

### Working on the container

- Build context is `cntlm-gss/`; `certs/*.crt` and `conf/` are copied in. Never commit certificates.
- Changes to upstream files under `cntlm-gss/cntlm-0.92.3/` need a "Modified by" notice and an entry in `cntlm-gss/MODIFICATIONS.md`.

## Code Style

- Shell: `bash`, `set -euo pipefail`, quote every expansion, no `eval`, never `source` a configuration file you did not write.
- Scripts that read `/etc/proxy.conf` must parse it, not execute it, and must support `--dry-run`.
- Indentation and line endings follow `.editorconfig`.
- Every new file outside `cntlm-gss/` starts with `SPDX-License-Identifier: Apache-2.0` and a copyright line.
- Upstream Cntlm sources under `cntlm-gss/cntlm-0.92.3/` are changed only when necessary, and each change is noted in
  `cntlm-gss/MODIFICATIONS.md` and in the file (GPLv2 section 2(a)).

## Licensing of contributions

- Contributions to `cntlm-gss/` are licensed under **GPL-2.0-or-later**.
- All other contributions are licensed under **Apache-2.0**.
- By opening a pull request you confirm that you wrote the change or have the right to submit it under that license.

## No real data in issues or pull requests

Do not paste credentials, tokens, password hashes, certificates, internal host names or IP addresses into issues, pull
requests, logs or screenshots. Use `example.com` and the documentation address ranges (`192.0.2.0/24`, `198.51.100.0/24`,
`203.0.113.0/24`).

## Changelog

Every `feat:`, `fix:` or `refactor:` change must add an entry under `## [Unreleased]` in `CHANGELOG.md`:

```markdown
## [Unreleased]

### Added

- Description of the new feature.

### Changed

- Description of the change.

### Fixed

- Description of the fix.
```

## Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/): `type(scope): subject`, where type is one of
`feat`, `fix`, `docs`, `refactor`, `test`, `ci`, `chore`. Keep the subject in the imperative and under 72 characters.

## Branch Naming

`feat/<short-description>`, `bugfix/<short-description>`, `hotfix/<short-description>`.

## Pull Requests

1. Target `develop` (hotfixes target `main`).
2. Fill in the pull request template and keep the checklist honest.
3. CI must pass. A maintainer reviews, and squash-merge is the default.

## CI Matrix

One job on `ubuntu-latest`: ShellCheck, `update-proxy` tests, license headers, compose validation, secret scan, then an image build.

## Release Process (Maintainers)

1. Move the `[Unreleased]` entries to a new version section with the date, update the compare links, and set
   `PROXY_GATEWAY_VERSION` in `.env.example` and the default in `compose.yml`.
2. Merge `develop` into `main` and wait for CI.
3. Tag `vX.Y.Z` on `main` and push the tag. The `Release` workflow builds the image for `amd64` and `arm64`, pushes it to
   `ghcr.io/8greg8/proxy-gateway` (tags `X.Y.Z` and `latest`, with provenance and SBOM), and creates the GitHub release with
   the image tarballs, `SHA256SUMS` and the changelog section as notes.
4. After the first release, make sure the GHCR package is public (it follows the repository when linked by the source label).
5. Check the release: `docker pull ghcr.io/8greg8/proxy-gateway:X.Y.Z`, `sha256sum -c SHA256SUMS`, `docker load` of a tarball.

To test the workflow without publishing, run `Release` manually from the Actions tab (`publish` off): it builds both
platforms and keeps the tarballs as a workflow artifact.

## Disclaimer

The project is provided as is and the maintainer is not liable for its use, see the [Disclaimer in the README](README.md#disclaimer-and-responsibility). Contributing does not create any warranty or support obligation.

## Security

Do not open public issues for vulnerabilities. See [SECURITY.md](SECURITY.md).

## Code of Conduct

This project follows the [Contributor Covenant 3.0](CODE_OF_CONDUCT.md).
