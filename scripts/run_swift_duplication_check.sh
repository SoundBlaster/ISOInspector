#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT_PATH="${REPORT_PATH:-${REPO_ROOT}/artifacts/swift-duplication-report.txt}"

mkdir -p "$(dirname "${REPORT_PATH}")"
cd "${REPO_ROOT}"

# Quiet npm funding prompts to keep CI logs clean.
npm config set fund false >/dev/null 2>&1 || true

IGNORE_PATTERNS=(
  "**/Derived/**"
  "**/Documentation/**"
  "**/.build/**"
  "**/TestResults-*/**"
  "**/artifacts/**"
)

IFS=,
IGNORE_PATTERN="${IGNORE_PATTERNS[*]}"
unset IFS

CMD=(
  npx -y jscpd@3.5.10
  --format swift
  --pattern "**/*.swift"
  --reporters console
  --min-tokens 120
  --threshold 1
  --max-lines 45
  --ignore "${IGNORE_PATTERN}"
  Sources
  Tests
  FoundationUI
  Examples
)

"${CMD[@]}" | tee "${REPORT_PATH}"
