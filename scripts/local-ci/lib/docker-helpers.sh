#!/usr/bin/env bash
# Docker utility functions for local CI

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

# SwiftLint Docker image
readonly SWIFTLINT_IMAGE="ghcr.io/realm/swiftlint:0.53.0"

# Python Docker images
readonly PYTHON_310_IMAGE="python:3.10-slim"
readonly PYTHON_311_IMAGE="python:3.11-slim"
readonly PYTHON_312_IMAGE="python:3.12-slim"

# Ensure Docker is running
ensure_docker() {
    if ! check_docker; then
        error_exit "Docker is not available. Please start Docker Desktop or install it from https://www.docker.com/products/docker-desktop"
    fi

    log_success "Docker is running"
}

# Pull Docker image if not present
pull_image_if_needed() {
    local image="$1"

    if docker image inspect "$image" >/dev/null 2>&1; then
        log_info "Docker image $image already present"
        return 0
    fi

    log_info "Pulling Docker image $image..."
    docker pull "$image" || error_exit "Failed to pull $image"
    log_success "Docker image $image pulled"
}

# Run SwiftLint in Docker
run_swiftlint_docker() {
    local work_dir="$1"
    local config_file="${2:-.swiftlint.yml}"
    shift 2
    local extra_args=("$@")

    ensure_docker
    pull_image_if_needed "$SWIFTLINT_IMAGE"

    log_info "Running SwiftLint in Docker..."

    docker run --rm \
        -u "$(id -u):$(id -g)" \
        -v "$work_dir:/work" \
        -w /work \
        "$SWIFTLINT_IMAGE" \
        swiftlint lint --config "$config_file" "${extra_args[@]}"
}

# Run SwiftLint autocorrect in Docker
run_swiftlint_autocorrect_docker() {
    local work_dir="$1"
    local config_file="${2:-.swiftlint.yml}"

    ensure_docker
    pull_image_if_needed "$SWIFTLINT_IMAGE"

    log_info "Running SwiftLint autocorrect in Docker..."

    docker run --rm \
        -u "$(id -u):$(id -g)" \
        -v "$work_dir:/work" \
        -w /work \
        "$SWIFTLINT_IMAGE" \
        /bin/sh -lc 'rm -f .swiftlint.cache; swiftlint --fix --no-cache --config '"$config_file"
}

# Run Python tests in Docker
run_python_tests_docker() {
    local work_dir="$1"
    local python_version="${2:-3.12}"
    local test_dir="${3:-scripts/tests}"

    local image
    case "$python_version" in
        3.10) image="$PYTHON_310_IMAGE" ;;
        3.11) image="$PYTHON_311_IMAGE" ;;
        3.12) image="$PYTHON_312_IMAGE" ;;
        *) error_exit "Unsupported Python version: $python_version" ;;
    esac

    ensure_docker
    pull_image_if_needed "$image"

    log_info "Running Python tests in Docker (Python $python_version)..."

    docker run --rm \
        -u "$(id -u):$(id -g)" \
        -v "$work_dir:/work" \
        -w "/work/$test_dir" \
        "$image" \
        python -m unittest discover -s . -p "test_*.py" -v
}

# Run Python syntax check in Docker
run_python_syntax_check_docker() {
    local work_dir="$1"
    local python_version="${2:-3.12}"
    shift 2
    local files=("$@")

    local image
    case "$python_version" in
        3.10) image="$PYTHON_310_IMAGE" ;;
        3.11) image="$PYTHON_311_IMAGE" ;;
        3.12) image="$PYTHON_312_IMAGE" ;;
        *) error_exit "Unsupported Python version: $python_version" ;;
    esac

    ensure_docker
    pull_image_if_needed "$image"

    log_info "Running Python syntax check in Docker (Python $python_version)..."

    for file in "${files[@]}"; do
        docker run --rm \
            -u "$(id -u):$(id -g)" \
            -v "$work_dir:/work" \
            -w /work \
            "$image" \
            python -m py_compile "$file" \
            || error_exit "Syntax error in $file"
    done

    log_success "All Python files passed syntax check"
}

# Clean up Docker resources
cleanup_docker() {
    log_info "Cleaning up Docker resources..."

    # Remove stopped containers (if any)
    docker container prune -f >/dev/null 2>&1 || true

    # Remove dangling images (if any)
    docker image prune -f >/dev/null 2>&1 || true

    log_success "Docker cleanup complete"
}

# Export functions
export -f ensure_docker pull_image_if_needed
export -f run_swiftlint_docker run_swiftlint_autocorrect_docker
export -f run_python_tests_docker run_python_syntax_check_docker
export -f cleanup_docker
