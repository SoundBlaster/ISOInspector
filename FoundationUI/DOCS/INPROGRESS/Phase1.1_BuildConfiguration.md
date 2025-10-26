# Phase 1.1: Build Configuration Setup

## 🎯 Objective

Complete the build configuration and tooling setup for FoundationUI, ensuring strict code quality standards, automated testing, and CI/CD readiness.

## 🧩 Context

- **Phase**: 1.1 Project Setup & Infrastructure
- **Layer**: Layer 0 (Infrastructure)
- **Priority**: P0 (Critical)
- **Dependencies**:
  - ✅ FoundationUI Swift Package structure created
  - ✅ SwiftLint configuration file exists
  - ✅ Package.swift with platform targets configured
  - ✅ Test infrastructure in place

## ✅ Success Criteria

### Compiler Settings
- [ ] Swift compiler configured with strict concurrency checking
- [ ] Warnings treated as errors in Package.swift
- [ ] Swift 6.0 language mode enabled
- [ ] Platform-specific compiler flags documented

### SwiftLint Configuration
- [x] `.swiftlint.yml` exists with `no_magic_numbers` rule ✅ Already complete
- [x] Custom rules for DS token usage ✅ Already complete
- [x] Analyzer rules configured ✅ Already complete
- [ ] Verify SwiftLint runs successfully on codebase

### CI/CD Pipeline
- [ ] Build script created for automated testing
- [ ] Script validates zero SwiftLint violations
- [ ] Script runs full test suite
- [ ] Platform-specific build commands documented
- [ ] GitHub Actions workflow (or similar) configured

### Code Coverage
- [ ] Code coverage reporting configured in Package.swift
- [ ] Coverage target set to ≥80%
- [ ] Coverage reports generated and accessible
- [ ] Integration with CI pipeline

### Documentation
- [ ] Build process documented in README or BUILD.md
- [ ] Developer setup instructions updated
- [ ] CI/CD workflow documented
- [ ] Troubleshooting guide for common build issues

## 🔧 Implementation Notes

### Swift Compiler Settings

Add to `FoundationUI/Package.swift`:

```swift
targets: [
    .target(
        name: "FoundationUI",
        dependencies: [],
        swiftSettings: [
            .enableUpcomingFeature("StrictConcurrency"),
            .unsafeFlags(["-warnings-as-errors"], .when(configuration: .release))
        ]
    ),
    // ...
]
```

### Build Scripts

Create `FoundationUI/Scripts/build.sh`:
```bash
#!/bin/bash
set -e

echo "🔨 Building FoundationUI..."
swift build

echo "✅ Running tests..."
swift test --enable-code-coverage

echo "🔍 Checking SwiftLint..."
swiftlint --strict

echo "📊 Generating coverage report..."
xcrun llvm-cov report .build/debug/FoundationUIPackageTests.xctest/Contents/MacOS/FoundationUIPackageTests \
  -instr-profile .build/debug/codecov/default.profdata \
  -ignore-filename-regex=".build|Tests"

echo "✅ All checks passed!"
```

### Code Coverage Configuration

For Xcode projects, add to scheme settings:
- Enable "Gather coverage for all targets"
- Set coverage target to 80%

For SPM, use `swift test --enable-code-coverage` and analyze with `llvm-cov`.

### CI/CD Integration

Example GitHub Actions workflow (`.github/workflows/foundationui.yml`):

```yaml
name: FoundationUI CI

on:
  push:
    branches: [ main, develop ]
    paths:
      - 'FoundationUI/**'
  pull_request:
    branches: [ main, develop ]
    paths:
      - 'FoundationUI/**'

jobs:
  build-and-test:
    runs-on: macos-latest

    steps:
    - uses: actions/checkout@v4

    - name: Select Xcode version
      run: sudo xcode-select -s /Applications/Xcode_15.0.app

    - name: SwiftLint
      run: |
        cd FoundationUI
        swiftlint --strict

    - name: Build
      run: |
        cd FoundationUI
        swift build

    - name: Run Tests
      run: |
        cd FoundationUI
        swift test --enable-code-coverage

    - name: Generate Coverage Report
      run: |
        cd FoundationUI
        xcrun llvm-cov export -format="lcov" \
          .build/debug/FoundationUIPackageTests.xctest/Contents/MacOS/FoundationUIPackageTests \
          -instr-profile .build/debug/codecov/default.profdata \
          > coverage.lcov

    - name: Upload Coverage
      uses: codecov/codecov-action@v3
      with:
        files: ./FoundationUI/coverage.lcov
        fail_ci_if_error: true
```

## 📁 Files to Create/Modify

### Create
- `FoundationUI/Scripts/build.sh` — Automated build and test script
- `FoundationUI/Scripts/coverage.sh` — Code coverage report generator
- `FoundationUI/BUILD.md` — Build and development setup guide
- `.github/workflows/foundationui.yml` — CI/CD workflow

### Modify
- `FoundationUI/Package.swift` — Add compiler flags and settings
- `FoundationUI/README.md` — Update with build instructions (if needed)

## 🧠 Source References

- [FoundationUI Task Plan § 1.1](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md#11-project-setup--infrastructure)
- [TDD Workflow Rules](../../../DOCS/RULES/02_TDD_XP_Workflow.md)
- [Swift Package Manager Documentation](https://www.swift.org/package-manager/)
- [SwiftLint Documentation](https://realm.github.io/SwiftLint/)
- [GitHub Actions for Swift](https://docs.github.com/en/actions/automating-builds-and-tests/building-and-testing-swift)

## 📋 Implementation Checklist

### Part 1: Compiler Configuration
- [ ] Read current `Package.swift` configuration
- [ ] Add `swiftSettings` with strict concurrency
- [ ] Add warnings-as-errors flag for release builds
- [ ] Test build with new settings (requires macOS)
- [ ] Document compiler flags and their purpose

### Part 2: Build Scripts
- [ ] Create `Scripts/` directory
- [ ] Write `build.sh` script
- [ ] Write `coverage.sh` script
- [ ] Make scripts executable (`chmod +x`)
- [ ] Test scripts locally (requires macOS)
- [ ] Add script usage to documentation

### Part 3: CI/CD Pipeline
- [ ] Research project's current CI setup
- [ ] Create GitHub Actions workflow file
- [ ] Configure workflow to run on FoundationUI changes
- [ ] Add SwiftLint step
- [ ] Add build and test steps
- [ ] Add coverage reporting step
- [ ] Test workflow (requires GitHub repository push)

### Part 4: Code Coverage
- [ ] Enable code coverage in Package.swift settings
- [ ] Set coverage threshold to 80%
- [ ] Generate initial coverage report
- [ ] Verify current coverage percentage
- [ ] Document how to view coverage locally
- [ ] Integrate coverage with CI reporting

### Part 5: Documentation
- [ ] Create BUILD.md with setup instructions
- [ ] Document required tools (Xcode, SwiftLint)
- [ ] Document build commands
- [ ] Document coverage commands
- [ ] Add troubleshooting section
- [ ] Update main README with build badge (optional)

### Part 6: Verification
- [ ] Run build script successfully
- [ ] Verify SwiftLint passes with strict mode
- [ ] Confirm test suite runs
- [ ] Verify coverage meets 80% threshold
- [ ] Test on clean macOS environment (if possible)
- [ ] Update Task Plan with completion marker

### Part 7: Finalization
- [ ] Commit all configuration files
- [ ] Update `next_tasks.md` with next priorities
- [ ] Archive this task document
- [ ] Create summary of work

## ⚠️ Platform Considerations

- **Linux**: Swift compiler available, but SwiftUI tests won't run
- **macOS**: Full toolchain required for testing and coverage
- **CI/CD**: Use macOS runners for complete validation

## 🎯 Expected Outcomes

After completing this task:

1. **Strict Quality Gates**: Code cannot be merged without passing SwiftLint and tests
2. **Automated Testing**: CI runs full test suite on every commit
3. **Coverage Visibility**: Team can see code coverage metrics
4. **Reproducible Builds**: Build scripts ensure consistent build process
5. **Documentation**: New developers can set up and build the project easily

## 📊 Quality Metrics

- SwiftLint violations: 0 (enforced)
- Test coverage: ≥80% (enforced)
- Build success rate: 100% (CI enforced)
- Documentation completeness: 100%

## 🔄 Next Tasks After Completion

With build configuration complete, Phase 1.1 will be 100% finished. According to the task plan:

- **Phase 1**: Move to remaining Phase 1 tasks (if any)
- **Phase 3**: Continue with Pattern implementations (7/16 tasks)
- **Phase 4**: Begin Agent Support & Polish work

Refer to `next_tasks.md` for specific next priorities.

---

**Created**: 2025-10-26
**Status**: Ready to implement
**Estimated Effort**: M-L (6-10 hours, mostly configuration and documentation)
