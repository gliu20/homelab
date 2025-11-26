help:
    @just --list

# We expect just >= 1.39.0 for require function to work

podman := require("podman")
python := require("python")
just := require("just")

# Container images

butane_img := "quay.io/coreos/butane:release"
coreos_installer_img := "quay.io/coreos/coreos-installer:release"
mkpasswd_img := "quay.io/coreos/mkpasswd:latest"
sops_img := "quay.io/getsops/sops:v3.10.2"
yq_img := "ghcr.io/mikefarah/yq:latest"

build:
    #!/usr/bin/env bash
    set -euo pipefail
    find . -type f -name "*.bu.yml" -print0 | while IFS= read -r -d '' file; do
        fullpath="$(realpath --relative-to="$PWD" "$file")"
        output_path="$(dirname "build/$fullpath")"
        filename="$(basename "$fullpath")"
        filename_no_ext="${filename%.*}"
        filename_no_sub_ext="${filename_no_ext%.*}"

        mkdir -p "$output_path"
        # We need to pipe in /dev/null otherwise `just` will consume
        # rest of stdin, prematurely ending the loop
        just transpile_ign "$fullpath" "$output_path/$filename_no_sub_ext.ign" < /dev/null
    done
    echo "All *.bu.yml files have been transpiled."

# Build only the main host Ignition
build-central:
    just transpile_ign central.bu.yml build/central.ign

transpile_ign in_file="central.bu.yml" out_file="build/central.ign":
    @echo "Transpiling {{ in_file }} to {{ out_file }}"
    just butane "--pretty --strict --files-dir . \"{{ in_file }}\" -o \"{{ out_file }}\""
    @echo "Done. Output written to {{ out_file }}"

serve: build
    python -m http.server -d build 8000

dev: build

mkpasswd args="--method=yescrypt": (podman_run_w_tty mkpasswd_img args)

alias b := build
alias f := format

format: just-format butane-format

# We do not trust the images so we disallow network and most permissions
[group("podman-tools")]
podman_run img args:
    @podman run --interactive --rm -v "${PWD}:/pwd:Z" --workdir /pwd \
    --security-opt=no-new-privileges --cap-drop=all --network=none \
    "{{ img }}" {{ args }}

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
podman_run_w_network_unconfined img args:
    @podman run --interactive --rm -v "${PWD}:/pwd:Z" --workdir /pwd \
    --security-opt=no-new-privileges --cap-drop=all \
    --network slirp4netns:enable_ipv6=false,allow_host_loopback=true \
    --security-opt seccomp=unconfined \
    "{{ img }}" {{ args }}

[group("podman-tools")]
podman_run_w_tty img args:
    @podman run --interactive --tty --rm -v "${PWD}:/pwd:Z" --workdir /pwd \
    --security-opt=no-new-privileges --cap-drop=all --network=none \
    "{{ img }}" {{ args }}

[group("podman-tools")]
butane args: (podman_run_unconfined butane_img args)

[group("podman-tools")]
coreos_installer args: (podman_run_w_network_unconfined coreos_installer_img args)

[group("podman-tools")]
sops args: (podman_run sops_img args)

[group("podman-tools")]
yq args: (podman_run yq_img args)

[group("podman-tools")]
yq-pretty-print in_file:
    just yq "eval -P \"{{ in_file }}\"" > "{{ in_file }}.tmp"
    mv "{{ in_file }}.tmp" "{{ in_file }}"

[group("qemu-test")]
download_fcos: (coreos_installer "download -s stable -p qemu -f qcow2.xz --decompress -C build/")

[group("qemu-test")]
deploy_fcos_qemu:
    #!/usr/bin/env bash
    IGNITION_CONFIG=$(realpath "build/central.ign")
    IMAGE="build/fedora-coreos-42.20250705.3.0-qemu.x86_64.qcow2"
    # for x86/aarch64:
    IGNITION_DEVICE_ARG="-fw_cfg name=opt/com.coreos/config,file=${IGNITION_CONFIG}"
    echo "To quit, press Ctrl+A then hit x"
    qemu-kvm -m 2048 -cpu host -nographic -snapshot \
    -drive "if=virtio,file=${IMAGE}" ${IGNITION_DEVICE_ARG} \
    -nic user,model=virtio,hostfwd=tcp::2222-:22,hostfwd=tcp::9091-:9090

# Automated E2E tests
test:
    @echo "Running E2E tests..."
    @./test/run_all_tests.sh

[group("format")]
butane-format:
    #!/usr/bin/env bash
    set -euo pipefail
    find . -type f -name "*.bu.yml" -print0 | while IFS= read -r -d '' file; do
        fullpath="$(realpath --relative-to="$PWD" "$file")"
        echo "Formatting $fullpath..."
        # We need to pipe in /dev/null otherwise `just` will consume
        # rest of stdin, prematurely ending the loop
        just yq-pretty-print "$fullpath" < /dev/null
    done
    echo "All *.bu.yml files have been formatted."

[group("format")]
just-format:
    just --fmt --unstable
    @echo "Done. Formatted justfile."

# Validation and discovery helpers
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

list-services:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Services (*.bu.yml under services/):"
    find services -type f -name "*.bu.yml" -printf " - %P\n" | sort || true
    echo
    echo "central.bu.yml ignition.config.merge targets:"
    grep -E "local:\s+build/services/.+\.ign" -n central.bu.yml || true

clean:
    #!/usr/bin/env bash
    set -euox pipefail
    find build/ -type f -name "*.ign" -delete
    find build/ -type d -empty -delete
