#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
CONFIG_PATH="${REPO_ROOT}/Sources/ISOInspectorKit/Resources/Distribution/DistributionMetadata.json"

usage() {
    cat <<USAGE
Usage: $0 --artifact <path-to-zip> [--profile <keychain-profile>] [--dry-run]

Submits the packaged ISOInspector app bundle to Apple's notarization service
using \`xcrun notarytool\`. Credentials should be stored in a keychain profile
configured via \`xcrun notarytool store-credentials\` and referenced with the
\`--profile\` flag or the \`NOTARYTOOL_PROFILE\` environment variable.

Examples:
  $0 --artifact build/ISOInspector.zip --profile isoinspector-notary
  $0 --artifact build/ISOInspector.zip --dry-run
USAGE
}

ARTIFACT=""
PROFILE="${NOTARYTOOL_PROFILE:-isoinspector-notary}"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --artifact)
            ARTIFACT="$2"
            shift 2
            ;;
        --profile)
            PROFILE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage
            exit 1
            ;;
    esac
done

if [[ -z "$ARTIFACT" ]]; then
    echo "error: --artifact is required" >&2
    usage
    exit 1
fi

if [[ ! -f "$ARTIFACT" ]]; then
    echo "error: artifact '$ARTIFACT' does not exist" >&2
    exit 1
fi

TEAM_ID=$(python3 - <<'PY'
import json
import pathlib
config_path = pathlib.Path("${CONFIG_PATH}")
config = json.loads(config_path.read_text())
print(config["teamIdentifier"])
PY
)

if [[ $DRY_RUN -eq 1 ]]; then
    cat <<INFO
[DRY RUN] Notarization submission skipped.
Would run:
  xcrun notarytool submit "$ARTIFACT" --wait --team-id "$TEAM_ID" --profile "$PROFILE"
INFO
    exit 0
fi

if ! command -v xcrun >/dev/null 2>&1; then
    echo "error: xcrun not found. Run with --dry-run on non-macOS hosts." >&2
    exit 1
fi

xcrun notarytool submit "$ARTIFACT" --wait --team-id "$TEAM_ID" --profile "$PROFILE"
