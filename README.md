# Homelab Infrastructure as Code

A declarative Fedora CoreOS homelab configuration managed with Butane and Podman.

## Architecture Overview

```mermaid
graph TD
    FCOS[Fedora CoreOS] --> Butane
    Butane --> Ignition
    Ignition -->|Provision| Podman_Containers
    Podman_Containers -->|Systemd Units| CoreOS
    Cockpit -->|Management| CoreOS
    Tailscale -->|Secure Networking| All_Services
```

## Core Components

### Infrastructure Foundation
- 🐧 Fedora CoreOS (Immutable OS with automated updates)
- 🔥 Butane configurations for declarative provisioning
- 🐳 Podman containers with systemd integration
- ✈️ Cockpit web console for management

### Networking & Security
- 🔒 Tailscale mesh VPN for secure service exposure
- 🛡️ Vaultwarden (Bitwarden-compatible password manager)
- 🔑 SOPS + Age for secrets management

## Service Catalog

### Knowledge Management
- Planned:
  - [Atomic Server](https://github.com/atomicdata-dev/atomic-server) - Linked Data knowledge base
  - [AFFiNE](https://github.com/toeverything/AFFiNE) - All-in-one workspace (Docker deployment)

### Web & Bookmarks
- Candidates:
  - Shiori - Simple bookmark manager
  - Grimoire - Knowledge organizer
  - Servas - Link sharing platform

### Development Ecosystem
- Source Control:
  - Gitea/Forgejo - Lightweight code hosting
- Development Tools:
  - Kinto - JSON storage service
  - Excalidraw - Collaborative diagramming

### Productivity
- Documentation:
  - Markdown wiki (Basic docs)
  - Task tracking solution (TBD)
- Remote Access:
  - Waypipe - Latency-tolerant Wayland proxy

## Repository Structure

```
homelab/
├── central.bu.yml          # Base system configuration
├── justfile                # Task runner commands
├── services/               # Service-specific configurations
│   ├── cockpit/            # Management console
│   ├── kinto/              # JSON storage service
│   └── tailscale/          # VPN configuration
└── README.md               # This documentation
```

## Getting Started

### Prerequisites
1. Fedora CoreOS host
2. Butane compiler (`butane` command)
3. Tailscale network configured

### Deployment Example
```bash
# Generate Ignition config
butane --pretty --strict central.bu.yml > ignition.json

# Apply to CoreOS
fcct -input ./central.bu.yml -output ./ignition.json
```

### Management
```bash
# Use Just commands for common tasks
just validate-configs  # Validate Butane configs
just list-services     # Show managed services
```

## Operational Excellence
- **Immutable Infrastructure**: CoreOS + Declarative Butane configs
- **GitOps Approach**: All changes through repository
- **Backup Strategy**: (TODO: Add backup plan)
- **Monitoring**: (TODO: Add monitoring solution)

## References

### Core Technologies
- [Butane Getting Started](https://coreos.github.io/butane/getting-started/)
- [Butane FCOS v1.6 Config](https://coreos.github.io/butane/config-fcos-v1_6/)
- [Fedora CoreOS OS Extensions](https://docs.fedoraproject.org/en-US/fedora-coreos/os-extensions/)
- [Podman Systemd Integration](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html)
- [Fedora CoreOS Documentation](https://docs.fedoraproject.org/en-US/fedora-coreos/)

### Additional Resources
- [Cockpit on CoreOS](https://cockpit-project.org/running.html#coreos)
- [Gitea Actions Guide](https://chrisliebaer.de/blog/gitea-actions/)
- [Just Task Runner Manual](https://just.systems/man/en/)
- [Age Encryption Issue #578](https://github.com/FiloSottile/age/issues/578)
