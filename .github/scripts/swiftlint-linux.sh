#!/usr/bin/env bash
set -euo pipefail

# Keep the same pinned SwiftLint image as the Linux build-and-test workflow.
workdir="/work${PWD#"$GITHUB_WORKSPACE"}"
exec docker run --rm -u "$(id -u):$(id -g)" \
  -v "$GITHUB_WORKSPACE:/work" -v /tmp:/tmp -w "$workdir" \
  ghcr.io/realm/swiftlint:0.57.0 swiftlint "$@"
