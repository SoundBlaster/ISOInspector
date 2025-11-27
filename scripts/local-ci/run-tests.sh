#!/usr/bin/env bash
# Run test suites locally
# Mirrors: ci.yml, macos.yml, foundationui.yml, script-tests.yml

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

Run test suites (unit tests, snapshot tests, script tests)

OPTIONS:
    --spm-only             Only run Swift Package Manager tests
    --xcode-only           Only run Xcode tests
    --skip-ios             Skip iOS tests
    --skip-macos           Skip macOS tests
    --skip-snapshot        Skip snapshot tests
    --skip-scripts         Skip Python script tests
    --update-snapshots     Update snapshot baselines
    -v, --verbose          Verbose output
    -h, --help             Show this help message

EXAMPLES:
    # Run all tests
    $(basename "$0")

    # Run only SPM tests
    $(basename "$0") --spm-only

    # Update snapshots
    $(basename "$0") --update-snapshots

    # Skip iOS tests
    $(basename "$0") --skip-ios
EOF
}

# Parse arguments
SPM_ONLY=false
XCODE_ONLY=false
SKIP_IOS=false
SKIP_MACOS=false
SKIP_SNAPSHOT=false
SKIP_SCRIPTS=false
UPDATE_SNAPSHOTS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --spm-only)
            SPM_ONLY=true
            shift
            ;;
        --xcode-only)
            XCODE_ONLY=true
            shift
            ;;
        --skip-ios)
            SKIP_IOS=true
            shift
            ;;
        --skip-macos)
            SKIP_MACOS=true
            shift
            ;;
        --skip-snapshot)
            SKIP_SNAPSHOT=true
            shift
            ;;
        --skip-scripts)
            SKIP_SCRIPTS=true
            shift
            ;;
        --update-snapshots)
            UPDATE_SNAPSHOTS=true
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

# Load configuration and validate environment
load_config
setup_ci_environment

# Set snapshot update mode
if [[ "$UPDATE_SNAPSHOTS" == "true" ]]; then
    export SNAPSHOT_UPDATE=1
    log_warning "Snapshot update mode enabled"
fi

# Track failures
FAILURES=0

# ============================================================================
# Swift Package Manager Tests
# ============================================================================
if [[ "$XCODE_ONLY" != "true" ]]; then
    log_section "Swift Package Manager Tests"

    # ISOInspectorKitTests
    if timed_run "Test ISOInspectorKitTests" swift test --filter ISOInspectorKitTests; then
        log_success "ISOInspectorKitTests passed"
    else
        log_error "ISOInspectorKitTests failed"
        ((FAILURES++))
    fi

    # ISOInspectorCLITests
    if timed_run "Test ISOInspectorCLITests" swift test --filter ISOInspectorCLITests; then
        log_success "ISOInspectorCLITests passed"
    else
        log_error "ISOInspectorCLITests failed"
        ((FAILURES++))
    fi
fi

# ============================================================================
# Xcode Tests
# ============================================================================
if [[ "$SPM_ONLY" != "true" ]] && [[ -f "$REPO_ROOT/ISOInspector.xcworkspace/contents.xcworkspacedata" ]]; then
    log_section "Xcode Tests"

    XCODE_TEST_ARGS=(
        -workspace ISOInspector.xcworkspace
        -configuration Debug
        -parallel-testing-enabled NO
        CODE_SIGN_IDENTITY=""
        CODE_SIGNING_ALLOWED=NO
        CODE_SIGNING_REQUIRED=NO
    )

    # macOS tests
    if [[ "$SKIP_MACOS" != "true" ]]; then
        # ISOInspectorAppTests-macOS
        if timed_run "Test ISOInspectorAppTests (macOS)" \
            xcodebuild test \
            "${XCODE_TEST_ARGS[@]}" \
            -scheme ISOInspectorAppTests-macOS \
            -destination 'platform=macOS'; then
            log_success "ISOInspectorAppTests (macOS) passed"
        else
            log_error "ISOInspectorAppTests (macOS) failed"
            ((FAILURES++))
        fi

        # FoundationUI tests (macOS)
        if [[ -d "$REPO_ROOT/FoundationUI" ]]; then
            if timed_run "Test FoundationUI (macOS)" \
                xcodebuild test \
                "${XCODE_TEST_ARGS[@]}" \
                -scheme FoundationUI \
                -destination 'platform=macOS'; then
                log_success "FoundationUI (macOS) tests passed"
            else
                log_error "FoundationUI (macOS) tests failed"
                ((FAILURES++))
            fi
        fi
    fi

    # iOS tests
    if [[ "$SKIP_IOS" != "true" ]]; then
        # FoundationUI tests (iOS)
        if [[ -d "$REPO_ROOT/FoundationUI" ]]; then
            if timed_run "Test FoundationUI (iOS)" \
                xcodebuild test \
                "${XCODE_TEST_ARGS[@]}" \
                -scheme FoundationUI \
                -destination 'platform=iOS Simulator,name=iPhone 16'; then
                log_success "FoundationUI (iOS) tests passed"
            else
                log_error "FoundationUI (iOS) tests failed"
                ((FAILURES++))
            fi
        fi
    fi
else
    if [[ "$SPM_ONLY" != "true" ]]; then
        log_warning "Xcode workspace not found. Run ./scripts/local-ci/run-build.sh first or use --spm-only"
    fi
fi

# ============================================================================
# Python Script Tests
# ============================================================================
if [[ "$SKIP_SCRIPTS" != "true" ]] && [[ -d "$REPO_ROOT/scripts/tests" ]]; then
    log_section "Python Script Tests"

    if validate_python; then
        PYTHON_VERSIONS=("3.10" "3.11" "3.12")

        for version in "${PYTHON_VERSIONS[@]}"; do
            if command_exists "python$version"; then
                log_info "Testing with Python $version..."

                # Run unittest discovery
                if timed_run "Python $version tests" \
                    "python$version" -m unittest discover -s scripts/tests -p "test_*.py" -v; then
                    log_success "Python $version tests passed"
                else
                    log_error "Python $version tests failed"
                    ((FAILURES++))
                fi
            else
                log_warning "Python $version not found, skipping"
            fi
        done

        # Validate script syntax
        log_info "Validating Python script syntax..."
        PYTHON_SCRIPTS=(
            "scripts/archive_completed_tasks.py"
            "scripts/validate_json.py"
        )

        for script in "${PYTHON_SCRIPTS[@]}"; do
            if [[ -f "$script" ]]; then
                if python3 -m py_compile "$script"; then
                    log_success "$script syntax valid"
                else
                    log_error "$script syntax invalid"
                    ((FAILURES++))
                fi
            fi
        done
    else
        log_warning "Python not available, skipping script tests"
    fi
fi

# ============================================================================
# Summary
# ============================================================================
log_section "Test Summary"

if [[ $FAILURES -eq 0 ]]; then
    log_success "All tests passed! ✅"
    exit 0
else
    log_error "$FAILURES test suite(s) failed"
    exit 1
fi
