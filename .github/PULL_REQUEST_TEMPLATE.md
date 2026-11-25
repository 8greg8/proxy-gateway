## Summary

<!-- Provide a brief summary of the changes -->

## Type of Change

- [ ] Bug fix
- [ ] New feature
- [ ] Refactor
- [ ] Documentation
- [ ] Chore / maintenance

## Related Issues

Closes #

## Checklist

- [ ] `shellcheck scripts/* tests/*.sh` passes
- [ ] `tests/test_update_proxy.sh` passes
- [ ] `docker compose config` is valid
- [ ] Secret scan is clean (`betterleaks git . -c .betterleaks.toml --confidence low`)
- [ ] No real credentials, hostnames, IP addresses or certificates in the diff, the description or the logs
- [ ] New files have an SPDX license header (Apache-2.0 outside `cntlm-gss/`, GPL-2.0-or-later inside)
- [ ] Tests added or updated for new functionality
- [ ] CHANGELOG.md updated (if applicable)
