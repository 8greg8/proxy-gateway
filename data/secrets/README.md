# data/secrets/

`ad_pass` holds the password of the user named in `.env` (`AD_USER`), on one line, nothing else.

- Mode `0600`, owned by the user who runs `docker compose`.
- The directory is mounted **read-only** into the container; the entrypoint reads it once to create
  a Kerberos keytab inside the container and then runs `kinit`.
- Never commit it. `.gitignore` excludes it, and CI runs a secret scan on every push.
- `update-proxy` and `/etc/proxy.conf` never read this file.
