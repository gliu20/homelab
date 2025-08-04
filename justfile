default: help

check-dev-deps:
    #!/usr/bin/env bash
    set -euo pipefail
    
    dependencies=("jq" "just" "podman")
    missing=()
    
    check_dependency()
    {
        local cmd="$1"
        if command -v "$cmd" &> /dev/null; then
            echo "  $cmd: $(command -v "$cmd")"
            return 0
        else
            echo "  $cmd: not found"
            return 1
        fi
    }

    echo "Checking development dependencies..."

    for dep in "${dependencies[@]}"; do
        if ! check_dependency "$dep"; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -eq 0 ]; then
        echo "All development dependencies are installed"
    else
        echo "Missing required development dependencies:"
        for dep in "${missing[@]}"; do
            echo "  - $dep"
        done
        echo ""
        echo "Please install the missing dependencies before continuing."
        exit 1
    fi


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

