#!/usr/bin/env bash
# CI environment validation and setup

# Guard against multiple sourcing
if [[ -n "${LOCAL_CI_ENV_SOURCED:-}" ]]; then
    return 0
fi
readonly LOCAL_CI_ENV_SOURCED=1

set -euo pipefail

# Source common functions
_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$_LIB_DIR/common.sh"

# Validate macOS version
validate_macos_version() {
    if is_linux; then
        log_info "Running on Linux - skipping macOS version check"
        return 0
    fi

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

    if is_linux; then
        log_info "Running on Linux - skipping Xcode validation"
        return 0
    fi

    if [[ ! -d "$XCODE_PATH" ]]; then
        error_exit "Xcode not found at $XCODE_PATH"
    fi

    # Check if correct Xcode is already selected
    local current_xcode_path
    current_xcode_path=$(xcode-select -p 2>/dev/null || echo "")
    local expected_path="$XCODE_PATH/Contents/Developer"

    if [[ "$current_xcode_path" != "$expected_path" ]]; then
        log_info "Selecting Xcode at $XCODE_PATH"
        sudo xcode-select -s "$XCODE_PATH" || error_exit "Failed to select Xcode"
    fi

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
        if is_linux; then
            log_warning "Swift not found on Linux. SPM builds will be skipped."
            log_info "Install Swift from https://swift.org/download/ or https://swiftlang.github.io/swiftly/"
            return 1
        else
            error_exit "Swift not found. Install Xcode or Swift toolchain."
        fi
    fi

    local swift_version
    swift_version=$(detect_swift_version)
    log_success "Swift version: $swift_version"

    # Note: Version comparison would need more sophisticated parsing
    # For now, just report the version
    return 0
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
        if check_docker; then
            log_success "Docker is available and running"
        else
            log_warning "Docker not running. Ensure Docker Desktop is started."
        fi
        return 0
    fi

    # On Linux, prefer Docker or build from source
    if is_linux; then
        if ! command_exists swiftlint; then
            log_warning "SwiftLint not found on Linux"

            # Try Docker first
            if check_docker; then
                log_info "Docker is available. Switching to Docker mode for SwiftLint"
                export SWIFTLINT_MODE="docker"
                return 0
            fi

            # Try building from source if Swift is available
            if command_exists swift; then
                log_info "Attempting to build SwiftLint from source..."
                local install_dir="$HOME/.local-ci/swiftlint"

                if [[ -x "$install_dir/swiftlint" ]]; then
                    log_success "Using cached SwiftLint from $install_dir"
                    export PATH="$install_dir:$PATH"
                    return 0
                fi

                log_info "This may take several minutes..."
                local temp_dir
                temp_dir=$(create_temp_dir)

                if git clone --depth 1 --branch 0.53.0 https://github.com/realm/SwiftLint.git "$temp_dir/SwiftLint" 2>/dev/null &&
                   cd "$temp_dir/SwiftLint" &&
                   swift build -c release 2>/dev/null; then
                    mkdir -p "$install_dir"
                    cp "$temp_dir/SwiftLint/.build/release/swiftlint" "$install_dir/"
                    export PATH="$install_dir:$PATH"
                    rm -rf "$temp_dir"
                    log_success "SwiftLint built and installed to $install_dir"
                    return 0
                else
                    rm -rf "$temp_dir"
                    log_warning "Failed to build SwiftLint from source"
                fi
            fi

            log_warning "SwiftLint not available. Use Docker mode: SWIFTLINT_MODE=docker"
            log_info "Or install Swift and try building from source"
            return 1
        fi

        local swiftlint_version
        swiftlint_version=$(swiftlint version)
        log_success "SwiftLint version: $swiftlint_version"
        return 0
    fi

    # macOS path
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
    if is_linux; then
        log_info "Running on Linux - Tuist is macOS-only, skipping"
        return 0
    fi

    local tuist_version="${TUIST_VERSION:-}"
    local install_dir="$HOME/.local-ci/tuist"

    # Check if system Tuist is available and working
    if command_exists tuist && [[ -z "$tuist_version" ]]; then
        local system_version
        system_version=$(tuist version 2>/dev/null || echo "")
        if [[ -n "$system_version" ]]; then
            # Verify system Tuist works by testing a simple command
            if tuist dump project >/dev/null 2>&1; then
                log_success "Using system Tuist $system_version"
                return 0
            else
                log_warning "System Tuist $system_version found but not working, will download compatible version"
            fi
        fi
    fi

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

# Detect best available iOS simulator for testing
# Returns destination specifier string with ID
detect_ios_simulator() {
    if is_linux; then
        log_warning "iOS Simulator not available on Linux"
        return 1
    fi

    local device_name="${1:-iPhone 16}"
    local workspace="${2:-}"
    local scheme="${3:-}"

    # Get all iOS Simulator destinations
    local destinations
    if [[ -n "$workspace" ]] && [[ -n "$scheme" ]]; then
        destinations=$(xcodebuild -workspace "$workspace" -scheme "$scheme" -showdestinations 2>/dev/null | grep "platform:iOS Simulator" || echo "")
    elif [[ -n "$scheme" ]]; then
        destinations=$(xcodebuild -scheme "$scheme" -showdestinations 2>/dev/null | grep "platform:iOS Simulator" || echo "")
    else
        # Fallback to simctl list if no workspace/scheme provided
        destinations=$(xcrun simctl list devices available 2>/dev/null | grep -E "iPhone|iPad" || echo "")
    fi

    if [[ -z "$destinations" ]]; then
        error_exit "No iOS simulators found"
    fi

    # Find matching device with highest OS version
    # Sort by OS version (descending) and pick first match
    local best_match
    best_match=$(echo "$destinations" | \
        grep "name:$device_name" | \
        sed -E 's/.*id:([^,]+).*OS:([^,]+).*/\2 \1/' | \
        sort -V -r | \
        head -1)

    if [[ -z "$best_match" ]]; then
        log_warning "Device '$device_name' not found, trying any iOS Simulator"
        # Fallback to any available simulator
        best_match=$(echo "$destinations" | \
            grep "platform:iOS Simulator" | \
            grep -v "placeholder" | \
            sed -E 's/.*id:([^,]+).*OS:([^,]+).*/\2 \1/' | \
            sort -V -r | \
            head -1)
    fi

    if [[ -z "$best_match" ]]; then
        error_exit "No suitable iOS simulator found"
    fi

    # Extract OS version and ID
    local os_version
    local device_id
    os_version=$(echo "$best_match" | awk '{print $1}')
    device_id=$(echo "$best_match" | awk '{print $2}')

    # Return destination specifier
    echo "platform=iOS Simulator,id=$device_id"
}

# Validate all CI prerequisites
validate_ci_environment() {
    log_section "Validating CI Environment"

    local current_os
    current_os=$(detect_os)
    log_info "Detected OS: $current_os"

    validate_macos_version
    validate_xcode 16 0
    validate_swift 6.0 || true
    check_homebrew || true
    ensure_swiftlint || true
    validate_python || true

    log_success "CI environment validation complete"
}

# Setup CI environment
setup_ci_environment() {
    log_section "Setting up CI Environment"

    load_config
    validate_ci_environment

    # Set up derived data path for consistent builds (macOS only)
    if is_macos; then
        export DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$HOME/Library/Developer/Xcode/DerivedData}"
    fi

    # Set up build cache
    export BUILD_CACHE_DIR="${BUILD_CACHE_DIR:-$HOME/.local-ci/build-cache}"
    mkdir -p "$BUILD_CACHE_DIR"

    log_success "CI environment setup complete"
}

# Export functions
export -f validate_macos_version validate_xcode validate_swift
export -f check_homebrew ensure_swiftlint ensure_tuist
export -f fetch_tuist_version validate_python detect_ios_simulator
export -f validate_ci_environment setup_ci_environment
