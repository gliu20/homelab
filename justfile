
default: help

# We expect just >= 1.39.0 for require function to work
jq := require("jq")
podman := require("podman")
just := require("just")

build:
    #!/usr/bin/env bash
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
        --pretty --strict "$INPUT_FILE" > "$OUTPUT_FILE" \
        --files-dir .

    echo "Done. Output written to $OUTPUT_FILE"


help:
    @just --list

