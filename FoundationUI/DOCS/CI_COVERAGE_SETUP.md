# Code Coverage Quality Gate Setup

**Date**: 2025-11-06
**Project**: FoundationUI
**Status**: ✅ Configured

---

## 📊 Overview

FoundationUI has a comprehensive code coverage quality gate that ensures all PRs meet the **80% coverage threshold** before merging. This document explains the setup, configuration, and how to work with the coverage system.

---

## 🎯 Coverage Targets

| Target | Threshold | Platforms | Test Types |
|--------|-----------|-----------|------------|
| **Primary Gate** | **≥80%** | macOS, iOS | Unit + Snapshot |
| **SPM Validation** | ≥80% | macOS (Linux-compatible) | Unit only |
| **Overall Project** | ≥80% | All | Comprehensive |

---

## 🔧 Architecture

### Coverage Workflow Components

```
┌─────────────────────────────────────────────────────────────┐
│                 GitHub Actions Workflow                      │
│            (.github/workflows/foundationui-coverage.yml)     │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┴───────────────────┐
        │                                       │
        ▼                                       ▼
┌───────────────────┐                  ┌────────────────────┐
│  SPM Coverage     │                  │  Xcode Coverage    │
│  (Unit Tests)     │                  │  (Comprehensive)   │
│  - macOS          │                  │  - macOS           │
│  - Swift Package  │                  │  - iOS Simulator   │
│  - llvm-cov       │                  │  - xccov           │
└───────────────────┘                  └────────────────────┘
        │                                       │
        │                                       │
        ▼                                       ▼
┌───────────────────┐                  ┌────────────────────┐
│  LCOV Format      │                  │  Cobertura XML     │
│  coverage-spm.lcov│                  │  coverage-*.xml    │
└───────────────────┘                  └────────────────────┘
        │                                       │
        └───────────────────┬───────────────────┘
                            │
                            ▼
                  ┌──────────────────┐
                  │  Coverage Action │
                  │  (Quality Gate)  │
                  │  - Threshold: 80%│
                  │  - Fail if below │
                  └──────────────────┘
                            │
                            ▼
                  ┌──────────────────┐
                  │   Codecov.io     │
                  │   (Optional)     │
                  │   - Tracking     │
                  │   - Trends       │
                  │   - PR Comments  │
                  └──────────────────┘
```

---

## 📝 Workflow Jobs

### 1. SPM Coverage (Linux-compatible)
**Purpose**: Validate coverage for cross-platform unit tests

```yaml
Job: spm-coverage
Runner: macos-15
Tools: swift test, llvm-cov
Output: coverage-spm.lcov
```

**What it tests:**
- Unit tests that run on both macOS and Linux
- Platform-agnostic code paths
- Design Tokens, Core Logic, Utilities

**Why it's important:**
- Ensures code works without SwiftUI dependencies
- Validates cross-platform compatibility
- Fast feedback loop

### 2. Xcode Coverage - macOS
**Purpose**: Comprehensive coverage including SwiftUI and platform-specific code

```yaml
Job: xcode-coverage-macos
Runner: macos-15
Tools: xcodebuild, xccov
Output: coverage-macos.xml (Cobertura)
```

**What it tests:**
- All unit tests (53+ test files)
- Snapshot tests (visual regression)
- SwiftUI view rendering
- macOS-specific features (NSPasteboard, keyboard shortcuts)

**Quality Gate:**
- ✅ **Pass**: ≥80% coverage
- ❌ **Fail**: <80% coverage (blocks merge)

### 3. Xcode Coverage - iOS
**Purpose**: iOS-specific coverage validation

```yaml
Job: xcode-coverage-ios
Runner: macos-15 + iOS Simulator (iPhone 16, iOS 18.4)
Tools: xcodebuild, xccov
Output: coverage-ios.xml (Cobertura)
```

**What it tests:**
- All unit tests on iOS
- Snapshot tests with iOS rendering
- iOS-specific features (UIPasteboard, touch targets)
- Dynamic Type, VoiceOver on iOS

**Quality Gate:**
- ✅ **Pass**: ≥80% coverage
- ❌ **Fail**: <80% coverage (blocks merge)

### 4. Coverage Summary
**Purpose**: Aggregate results and generate PR summary

```yaml
Job: coverage-summary
Runner: ubuntu-latest
Depends: spm-coverage, xcode-coverage-macos, xcode-coverage-ios
```

**Output:**
- GitHub Step Summary with coverage table
- Platform-by-platform status
- Overall quality gate result
- Fails if any platform fails the gate

---

## 🚀 Usage

### For Developers

#### Running Coverage Locally

**Option 1: SPM (fast, unit tests only)**
```bash
cd FoundationUI
swift test --enable-code-coverage

# Generate report
swift test --enable-code-coverage --parallel
xcrun llvm-cov report \
  -instr-profile=.build/debug/codecov/default.profdata \
  .build/debug/FoundationUIPackageTests.xctest/Contents/MacOS/FoundationUIPackageTests
```

**Option 2: Xcode (comprehensive, with UI)**
```bash
# Generate Xcode project with Tuist
tuist generate

# Open Xcode and run tests with coverage
xcodebuild test \
  -workspace ISOInspector.xcworkspace \
  -scheme FoundationUI \
  -destination 'platform=macOS' \
  -enableCodeCoverage YES \
  -resultBundlePath ./TestResults.xcresult

# View in Xcode
open ./TestResults.xcresult
```

**Option 3: Generate Cobertura XML**
```bash
# After running Xcode tests
bash scripts/convert_coverage_to_cobertura.sh \
  -xcresult ./TestResults.xcresult \
  -output coverage.xml \
  -v
```

#### Viewing Coverage in Xcode
1. Run tests with coverage: `⌘U`
2. Open Report Navigator: `⌘9`
3. Select latest test run
4. Click "Coverage" tab
5. Drill down into specific files

#### Improving Coverage
1. Identify untested code paths (red lines in Xcode)
2. Write tests for uncovered scenarios:
   - Edge cases
   - Error handling
   - Platform-specific paths
   - Accessibility features
3. Run coverage again to verify
4. Commit tests with implementation

### For CI/CD

#### Automatic Checks
- **Every PR**: Coverage gate runs automatically
- **Every push to main**: Coverage tracking updated
- **Threshold**: 80% required on macOS and iOS

#### Status Checks
The following checks must pass before merging:
- ✅ `Coverage - SPM (Unit Tests)`
- ✅ `Coverage - Xcode (macOS)` ← **Quality Gate**
- ✅ `Coverage - Xcode (iOS)` ← **Quality Gate**
- ✅ `Coverage Summary`

#### What Happens When Coverage Fails
1. PR check fails with red ❌
2. GitHub blocks merge (if branch protection enabled)
3. Coverage report shows which files are below threshold
4. Developer adds tests to improve coverage
5. Push updated tests
6. Coverage gate re-runs automatically

---

## 🔐 Branch Protection Setup

### Recommended Settings

Go to: **Settings → Branches → main → Add rule**

**Required status checks:**
- ✅ `Coverage - Xcode (macOS)`
- ✅ `Coverage - Xcode (iOS)`
- ✅ `Coverage Summary`

**Additional recommendations:**
- ✅ Require branches to be up to date before merging
- ✅ Require conversation resolution before merging
- ✅ Require linear history
- ✅ Include administrators (enforce for everyone)

**Optional:**
- `Coverage - SPM (Unit Tests)` (not required but useful)

---

## 📦 Required GitHub Secrets

### Codecov Integration (Optional)

If you want to use Codecov for tracking and PR comments:

1. Go to [codecov.io](https://codecov.io) and sign up with GitHub
2. Add the ISOInspector repository
3. Copy the Codecov token
4. Add to GitHub: **Settings → Secrets → Actions → New repository secret**
   - Name: `CODECOV_TOKEN`
   - Value: `<your-token>`

**Note**: Coverage gate works without Codecov, but Codecov provides:
- Coverage trends over time
- PR comment with coverage diff
- Beautiful coverage dashboards
- Coverage badges

---

## 🛠️ Technical Details

### Coverage Conversion Script

**Location**: `scripts/convert_coverage_to_cobertura.sh`

**What it does:**
1. Extracts coverage data from `.xcresult` bundle using `xccov`
2. Parses JSON coverage report with `jq`
3. Converts to Cobertura XML format (widely supported)
4. Validates XML output

**Usage:**
```bash
bash scripts/convert_coverage_to_cobertura.sh \
  -xcresult path/to/Test.xcresult \
  -output coverage.xml \
  -v
```

**Requirements:**
- Xcode with `xccov` tool
- `jq` (install: `brew install jq`)
- `xmllint` (optional, for validation)

### Coverage Action

**GitHub Action**: `insightsengineering/coverage-action@v3`

**Configuration:**
```yaml
- name: Check coverage threshold
  uses: insightsengineering/coverage-action@v3
  with:
    path: ./coverage-macos.xml
    threshold: 80.0           # Minimum coverage percentage
    fail: true                # Fail job if below threshold
    publish: true             # Publish results to PR
    diff: true                # Show coverage diff
    togglable-report: true    # Collapsible report in PR
```

**What it checks:**
- Overall line coverage percentage
- Per-file coverage
- Coverage diff (new vs existing code)
- Branch coverage (if available)

---

## 📊 Current Coverage Status

As of 2025-11-06:

| Layer | Coverage | Status |
|-------|----------|--------|
| Layer 0 (Design Tokens) | 123.5% | ✅ Excellent |
| Layer 1 (View Modifiers) | 72.3% | ⚠️ Good |
| Layer 2 (Components) | 84.7% | ✅ Excellent |
| Layer 3 (Patterns) | 59.1% | ⚠️ Needs work |
| Layer 4 (Contexts) | 145.5% | ✅ Excellent |
| Utilities | 77.7% | ⚠️ Good |
| **Overall** | **84.5%** | ✅ **Above threshold** |

**Analysis:**
- ✅ Overall coverage exceeds 80% threshold
- ⚠️ Layer 3 (Patterns) needs more tests (target: 80%)
- ⚠️ Layer 1 (View Modifiers) close to threshold

**Improvement Plan:**
1. Add 440 test LOC to Layer 3 (Patterns)
2. Add 100 test LOC to Layer 1 (View Modifiers)
3. Add 20 test LOC to Utilities
4. Focus on edge cases and error handling

**Reference**: See `CoverageReport_2025-11-06.md` for detailed analysis

---

## 🔍 Troubleshooting

### Coverage Lower Than Expected

**Possible causes:**
1. **Tests not running**: Check test execution logs
2. **Coverage not enabled**: Verify `-enableCodeCoverage YES` flag
3. **Files excluded**: Check xcodeproj settings (don't exclude source files)
4. **Platform-specific code**: Some code may only run on specific platforms

**Solutions:**
1. Run tests locally with coverage enabled
2. Review uncovered code in Xcode (Coverage tab)
3. Add missing tests for untested paths
4. Ensure platform-specific tests run on correct platform

### CI Job Failing

**Common issues:**

1. **Tuist installation fails**
   - Check Tuist release API availability
   - Verify cache is working
   - Try clearing cache

2. **Simulator not available**
   - Check simulator availability: `xcrun simctl list`
   - Update iOS version in workflow if needed
   - Ensure macOS runner has required simulators

3. **Coverage conversion fails**
   - Check `.xcresult` bundle exists
   - Verify `jq` is installed
   - Check script permissions (`chmod +x`)

4. **Coverage action fails**
   - Verify Cobertura XML is well-formed
   - Check XML contains coverage data
   - Ensure threshold is realistic (not 100%)

### Local Coverage Different from CI

**Possible reasons:**
1. **Different test sets**: CI may run more/fewer tests
2. **Platform differences**: macOS vs iOS coverage differs
3. **Xcode version**: Different versions may calculate differently
4. **Cache issues**: Old coverage data cached locally

**Solutions:**
1. Clear DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData`
2. Use same Xcode version as CI
3. Run same test command as CI
4. Check for flaky tests

---

## 📚 References

### Documentation
- [Xcode Code Coverage](https://developer.apple.com/documentation/xcode/code-coverage)
- [llvm-cov Documentation](https://llvm.org/docs/CommandGuide/llvm-cov.html)
- [Cobertura XML Format](https://cobertura.github.io/cobertura/)
- [GitHub Actions: Branch Protection](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)

### Tools
- [insightsengineering/coverage-action](https://github.com/insightsengineering/coverage-action)
- [Codecov](https://codecov.io)
- [xcpretty](https://github.com/xcpretty/xcpretty)
- [Tuist](https://tuist.io)

### Related Files
- `.github/workflows/foundationui-coverage.yml` - Coverage workflow
- `scripts/convert_coverage_to_cobertura.sh` - Conversion script
- `FoundationUI/DOCS/INPROGRESS/CoverageReport_2025-11-06.md` - Latest report
- `FoundationUI/DOCS/INPROGRESS/Phase5.2_ComprehensiveUnitTestCoverage.md` - Task document

---

## 🎯 Best Practices

### Writing Testable Code
1. **Small functions**: Easier to test, better coverage
2. **Dependency injection**: Mock dependencies in tests
3. **Pure functions**: Deterministic, no side effects
4. **Platform abstraction**: Isolate platform-specific code

### Writing Comprehensive Tests
1. **Test public API**: Every public method/property
2. **Edge cases**: Empty, nil, extreme values
3. **Error handling**: Test all error paths
4. **Platform variants**: Test iOS and macOS paths
5. **Accessibility**: Test VoiceOver, Dynamic Type

### Maintaining Coverage
1. **Write tests first** (TDD): Ensures coverage from start
2. **Review coverage in PRs**: Check coverage diff
3. **Monitor trends**: Track coverage over time
4. **Fix drops immediately**: Don't let coverage decay
5. **Celebrate improvements**: Acknowledge good tests

---

## ✅ Checklist for New Features

When adding new code to FoundationUI:

- [ ] Write unit tests before implementation (TDD)
- [ ] Achieve ≥80% coverage for new code
- [ ] Test on both macOS and iOS
- [ ] Add edge case tests
- [ ] Test error handling
- [ ] Verify accessibility features
- [ ] Run coverage locally before pushing
- [ ] Check CI coverage report after PR
- [ ] Address any coverage drops
- [ ] Update documentation if needed

---

**Last Updated**: 2025-11-06
**Maintained By**: FoundationUI Team
**Contact**: See repository contributors
