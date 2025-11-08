# CI Testing Guide for FoundationUI

This guide explains how to test GitHub Actions CI workflows locally before pushing changes.

## Background

The FoundationUI test suite includes 99 snapshot tests that render SwiftUI views. These tests can be slow on CI runners, and output buffering can make them appear hung. This guide helps you validate CI changes locally.

## Quick Start

### Test the exact CI commands locally

Two pre-configured scripts are available to run the exact same xcodebuild commands as CI:

**Test iOS (matches CI iOS job):**
```bash
cd /path/to/ISOInspector
/tmp/test_ci_ios.sh
```

**Test macOS (matches CI macOS job):**
```bash
cd /path/to/ISOInspector
/tmp/test_ci_macos.sh
```

Or create them yourself:

```bash
# iOS test script
cat > test_ci_ios.sh << 'EOF'
#!/bin/bash
set -eo pipefail

# Set environment to disable buffering for real-time output
export NSUnbufferedIO=YES

# Run tests without xcpretty to avoid output buffering issues
xcodebuild test \
  -workspace ISOInspector.xcworkspace \
  -scheme FoundationUI \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -configuration Debug \
  -enableCodeCoverage YES \
  -derivedDataPath ./DerivedData \
  -resultBundlePath ./TestResults-iOS.xcresult \
  -test-timeouts-enabled YES \
  -default-test-execution-time-allowance 60 \
  -maximum-test-execution-time-allowance 120 \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  2>&1 | tee xcodebuild-test-ios.log
EOF
chmod +x test_ci_ios.sh
```

```bash
# macOS test script
cat > test_ci_macos.sh << 'EOF'
#!/bin/bash
set -eo pipefail

# Set environment to disable buffering for real-time output
export NSUnbufferedIO=YES

# Run tests without xcpretty to avoid output buffering issues
xcodebuild test \
  -workspace ISOInspector.xcworkspace \
  -scheme FoundationUI \
  -destination 'platform=macOS' \
  -configuration Debug \
  -enableCodeCoverage YES \
  -derivedDataPath ./DerivedData \
  -resultBundlePath ./TestResults-macOS.xcresult \
  -test-timeouts-enabled YES \
  -default-test-execution-time-allowance 60 \
  -maximum-test-execution-time-allowance 120 \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  2>&1 | tee xcodebuild-test-macos.log
EOF
chmod +x test_ci_macos.sh
```

## Testing Options

### Option 1: Run Exact CI Commands (Recommended)

This runs the same xcodebuild commands as the CI workflow.

**Advantages:**
- ✅ Exact match to CI environment
- ✅ Tests real-time output
- ✅ Validates timeout settings
- ✅ Fast feedback (5-15 minutes locally)

**What to verify:**
1. Real-time output appears immediately
2. Each test name is displayed as it runs
3. No long pauses or buffering
4. Tests complete successfully
5. Log file is created

### Option 2: Test a Single Test Class

Quick verification that output is working:

```bash
xcodebuild test \
  -workspace ISOInspector.xcworkspace \
  -scheme FoundationUI \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:FoundationUITests/BadgeSnapshotTests \
  -test-timeouts-enabled YES \
  -default-test-execution-time-allowance 60 \
  2>&1 | tee test-output.log
```

**Advantages:**
- ✅ Very fast (1-2 minutes)
- ✅ Good for quick validation

**Disadvantages:**
- ⚠️ Doesn't test full suite

### Option 3: Push to Test Branch

Test in the actual CI environment:

```bash
# Create a test branch
git checkout -b test/ci-changes

# Commit your changes
git add .github/workflows/foundationui-coverage.yml
git commit -m "Test: CI configuration changes"

# Push and watch CI
git push -u origin test/ci-changes
```

Then monitor the workflow at: `https://github.com/YOUR_REPO/actions`

**Advantages:**
- ✅ Tests actual CI environment
- ✅ Tests all runners (macOS-15)
- ✅ Validates entire workflow

**Disadvantages:**
- ⚠️ Slower (uses CI minutes)
- ⚠️ Requires push access

### Option 4: Using GitHub's `act` tool

**Note:** This doesn't work well for macOS/Xcode workflows, but included for completeness.

```bash
# Install act
brew install act

# Run specific job
act -j xcode-coverage-ios

# Run entire workflow
act -W .github/workflows/foundationui-coverage.yml
```

**Limitations:**
- ❌ Can't run macOS jobs in Docker
- ❌ Limited Xcode support
- ✅ Good for Linux/cross-platform workflows

## Expected Output

When tests run correctly, you should see:

```
Test Suite FoundationUITests.xctest started
AccessibilityContextTests
    ✓ testBoldText_UsesBoldWeight (0.004 seconds)
    ✓ testDefaultContext_UsesSystemDefaults (0.002 seconds)
    ...

BadgeSnapshotTests
    ✓ testBadgeInfoLightMode (0.234 seconds)
    ✓ testBadgeWarningLightMode (0.198 seconds)
    ✓ testBadgeErrorLightMode (0.201 seconds)
    ...

Test Suite FoundationUITests.xctest passed
    Executed 150 tests, with 0 failures
```

## Common Issues

### Tests appear to hang

**Symptoms:**
- Output stops after a few tests
- No progress for minutes

**Causes:**
- xcpretty buffering output
- Missing `NSUnbufferedIO=YES`
- Slow snapshot rendering

**Solutions:**
1. Remove xcpretty from the pipeline
2. Add `export NSUnbufferedIO=YES`
3. Use `2>&1 | tee log.txt` for unbuffered output
4. Add test timeouts

### Individual test timeouts

**Symptoms:**
- Test fails with timeout error
- Shows "Exceeded timeout of 60 seconds"

**Solutions:**
1. Optimize the test (reduce view complexity)
2. Increase timeout limits if needed:
   ```bash
   -default-test-execution-time-allowance 120 \
   -maximum-test-execution-time-allowance 180
   ```

### Simulator not found

**Symptoms:**
- "Unable to find destination matching provided destination specifier"

**Solutions:**
1. List available simulators:
   ```bash
   xcrun simctl list devices available
   ```
2. Update destination to match available device:
   ```bash
   -destination 'platform=iOS Simulator,name=iPhone 15'
   ```

## CI Configuration Details

### Test Timeouts

The workflow uses these timeout settings:

| Setting | Value | Purpose |
|---------|-------|---------|
| Job timeout | 60 minutes | Fail job if entire test suite hangs |
| Default test timeout | 60 seconds | Timeout for individual tests |
| Maximum test timeout | 120 seconds | Hard limit for slow tests |

### Output Configuration

- `NSUnbufferedIO=YES` - Disables system-level output buffering
- `2>&1 \| tee log.txt` - Captures both stdout and stderr in real-time
- No xcpretty - Removed to prevent output buffering

### Coverage Collection

Coverage is collected via:
- `-enableCodeCoverage YES` flag
- Results stored in `.xcresult` bundle
- Converted to Cobertura XML format
- Uploaded to Codecov

## Workflow File Location

The CI configuration is in:
```
.github/workflows/foundationui-coverage.yml
```

## Related Files

- `scripts/convert_coverage_to_cobertura.sh` - Coverage conversion script
- `scripts/check_coverage_threshold.py` - Coverage validation
- `FoundationUI/Tests/SnapshotTests/` - Snapshot test directory (99 tests)

## Tips for Fast Iteration

1. **Test locally first** - Always run tests locally before pushing
2. **Use test branch** - Don't push directly to main for CI testing
3. **Watch output live** - Real-time output helps identify issues quickly
4. **Check simulator availability** - Ensure target simulator exists locally
5. **Use `-only-testing`** - Test specific classes during development

## Maintenance

When updating CI configuration:

1. Test locally using scripts above
2. Verify output is real-time (not buffered)
3. Confirm timeouts work as expected
4. Push to test branch first
5. Monitor CI run completely
6. Merge only after successful CI run

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [xcodebuild Man Page](https://developer.apple.com/library/archive/technotes/tn2339/)
- [SnapshotTesting Library](https://github.com/pointfreeco/swift-snapshot-testing)
- [Codecov Documentation](https://docs.codecov.com/)
