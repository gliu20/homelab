help:
    @just --list

# We expect just >= 1.39.0 for require function to work
podman := require("podman")
python := require("python")
just := require("just")
yamllint := require("yamllint")

# --- Configuration ---

butane_img           := "quay.io/coreos/butane:release"
coreos_installer_img := "quay.io/coreos/coreos-installer:release"
mkpasswd_img         := "quay.io/coreos/mkpasswd:latest"
sops_img             := "quay.io/getsops/sops:v3.10.2"
yq_img               := "ghcr.io/mikefarah/yq:latest"

# --- Primary Build Targets ---

build:
    @echo "Transpiling all *.bu.yml files..."
    @find . -type f -name "*.bu.yml" -exec just transpile_ign_wrapper '{}' \;
    @echo "All *.bu.yml files have been transpiled."

build-central:
    @just transpile_ign central.bu.yml build/central.ign

# Helper to dynamically set output path for `transpile_ign`
transpile_ign_wrapper in_file:
    #!/usr/bin/env bash
    set -euo pipefail
    output_path="build/$(dirname "{{in_file}}")"
    filename=$(basename "{{in_file}}")
    filename_no_ext="${filename%.*}"
    filename_no_sub_ext="${filename_no_ext%.*}"
    mkdir -p "$output_path"
    just transpile_ign "{{in_file}}" "$output_path/$filename_no_sub_ext.ign"

transpile_ign in_file="central.bu.yml" out_file="build/central.ign":
    @echo "Transpiling {{ in_file }} to {{ out_file }}"
    @just butane "--pretty --strict --files-dir . \"{{ in_file }}\" -o \"{{ out_file }}\""
    @echo "Done. Output written to {{ out_file }}"

# --- Development & Testing ---

dev: build

serve: build
    @echo "Serving build artifacts at http://localhost:8000"
    @python -m http.server -d build 8000

validate-configs:
    #!/usr/bin/env bash
    set -euo pipefail
    status=0
    while IFS= read -r -d '' file; do
        echo "Validating $file"
        if ! just butane "--pretty --strict --files-dir . \"$file\" -o /dev/null" < /dev/null; then
            echo "Validation failed: $file"
            status=1
        fi
    done < <(find . -type f -name "*.bu.yml" -print0)
    if [ "$status" -ne 0 ]; then
        echo "One or more Butane files failed validation."
        exit "$status"
    fi
    echo "All Butane files validated successfully."

[group("qemu-test")]
download_fcos:
    @just coreos_installer "download -s stable -p qemu -f qcow2.xz --decompress -C build/"

[group("qemu-test")]
deploy_fcos_qemu: build-central
    #!/usr/bin/env bash
    set -euo pipefail
    IGNITION_CONFIG=$(realpath "build/central.ign")
    IMAGE=$(find build -name "fedora-coreos-*.qcow2" | sort -r | head -n 1)
    if [ -z "$IMAGE" ]; then
        echo "QEMU image not found in build/ directory."
        echo "Please run 'just download_fcos' first."
        exit 1
    fi
    # for x86/aarch64:
    IGNITION_DEVICE_ARG="-fw_cfg name=opt/com.coreos/config,file=${IGNITION_CONFIG}"
    echo "To quit, press Ctrl+A then hit x"
    qemu-kvm -m 2048 -cpu host -nographic -snapshot \
        -drive "if=virtio,file=${IMAGE}" ${IGNITION_DEVICE_ARG} \
        -nic user,model=virtio,hostfwd=tcp::2222-:22,hostfwd=tcp::9091-:9090

# --- Formatting & Cleanup ---

format: just-format butane-format lint

[group("format")]
just-format:
    @just --fmt --unstable
    @echo "Done. Formatted justfile."

[group("format")]
butane-format:
    @echo "Formatting all *.bu.yml files..."
    @find . -type f -name "*.bu.yml" -exec just yq-pretty-print '{}' \;
    @echo "All *.bu.yml files have been formatted."

[group("format")]
lint:
    @echo "Linting all *.bu.yml files..."
    @yamllint .
    @echo "Done."

clean:
    @echo "Cleaning build artifacts..."
    @find build/ -type f -name "*.ign" -delete
    @find build/ -type d -empty -delete
    @echo "Done."

# --- Utility & Helper Tasks ---

list-services:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Services (*.bu.yml under services/):"
    find services -type f -name "*.bu.yml" -printf " - %P\n" | sort || true
    echo
    echo "central.bu.yml ignition.config.merge targets:"
    grep -E "local:\s+build/services/.+\.ign" -n central.bu.yml || true

mkpasswd args="--method=yescrypt": (podman_run_w_tty mkpasswd_img args)

yq-pretty-print in_file:
    @just yq "eval -P \"{{ in_file }}\"" > "{{ in_file }}.tmp"
    @mv "{{ in_file }}.tmp" "{{ in_file }}"

# --- Podman Tool Wrappers ---

[group("podman-tools")]
podman_run img args:
    @podman run --interactive --rm -v "${PWD}:/pwd:Z" --workdir /pwd \
    --security-opt=no-new-privileges --cap-drop=all --network=none \
    "{{ img }}" {{ args }}

# This is a workaround for seccomp issues in some environments (e.g., Ubuntu 24.04).
[group("podman-tools")]
podman_run_unconfined img args:
    @podman run --interactive --rm -v "${PWD}:/pwd:Z" --workdir /pwd \
    --security-opt=no-new-privileges --cap-drop=all --network=none \
    --security-opt seccomp=unconfined \
    "{{ img }}" {{ args }}

[group("podman-tools")]
podman_run_w_network img args:
    @podman run --interactive --rm -v "${PWD}:/pwd:Z" --workdir /pwd \
    --security-opt=no-new-privileges --cap-drop=all \
    --network slirp4netns:enable_ipv6=false,allow_host_loopback=true \
    "{{ img }}" {{ args }}

[group("podman-tools")]
podman_run_w_tty img args:
    @podman run --interactive --tty --rm -v "${PWD}:/pwd:Z" --workdir /pwd \
    --security-opt=no-new-privileges --cap-drop=all --network=none \
    "{{ img }}" {{ args }}

[group("podman-tools")]
butane args: (podman_run_unconfined butane_img args)

[group("podman-tools")]
coreos_installer args: (podman_run_w_network coreos_installer_img args)

[group("podman-tools")]
sops args: (podman_run sops_img args)

[group("podman-tools")]
yq args: (podman_run yq_img args)

# --- Aliases ---

alias b := build
alias f := format
