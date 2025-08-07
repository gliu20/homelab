# Services

All services live under services/<name>/ with:
- A Butane file (*.bu.yml) that declares systemd units and files for the service
- Optional container/unit files referenced by the Butane config
- The build step generates build/services/<name>/<name>.ign that is merged by central.bu.yml

Currently implemented:
- Cockpit: services/cockpit/
- Tailscale: services/tailscale/
- Kinto: services/kinto/

Ignition merge points (central.bu.yml):
- build/services/cockpit/cockpit.ign
- build/services/tailscale/tailscale.ign
- build/services/kinto/kinto.ign

Build output layout:
- build/services/<name>/<name>.ign
- build/central.ign

Notes:
- Service enablement is controlled by presence of the per-service *.bu.yml and reference in central.bu.yml.
- Adjust container images and environment inside the service directories as needed.

Cockpit implementation details:
- Cockpit runs via Podman Quadlet defined at /etc/containers/systemd/cockpit.container.
- systemd’s podman-system-generator reads that file on boot and daemon-reload, and generates cockpit.service dynamically.
- The Quadlet includes [Install] WantedBy=multi-user.target, and the generator applies it (like systemctl enable) so the service becomes enabled automatically; no manual unit file is shipped.
- Access is via https://<host>:9090 (host networking).

Optional Podman socket:
- Cockpit can manage local Podman if /run/podman/podman.sock is available. The Quadlet does not mount it by default to avoid hard failure on hosts without the socket.
- To enable Podman management in Cockpit, enable the socket on the host:
  - sudo systemctl enable --now podman.socket
  - Verify exists: ls -l /run/podman/podman.sock
  - Then add this mount to the Quadlet and reload:
    - Volume=/run/podman/podman.sock:/run/podman/podman.sock
- If the socket is absent and mounted, Podman exits with status=125.

Verify Cockpit:
- sudo systemctl daemon-reload
- sudo systemctl list-unit-files | grep -E '^cockpit\.service'
- sudo systemctl status cockpit.service
- sudo podman ps -a --filter name=cockpit
- sudo ss -lntp | grep ':9090'

Generator details:
- The generator binary is /usr/lib/systemd/system-generators/podman-system-generator
- View generator output/errors:
  - systemd-analyze --generators
  - /usr/lib/systemd/system-generators/podman-system-generator --dryrun
For deeper debugging steps, see Troubleshooting.
