# Setup

Requirements on your workstation:
- just >= 1.39.0
- podman
- Python 3 (for local file server)
- Optional: qemu-kvm (for local VM testing)

Container images used (pulled automatically by `just` when invoked):
- Butane: quay.io/coreos/butane:release
- CoreOS Installer: quay.io/coreos/coreos-installer:release
- mkpasswd: quay.io/coreos/mkpasswd:latest
- sops: quay.io/getsops/sops:v3.10.2
- yq: ghcr.io/mikefarah/yq:latest

Local files to be aware of:
- build/: Generated artifacts (Ignition files, images)
- services/: Service-specific Butane configurations
- central.bu.yml: Host-level Butane config that merges per-service Ignition

First-time steps:
1) Install dependencies (just, podman, qemu-kvm if you want to test locally).
2) Clone the repo and ensure `just --version` >= 1.39.0.
3) Optional: Log in to container registry if your environment requires it for pulling public images.
4) Generate a password hash for the `core` user:
   - Run: `just mkpasswd --method=yescrypt`
   - Update `central.bu.yml` passwd.users[0].password_hash with the output.
