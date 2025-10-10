#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
OUTPUT_ROOT="${1:-${REPO_ROOT}/Documentation/DocC}"

echo "Generating DocC archives into ${OUTPUT_ROOT}" >&2
mkdir -p "${OUTPUT_ROOT}"

TARGETS=(ISOInspectorKit ISOInspectorCLI ISOInspectorApp)

for target in "${TARGETS[@]}"; do
  TARGET_OUTPUT="${OUTPUT_ROOT}/${target}"
  mkdir -p "${TARGET_OUTPUT}"
  echo "→ Building documentation for ${target}" >&2
  swift package \
    --allow-writing-to-directory "${TARGET_OUTPUT}" \
    generate-documentation \
    --target "${target}" \
    --output-path "${TARGET_OUTPUT}" \
    --transform-for-static-hosting \
    --hosting-base-path "${target}"
done

echo "DocC archives available under ${OUTPUT_ROOT}" >&2
