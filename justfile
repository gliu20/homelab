help:
    @just --list

# We expect just >= 1.39.0 for require function to work

podman := require("podman")
python := require("python")
just := require("just")

# Container images

butane_img := "quay.io/coreos/butane:release"
sops_img := "quay.io/getsops/sops:v3.10.2"
yq_img := "ghcr.io/mikefarah/yq"

build in_file="central.bu" out_file="build/central.ign":
    @echo "Transpiling {{ in_file }} to {{ out_file }}"
    just butane "--pretty --strict --files-dir . \"{{ in_file }}\" -o \"{{ out_file }}\""
    @echo "Done. Output written to {{ out_file }}"

serve:
    python -m http.server -d build 8000

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
butane args: (podman_run butane_img args)

[group("podman-tools")]
sops args: (podman_run sops_img args)

[group("podman-tools")]
yq args: (podman_run yq_img args)

[group("podman-tools")]
yq-pretty-print in_file:
    just yq "eval -P --inplace \"{{ in_file }}\""

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
