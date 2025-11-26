#!/usr/bin/env bash

set -euo pipefail

# Central test runner.
# This script starts the QEMU VM once, runs all test suites,
# and then stops the VM.

# Source the shared library.
# shellcheck source=test/lib.sh
source "$(dirname "$0")/lib.sh"

# It is a good practice to ensure cleanup happens on exit.
trap stop_qemu EXIT

main() {
    start_qemu
    wait_for_ssh

    echo "Running Cockpit tests..."
    "$(dirname "$0")/test_cockpit.sh"

    echo "Running Tailscale tests..."
    "$(dirname "$0")/test_tailscale.sh"
}

main
