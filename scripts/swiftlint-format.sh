#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"

cd "$REPO_ROOT"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required to run SwiftLint formatting via the provided container." >&2
  exit 1
fi

rm -f "$PWD/.swiftlint.cache"

docker run --rm \
  -u "$(id -u):$(id -g)" \
  -v "$PWD:/work" \
  -w /work \
  ghcr.io/realm/swiftlint:0.53.0 \
  swiftlint --fix --no-cache --config .swiftlint.yml "$@"
