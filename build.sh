#!/usr/bin/env bash

# Exit on error, undefined variable, or error in a pipeline
set -euo pipefail

# Configuration
INPUT_FILE="central.bu"
OUTPUT_FILE="central.ign"
BUTANE_IMAGE="quay.io/coreos/butane:release"

# Optional: Check if input file exists
if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: Input file '$INPUT_FILE' not found."
    exit 1
fi

echo "Transpiling $INPUT_FILE to $OUTPUT_FILE..."

podman run --interactive --rm --security-opt label=disable \
    --volume "${PWD}:/pwd" --workdir /pwd "$BUTANE_IMAGE" \
    --pretty --strict "$INPUT_FILE" > "$OUTPUT_FILE"

echo "Done. Output written to $OUTPUT_FILE"
