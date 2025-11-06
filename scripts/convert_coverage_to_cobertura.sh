#!/bin/bash
#
# Convert Xcode coverage report to Cobertura XML format
#
# Usage:
#   bash scripts/convert_coverage_to_cobertura.sh \
#     -xcresult path/to/Test.xcresult \
#     -output coverage.xml
#
# Requirements:
#   - Xcode with xccov tool
#   - jq (for JSON processing)
#

set -euo pipefail

# Default values
XCRESULT_PATH=""
OUTPUT_PATH="coverage.xml"
VERBOSE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -xcresult)
            XCRESULT_PATH="$2"
            shift 2
            ;;
        -output)
            OUTPUT_PATH="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 -xcresult <path> -output <path>"
            echo ""
            echo "Options:"
            echo "  -xcresult <path>  Path to .xcresult bundle"
            echo "  -output <path>    Output path for Cobertura XML (default: coverage.xml)"
            echo "  -v, --verbose     Enable verbose output"
            echo "  -h, --help        Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Validate required arguments
if [[ -z "$XCRESULT_PATH" ]]; then
    echo "Error: -xcresult is required"
    exit 1
fi

if [[ ! -d "$XCRESULT_PATH" ]]; then
    echo "Error: xcresult bundle not found: $XCRESULT_PATH"
    exit 1
fi

# Check for required tools
if ! command -v xcrun &> /dev/null; then
    echo "Error: xcrun not found. This script requires Xcode."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq not found. Please install jq: brew install jq"
    exit 1
fi

# Log function
log() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo "[coverage] $*"
    fi
}

log "Converting coverage from $XCRESULT_PATH to $OUTPUT_PATH"

# Extract coverage JSON from xcresult
COVERAGE_JSON=$(mktemp)
trap "rm -f $COVERAGE_JSON" EXIT

log "Extracting coverage data with xccov..."
xcrun xccov view --report --json "$XCRESULT_PATH" > "$COVERAGE_JSON"

if [[ ! -s "$COVERAGE_JSON" ]]; then
    echo "Error: Failed to extract coverage data from xcresult"
    exit 1
fi

log "Parsing coverage data..."

# Extract overall metrics
LINE_COVERAGE=$(jq -r '.lineCoverage // 0' "$COVERAGE_JSON")
LINES_COVERED=$(jq -r '.coveredLines // 0' "$COVERAGE_JSON")
LINES_VALID=$(jq -r '.executableLines // 0' "$COVERAGE_JSON")
BRANCH_COVERAGE=$(jq -r '.branchCoverage // 0' "$COVERAGE_JSON")
BRANCHES_COVERED=$(jq -r '.coveredBranches // 0' "$COVERAGE_JSON")
BRANCHES_VALID=$(jq -r '.executableBranches // 0' "$COVERAGE_JSON")

# Convert percentage to rate (0.0-1.0)
LINE_RATE=$(echo "$LINE_COVERAGE" | awk '{printf "%.4f", $1}')
BRANCH_RATE=$(echo "$BRANCH_COVERAGE" | awk '{printf "%.4f", $1}')

# Get timestamp
TIMESTAMP=$(date +%s)

log "Overall line coverage: ${LINE_COVERAGE}% ($LINES_COVERED/$LINES_VALID)"
log "Overall branch coverage: ${BRANCH_COVERAGE}% ($BRANCHES_COVERED/$BRANCHES_VALID)"

# Start generating Cobertura XML
cat > "$OUTPUT_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE coverage SYSTEM "http://cobertura.sourceforge.net/xml/coverage-04.dtd">
<coverage line-rate="$LINE_RATE" branch-rate="$BRANCH_RATE" lines-covered="$LINES_COVERED" lines-valid="$LINES_VALID" branches-covered="$BRANCHES_COVERED" branches-valid="$BRANCHES_VALID" complexity="0" version="1.0" timestamp="$TIMESTAMP">
  <sources>
    <source>FoundationUI/Sources</source>
  </sources>
  <packages>
EOF

# Process each target/package
jq -c '.targets[]?' "$COVERAGE_JSON" | while read -r target; do
    TARGET_NAME=$(echo "$target" | jq -r '.name // "Unknown"')
    TARGET_LINE_COVERAGE=$(echo "$target" | jq -r '.lineCoverage // 0')
    TARGET_LINES_COVERED=$(echo "$target" | jq -r '.coveredLines // 0')
    TARGET_LINES_VALID=$(echo "$target" | jq -r '.executableLines // 0')
    TARGET_BRANCH_COVERAGE=$(echo "$target" | jq -r '.branchCoverage // 0')
    TARGET_BRANCHES_COVERED=$(echo "$target" | jq -r '.coveredBranches // 0')
    TARGET_BRANCHES_VALID=$(echo "$target" | jq -r '.executableBranches // 0')

    TARGET_LINE_RATE=$(echo "$TARGET_LINE_COVERAGE" | awk '{printf "%.4f", $1}')
    TARGET_BRANCH_RATE=$(echo "$TARGET_BRANCH_COVERAGE" | awk '{printf "%.4f", $1}')

    log "Processing target: $TARGET_NAME (${TARGET_LINE_COVERAGE}% line coverage)"

    cat >> "$OUTPUT_PATH" <<EOF
    <package name="$TARGET_NAME" line-rate="$TARGET_LINE_RATE" branch-rate="$TARGET_BRANCH_RATE" complexity="0">
      <classes>
EOF

    # Process each file in the target
    echo "$target" | jq -c '.files[]?' | while read -r file; do
        FILE_PATH=$(echo "$file" | jq -r '.path // "unknown"')
        FILE_NAME=$(echo "$file" | jq -r '.name // "unknown"')
        FILE_LINE_COVERAGE=$(echo "$file" | jq -r '.lineCoverage // 0')
        FILE_LINES_COVERED=$(echo "$file" | jq -r '.coveredLines // 0')
        FILE_LINES_VALID=$(echo "$file" | jq -r '.executableLines // 0')

        FILE_LINE_RATE=$(echo "$FILE_LINE_COVERAGE" | awk '{printf "%.4f", $1}')

        # Skip files with no executable lines
        if [[ "$FILE_LINES_VALID" == "0" ]]; then
            continue
        fi

        log "  - $FILE_NAME: ${FILE_LINE_COVERAGE}% ($FILE_LINES_COVERED/$FILE_LINES_VALID)"

        cat >> "$OUTPUT_PATH" <<EOF
        <class name="$FILE_NAME" filename="$FILE_PATH" line-rate="$FILE_LINE_RATE" branch-rate="1.0" complexity="0">
          <methods/>
          <lines>
EOF

        # Process each line in the file
        echo "$file" | jq -c '.functions[]? | .executableLines[]?' 2>/dev/null | while read -r line; do
            LINE_NUMBER=$(echo "$line" | jq -r '.line // 0')
            EXECUTION_COUNT=$(echo "$line" | jq -r '.executionCount // 0')

            # Determine if line is covered (hits > 0)
            if [[ "$EXECUTION_COUNT" -gt 0 ]]; then
                cat >> "$OUTPUT_PATH" <<EOF
            <line number="$LINE_NUMBER" hits="$EXECUTION_COUNT" branch="false"/>
EOF
            else
                cat >> "$OUTPUT_PATH" <<EOF
            <line number="$LINE_NUMBER" hits="0" branch="false"/>
EOF
            fi
        done

        cat >> "$OUTPUT_PATH" <<EOF
          </lines>
        </class>
EOF
    done

    cat >> "$OUTPUT_PATH" <<EOF
      </classes>
    </package>
EOF
done

# Close XML document
cat >> "$OUTPUT_PATH" <<EOF
  </packages>
</coverage>
EOF

log "Cobertura XML generated successfully: $OUTPUT_PATH"

# Validate XML is well-formed
if command -v xmllint &> /dev/null; then
    if xmllint --noout "$OUTPUT_PATH" 2>/dev/null; then
        log "XML validation: PASS"
    else
        echo "Warning: Generated XML may be malformed"
    fi
fi

# Print summary
echo ""
echo "✅ Coverage conversion complete!"
echo "   Output: $OUTPUT_PATH"
echo "   Line Coverage: ${LINE_COVERAGE}% ($LINES_COVERED/$LINES_VALID lines)"
echo "   Branch Coverage: ${BRANCH_COVERAGE}% ($BRANCHES_COVERED/$BRANCHES_VALID branches)"
echo ""
