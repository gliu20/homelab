#!/usr/bin/env bash

set -euo pipefail

# Test script for Tailscale.

# Source the shared library.
# shellcheck source=test/lib.sh
source "$(dirname "$0")/lib.sh"

main() {
    echo "Checking Tailscale service status..."
    if run_ssh "systemctl is-active --quiet tailscale.service"; then
        echo "Tailscale service is active."
    else
        echo "Tailscale service is not active."
        exit 1
    fi
}

main
