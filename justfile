default: help

# We expect just >= 1.39.0 for require function to work

jq := require("jq")
podman := require("podman")
just := require("just")
butane_img := "quay.io/coreos/butane:release"
yq_img := "ghcr.io/mikefarah/yq"

podman_run img args:
    @podman run --interactive --rm -v "${PWD}:/pwd" --workdir /pwd \
    --security-opt=no-new-privileges --cap-drop=all --network=none \
    "{{ img }}" {{ args }}

butane args: (podman_run butane_img args)

build in_file="central.bu" out_file="central.ign":
    @echo "Transpiling {{ in_file }} to {{ out_file }}"
    just butane "--pretty --strict --files-dir . \"{{ in_file }}\" > \"{{ out_file }}\""
    @echo "Done. Output written to {{ out_file }}"

[group("just-meta")]
format:
    just --fmt --unstable
    @echo "Done. Formatted justfile."

[group("just-meta")]
help:
    @just --list
