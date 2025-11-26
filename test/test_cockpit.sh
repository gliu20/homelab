#!/usr/bin/env bash

set -euo pipefail

# Test script for Cockpit.

# Source the shared library.
# shellcheck source=test/lib.sh
source "$(dirname "$0")/lib.sh"

main() {
    echo "Installing Python (dependency for Cockpit)..."
    run_ssh "sudo rpm-ostree install -y python"

    echo "Rebooting to apply changes..."
    run_ssh "sudo systemctl reboot" || true

    # Wait a bit for the reboot to start
    sleep 10

    wait_for_ssh

    echo "Checking Cockpit service status..."
    if run_ssh "systemctl is-active --quiet cockpit.service"; then
        echo "Cockpit service is active."
    else
        echo "Cockpit service is not active."
        exit 1
    fi

    echo "Checking Cockpit web interface..."
    if curl --fail http://localhost:9091; then
        echo "Cockpit web interface is up."
    else
        echo "Cockpit web interface is down."
        exit 1
    fi
}

main
