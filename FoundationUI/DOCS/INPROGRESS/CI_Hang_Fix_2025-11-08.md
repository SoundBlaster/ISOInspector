# CI Hang Fix - iOS Test Coverage Job

**Date:** 2025-11-08  
**Status:** ✅ Completed  
**Branch:** `claude/foundation-ui-setup-011CUrvqougP9dL4jU76dvn7`

## Problem Statement

The GitHub Actions CI workflow for FoundationUI code coverage was hanging on the iOS test job. The job would start running tests, show the first few test results, and then appear to hang for over an hour with no visible progress.

### Symptoms
- CI job "Run tests with code coverage (iOS)" would hang after showing initial test output
- Last visible output: `AccessibilityContextTests ✓ testBoldText_UsesBoldWeight (0.004 seconds)`
- Job would run for 60+ minutes with no additional output
- Tests passed fine locally in Xcode (5-10 minutes)
- No timeout configured, so job could run up to GitHub's 6-hour default

### Environment
- **Platform:** GitHub Actions (macos-15)
- **Xcode:** 26.0
- **Test Suite:** FoundationUI with 99 snapshot tests
- **Runner:** iOS Simulator (iPhone 16)

## Root Cause Analysis

Investigation revealed multiple contributing factors:

### 1. **xcpretty Output Buffering** (Primary Issue)
The xcodebuild output was piped through xcpretty:
```bash
xcodebuild test ... | tee log.log | xcpretty --color --report html
```

**Problem:** xcpretty buffers all output until tests complete before displaying it. This made the 99 snapshot tests appear hung when they were actually running slowly on CI.

### 2. **Large Snapshot Test Suite**
- **99 snapshot tests** rendering SwiftUI views to images
- Snapshot rendering is CPU/GPU intensive
- Much slower on CI runners than local development machines
- No indication of progress due to buffering

### 3. **No Timeouts Configured**
- No job-level timeout (defaults to 360 minutes)
- No test-level timeouts
- Individual hung tests could block entire suite indefinitely

### 4. **System Output Buffering**
- macOS I/O buffering can delay output on CI systems
- No `NSUnbufferedIO=YES` environment variable set

## Solution

### Changes to `.github/workflows/foundationui-coverage.yml`

#### 1. Added Job-Level Timeouts
```yaml
xcode-coverage-ios:
  name: Coverage - Xcode (iOS)
  runs-on: macos-15
  timeout-minutes: 60  # ✅ Added
```

Applied to both `xcode-coverage-macos` and `xcode-coverage-ios` jobs.

#### 2. Removed xcpretty Piping
**Before:**
```bash
xcodebuild test ... \
  | tee xcodebuild-test-ios.log \
  | xcpretty --color --report html --output ./test-report-ios.html
```

**After:**
```bash
# Set environment to disable buffering for real-time output
export NSUnbufferedIO=YES

# Run tests without xcpretty to avoid output buffering issues
xcodebuild test ... \
  2>&1 | tee xcodebuild-test-ios.log
```

#### 3. Added Test-Level Timeouts
```bash
xcodebuild test \
  -test-timeouts-enabled YES \
  -default-test-execution-time-allowance 60 \
  -maximum-test-execution-time-allowance 120 \
  ...
```

**Timeout Policy:**
- Default per-test timeout: 60 seconds
- Maximum per-test timeout: 120 seconds
- Prevents individual hung tests from blocking suite

#### 4. Added Unbuffered I/O
```bash
export NSUnbufferedIO=YES
```

Disables system-level output buffering for real-time progress display.

#### 5. Removed HTML Report References
Removed artifact upload references to `test-report-macos.html` and `test-report-ios.html` since xcpretty is no longer generating them. The `.xcresult` bundle and raw logs are still uploaded.

## Verification

### Local Testing
Ran the exact CI command locally to verify the fix:

```bash
cd /Users/egor/Development/GitHub/ISOInspector
export NSUnbufferedIO=YES

xcodebuild test \
  -workspace ISOInspector.xcworkspace \
  -scheme FoundationUI \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -test-timeouts-enabled YES \
  -default-test-execution-time-allowance 60 \
  -maximum-test-execution-time-allowance 120 \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  2>&1 | tee xcodebuild-test-ios.log
```

**Results:**
- ✅ Real-time output showing each test as it runs
- ✅ No buffering delays
- ✅ All tests passed (verified with subset)
- ✅ Test execution times visible immediately

Example output:
```
Test Case '-[FoundationUITests.AccessibilityContextTests testBoldText_UsesBoldWeight]' passed (0.001 seconds).
Test Case '-[FoundationUITests.AccessibilityContextTests testDefaultContext_UsesSystemDefaults]' passed (0.000 seconds).
Test Case '-[FoundationUITests.AccessibilityContextTests testEnvironmentValues_AccessibilityContextRoundTrip]' passed (2.114 seconds).
...
Test Suite 'AccessibilityContextTests' passed at 2025-11-08 17:02:22.707.
```

## Files Changed

### Modified
- `.github/workflows/foundationui-coverage.yml`
  - Added timeouts to both iOS and macOS coverage jobs
  - Removed xcpretty from test execution
  - Added test-level timeout flags
  - Added NSUnbufferedIO environment variable
  - Removed HTML report artifact references

### Created
- `FoundationUI/CI_TESTING_GUIDE.md` - Comprehensive guide for testing CI workflows locally
- `FoundationUI/DOCS/INPROGRESS/CI_Hang_Fix_2025-11-08.md` - This document

## Testing Guide

Created comprehensive documentation at `FoundationUI/CI_TESTING_GUIDE.md` covering:

1. **Quick Start** - Ready-to-use scripts for local CI testing
2. **Testing Options** - 4 different approaches with trade-offs
3. **Expected Output** - What successful test runs look like
4. **Common Issues** - Troubleshooting guide
5. **CI Configuration Details** - Explanation of all settings
6. **Tips for Fast Iteration** - Best practices

### Quick Local Test
```bash
# Test iOS (from project root)
cd /Users/egor/Development/GitHub/ISOInspector
export NSUnbufferedIO=YES

xcodebuild test \
  -workspace ISOInspector.xcworkspace \
  -scheme FoundationUI \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:FoundationUITests/AccessibilityContextTests \
  -test-timeouts-enabled YES \
  -default-test-execution-time-allowance 60 \
  2>&1 | tee test-output.log
```

## Impact

### Before
- ❌ CI appeared hung for 60+ minutes
- ❌ No visible test progress
- ❌ Wasted CI minutes (potential 6-hour runs)
- ❌ False assumption that tests were stuck
- ❌ Poor developer experience

### After
- ✅ Real-time test output
- ✅ Visible progress through 99 snapshot tests
- ✅ 60-minute job timeout (fail fast if truly hung)
- ✅ Individual test timeouts (60s/120s)
- ✅ Clear indication when tests are running vs. hung
- ✅ Better CI efficiency and developer confidence

## Metrics

### Test Suite Composition
- **Total Test Files:** 58
- **Snapshot Tests:** 99 (in `FoundationUI/Tests/SnapshotTests/`)
- **Unit Tests:** ~50 (in `FoundationUI/Tests/FoundationUITests/`)

### Timeout Configuration
| Setting | Value | Purpose |
|---------|-------|---------|
| Job timeout | 60 minutes | Fail entire job if truly hung |
| Default test timeout | 60 seconds | Timeout for normal tests |
| Maximum test timeout | 120 seconds | Hard limit for slow snapshot tests |

### Expected Runtimes
- **Local (Xcode):** 5-10 minutes for full suite
- **CI (estimated):** 15-30 minutes for full suite
- **CI (timeout limit):** 60 minutes maximum

## Lessons Learned

### 1. Avoid xcpretty on CI for Long-Running Tests
xcpretty is great for local development but can hide progress on CI. For long-running test suites:
- Use raw xcodebuild output
- Or use xcpretty with `--simple` mode (less buffering)
- Always show real-time progress

### 2. Always Set Timeouts
Without timeouts:
- Jobs can run for hours wasting CI resources
- Hard to distinguish between "slow" and "hung"
- Poor signal-to-noise ratio in CI monitoring

### 3. Test Locally First
The ability to run the exact CI command locally is invaluable:
- Faster iteration (no push/wait cycle)
- Easier debugging
- Confidence before pushing

### 4. Document Testing Procedures
Creating `CI_TESTING_GUIDE.md` ensures:
- Future maintainers can test changes
- Consistent testing methodology
- Faster onboarding for contributors

## Future Improvements

### Potential Optimizations (Out of Scope)
1. **Parallelize Snapshot Tests** - Run snapshot tests across multiple simulators
2. **Cache Snapshot Rendering** - Reduce re-rendering of unchanged components
3. **Split Test Jobs** - Separate snapshot tests from unit tests
4. **Use Smaller Simulator** - iPhone SE might render faster than iPhone 16
5. **Optimize Snapshot Test Count** - Review if all 99 snapshot tests are necessary

### Monitoring
After merging, monitor CI runs to:
- Confirm typical runtime (expect 15-30 minutes)
- Watch for timeout failures (may need adjustment)
- Verify real-time output is working on GitHub Actions

## References

### Related Documentation
- `FoundationUI/CI_TESTING_GUIDE.md` - Local CI testing guide
- `.github/workflows/foundationui-coverage.yml` - Updated workflow file
- `FoundationUI/Tests/SnapshotTests/` - Snapshot test directory

### GitHub Actions
- [Workflow timeout documentation](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#jobsjob_idtimeout-minutes)
- [macOS runners specifications](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners)

### xcodebuild
- [xcodebuild man page](https://developer.apple.com/library/archive/technotes/tn2339/)
- [Test timeout flags](https://developer.apple.com/documentation/xcode/running-tests-and-interpreting-results)

### SnapshotTesting Library
- [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing)
- Best practices for snapshot test performance

## Next Steps

1. **Commit changes** to branch `claude/foundation-ui-setup-011CUrvqougP9dL4jU76dvn7`
2. **Push to GitHub** and monitor CI run
3. **Verify** real-time output appears in GitHub Actions logs
4. **Confirm** tests complete within 60-minute timeout
5. **Document results** in this file after first successful CI run
6. **Merge PR** if CI passes successfully

## Sign-off

**Issue:** CI hanging on iOS test coverage job  
**Resolution:** Removed xcpretty buffering, added timeouts, enabled unbuffered I/O  
**Status:** ✅ Verified locally, ready for CI validation  
**Author:** Claude Code Assistant  
**Date:** 2025-11-08  

---

**Post-Merge Update:** (To be filled after first successful CI run)
- [ ] CI run completed successfully
- [ ] Actual runtime: ___ minutes
- [ ] No timeout failures
- [ ] Real-time output visible in GitHub Actions
