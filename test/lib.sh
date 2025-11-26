#!/usr/bin/env bash

set -euo pipefail

# Shared library for QEMU-based tests.

# Constants
readonly IGNITION_CONFIG="build/central.ign"
readonly IMAGE="build/fedora-coreos-42.20250705.3.0-qemu.x86_64.qcow2"
readonly SSH_PORT="2222"
readonly SSH_USER="core"
readonly SSH_KEY="${HOME}/.ssh/id_rsa" # Assumes a key exists; replace if needed.
readonly SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

QEMU_PID=""

# Starts the QEMU VM in the background.
# The PID of the QEMU process is stored in the QEMU_PID global variable.
start_qemu() {
    echo "Starting QEMU VM..."
    if [[ ! -f "${IMAGE}" ]]; then
        echo "QEMU image not found. Please run 'just download_fcos'."
        exit 1
    fi
    if [[ ! -f "${IGNITION_CONFIG}" ]]; then
        echo "Ignition config not found. Please run 'just build-central'."
        exit 1
    fi

    local ignition_device_arg="-fw_cfg name=opt/com.coreos/config,file=${IGNITION_CONFIG}"
    qemu-kvm -m 2048 -cpu host -nographic -snapshot \
        -drive "if=virtio,file=${IMAGE}" "${ignition_device_arg}" \
        -nic user,model=virtio,hostfwd=tcp::${SSH_PORT}-:22,hostfwd=tcp::9091-:9090 >/dev/null 2>&1 &
    QEMU_PID=$!
    echo "QEMU started with PID ${QEMU_PID}."
}

# Stops the QEMU VM.
stop_qemu() {
    if [[ -n "${QEMU_PID}" ]]; then
        echo "Stopping QEMU VM (PID ${QEMU_PID})..."
        kill "${QEMU_PID}"
        wait "${QEMU_PID}" 2>/dev/null || true
        QEMU_PID=""
    fi
}

# Waits for the SSH server on the guest to become available.
wait_for_ssh() {
    echo "Waiting for SSH to become available..."
    for _ in {1..60}; do
        if ssh "${SSH_USER}@localhost" -p "${SSH_PORT}" ${SSH_OPTS} "echo 'SSH is up'" >/dev/null 2>&1; then
            echo "SSH is available."
            return 0
        fi
        sleep 5
    done
    echo "SSH did not become available after 5 minutes."
    return 1
}

# Runs a command on the guest VM via SSH.
run_ssh() {
    local cmd="$1"
    echo "Running command on guest: ${cmd}"
    ssh "${SSH_USER}@localhost" -p "${SSH_PORT}" ${SSH_OPTS} "${cmd}"
}
