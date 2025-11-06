# CI/CD Scripts

This directory contains utility scripts for CI/CD pipelines and local development workflows.

---

## 📄 Available Scripts

### `convert_coverage_to_cobertura.sh`

Converts Xcode code coverage reports to Cobertura XML format for use with coverage quality gates and reporting tools.

**Purpose:**
- Extract coverage data from `.xcresult` bundles
- Convert to standardized Cobertura XML format
- Enable coverage quality gates in CI/CD pipelines
- Integrate with coverage tracking services (Codecov, Coveralls, etc.)

**Usage:**
```bash
bash scripts/convert_coverage_to_cobertura.sh \
  -xcresult path/to/Test.xcresult \
  -output coverage.xml \
  [-v]
```

**Options:**
- `-xcresult <path>` - Path to `.xcresult` bundle (required)
- `-output <path>` - Output path for Cobertura XML (default: `coverage.xml`)
- `-v, --verbose` - Enable verbose logging
- `-h, --help` - Show help message

**Requirements:**
- macOS with Xcode installed
- `xccov` tool (comes with Xcode)
- `jq` for JSON processing (install: `brew install jq`)
- `xmllint` for validation (optional, comes with macOS)

**Example:**
```bash
# Run tests with coverage
xcodebuild test \
  -workspace ISOInspector.xcworkspace \
  -scheme FoundationUI \
  -destination 'platform=macOS' \
  -enableCodeCoverage YES \
  -resultBundlePath ./TestResults.xcresult

# Convert to Cobertura XML
bash scripts/convert_coverage_to_cobertura.sh \
  -xcresult ./TestResults.xcresult \
  -output coverage.xml \
  -v

# Output:
# ✅ Coverage conversion complete!
#    Output: coverage.xml
#    Line Coverage: 84.5% (5265/6233 lines)
#    Branch Coverage: 0.0% (0/0 branches)
```

**Output Format:**
The script generates a Cobertura XML file with the following structure:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<coverage line-rate="0.845" branch-rate="0.0" ...>
  <sources>
    <source>FoundationUI/Sources</source>
  </sources>
  <packages>
    <package name="FoundationUI" ...>
      <classes>
        <class name="Badge.swift" filename="..." line-rate="0.95" ...>
          <methods/>
          <lines>
            <line number="42" hits="10" branch="false"/>
            ...
          </lines>
        </class>
      </classes>
    </package>
  </packages>
</coverage>
```

**Integration with CI:**
```yaml
- name: Generate Cobertura coverage report
  run: |
    bash scripts/convert_coverage_to_cobertura.sh \
      -xcresult ./TestResults.xcresult \
      -output coverage.xml \
      -v

- name: Check coverage threshold
  uses: insightsengineering/coverage-action@v3
  with:
    path: ./coverage.xml
    threshold: 80.0
    fail: true
```

**Technical Details:**
1. Extracts coverage JSON from `.xcresult` using `xccov view --report --json`
2. Parses JSON structure with `jq` to extract:
   - Overall metrics (line/branch coverage)
   - Per-target metrics
   - Per-file metrics
   - Per-line execution counts
3. Generates Cobertura XML with proper structure
4. Validates XML if `xmllint` is available

**Limitations:**
- Requires macOS (uses `xccov`)
- Branch coverage may not be fully supported (depends on Xcode version)
- Large `.xcresult` bundles may take time to process

**Troubleshooting:**

*"jq: command not found"*
```bash
brew install jq
```

*"Failed to extract coverage data"*
- Ensure tests ran with `-enableCodeCoverage YES`
- Verify `.xcresult` bundle exists and is not empty
- Check Xcode version supports `xccov view --report --json`

*"XML validation failed"*
- Script still outputs XML (check for syntax errors manually)
- Some coverage actions are lenient with XML format
- Consider using `xmllint` to debug: `xmllint --noout coverage.xml`

---

## 🚀 Future Scripts

Planned scripts for this directory:

- `run_swiftlint.sh` - Run SwiftLint with custom configuration
- `generate_docc.sh` - Generate DocC documentation
- `archive_test_results.sh` - Archive test results for historical tracking
- `check_magic_numbers.sh` - Verify zero magic numbers policy
- `run_performance_tests.sh` - Run and analyze performance tests

---

## 📚 See Also

- [CI Coverage Setup Guide](../FoundationUI/DOCS/CI_COVERAGE_SETUP.md)
- [GitHub Actions Workflow](../.github/workflows/foundationui-coverage.yml)
- [Coverage Report](../FoundationUI/DOCS/INPROGRESS/CoverageReport_2025-11-06.md)

---

**Last Updated**: 2025-11-06
