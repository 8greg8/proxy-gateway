# Security Policy

## Supported Versions

| Version | Supported |
| ------- | --------- |
| 0.1.x   | :white_check_mark: |

Only the latest release and the `main` branch receive fixes.

## Scope

### In Scope

- `scripts/` (`update-proxy`, `init`) and the files they generate on the host
- `compose.yml`, `.env.example`, `config/` and `etc/` templates
- The container build and runtime in `cntlm-gss/` (Dockerfile, entrypoint, ticket renewal scripts)
- GitHub Actions workflows (`.github/workflows/`)

### Out of Scope

- Vulnerabilities in upstream **Cntlm** itself or in Alpine, Kerberos or Docker. Report them to the upstream project; tell us as well so we can track the fix.
- Social engineering or phishing attacks targeting maintainers
- Physical access attacks
- Denial-of-service attacks (unless targeting the code in this repository)
- Findings that require an attacker who already controls the host or the `data/` directory

## Reporting a Vulnerability

Please report vulnerabilities privately instead of opening a public issue.

**Preferred:** use the repository's "Report a vulnerability" button (Security tab, private vulnerability reporting).

**Fallback:** email info@koporec.eu

Please include:

- A clear description of the vulnerability
- Steps to reproduce the issue
- The potential impact
- Any suggested mitigations or fixes
- Your estimate of the CVSS v3.1 severity (if known)

**Do not include real credentials, password hashes or tickets in your report.** If the issue involves a leaked secret, say where
it is, not what it is.

**Preferred language:** English.

## Severity Classification

We use [CVSS v3.1](https://www.first.org/cvss/v3.1/specification-document) scores to classify severity and set resolution timelines:

| Severity | CVSS v3.1 Score | Resolution SLA   |
| -------- | --------------- | ---------------- |
| Critical | 9.0 – 10.0      | 14 business days |
| High     | 7.0 – 8.9       | 14 business days |
| Medium   | 4.0 – 6.9       | 30 business days |
| Low      | 0.1 – 3.9       | 30 business days |

## Response SLA

- **Acknowledgment:** within 48 hours of receiving your report.
- **Initial assessment:** within 5 business days.
- **Resolution or mitigation plan:** within 14 business days for critical and high vulnerabilities, 30 business days for all others.

We will keep you informed and credit you in any public disclosure (unless you prefer to remain anonymous).

## CVE Assignment

We request a CVE identifier for confirmed vulnerabilities through [GitHub Security Advisories](https://docs.github.com/en/code-security/security-advisories).

## Coordinated Disclosure

We follow a **90-day coordinated disclosure policy**. We publish a security advisory within 90 days of receiving a report,
whether or not a fix is released. Please do not disclose the vulnerability publicly before we have had the opportunity to respond.

## Supply Chain

If you find a vulnerability in one of our dependencies (base image, packages, Cntlm), report it to the upstream maintainer first.
You are welcome to tell us as well.

## Known Hardening Notes and Limits

Read these before you run the proxy on a shared machine.

- **Anyone who can reach the proxy uses your identity.** Cntlm signs requests with your Kerberos ticket and does not
  authenticate its clients. The port is published on `127.0.0.1` only, but every container on the `cntlm-net` network can
  also use it. Attach only containers you trust, and consider `Allow`/`Deny` rules in `data/conf/cntlm.conf`.
  Never publish the port on another interface.
- **The password is stored in clear text** in `data/secrets/ad_pass` (mode `0600`), because the container needs it to
  create a Kerberos keytab. It is mounted read-only and never copied into the image. Protect the host account and its backups,
  and use a dedicated account where your organisation allows it.
- **A trusted root CA affects everything in the image.** `./scripts/setup` fetches the certificate from the network, so the
  choice is trust-on-first-use. Compare the SHA-256 fingerprint with the one your IT department publishes before you
  confirm. A wrong certificate lets whoever controls it intercept the image build. The certificate is written to the
  git-ignored `cntlm-gss/certs/` and used during the build only.
- **The container runs as root** inside its own namespace (Cntlm, `crond`, `kinit`), with `no-new-privileges` set.
  Further hardening (`cap_drop`, `read_only`) has not been tested with Kerberos and is not enabled.
- **Cntlm 0.92.3 is unmaintained upstream** (last release 2012) and the Kerberos patch is a community patch. Treat the
  proxy as a convenience for a trusted workstation, not as an internet-facing service.
- **Base image:** Alpine 3.23 by default. Alpine versions go end-of-life, so rebuild regularly with
  `docker compose build --no-cache --pull`, or override `ALPINE_VERSION` and test the build.
- **`update-proxy` runs as root** and edits shared files. It parses `/etc/proxy.conf` (never executes it), accepts only
  host-name characters in the values, writes files atomically, and keeps a one-time backup
  (`*.update-proxy.bak`) of `/etc/environment` and `/etc/gitconfig`. It removes `HTTP_PROXY`, `HTTPS_PROXY`,
  `NO_PROXY` and `DOCKER_PROXY` lines from `/etc/environment`, including ones you wrote by hand. Keep
  `/etc/proxy.conf` owned by root and not writable by others.
- **The proxy URL has no credentials.** Tools get `http://localhost:3128` only.
- The proxy port is published on `127.0.0.1` only.

## Safe Harbor

We consider security research conducted in accordance with this policy to be authorised. We will not initiate legal action against researchers who:

- Report vulnerabilities through the channels described above
- Avoid accessing, modifying or deleting data beyond what is necessary to demonstrate the issue
- Do not disrupt services or degrade user experience during testing
- Act in good faith and do not exploit vulnerabilities for personal gain
