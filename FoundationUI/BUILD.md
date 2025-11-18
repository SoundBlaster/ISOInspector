# FoundationUI Build & Development Guide

This guide covers how to build, test, and develop FoundationUI, including setting up your environment, running tests, and understanding the build pipeline.

---

## Quick Start

```bash
# Clone and navigate to FoundationUI
cd FoundationUI

# Build the package
swift build

# Run tests
swift test

# Run full validation (build + test + lint + coverage)
./Scripts/build.sh
```

---

## Prerequisites

### Required Tools

| Tool | Minimum Version | Purpose |
|------|----------------|---------|
| **Swift** | 6.0+ | Compiler and Package Manager |
| **Xcode** | 15.0+ | macOS development and testing |
| **SwiftLint** | Latest | Code quality enforcement |

### Platform Requirements

- **macOS**: 14.0+ (Sonoma) for macOS target testing
- **iOS**: 17.0+ for iOS target testing
- **iPadOS**: 17.0+ for iPad target testing

### Installing Tools

#### Swift & Xcode
Download from [Apple Developer](https://developer.apple.com/xcode/) or via Mac App Store.

#### SwiftLint
```bash
# Using Homebrew
brew install swiftlint

# Or download from GitHub
# https://github.com/realm/SwiftLint/releases
```

Verify installation:
```bash
swift --version    # Should show 6.0+
swiftlint version  # Should show latest version
```

---

## Dependencies

FoundationUI uses Swift Package Manager (SPM) for dependency management. The following external packages are required:

### External Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| **[Yams](https://github.com/jpsim/Yams)** | ≥5.0.0 | YAML parsing for component schemas and agent configuration |
| **[NavigationSplitViewKit](https://github.com/SoundBlaster/NavigationSplitView)** | ≥1.0.0 | Production-ready NavigationSplitView with state management and adaptive behaviors |

### Dependency Resolution

Dependencies are automatically resolved by SPM:

```bash
# Resolve dependencies
cd FoundationUI
swift package resolve

# Update dependencies to latest compatible versions
swift package update

# Show dependency tree
swift package show-dependencies
```

All dependencies are cached by SPM in `.build` directory and tracked in `Package.resolved` lockfile.

---

## Project Structure

```bash
FoundationUI/
├── Package.swift                    # SPM configuration
├── Sources/
│   └── FoundationUI/
│       ├── DesignTokens/           # Layer 0: DS tokens
│       ├── Modifiers/              # Layer 1: View modifiers
│       ├── Components/             # Layer 2: UI components
│       ├── Patterns/               # Layer 3: UI patterns
│       ├── Contexts/               # Layer 4: Environment & adaptation
│       └── Utilities/              # Helper utilities
├── Tests/
│   └── FoundationUITests/          # Unit, snapshot, and integration tests
├── Scripts/
│   ├── build.sh                    # Main build and validation script
│   └── coverage.sh                 # Code coverage report generator
└── Documentation/                   # DocC documentation (future)
```

---

## Building FoundationUI

### Standard Build

```bash
# Build debug configuration
swift build

# Build release configuration
swift build -c release
```

### Build Targets

- **FoundationUI**: Main library target
- **FoundationUITests**: Test target

### Compiler Settings

FoundationUI uses strict compiler settings for code quality:

- **Strict Concurrency Checking**: Enabled by default in Swift 6.0+
- **Warnings as Errors**: Enabled in release builds
- **Swift Tools Version**: 6.0

These settings are configured in `Package.swift`:

```swift
swiftSettings: [
    .unsafeFlags(["-warnings-as-errors"], .when(configuration: .release))
]
```

**Note**: Swift 6.0 enables strict concurrency checking by default, so no explicit feature flag is needed.

---

## Testing

### Running Tests

```bash
# Run all tests
swift test

# Run tests with code coverage
swift test --enable-code-coverage

# Run specific test
swift test --filter FoundationUITests.BadgeTests

# Run tests in parallel
swift test --parallel
```

### Test Categories

| Test Type | Location | Purpose |
|-----------|----------|---------|
| **Unit Tests** | `Tests/FoundationUITests/` | Component logic and API |
| **Snapshot Tests** | `Tests/FoundationUITests/SnapshotTests/` | Visual regression |
| **Accessibility Tests** | `Tests/FoundationUITests/AccessibilityTests/` | VoiceOver, contrast, Dynamic Type |
| **Performance Tests** | `Tests/FoundationUITests/PerformanceTests/` | Memory, render time |
| **Integration Tests** | `Tests/FoundationUITests/IntegrationTests/` | Component composition |

### Test Coverage

FoundationUI maintains **≥80% code coverage** as a quality gate.

#### Generate Coverage Report

```bash
# macOS only - generates detailed HTML report
./Scripts/coverage.sh
```

This will create:
- **Text report**: Console output
- **HTML report**: `coverage_report/index.html`
- **LCOV export**: `coverage.lcov` (for CI tools)

#### View Coverage

```bash
# Open HTML report in browser
open coverage_report/index.html
```

---

## Code Quality

### SwiftLint

FoundationUI enforces zero SwiftLint violations via `.swiftlint.yml`.

#### Run SwiftLint

```bash
# Check for violations
swiftlint

# Check with strict mode (warnings as errors)
swiftlint --strict

# Auto-fix violations (where possible)
swiftlint --fix
```

#### Key Rules

- **No Magic Numbers**: All numeric values must use DS tokens
- **Strict Naming**: Swift API Design Guidelines enforced
- **File Length**: Max 400 lines per file (encourages one entity per file)
- **Complexity**: Max cyclomatic complexity of 10
- **Documentation**: Public APIs require DocC comments

Configuration: `FoundationUI/.swiftlint.yml`

---

## Automated Build Pipeline

### Using the Build Script

The `Scripts/build.sh` script runs the complete validation pipeline:

```bash
./Scripts/build.sh
```

This script performs:
1. **Build**: Compile FoundationUI package
2. **Test**: Run full test suite with coverage
3. **Lint**: Verify SwiftLint compliance (0 violations)
4. **Coverage**: Generate coverage report (macOS only)

#### Exit Codes

- `0`: All checks passed
- `1`: Build, test, or lint failure

---

## CI/CD Integration

### GitHub Actions Workflow

FoundationUI includes a GitHub Actions workflow for continuous integration.

**File**: `.github/workflows/foundationui.yml`

#### Workflow Triggers

- Push to `main` or `develop` branches
- Pull requests targeting `main` or `develop`
- Changes to `FoundationUI/**` paths

#### Workflow Steps

1. Checkout code
2. Select Xcode 15.0+
3. Run SwiftLint with strict mode
4. Build FoundationUI package
5. Run tests with code coverage
6. Generate coverage report
7. Upload coverage to Codecov

#### Running Locally

Simulate the CI environment:

```bash
# Equivalent to CI pipeline
./Scripts/build.sh
```

---

## Development Workflow

### Adding a New Component

Following TDD (Test-Driven Development) principles:

#### 1. Write Tests First

```swift
// Tests/FoundationUITests/ComponentsTests/MyComponentTests.swift
import XCTest
@testable import FoundationUI

final class MyComponentTests: XCTestCase {
    func testMyComponentInitialization() {
        let component = MyComponent(title: "Test")
        XCTAssertEqual(component.title, "Test")
    }
}
```

#### 2. Run Tests (should fail)

```bash
swift test --filter MyComponentTests
# Expected: ❌ Test failure (MyComponent doesn't exist yet)
```

#### 3. Implement Component

```swift
// Sources/FoundationUI/Components/MyComponent.swift
import SwiftUI

/// A custom component for displaying...
///
/// Example usage:
/// ```swift
/// MyComponent(title: "Hello")
/// ```
public struct MyComponent: View {
    public let title: String

    public init(title: String) {
        self.title = title
    }

    public var body: some View {
        Text(title)
            .padding(DS.Spacing.m)
            .background(DS.Colors.accent)
            .cornerRadius(DS.Radius.medium)
    }
}

#Preview {
    MyComponent(title: "Preview")
}
```

#### 4. Run Tests (should pass)

```bash
swift test --filter MyComponentTests
# Expected: ✅ All tests pass
```

#### 5. Verify SwiftLint

```bash
swiftlint --strict
# Expected: 0 violations
```

#### 6. Run Full Validation

```bash
./Scripts/build.sh
# Expected: ✅ All checks passed
```

### Design System Compliance

**All values MUST use DS (Design System) tokens. Never use magic numbers.**

#### ✅ Correct

```swift
.padding(DS.Spacing.m)
.background(DS.Colors.infoBG)
.cornerRadius(DS.Radius.chip)
.font(DS.Typography.body)
```

#### ❌ Incorrect

```swift
.padding(12)              // Magic number!
.background(Color.blue)   // Not semantic!
.cornerRadius(8)          // Magic number!
.font(.body)              // Not using DS token!
```

SwiftLint will catch magic numbers and fail the build.

---

## Troubleshooting

### Common Issues

#### Build Fails with "Cannot find 'DS' in scope"

**Cause**: Missing import or Design Tokens not built.

**Solution**:
```bash
# Clean build directory and rebuild
rm -rf .build
swift build
```

#### Tests Fail on Linux

**Cause**: SwiftUI tests require macOS/Xcode.

**Solution**: Run tests on macOS with Xcode:
```bash
# macOS only
swift test
```

#### SwiftLint Not Found

**Cause**: SwiftLint not installed.

**Solution**:
```bash
brew install swiftlint
```

#### Code Coverage Not Generated

**Cause**: Coverage requires macOS and `llvm-cov`.

**Solution**: Run on macOS:
```bash
swift test --enable-code-coverage
./Scripts/coverage.sh
```

#### Strict Concurrency Warnings

**Cause**: Swift 6.0 strict concurrency checking.

**Solution**: Ensure all public APIs are `Sendable` and marked with `@MainActor` where needed.

---

## Build Performance

### Benchmarks

| Metric | Target | Current |
|--------|--------|---------|
| Clean build time | <10s | ~5s |
| Incremental build | <2s | ~1s |
| Test execution | <30s | ~15s |
| SwiftLint check | <5s | ~2s |

### Optimization Tips

1. **Use incremental builds**: `swift build` after changes
2. **Filter tests**: `swift test --filter SpecificTest`
3. **Parallel testing**: `swift test --parallel`
4. **Cache dependencies**: SPM caches resolved dependencies

---

## Environment Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `SWIFT_EXEC` | Override Swift toolchain | `/path/to/swift` |
| `SWIFTLINT_DISABLE` | Disable SwiftLint | `1` |

---

## Additional Resources

- [Swift Package Manager Documentation](https://www.swift.org/package-manager/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [SwiftLint Rules Reference](https://realm.github.io/SwiftLint/rule-directory.html)
- [FoundationUI PRD](../DOCS/AI/ISOViewer/FoundationUI_PRD.md)
- [FoundationUI Task Plan](../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md)

---

## Getting Help

If you encounter issues not covered here:

1. Check [FoundationUI Task Plan](../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md) for known issues
2. Review [TDD Workflow Rules](../DOCS/RULES/02_TDD_XP_Workflow.md)
3. Check SwiftLint configuration in `.swiftlint.yml`

---

**Last Updated**: 2025-10-26
**Maintainer**: ISO Inspector Team
