#!/bin/bash
# FoundationUI Build and Test Script
# Validates code quality, runs tests, and generates coverage reports

set -e  # Exit on any error

# Color output for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_step() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

# Change to FoundationUI directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

print_step "FoundationUI Build and Quality Assurance"
echo ""

# Step 1: Build the package
print_step "Building FoundationUI package..."
if swift build; then
    print_success "Build successful"
else
    print_error "Build failed"
    exit 1
fi
echo ""

# Step 2: Run tests with code coverage
print_step "Running test suite with code coverage..."
if swift test --enable-code-coverage; then
    print_success "All tests passed"
else
    print_error "Tests failed"
    exit 1
fi
echo ""

# Step 3: Check SwiftLint (if available)
print_step "Checking code quality with SwiftLint..."
if command -v swiftlint &> /dev/null; then
    if swiftlint --strict; then
        print_success "SwiftLint passed (0 violations)"
    else
        print_error "SwiftLint found violations"
        exit 1
    fi
else
    print_warning "SwiftLint not installed - skipping linting"
    echo "Install SwiftLint: brew install swiftlint"
fi
echo ""

# Step 4: Generate coverage report (macOS only)
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_step "Generating code coverage report..."

    # Find the test bundle
    TEST_BUNDLE=$(find .build -name "FoundationUITests.xctest" -type d | head -n 1)

    if [ -n "$TEST_BUNDLE" ]; then
        # Find the profdata file
        PROFDATA=$(find .build -name "*.profdata" | head -n 1)

        if [ -n "$PROFDATA" ]; then
            # Generate coverage report
            xcrun llvm-cov report \
                "$TEST_BUNDLE/Contents/MacOS/FoundationUITests" \
                -instr-profile "$PROFDATA" \
                -ignore-filename-regex=".build|Tests" \
                -use-color

            print_success "Coverage report generated"
            echo ""
            echo "To view detailed coverage:"
            echo "  ./Scripts/coverage.sh"
        else
            print_warning "Coverage data not found"
        fi
    else
        print_warning "Test bundle not found"
    fi
else
    print_warning "Code coverage reporting requires macOS"
fi

echo ""
print_success "All checks passed!"
echo ""
echo "Summary:"
echo "  ✅ Build successful"
echo "  ✅ Tests passed"
if command -v swiftlint &> /dev/null; then
    echo "  ✅ SwiftLint passed"
else
    echo "  ⚠️  SwiftLint not available"
fi
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "  ✅ Coverage report generated"
else
    echo "  ⚠️  Coverage reporting requires macOS"
fi
