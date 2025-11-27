#!/usr/bin/env bash
# Run complete CI suite locally
# Orchestrates all CI jobs in correct order

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source libraries
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

show_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Run complete CI suite (lint → build → test)

OPTIONS:
    --fail-fast            Stop on first failure
    --skip-lint            Skip linting checks
    --skip-build           Skip builds
    --skip-test            Skip tests
    --jobs JOBS            Comma-separated list of jobs to run
                           Available: lint,build,test,coverage,docc
    -v, --verbose          Verbose output
    -h, --help             Show this help message

EXAMPLES:
    # Run everything
    $(basename "$0")

    # Stop on first failure
    $(basename "$0") --fail-fast

    # Run only lint and test
    $(basename "$0") --jobs lint,test

    # Skip builds (useful for quick checks)
    $(basename "$0") --skip-build
EOF
}

# Parse arguments
FAIL_FAST=false
SKIP_LINT=false
SKIP_BUILD=false
SKIP_TEST=false
JOBS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --fail-fast)
            FAIL_FAST=true
            shift
            ;;
        --skip-lint)
            SKIP_LINT=true
            shift
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --skip-test)
            SKIP_TEST=true
            shift
            ;;
        --jobs)
            JOBS="$2"
            shift 2
            ;;
        -v|--verbose)
            export VERBOSE=true
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

# Determine which jobs to run
if [[ -n "$JOBS" ]]; then
    IFS=',' read -ra JOB_ARRAY <<< "$JOBS"
    SKIP_LINT=true
    SKIP_BUILD=true
    SKIP_TEST=true

    for job in "${JOB_ARRAY[@]}"; do
        case "$job" in
            lint) SKIP_LINT=false ;;
            build) SKIP_BUILD=false ;;
            test) SKIP_TEST=false ;;
            *) log_warning "Unknown job: $job" ;;
        esac
    done
fi

# Track overall timing
OVERALL_START=$(date +%s)
FAILURES=0

# Helper to run job with failure tracking
run_job() {
    local name="$1"
    local script="$2"
    shift 2
    local args=("$@")

    log_section "Running: $name"

    if "$script" "${args[@]}"; then
        log_success "$name completed"
        return 0
    else
        log_error "$name failed"
        ((FAILURES++))

        if [[ "$FAIL_FAST" == "true" ]]; then
            log_error "Stopping due to --fail-fast"
            exit 1
        fi
        return 1
    fi
}

# ============================================================================
# CI Suite Execution
# ============================================================================

log_section "🚀 Local CI Suite"
log_info "Repository: $(detect_repo_root)"
log_info "Mode: ${JOBS:-all jobs}"

# 1. Linting
if [[ "$SKIP_LINT" != "true" ]]; then
    run_job "Linting & Formatting" "$SCRIPT_DIR/run-lint.sh"
fi

# 2. Build
if [[ "$SKIP_BUILD" != "true" ]]; then
    run_job "Build Matrix" "$SCRIPT_DIR/run-build.sh"
fi

# 3. Tests
if [[ "$SKIP_TEST" != "true" ]]; then
    run_job "Test Suites" "$SCRIPT_DIR/run-tests.sh"
fi

# ============================================================================
# Final Summary
# ============================================================================

OVERALL_END=$(date +%s)
OVERALL_DURATION=$((OVERALL_END - OVERALL_START))
MINUTES=$((OVERALL_DURATION / 60))
SECONDS=$((OVERALL_DURATION % 60))

log_section "🏁 CI Suite Summary"
log_info "Total time: ${MINUTES}m ${SECONDS}s"

if [[ $FAILURES -eq 0 ]]; then
    log_success "All CI checks passed! 🎉"
    log_info ""
    log_info "Next steps:"
    log_info "  - Review changes: git status"
    log_info "  - Commit: git commit -am 'Your message'"
    log_info "  - Push: git push"
    exit 0
else
    log_error "$FAILURES job(s) failed"
    log_info ""
    log_info "To fix:"
    log_info "  - Review errors above"
    log_info "  - Run individual jobs: $SCRIPT_DIR/run-lint.sh"
    log_info "  - Auto-fix: $SCRIPT_DIR/run-lint.sh --fix"
    exit 1
fi
