#!/bin/bash
# FoundationUI Code Coverage Report Generator
# Generates detailed HTML and text coverage reports

set -e

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

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "Code coverage reporting requires macOS"
    exit 1
fi

# Change to FoundationUI directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

print_step "FoundationUI Code Coverage Report"
echo ""

# Find the test bundle
TEST_BUNDLE=$(find .build -name "FoundationUITests.xctest" -type d | head -n 1)

if [ -z "$TEST_BUNDLE" ]; then
    print_error "Test bundle not found. Run tests first with: swift test --enable-code-coverage"
    exit 1
fi

# Find the profdata file
PROFDATA=$(find .build -name "*.profdata" | head -n 1)

if [ -z "$PROFDATA" ]; then
    print_error "Coverage data not found. Run tests first with: swift test --enable-code-coverage"
    exit 1
fi

TEST_BINARY="$TEST_BUNDLE/Contents/MacOS/FoundationUITests"

# Generate text report
print_step "Generating text coverage report..."
xcrun llvm-cov report \
    "$TEST_BINARY" \
    -instr-profile "$PROFDATA" \
    -ignore-filename-regex=".build|Tests" \
    -use-color

print_success "Text report generated"
echo ""

# Generate detailed coverage by file
print_step "Detailed coverage by file:"
xcrun llvm-cov show \
    "$TEST_BINARY" \
    -instr-profile "$PROFDATA" \
    -ignore-filename-regex=".build|Tests" \
    -format=text \
    -use-color

print_success "Detailed report generated"
echo ""

# Generate HTML report (if output directory doesn't exist)
OUTPUT_DIR="coverage_report"
print_step "Generating HTML coverage report..."

if [ -d "$OUTPUT_DIR" ]; then
    rm -rf "$OUTPUT_DIR"
fi

xcrun llvm-cov show \
    "$TEST_BINARY" \
    -instr-profile "$PROFDATA" \
    -ignore-filename-regex=".build|Tests" \
    -format=html \
    -output-dir="$OUTPUT_DIR"

print_success "HTML report generated at: $OUTPUT_DIR/index.html"
echo ""

# Export LCOV format for CI tools
print_step "Exporting coverage in LCOV format..."
xcrun llvm-cov export \
    "$TEST_BINARY" \
    -instr-profile "$PROFDATA" \
    -ignore-filename-regex=".build|Tests" \
    -format=lcov \
    > coverage.lcov

print_success "LCOV report exported to: coverage.lcov"
echo ""

# Calculate overall coverage percentage
COVERAGE=$(xcrun llvm-cov report \
    "$TEST_BINARY" \
    -instr-profile "$PROFDATA" \
    -ignore-filename-regex=".build|Tests" | \
    grep TOTAL | \
    awk '{print $NF}')

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Overall Code Coverage: $COVERAGE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if coverage meets target (80%)
COVERAGE_VALUE=$(echo "$COVERAGE" | sed 's/%//')
TARGET=80

if (( $(echo "$COVERAGE_VALUE >= $TARGET" | bc -l) )); then
    print_success "Coverage meets target of ${TARGET}%"
else
    print_warning "Coverage below target of ${TARGET}% (current: $COVERAGE)"
fi

echo ""
echo "To view HTML report, open:"
echo "  open $OUTPUT_DIR/index.html"
