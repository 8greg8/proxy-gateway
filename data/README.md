# data/

Per-host runtime files. Everything here except the README and `.gitkeep` files is git-ignored,
and `scripts/init` creates the files from the templates.

| Path | Content |
|---|---|
| `conf/cntlm.conf` | Cntlm configuration (parent proxies, `NoProxy`, listen port) |
| `conf/krb5.conf` | Kerberos configuration (realm and domain controllers) |
| `secrets/ad_pass` | Your directory password, one line, mode `0600` (see `secrets/README.md`) |
| `logs/` | Optional log output |
