default: help

# We expect just >= 1.39.0 for require function to work

jq := require("jq")
podman := require("podman")
just := require("just")
butane_img := "quay.io/coreos/butane:release"

build in_file="central.bu" out_file="central.ign":
    @echo "Transpiling {{ in_file }} to {{ out_file }}..."
    podman run --interactive --rm --security-opt label=disable \
        --volume "${PWD}:/pwd" --workdir /pwd "{{ butane_img }}" \
        --pretty --strict "{{ in_file }}" > "{{ out_file }}" \
        --files-dir .
    @echo "Done. Output written to {{ out_file }}"

[group("just-meta")]
format:
    just --fmt --unstable
    @echo "Done. Formatted justfile."

[group("just-meta")]
help:
    @just --list
