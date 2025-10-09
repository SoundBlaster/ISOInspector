#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"

cd "$REPO_ROOT"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required to run SwiftLint formatting via the provided container." >&2
  exit 1
fi

docker run --rm \
  -v "$PWD":"$PWD" \
  -w "$PWD" \
  ghcr.io/realm/swiftlint:0.53.0 \
  swiftlint lint --autocorrect --strict "$@"
