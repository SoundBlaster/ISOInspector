#!/usr/bin/env bash
# CI environment validation and setup

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

# Validate macOS version
validate_macos_version() {
    local os_version
    os_version=$(sw_vers -productVersion)
    local major_version
    major_version=$(echo "$os_version" | cut -d. -f1)

    if [[ "$major_version" -lt 13 ]]; then
        error_exit "macOS 13 (Ventura) or later required (found $os_version)"
    fi

    log_success "macOS version: $os_version"
}

# Validate Xcode installation
validate_xcode() {
    local required_major="${1:-16}"
    local required_minor="${2:-0}"

    if [[ ! -d "$XCODE_PATH" ]]; then
        error_exit "Xcode not found at $XCODE_PATH"
    fi

    # Select Xcode
    sudo xcode-select -s "$XCODE_PATH" || error_exit "Failed to select Xcode"

    # Accept license if needed
    if ! /usr/bin/xcrun --find xcodebuild >/dev/null 2>&1; then
        log_warning "Xcode license may need acceptance. Run: sudo xcodebuild -license accept"
    fi

    check_xcode_version "$required_major" "$required_minor"
}

# Validate Swift installation
validate_swift() {
    local required_version="${1:-6.0}"

    if ! command_exists swift; then
        error_exit "Swift not found. Install Xcode or Swift toolchain."
    fi

    local swift_version
    swift_version=$(detect_swift_version)
    log_success "Swift version: $swift_version"

    # Note: Version comparison would need more sophisticated parsing
    # For now, just report the version
}

# Check Homebrew
check_homebrew() {
    if ! command_exists brew; then
        log_warning "Homebrew not found. Some tools may need manual installation."
        log_info "Install Homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        return 1
    fi

    log_success "Homebrew is installed"
    return 0
}

# Install or update SwiftLint via Homebrew
ensure_swiftlint() {
    local mode="${SWIFTLINT_MODE:-native}"

    if [[ "$mode" == "docker" ]]; then
        log_info "SwiftLint mode: Docker (no local installation needed)"
        return 0
    fi

    if ! command_exists swiftlint; then
        log_warning "SwiftLint not found"
        if check_homebrew; then
            log_info "Installing SwiftLint via Homebrew..."
            brew install swiftlint || error_exit "Failed to install SwiftLint"
        else
            error_exit "SwiftLint not found. Install manually or use Docker mode (SWIFTLINT_MODE=docker)"
        fi
    fi

    local swiftlint_version
    swiftlint_version=$(swiftlint version)
    log_success "SwiftLint version: $swiftlint_version"
}

# Ensure Tuist is installed
ensure_tuist() {
    local tuist_version="${TUIST_VERSION:-}"
    local install_dir="$HOME/.local-ci/tuist"

    # Auto-detect version if not specified
    if [[ -z "$tuist_version" ]]; then
        log_info "Auto-detecting Tuist version from GitHub..."
        tuist_version=$(fetch_tuist_version)
    fi

    local tuist_path="$install_dir/$tuist_version/tuist"

    if [[ -x "$tuist_path" ]]; then
        log_success "Tuist $tuist_version already installed"
        export PATH="$install_dir/$tuist_version:$PATH"
        return 0
    fi

    log_info "Installing Tuist $tuist_version..."
    mkdir -p "$install_dir/$tuist_version"

    local temp_dir
    temp_dir=$(create_temp_dir)

    curl -fsSL -o "$temp_dir/tuist.zip" \
        "https://github.com/tuist/tuist/releases/download/$tuist_version/tuist.zip" \
        || error_exit "Failed to download Tuist"

    unzip -q "$temp_dir/tuist.zip" -d "$temp_dir" \
        || error_exit "Failed to extract Tuist"

    mv "$temp_dir/tuist" "$tuist_path" \
        || error_exit "Failed to install Tuist"

    chmod +x "$tuist_path"
    rm -rf "$temp_dir"

    export PATH="$install_dir/$tuist_version:$PATH"
    log_success "Tuist $tuist_version installed"
}

# Fetch latest Tuist CLI version from GitHub
fetch_tuist_version() {
    local api_url="https://api.github.com/repos/tuist/tuist/releases?per_page=30"
    local response

    response=$(curl -fsSL \
        -H "Accept: application/vnd.github+json" \
        -H "User-Agent: isoinspector-local-ci" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "$api_url" 2>/dev/null) || error_exit "Failed to fetch Tuist releases"

    local tuist_version
    tuist_version=$(echo "$response" | python3 -c "
import sys, json
releases = json.load(sys.stdin)
for r in releases:
    if 'CLI' in r.get('name', '') and r.get('tag_name'):
        print(r['tag_name'])
        break
else:
    for r in releases:
        tag = r.get('tag_name', '')
        if tag and '@' not in tag:
            print(tag)
            break
" 2>/dev/null) || error_exit "Failed to parse Tuist version"

    if [[ -z "$tuist_version" ]]; then
        error_exit "Could not determine Tuist version"
    fi

    echo "$tuist_version"
}

# Validate Python installation (for script tests)
validate_python() {
    local required_versions=("3.10" "3.11" "3.12")

    if ! command_exists python3; then
        log_warning "Python 3 not found. Script tests will be skipped."
        return 1
    fi

    local python_version
    python_version=$(python3 --version | awk '{print $2}')
    log_success "Python version: $python_version"

    return 0
}

# Validate all CI prerequisites
validate_ci_environment() {
    log_section "Validating CI Environment"

    validate_macos_version
    validate_xcode 16 0
    validate_swift 6.0
    check_homebrew || true
    ensure_swiftlint
    validate_python || true

    log_success "CI environment validation complete"
}

# Setup CI environment
setup_ci_environment() {
    log_section "Setting up CI Environment"

    load_config
    validate_ci_environment

    # Set up derived data path for consistent builds
    export DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$HOME/Library/Developer/Xcode/DerivedData}"

    # Set up build cache
    export BUILD_CACHE_DIR="${BUILD_CACHE_DIR:-$HOME/.local-ci/build-cache}"
    mkdir -p "$BUILD_CACHE_DIR"

    log_success "CI environment setup complete"
}

# Export functions
export -f validate_macos_version validate_xcode validate_swift
export -f check_homebrew ensure_swiftlint ensure_tuist
export -f fetch_tuist_version validate_python
export -f validate_ci_environment setup_ci_environment
