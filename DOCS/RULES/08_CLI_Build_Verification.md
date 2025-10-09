# Rule 8: Verify ISOInspectorCLI Builds on Linux

Maintainers must ensure the command-line interface target `ISOInspectorCLI` builds successfully in a Linux environment. The repository ships with a helper script that performs all required checks locally or inside a Swift Docker image.

## ✅ Rule 8 Requirements

- Run the CLI verification script before cutting releases or merging changes that affect the CLI.
- The script must complete without failures, confirming the CLI target and its `isoinspect` executable product compile with warnings treated as errors.
- Prefer the Docker-backed execution mode to reproduce the canonical Linux build unless you are already on Linux with a

  compatible Swift toolchain.

## ▶️ Verification Script

Execute the helper from the repository root:

```bash
./scripts/check_cli_linux.sh

```

### Options

| Environment Variable | Default            | Description |
| -------------------- | ------------------ | ----------- |
| `USE_DOCKER`         | `1`                | When set to `1`, runs checks inside the official Swift Docker image. Set to `0` to run on the host. |
| `SWIFT_IMAGE`        | `swift:5.9-jammy`  | Docker image tag used when `USE_DOCKER=1`. |
| `CLI_TARGET`         | `ISOInspectorCLI`  | Swift target name compiled by the script. |
| `CLI_PRODUCT`        | `isoinspect`       | Executable product name validated after the build. |

When Docker is enabled, the script mounts the repository into the container and reruns itself with `USE_DOCKER=0` to perform the Swift package operations.

## 📋 What the Script Checks

1. Resolves package dependencies.
1. Builds the full package in release mode with warnings treated as errors.
1. Runs the test suite in parallel.
1. Builds the `ISOInspectorCLI` target in release mode with warnings as errors.
1. Builds the distributable `isoinspect` executable and prints the binary path.

If any of these steps fail, the CLI is not considered Linux-ready and the issue must be resolved before proceeding.
