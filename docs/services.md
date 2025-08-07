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
