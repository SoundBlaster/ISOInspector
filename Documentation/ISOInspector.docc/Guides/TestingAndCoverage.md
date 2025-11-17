# Testing and Code Coverage

This guide explains how to run tests, interpret coverage reports, and understand the coverage gating system in ISOInspector.

## Overview

ISOInspector maintains a **minimum test coverage threshold of 67%** to ensure code quality and reliability. This threshold is enforced through:

- **Pre-push hooks**: Local validation before pushing to any branch
- **GitHub Actions**: Automated checks on pull requests and main branch pushes
- **Coverage analysis script**: Python tool that analyzes test coverage based on lines of code (LOC)

## Running Tests Locally

### Main Project (ISOInspectorKit, ISOInspectorCLI)

To run unit tests for the main project:

```bash
# Run all tests
swift test

# Run tests with code coverage enabled
swift test --enable-code-coverage

# Run specific test target
swift test --filter ISOInspectorKitTests
```

### FoundationUI Package

The FoundationUI package is a separate Swift Package that is integrated as a dependency:

```bash
# Navigate to FoundationUI directory
cd FoundationUI

# Run all tests
swift test

# Run tests with code coverage
swift test --enable-code-coverage

# Run specific test layer
swift test --filter DesignTokensTests
```

## Understanding the Coverage Analysis Script

The `coverage_analysis.py` script at the repository root analyzes test coverage by counting lines of code (LOC) and comparing source code LOC to test code LOC.

### Running the Coverage Analysis

To analyze coverage in the FoundationUI package:

```bash
# Basic analysis - prints detailed report
python3 coverage_analysis.py

# Check if coverage meets the 67% threshold
python3 coverage_analysis.py --threshold 0.67

# Write report to a file
python3 coverage_analysis.py --report coverage-report.txt

# Verbose mode with repository detection details
python3 coverage_analysis.py -v

# Combine options
python3 coverage_analysis.py --threshold 0.67 --report coverage.txt -v
```

### Understanding the Output

The script produces a detailed report showing:

1. **Per-Layer Analysis** - For each FoundationUI layer (DesignTokens, Modifiers, Components, etc.):
   - Source files and their lines of code (LOC)
   - Test files and their LOC
   - Test/Code ratio percentage
   - Constructs count (functions, structs, classes, enums, etc.)

2. **Summary** - Overall statistics:
   - Total source LOC across all layers
   - Total test LOC across all layers
   - Overall test/code ratio

### Example Report

```
================================================================================
SUMMARY
================================================================================

Total Source LOC: 6,926
Total Test LOC:   5,817
Overall Test/Code Ratio: 84.0%

Layer                  Source LOC     Test LOC      Ratio
------------------------------------------------------------
Layer 0                       100          161     161.0%
Layer 1                     1,188          842      70.9%
Layer 2                     1,418          926      65.3%
Layer 3                     2,272        1,333      58.7%
Layer 4                     1,125        1,877     166.8%
Utilities                     823          678      82.4%

✅ Coverage 84.0% meets threshold 67.0%
```

## Coverage Gating System

### Pre-Push Hook

The pre-push hook automatically checks coverage before you push code:

1. **Trigger**: The hook runs when you execute `git push`
2. **Detection**: It identifies if you've changed files in `FoundationUI/Sources/` or `FoundationUI/Tests/`
3. **Check**: If changes are detected, it runs:
   ```bash
   python3 coverage_analysis.py --threshold 0.67
   ```
4. **Result**:
   - ✅ **Pass**: Push proceeds normally
   - ❌ **Fail**: Push is aborted with clear error message

If the hook fails, you must improve your test coverage before pushing:

```bash
# Review the coverage report
python3 coverage_analysis.py --verbose

# Write tests to improve coverage
# Then stage and commit changes
git add .
git commit -m "Add tests to improve coverage"

# Try pushing again
git push
```

To bypass the hook (not recommended):

```bash
git push --no-verify
```

### GitHub Actions Workflow

The `coverage-gate.yml` workflow runs on:

- Pull requests to `main` or any branch
- Pushes to `main`
- Changes in test or source files

**Workflow Steps:**

1. Checks out the repository
2. Runs tests with code coverage enabled
3. Executes `coverage_analysis.py --threshold 0.67`
4. Uploads coverage reports as artifacts
5. Comments on PRs with coverage results
6. Fails the workflow if coverage drops below 67%

**Artifact Location:**

Coverage reports are available as GitHub Actions artifacts in the `coverage-reports` artifact:

- `coverage-report.txt` - Main coverage analysis report
- `foundationui-test.log` - FoundationUI test output
- `main-test.log` - Main project test output
- `coverage-analysis.log` - Coverage script execution log

## Updating Coverage Thresholds

If project requirements change and you need to adjust the coverage threshold:

### 1. Update Pre-Push Hook

Edit `.githooks/pre-push` and change the threshold:

```bash
# Current:
COVERAGE_THRESHOLD=${ISOINSPECTOR_MIN_TEST_COVERAGE:-0.67}

# Change 0.67 to your new threshold (e.g., 0.75)
COVERAGE_THRESHOLD=${ISOINSPECTOR_MIN_TEST_COVERAGE:-0.75}
```

### 2. Update GitHub Actions Workflow

Edit `.github/workflows/coverage-gate.yml`:

```yaml
- name: Run coverage analysis
  run: |
    # Change 0.67 to your new threshold
    python3 coverage_analysis.py --threshold 0.75 --report Documentation/Quality/coverage-report.txt -v
```

### 3. Update Environment Variable (Optional)

You can set the `ISOINSPECTOR_MIN_TEST_COVERAGE` environment variable to avoid hardcoding:

```bash
# Before pushing
export ISOINSPECTOR_MIN_TEST_COVERAGE=0.75
git push
```

### 4. Document the Change

Update this guide and any relevant architecture documentation.

## Best Practices

### Writing Testable Code

1. **Keep functions focused** - Smaller functions are easier to test
2. **Avoid hidden dependencies** - Inject dependencies instead of hardcoding
3. **Separate concerns** - Keep business logic separate from I/O
4. **Use protocols** - Make code mockable and testable
5. **Avoid global state** - Use parameters and return values

### Writing Effective Tests

1. **Test one thing per test** - Clear test names describe what's tested
2. **Use Arrange-Act-Assert pattern**:
   ```swift
   // Arrange - Set up test data
   let input = "test"

   // Act - Execute the code being tested
   let result = functionUnderTest(input)

   // Assert - Verify the result
   XCTAssertEqual(result, expected)
   ```

3. **Test edge cases** - Empty inputs, nil values, boundaries
4. **Use descriptive names** - `test_returnsEmptyArray_whenInputIsNil()` vs `test1()`
5. **Keep tests independent** - No shared state between tests

### Coverage Metrics to Track

The script provides several metrics:

- **Test/Code Ratio (%)**: Higher is better, but diminishing returns after 70-80%
- **Per-Layer Coverage**: Identify layers that need more testing
- **Construct Count**: Verify all public functions/structs have tests

## Troubleshooting

### "Coverage FAILED: X% below threshold Y%"

**Cause**: Your changes introduced code without corresponding tests.

**Solution**:
```bash
# 1. Analyze which layers have low coverage
python3 coverage_analysis.py -v

# 2. Add tests for new/modified code
# 3. Verify the fix
python3 coverage_analysis.py --threshold 0.67
```

### Pre-push hook blocked my push

**Cause**: Local coverage is below 67%.

**Solution**:
```bash
# 1. Run coverage analysis locally
python3 coverage_analysis.py --verbose

# 2. Identify untested code and add tests
# 3. Verify coverage is above threshold
python3 coverage_analysis.py --threshold 0.67

# 4. Commit and try pushing again
git add .
git commit -m "Add tests to meet coverage threshold"
git push
```

### Script says "Python3 not available"

**Cause**: Python 3 is not installed or not in PATH.

**Solution**:
```bash
# Install Python 3
brew install python3  # macOS
apt-get install python3  # Ubuntu/Linux

# Verify installation
python3 --version

# Run script again
python3 coverage_analysis.py --threshold 0.67
```

### Coverage seems inconsistent between local and CI

**Cause**: Different test sets or environment differences.

**Solution**:
1. Ensure you're in the repository root when running the script
2. Check that all FoundationUI source and test files are properly located
3. Verify the script can find `.git` directory for repo root detection

```bash
# Debug repository detection
python3 coverage_analysis.py -v
```

## Related Documentation

- [Developer Onboarding Guide](./DeveloperOnboarding.md)
- [Architecture Overview](../../../DOCS/AI/ISOViewer/ISOInspector_PRD_Full/ISOInspector_Master_PRD.md)
- [Code of Conduct](../../../DOCS/RULES)

## Questions or Issues?

If you encounter problems with testing or coverage:

1. Check this guide first
2. Review test logs from GitHub Actions artifacts
3. Consult the project's issue tracker
4. Reach out to the development team
