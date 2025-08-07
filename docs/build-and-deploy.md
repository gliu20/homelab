# Build and Deploy

Build all Ignition fragments from Butane:
- just build
  - Finds every *.bu.yml and transpiles to build/.../*.ign using the Butane container.

Build only the main host Ignition:
- just build-central
  - Equivalent to: just transpile_ign central.bu.yml build/central.ign

Validate all Butane files strictly:
- just validate-configs

Format Butane YAML and justfile:
- just format

List discovered services and central merges:
- just list-services

Serve build artifacts locally:
- just serve
  - Serves http://localhost:8000 from ./build

Clean generated artifacts:
- just clean

Direct transpilation example:
- just transpile_ign central.bu.yml build/central.ign

Deploy with coreos-installer (to disk /dev/sdX):
- just coreos_installer 'install --ignition-file build/central.ign /dev/sdX'

QEMU smoke test:
1) just download_fcos
2) just deploy_fcos_qemu
   - Boots with build/central.ign via fw_cfg
   - SSH forwards: host 2222 -> guest 22
   - Cockpit available on host 9091 -> guest 9090 (if enabled)
