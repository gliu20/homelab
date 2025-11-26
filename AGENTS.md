# Agent Environment Setup

This document outlines the necessary steps to set up the development environment for this repository within a Debian-based sandbox.

## Prerequisites

The following tools and configurations are required to build, test, and run the code in this repository.

### 1. Install System Dependencies

Install `podman` and `python3`:

```bash
sudo apt-get update && sudo apt-get install -y podman python3
```

### 2. Install `just`

This project uses `just` as a command runner. The version required is >= 1.39.0.

```bash
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | sudo bash -s -- --to /usr/local/bin
```

### 3. Create a `python` Symlink

The `justfile` expects a `python` executable. Create a symbolic link to `python3`:

```bash
sudo ln -s /usr/bin/python3 /usr/bin/python
```

### 4. Configure `podman` for Rootless Containers

`podman` requires subuid and subgid mappings for the current user.

```bash
echo "$(whoami):100000:65536" | sudo tee /etc/subuid
echo "$(whoami):100000:65536" | sudo tee /etc/subgid
```

### 5. Migrate `podman` Storage

Apply the new subuid/subgid configuration:

```bash
podman system migrate
```

## Environment Workaround

Due to a persistent `seccomp` issue in the development environment, the `justfile` contains a workaround to run `podman` with `--security-opt seccomp=unconfined` for certain build-related tasks. This is isolated to specific recipes and should not affect the final deployed artifact.
