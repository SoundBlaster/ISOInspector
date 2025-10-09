#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)

SWIFT_IMAGE="${SWIFT_IMAGE:-swift:5.9-jammy}"
CLI_TARGET="${CLI_TARGET:-ISOInspectorCLI}"
CLI_PRODUCT="${CLI_PRODUCT:-isoinspect}"
USE_DOCKER="${USE_DOCKER:-1}"

run_checks() {
  pushd "${REPO_ROOT}" > /dev/null
  swift package resolve
  swift build -c release -Xswiftc -warnings-as-errors
  swift test --parallel
  swift build -c release --target "${CLI_TARGET}" -Xswiftc -warnings-as-errors
  swift build -c release --product "${CLI_PRODUCT}" -Xswiftc -warnings-as-errors
  BIN_PATH=$(swift build -c release --show-bin-path)
  echo "CLI binary: ${BIN_PATH}/${CLI_PRODUCT}"
  popd > /dev/null
}

if [[ "${USE_DOCKER}" == "1" ]]; then
  docker run --rm -t -v "${REPO_ROOT}":/workspace -w /workspace "${SWIFT_IMAGE}" \
    bash -lc "USE_DOCKER=0 CLI_TARGET=\"${CLI_TARGET}\" CLI_PRODUCT=\"${CLI_PRODUCT}\" ./scripts/check_cli_linux.sh"
else
  run_checks
fi
