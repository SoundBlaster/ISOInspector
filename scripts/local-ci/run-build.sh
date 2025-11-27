#!/usr/bin/env bash
# Run build matrix locally
# Mirrors: ci.yml, macos.yml, foundationui.yml

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source libraries
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=lib/ci-env.sh
source "$SCRIPT_DIR/lib/ci-env.sh"

# Configuration
REPO_ROOT=$(detect_repo_root)
cd "$REPO_ROOT"

show_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Run build matrix (SPM, Xcode, Tuist)

OPTIONS:
    --spm-only             Only build Swift Package Manager targets
    --xcode-only           Only build Xcode targets
    --skip-ios             Skip iOS builds
    --skip-macos           Skip macOS builds
    --skip-tuist           Skip Tuist workspace generation
    -c, --configuration    Build configuration: debug or release (default: debug)
    -v, --verbose          Verbose output
    -h, --help             Show this help message

EXAMPLES:
    # Build everything
    $(basename "$0")

    # Build only SPM targets
    $(basename "$0") --spm-only

    # Build only macOS targets
    $(basename "$0") --skip-ios

    # Release build
    $(basename "$0") --configuration release
EOF
}

# Parse arguments
SPM_ONLY=false
XCODE_ONLY=false
SKIP_IOS=false
SKIP_MACOS=false
SKIP_TUIST=false
CONFIGURATION="Debug"

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
        --skip-tuist)
            SKIP_TUIST=true
            shift
            ;;
        -c|--configuration)
            if [[ "$2" == "release" ]]; then
                CONFIGURATION="Release"
            fi
            shift 2
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

# Track failures
FAILURES=0

# ============================================================================
# Swift Package Manager Builds
# ============================================================================
if [[ "$XCODE_ONLY" != "true" ]]; then
    log_section "Swift Package Manager Builds"

    # Build ISOInspectorKit
    if timed_run "Build ISOInspectorKit" swift build --target ISOInspectorKit; then
        log_success "ISOInspectorKit build passed"
    else
        log_error "ISOInspectorKit build failed"
        ((FAILURES++))
    fi

    # Build ISOInspectorCLI
    if timed_run "Build ISOInspectorCLI" swift build --target ISOInspectorCLI; then
        log_success "ISOInspectorCLI build passed"
    else
        log_error "ISOInspectorCLI build failed"
        ((FAILURES++))
    fi

    # Build ISOInspectorCLIRunner
    if timed_run "Build ISOInspectorCLIRunner" swift build --target ISOInspectorCLIRunner; then
        log_success "ISOInspectorCLIRunner build passed"
    else
        log_error "ISOInspectorCLIRunner build failed"
        ((FAILURES++))
    fi

    # Build CLI release binary
    if [[ "$CONFIGURATION" == "Release" ]]; then
        if timed_run "Build CLI (release)" swift build --product isoinspect --configuration release; then
            log_success "CLI release binary built"
            BIN_PATH=$(swift build --product isoinspect --configuration release --show-bin-path)
            log_info "Binary location: $BIN_PATH/isoinspect"
        else
            log_error "CLI release build failed"
            ((FAILURES++))
        fi
    fi
fi

# ============================================================================
# Tuist Workspace Generation
# ============================================================================
if [[ "$SPM_ONLY" != "true" ]] && [[ "$SKIP_TUIST" != "true" ]]; then
    log_section "Tuist Workspace Generation"

    ensure_tuist

    # Validate Tuist project
    if timed_run "Validate Tuist project" tuist dump project; then
        log_success "Tuist project validation passed"
    else
        log_error "Tuist project validation failed"
        ((FAILURES++))
    fi

    # Install dependencies
    if timed_run "Install Tuist dependencies" tuist install; then
        log_success "Tuist dependencies installed"
    else
        log_error "Tuist install failed"
        ((FAILURES++))
    fi

    # Generate workspace
    if timed_run "Generate Xcode workspace" tuist generate --no-open; then
        log_success "Xcode workspace generated"
    else
        log_error "Tuist generate failed"
        ((FAILURES++))
    fi
fi

# ============================================================================
# Xcode Builds
# ============================================================================
if [[ "$SPM_ONLY" != "true" ]] && [[ -f "$REPO_ROOT/ISOInspector.xcworkspace/contents.xcworkspacedata" ]]; then
    log_section "Xcode Builds"

    XCODE_BUILD_ARGS=(
        -workspace ISOInspector.xcworkspace
        -configuration "$CONFIGURATION"
        CODE_SIGN_IDENTITY=""
        CODE_SIGNING_ALLOWED=NO
        CODE_SIGNING_REQUIRED=NO
    )

    # macOS builds
    if [[ "$SKIP_MACOS" != "true" ]]; then
        # ISOInspectorApp (macOS)
        if timed_run "Build ISOInspectorApp (macOS)" \
            xcodebuild build \
            "${XCODE_BUILD_ARGS[@]}" \
            -scheme ISOInspectorApp-macOS \
            -destination 'platform=macOS'; then
            log_success "ISOInspectorApp (macOS) build passed"
        else
            log_error "ISOInspectorApp (macOS) build failed"
            ((FAILURES++))
        fi

        # FoundationUI (macOS)
        if [[ -d "$REPO_ROOT/FoundationUI" ]]; then
            if timed_run "Build FoundationUI (macOS)" \
                xcodebuild build \
                "${XCODE_BUILD_ARGS[@]}" \
                -scheme FoundationUI \
                -destination 'platform=macOS'; then
                log_success "FoundationUI (macOS) build passed"
            else
                log_error "FoundationUI (macOS) build failed"
                ((FAILURES++))
            fi
        fi

        # ComponentTestApp (macOS)
        if [[ -d "$REPO_ROOT/Examples/ComponentTestApp" ]]; then
            if timed_run "Build ComponentTestApp (macOS)" \
                xcodebuild build \
                "${XCODE_BUILD_ARGS[@]}" \
                -scheme ComponentTestApp-macOS \
                -destination 'platform=macOS'; then
                log_success "ComponentTestApp (macOS) build passed"
            else
                log_error "ComponentTestApp (macOS) build failed"
                ((FAILURES++))
            fi
        fi
    fi

    # iOS builds
    if [[ "$SKIP_IOS" != "true" ]]; then
        # FoundationUI (iOS)
        if [[ -d "$REPO_ROOT/FoundationUI" ]]; then
            if timed_run "Build FoundationUI (iOS)" \
                xcodebuild build \
                "${XCODE_BUILD_ARGS[@]}" \
                -scheme FoundationUI \
                -destination 'platform=iOS Simulator,name=iPhone 16'; then
                log_success "FoundationUI (iOS) build passed"
            else
                log_error "FoundationUI (iOS) build failed"
                ((FAILURES++))
            fi
        fi

        # ComponentTestApp (iOS)
        if [[ -d "$REPO_ROOT/Examples/ComponentTestApp" ]]; then
            if timed_run "Build ComponentTestApp (iOS)" \
                xcodebuild build \
                "${XCODE_BUILD_ARGS[@]}" \
                -scheme ComponentTestApp-iOS \
                -destination 'platform=iOS Simulator,name=iPhone 16'; then
                log_success "ComponentTestApp (iOS) build passed"
            else
                log_error "ComponentTestApp (iOS) build failed"
                ((FAILURES++))
            fi
        fi
    fi
else
    if [[ "$SPM_ONLY" != "true" ]]; then
        log_warning "Xcode workspace not found. Run with Tuist generation or use --spm-only"
    fi
fi

# ============================================================================
# Summary
# ============================================================================
log_section "Build Summary"

if [[ $FAILURES -eq 0 ]]; then
    log_success "All builds passed! 🎉"
    exit 0
else
    log_error "$FAILURES build(s) failed"
    exit 1
fi
