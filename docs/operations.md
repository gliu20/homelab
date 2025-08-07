# Operations

Immutable host:
- Fedora CoreOS with Zincati manages updates.
- Update window is configured in /etc/zincati/config.d/55-updates-strategy.toml (UTC offset per time_zone).

Host tuning:
- ZRAM enabled via /etc/systemd/zram-generator.conf.
- Hostname managed by /etc/hostname.

User management:
- `core` user exists; update password hash in central.bu.yml before provisioning.

Secrets:
- SOPS and age are planned; not fully integrated yet.
- Do not store plaintext secrets; prefer environment files and consider SOPS once wired.

Backups and monitoring:
- Not implemented yet. Consider restic/borg for backups and node-exporter/prometheus or a lightweight alternative for metrics.

GitOps flow:
- All changes via Git.
- Rebuild Ignition after changes: just build or just build-central.
- Reprovision host to apply immutable config changes.
