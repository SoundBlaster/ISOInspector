#!/usr/bin/env bash
# Common utility functions for local CI scripts

# Guard against multiple sourcing
if [[ -n "${LOCAL_CI_COMMON_SOURCED:-}" ]]; then
    return 0
fi
readonly LOCAL_CI_COMMON_SOURCED=1

set -euo pipefail

# Colors for output
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_RESET='\033[0m'

# Logging functions
log_info() {
    echo -e "${COLOR_BLUE}ℹ️  ${1}${COLOR_RESET}"
}

log_success() {
    echo -e "${COLOR_GREEN}✅ ${1}${COLOR_RESET}"
}

log_warning() {
    echo -e "${COLOR_YELLOW}⚠️  ${1}${COLOR_RESET}"
}

log_error() {
    echo -e "${COLOR_RED}❌ ${1}${COLOR_RESET}" >&2
}

log_section() {
    echo ""
    echo -e "${COLOR_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
    echo -e "${COLOR_BLUE}▶ ${1}${COLOR_RESET}"
    echo -e "${COLOR_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
}

# Error handling
error_exit() {
    log_error "$1"
    exit 1
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect operating system
detect_os() {
    case "$(uname -s)" in
        Darwin*)
            echo "macos"
            ;;
        Linux*)
            echo "linux"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Check if running on macOS
is_macos() {
    [[ "$(detect_os)" == "macos" ]]
}

# Check if running on Linux
is_linux() {
    [[ "$(detect_os)" == "linux" ]]
}

# Detect repository root
detect_repo_root() {
    local current_dir="$PWD"
    while [[ "$current_dir" != "/" ]]; do
        if [[ -d "$current_dir/.git" ]] || [[ -f "$current_dir/Package.swift" ]]; then
            echo "$current_dir"
            return 0
        fi
        current_dir=$(dirname "$current_dir")
    done
    error_exit "Could not detect repository root (no .git or Package.swift found)"
}

# Load configuration
load_config() {
    local repo_root="${1:-$(detect_repo_root)}"
    local config_file="$repo_root/.local-ci-config"

    # Set defaults
    export XCODE_PATH="${XCODE_PATH:-/Applications/Xcode.app}"
    export TUIST_VERSION="${TUIST_VERSION:-}"
    export SWIFTLINT_MODE="${SWIFTLINT_MODE:-native}"
    export SKIP_SNAPSHOT_TESTS="${SKIP_SNAPSHOT_TESTS:-false}"
    export SKIP_IOS_TESTS="${SKIP_IOS_TESTS:-false}"
    export COVERAGE_THRESHOLD="${COVERAGE_THRESHOLD:-0.67}"
    export PARALLEL_BUILDS="${PARALLEL_BUILDS:-true}"
    export MAX_JOBS="${MAX_JOBS:-4}"
    export VERBOSE="${VERBOSE:-false}"

    # Override with config file if exists
    if [[ -f "$config_file" ]]; then
        log_info "Loading configuration from $config_file"
        # shellcheck source=/dev/null
        source "$config_file"
    fi
}

# Detect installed Xcode version
detect_xcode_version() {
    if ! command_exists xcodebuild; then
        error_exit "xcodebuild not found. Please install Xcode."
    fi

    local xcode_version
    xcode_version=$(xcodebuild -version | head -n 1 | awk '{print $2}')
    echo "$xcode_version"
}

# Detect installed Swift version
detect_swift_version() {
    if ! command_exists swift; then
        error_exit "swift not found. Please install Xcode."
    fi

    local swift_version
    swift_version=$(swift --version | head -n 1 | awk '{print $4}')
    echo "$swift_version"
}

# Check minimum Xcode version
check_xcode_version() {
    local required_major="$1"
    local required_minor="${2:-0}"
    local current_version
    current_version=$(detect_xcode_version)

    local current_major
    local current_minor
    current_major=$(echo "$current_version" | cut -d. -f1)
    current_minor=$(echo "$current_version" | cut -d. -f2)

    if [[ "$current_major" -lt "$required_major" ]] || \
       [[ "$current_major" -eq "$required_major" && "$current_minor" -lt "$required_minor" ]]; then
        error_exit "Xcode $required_major.$required_minor or later required (found $current_version)"
    fi

    log_success "Xcode version: $current_version"
}

# Check if Docker is available
check_docker() {
    if ! command_exists docker; then
        return 1
    fi

    if ! docker info >/dev/null 2>&1; then
        log_warning "Docker is installed but not running"
        return 1
    fi

    return 0
}

# Run command with timing
timed_run() {
    local description="$1"
    shift

    log_info "Running: $description"
    local start_time
    start_time=$(date +%s)

    if [[ "${VERBOSE:-false}" == "true" ]]; then
        "$@"
    else
        "$@" > /tmp/local-ci-output.log 2>&1
    fi

    local exit_code=$?
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))

    if [[ $exit_code -eq 0 ]]; then
        log_success "$description completed in ${duration}s"
    else
        log_error "$description failed after ${duration}s"
        if [[ "${VERBOSE:-false}" != "true" ]]; then
            log_error "See /tmp/local-ci-output.log for details"
            tail -n 50 /tmp/local-ci-output.log
        fi
        return $exit_code
    fi
}

# Create temporary directory
create_temp_dir() {
    local temp_dir
    temp_dir=$(mktemp -d -t local-ci-XXXXXX)
    echo "$temp_dir"
}

# Cleanup function
cleanup_temp_files() {
    local temp_pattern="${1:-local-ci-*}"
    find /tmp -maxdepth 1 -name "$temp_pattern" -type d -mtime +1 -exec rm -rf {} + 2>/dev/null || true
}

# Parse command line arguments
parse_common_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                export VERBOSE=true
                shift
                ;;
            -h|--help)
                if declare -f show_help >/dev/null; then
                    show_help
                    exit 0
                else
                    error_exit "Help function not defined"
                fi
                ;;
            *)
                log_error "Unknown option: $1"
                if declare -f show_help >/dev/null; then
                    show_help
                fi
                exit 1
                ;;
        esac
    done
}

# Export functions
export -f log_info log_success log_warning log_error log_section
export -f error_exit command_exists detect_os is_macos is_linux
export -f detect_repo_root load_config
export -f detect_xcode_version detect_swift_version check_xcode_version
export -f check_docker timed_run create_temp_dir cleanup_temp_files
export -f parse_common_args
