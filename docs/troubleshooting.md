# Troubleshooting

Butane validation fails:
- Run: just validate-configs
- Inspect the error; files are validated in a container with --strict.

Build produces no .ign:
- Ensure files end in .bu.yml
- Run: just build (it discovers recursively)

Cannot pull images in just tasks:
- The helper runs containers with hardened flags (no network for most).
- For networked pulls, tasks use podman with slirp4netns when needed (e.g., coreos_installer).
- If your podman needs auth, log in: podman login <registry>

QEMU boots but services aren’t active:
- Check that build/services/<name>/<name>.ign exists.
- Confirm central.bu.yml has the corresponding ignition.config.merge entry.
- Use the QEMU console or later SSH to inspect systemd units: journalctl -u <unit>

Cockpit not reachable:
- In QEMU, port-forward is host 9091 -> guest 9090.
- Ensure the Cockpit systemd unit is enabled by the corresponding service Ignition.

Password login not working:
- Ensure central.bu.yml passwd.users.core.password_hash is set to a valid hash.
- Generate with: just mkpasswd --method=yescrypt
