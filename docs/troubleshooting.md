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

---

## Cockpit: Verify and Debug

1) Confirm Quadlet file exists and is correct
- sudo ls -l /etc/containers/systemd/cockpit.container
- sudo cat /etc/containers/systemd/cockpit.container

2) Ensure systemd has generated the unit from Quadlet (generator runs automatically)
- sudo systemctl daemon-reload
- sudo systemd-analyze --generators
- sudo systemctl list-unit-files | grep -E '^cockpit\.service'
  - Expected: cockpit.service enabled
- If not present, inspect generator directly:
  - /usr/lib/systemd/system-generators/podman-system-generator --dryrun
  - sudo systemctl cat cockpit.service || true
  - sudo journalctl -b -u cockpit.service -u systemd -g podman

3) Enable and start (if not already)
- sudo systemctl enable --now cockpit.service
- Then check status:
  - sudo systemctl status cockpit.service
  - sudo journalctl -u cockpit.service -b --no-pager

4) Check the underlying podman unit and container
- sudo systemctl status podman-cockpit.service || true
- sudo podman ps -a --filter name=cockpit
- If not running, inspect logs:
  - sudo podman logs cockpit || sudo podman logs $(sudo podman ps -a --format '{{.Names}}' | grep '^cockpit$')

5) Network and port checks
- Since Network=host is used, service should be on https://<host>:9090
- Check listener:
  - sudo ss -lntp | grep ':9090'
- If QEMU with port-forwarding, use https://localhost:9091

6) SELinux denials (even with Label=disable, verify)
- sudo ausearch -m AVC,USER_AVC -ts recent | audit2why
- sudo journalctl -b | grep -i avc

7) DBus and system access mounts
- Verify host sockets available in container:
  - sudo podman exec cockpit ls -l /run/dbus/system_bus_socket /run/podman/podman.sock /run/systemd/journal || true

8) Regenerate after config changes
- After changing the Quadlet, run:
  - sudo systemctl daemon-reload
  - sudo systemctl reenable cockpit.service
  - sudo systemctl restart cockpit.service

Common issues:
- cockpit.service not found: The systemd generator (podman-system-generator) didn’t see the file. Ensure /etc/containers/systemd/cockpit.container exists, then run daemon-reload; check systemd-analyze --generators and the generator --dryrun output.
- Image pull failures: Check network and run sudo podman pull quay.io/cockpit/ws:latest; review journal for cockpit.service.
- Permission errors: Confirm Label=disable is set in Quadlet. Check SELinux logs for denials.
