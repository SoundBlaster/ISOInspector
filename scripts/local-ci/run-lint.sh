#!/usr/bin/env bash
# Run linting and formatting checks locally
# Mirrors: ci.yml, swift-linux.yml, swiftlint.yml

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source libraries
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=lib/ci-env.sh
source "$SCRIPT_DIR/lib/ci-env.sh"
# shellcheck source=lib/docker-helpers.sh
source "$SCRIPT_DIR/lib/docker-helpers.sh"

# Configuration
REPO_ROOT=$(detect_repo_root)
cd "$REPO_ROOT"

show_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Run linting and formatting checks (SwiftLint, swift-format, JSON validation)

OPTIONS:
    -m, --mode MODE         SwiftLint mode: native or docker (default: from config)
    -f, --fix              Auto-fix issues where possible
    --skip-swiftlint       Skip SwiftLint checks
    --skip-format          Skip swift-format checks
    --skip-json            Skip JSON validation
    -v, --verbose          Verbose output
    -h, --help             Show this help message

EXAMPLES:
    # Run all checks with native SwiftLint
    $(basename "$0")

    # Run with Docker SwiftLint
    $(basename "$0") --mode docker

    # Auto-fix issues
    $(basename "$0") --fix

    # Skip specific checks
    $(basename "$0") --skip-json --skip-format
EOF
}

# Parse arguments
SWIFTLINT_MODE_OVERRIDE=""
AUTO_FIX=false
SKIP_SWIFTLINT=false
SKIP_FORMAT=false
SKIP_JSON=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--mode)
            SWIFTLINT_MODE_OVERRIDE="$2"
            shift 2
            ;;
        -f|--fix)
            AUTO_FIX=true
            shift
            ;;
        --skip-swiftlint)
            SKIP_SWIFTLINT=true
            shift
            ;;
        --skip-format)
            SKIP_FORMAT=true
            shift
            ;;
        --skip-json)
            SKIP_JSON=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Load configuration
load_config

# Override mode if specified
if [[ -n "$SWIFTLINT_MODE_OVERRIDE" ]]; then
    SWIFTLINT_MODE="$SWIFTLINT_MODE_OVERRIDE"
fi

# Validate environment
validate_ci_environment

# Track failures
FAILURES=0

# ============================================================================
# JSON Validation
# ============================================================================
if [[ "$SKIP_JSON" != "true" ]]; then
    log_section "JSON Validation"

    if timed_run "JSON validation" python3 scripts/validate_json.py; then
        log_success "JSON validation passed"
    else
        log_error "JSON validation failed"
        ((FAILURES++))
    fi
fi

# ============================================================================
# Swift Format Check
# ============================================================================
if [[ "$SKIP_FORMAT" != "true" ]]; then
    log_section "Swift Format Check"

    if [[ "$AUTO_FIX" == "true" ]]; then
        log_info "Auto-fixing Swift formatting..."
        if timed_run "Swift format (fix)" swift format --in-place --recursive Sources Tests; then
            log_success "Swift formatting applied"
        else
            log_error "Swift format failed"
            ((FAILURES++))
        fi
    else
        log_info "Checking Swift code formatting (lint mode)..."
        if timed_run "Swift format (lint)" swift format lint --recursive Sources Tests; then
            log_success "All Swift files are correctly formatted"
        else
            log_error "Swift code is not formatted correctly"
            log_info "Run locally to fix: swift format --in-place --recursive Sources Tests"
            ((FAILURES++))
        fi
    fi
fi

# ============================================================================
# SwiftLint
# ============================================================================
if [[ "$SKIP_SWIFTLINT" != "true" ]]; then
    log_section "SwiftLint ($SWIFTLINT_MODE mode)"

    # Function to run SwiftLint on a specific config
    run_swiftlint_check() {
        local name="$1"
        local work_dir="$2"
        local config="$3"

        log_info "Running SwiftLint on $name..."

        if [[ "$SWIFTLINT_MODE" == "docker" ]]; then
            if [[ "$AUTO_FIX" == "true" ]]; then
                run_swiftlint_autocorrect_docker "$work_dir" "$config"
            fi
            run_swiftlint_docker "$work_dir" "$config" --strict
        else
            # Native mode
            pushd "$work_dir" >/dev/null

            if [[ "$AUTO_FIX" == "true" ]]; then
                swiftlint --fix --config "$config" || true
            fi

            swiftlint lint --strict --config "$config"
            local result=$?

            popd >/dev/null
            return $result
        fi
    }

    # Main Project
    if timed_run "SwiftLint (Main Project)" run_swiftlint_check "Main Project" "$REPO_ROOT" ".swiftlint.yml"; then
        log_success "Main Project SwiftLint passed"
    else
        log_error "Main Project SwiftLint failed"
        ((FAILURES++))
    fi

    # FoundationUI
    if [[ -d "$REPO_ROOT/FoundationUI" ]]; then
        if timed_run "SwiftLint (FoundationUI)" run_swiftlint_check "FoundationUI" "$REPO_ROOT/FoundationUI" ".swiftlint.yml"; then
            log_success "FoundationUI SwiftLint passed"
        else
            log_error "FoundationUI SwiftLint failed"
            ((FAILURES++))
        fi
    fi

    # ComponentTestApp
    if [[ -d "$REPO_ROOT/Examples/ComponentTestApp" ]]; then
        if timed_run "SwiftLint (ComponentTestApp)" run_swiftlint_check "ComponentTestApp" "$REPO_ROOT/Examples/ComponentTestApp" "../../.swiftlint.yml"; then
            log_success "ComponentTestApp SwiftLint passed"
        else
            log_error "ComponentTestApp SwiftLint failed"
            ((FAILURES++))
        fi
    fi
fi

# ============================================================================
# Summary
# ============================================================================
log_section "Lint Summary"

if [[ $FAILURES -eq 0 ]]; then
    log_success "All linting checks passed! ✨"
    exit 0
else
    log_error "$FAILURES check(s) failed"
    exit 1
fi
