# Unit Test Infrastructure Setup

## 🎯 Objective

Configure and integrate comprehensive unit test infrastructure for FoundationUI, enabling test execution via Swift Package Manager and establishing foundation for code coverage analysis.

## 🧩 Context

- **Phase**: Phase 5.2 Testing & Quality Assurance
- **Layer**: Infrastructure (All Layers)
- **Priority**: P0 (Critical for release)
- **Dependencies**:
  - ✅ All FoundationUI components implemented (Phases 1-3 complete)
  - ✅ Test files exist (53 files in `FoundationUI/Tests/`)
  - ❌ Test target not configured in `Package.swift`

## ✅ Success Criteria

- [ ] FoundationUI testTarget added to `Package.swift`
- [ ] All 53 existing test files integrated and discoverable
- [ ] `swift test` command successfully runs FoundationUI tests
- [ ] Test data fixtures configured and accessible
- [ ] Test helpers and utilities properly imported
- [ ] XCTest framework configured for all test types
- [ ] Platform guards working correctly (`#if canImport(SwiftUI)`)
- [ ] Mock environment values available for testing
- [ ] Test execution completes without infrastructure errors
- [ ] Zero test configuration warnings or errors
- [ ] Tests can be run individually and as suite
- [ ] Test output properly formatted and readable

## 🔧 Implementation Notes

### Current State Analysis

**Existing Test Structure** (53 test files in `FoundationUI/Tests/`):
```
FoundationUITests/
├── AccessibilityTests/          # Accessibility compliance tests
├── ComponentsTests/             # Badge, Card, KeyValueRow, SectionHeader, Copyable
├── ContextsTests/               # SurfaceStyleKey, ColorSchemeAdapter, etc.
├── DesignTokensTests/           # DS token validation
├── IntegrationTests/            # Cross-component integration
├── ModifiersTests/              # BadgeChipStyle, CardStyle, etc.
├── PatternsTests/               # InspectorPattern, SidebarPattern, etc.
├── PatternsIntegrationTests/    # Pattern composition tests
├── PerformanceTests/            # Performance benchmarks
└── UtilitiesTests/              # CopyableText, KeyboardShortcuts, etc.

SnapshotTests/                   # Visual regression tests
├── BadgeSnapshotTests.swift
├── CardSnapshotTests.swift
├── KeyValueRowSnapshotTests.swift
└── SectionHeaderSnapshotTests.swift
```

**Problem**: No `testTarget` for FoundationUI in `Package.swift` (lines 82-113 only define ISOInspector* test targets)

### Files to Create/Modify

1. **Package.swift** (modify)
   - Add `.testTarget(name: "FoundationUITests", ...)` after line 81
   - Configure dependencies: `["FoundationUI"]`
   - Set path: `"FoundationUI/Tests/FoundationUITests"`
   - Add SnapshotTesting dependency if needed
   - Configure platform guards

2. **FoundationUI/Tests/FoundationUITests/** (verify structure)
   - Ensure all test files are in correct locations
   - Verify import statements (`import XCTest`, `import FoundationUI`)
   - Check platform guards (`#if canImport(SwiftUI)`)

3. **Test Helpers** (create if needed)
   - `FoundationUI/Tests/FoundationUITests/Helpers/TestHelpers.swift`
   - Mock environment values
   - Test data fixtures
   - Common assertions

### Package.swift Integration

Add this testTarget configuration:

```swift
.testTarget(
    name: "FoundationUITests",
    dependencies: [
        "FoundationUI",
        // Add SnapshotTesting if snapshot tests are active
        // .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
    ],
    path: "FoundationUI/Tests/FoundationUITests",
    exclude: [
        // Exclude any non-test files if needed
    ],
    resources: [
        // Add snapshot reference images if needed
        // .copy("__Snapshots__")
    ]
),
.testTarget(
    name: "FoundationUISnapshotTests",
    dependencies: [
        "FoundationUI",
        // .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
    ],
    path: "FoundationUI/Tests/SnapshotTests",
    resources: [
        // .copy("__Snapshots__")
    ]
)
```

### Test Execution Validation

After configuration, verify:

```bash
# List all tests
swift test --list-tests | grep FoundationUI

# Run all FoundationUI tests
swift test --filter FoundationUITests

# Run specific test file
swift test --filter BadgeTests

# Run with verbose output
swift test --verbose
```

### Platform-Specific Considerations

**macOS-only tests** (clipboard, keyboard shortcuts):
```swift
#if os(macOS)
// NSPasteboard tests
#endif
```

**iOS-only tests** (touch gestures, UIPasteboard):
```swift
#if os(iOS)
// UIPasteboard tests
#endif
```

**SwiftUI tests** (all platforms with SwiftUI):
```swift
#if canImport(SwiftUI)
import SwiftUI
// SwiftUI-dependent tests
#endif
```

## 🧠 Source References

- [FoundationUI Task Plan § Phase 5.2](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md#52-testing--quality-assurance)
- [FoundationUI Test Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TestPlan.md)
- [02_TDD_XP_Workflow.md](../../../DOCS/RULES/02_TDD_XP_Workflow.md)
- [Swift Package Manager Documentation](https://swift.org/package-manager/)
- [XCTest Documentation](https://developer.apple.com/documentation/xctest)

## 📋 Checklist

- [ ] Read current Package.swift configuration
- [ ] Analyze existing test file structure (53 files)
- [ ] Design testTarget configuration for FoundationUITests
- [ ] Design testTarget configuration for FoundationUISnapshotTests (if needed)
- [ ] Update Package.swift with test targets
- [ ] Verify test file import statements
- [ ] Add platform guards where needed
- [ ] Create test helpers if required
- [ ] Run `swift test --list-tests` to verify discovery
- [ ] Run `swift test --filter FoundationUITests` to verify execution
- [ ] Fix any test infrastructure errors
- [ ] Verify all 53 test files are discovered
- [ ] Run individual test suites to verify isolation
- [ ] Document test execution workflow
- [ ] Update Task Plan with ✅ completion mark
- [ ] Commit with message: "Configure FoundationUI unit test infrastructure"
- [ ] Archive task document to TASK_ARCHIVE/

## 🎯 Expected Outcome

After completion:
- ✅ All 53 FoundationUI test files integrated into SPM
- ✅ `swift test` discovers and runs FoundationUI tests
- ✅ Test infrastructure ready for coverage analysis (next task)
- ✅ Foundation established for snapshot tests, accessibility tests, performance tests
- ✅ Zero test configuration errors
- ✅ Tests executable on macOS (primary platform for development)

## 📊 Related Tasks

**Blocked by this task**:
- Phase 5.2 → Comprehensive unit test coverage (≥80%)
- Phase 5.2 → Snapshot testing setup
- Phase 5.2 → Accessibility audit
- Phase 5.2 → Performance profiling with Instruments

**Next steps after completion**:
1. Run code coverage analysis (`swift test --enable-code-coverage`)
2. Identify untested code paths
3. Write missing unit tests for gaps
4. Set up CI integration for test automation

---

**Status**: 🚧 IN PROGRESS
**Created**: 2025-11-05
**Estimated Effort**: 2-4 hours
**Actual Effort**: TBD
