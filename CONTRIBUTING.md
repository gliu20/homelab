# Contributing

We welcome contributions to this project! To ensure a consistent and high-quality codebase, we've established a set of coding standards and best practices. Please take a moment to review these guidelines before submitting your changes.

## Butane and Ignition

- **Clarity and Comments**: Butane files should be well-documented with comments that explain the purpose of each service, configuration, and any security-sensitive settings.
- **Service Definitions**: Each service should have its own Butane file in the `services/` directory. This file should define all the necessary resources for the service, including container definitions, storage, and networking.
- **Security**: Be mindful of the security implications of your changes. Avoid running containers with unnecessary privileges, and use dedicated environment files for secrets.

## Justfile

- **Default Goal**: The `justfile` should have a default goal (`all`) that runs the most common tasks, such as validation and building.
- **Task Organization**: Tasks should be organized into logical groups (e.g., `[format]`, `[qemu-test]`) to make them easy to find and understand.
- **Containerized Tools**: Whenever possible, use containerized tools to ensure a consistent development environment.

## Linting

To maintain a consistent coding style, we use `yamllint` to lint all Butane files. Before submitting your changes, please run the following command to check for any style violations:

```bash
just lint
```

## Known Issues

- The `just download_fcos` command may fail in some environments due to a `podman` seccomp issue. If you encounter this issue, please download the Fedora CoreOS QEMU image manually and place it in the `build/` directory.

## Submitting Changes

1.  Fork the repository and create a new branch for your changes.
2.  Make your changes, following the coding standards and best practices outlined in this document.
3.  Run `just` to validate your changes and ensure that the Butane configurations can be transpiled without errors.
4.  Run `just lint` to check for any style violations.
5.  Commit your changes and push them to your fork.
6.  Open a pull request, and we'll review your changes as soon as possible.

Thank you for your contributions!
