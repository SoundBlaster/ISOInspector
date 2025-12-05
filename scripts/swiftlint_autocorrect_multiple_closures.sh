#!/usr/bin/env bash
# Auto-correct Swift files that violate the multiple_closures_with_trailing_closure rule.
# This provides automation parity with SwiftFormat so SwiftLint can fix layout conflicts.

set -euo pipefail

RULE="multiple_closures_with_trailing_closure"
SWIFTLINT_BIN="${SWIFTLINT_BIN:-swiftlint}"

if ! command -v "$SWIFTLINT_BIN" >/dev/null 2>&1; then
    echo "SwiftLint is not installed. Install it (e.g. brew install swiftlint) to enable autocorrect." >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

run_autocorrect() {
    local working_dir="$1"
    local config_path="$2"

    if [[ ! -d "$working_dir" ]]; then
        return
    fi

    pushd "$working_dir" >/dev/null
    local only_rule_flag="--only-rules"
    if ! "$SWIFTLINT_BIN" lint --help 2>&1 | grep -q -- "--only-rules"; then
        only_rule_flag="--only-rule"
    fi

    if [[ -n "$config_path" && -f "$config_path" ]]; then
        "$SWIFTLINT_BIN" --autocorrect --strict "$only_rule_flag" "$RULE" --config "$config_path"
    else
        "$SWIFTLINT_BIN" --autocorrect --strict "$only_rule_flag" "$RULE"
    fi
    popd >/dev/null
}

# FoundationUI enforces multiple_closures_with_trailing_closure, so fix violations there.
run_autocorrect "$REPO_ROOT/FoundationUI" ".swiftlint.yml"
