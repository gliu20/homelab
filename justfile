help:
    @just --list

# We expect just >= 1.39.0 for require function to work

podman := require("podman")
python := require("python")
just := require("just")

# Container images

butane_img := "quay.io/coreos/butane:release"
coreos_installer_img := "quay.io/coreos/coreos-installer:release"
sops_img := "quay.io/getsops/sops:v3.10.2"
yq_img := "ghcr.io/mikefarah/yq:latest"

build in_file="central.bu" out_file="build/central.ign":
    @echo "Transpiling {{ in_file }} to {{ out_file }}"
    just butane "--pretty --strict --files-dir . \"{{ in_file }}\" -o \"{{ out_file }}\""
    @echo "Done. Output written to {{ out_file }}"

serve: build
    python -m http.server -d build 8000

dev: build

alias b := build
alias f := format

format: just-format butane-format

# We do not trust the images so we disallow network and most permissions
[group("podman-tools")]
podman_run img args:
    @podman run --interactive --rm -v "${PWD}:/pwd" --workdir /pwd \
    --security-opt=no-new-privileges --cap-drop=all --network=none \
    "{{ img }}" {{ args }}

[group("podman-tools")]
podman_run_w_network img args:
    @podman run --interactive --rm -v "${PWD}:/pwd" --workdir /pwd \
    --security-opt=no-new-privileges --cap-drop=all \
    --network slirp4netns:enable_ipv6=false,allow_host_loopback=true \
    "{{ img }}" {{ args }}

[group("podman-tools")]
butane args: (podman_run butane_img args)

[group("podman-tools")]
coreos_installer args: (podman_run_w_network coreos_installer_img args)

[group("podman-tools")]
sops args: (podman_run sops_img args)

[group("podman-tools")]
yq args: (podman_run yq_img args)

[group("podman-tools")]
yq-pretty-print in_file:
    just yq "eval -P --inplace \"{{ in_file }}\""

[group("qemu-test")]
download_fcos: (coreos_installer "download -s stable -p qemu -f qcow2.xz --decompress -C build/")

[group("qemu-test")]
deploy_fcos_qemu:
    #!/usr/bin/env bash
    IGNITION_CONFIG="build/central.ign"
    IMAGE="build/fedora-coreos-42.20250705.3.0-qemu.x86_64.qcow2"
    # for x86/aarch64:
    IGNITION_DEVICE_ARG="-fw_cfg name=opt/com.coreos/config,file=${IGNITION_CONFIG}"

    qemu-kvm -m 2048 -cpu host -nographic -snapshot \
    -drive "if=virtio,file=${IMAGE}" ${IGNITION_DEVICE_ARG} \
    -nic user,model=virtio,hostfwd=tcp::2222-:22 
[group("format")]
butane-format:
    #!/usr/bin/env bash
    set -euo pipefail
    find . -type f -name "*.bu" -print0 | while IFS= read -r -d '' file; do
        echo "Formatting $file..."
        # We need to pipe in /dev/null otherwise `just` will consume
        # rest of stdin, prematurely ending the loop
        just yq-pretty-print "$file" < /dev/null
    done
    echo "All *.bu files have been formatted."

[group("format")]
just-format:
    just --fmt --unstable
    @echo "Done. Formatted justfile."
