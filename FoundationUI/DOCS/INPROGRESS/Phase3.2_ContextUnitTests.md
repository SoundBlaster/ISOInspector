# Phase 3.2: Context Unit Tests

## 🎯 Objective

Create comprehensive unit tests for all Context layer components to ensure reliability, maintainability, and production-quality code for Layer 4 (Contexts).

## 🧩 Context

- **Phase**: Phase 3.2 - Contexts & Platform Adaptation
- **Layer**: Layer 4 - Contexts
- **Priority**: P0 (Critical - Required for quality)
- **Dependencies**: All Phase 3.2 Context implementations ✅
  - SurfaceStyleKey ✅
  - PlatformAdaptation ✅
  - ColorSchemeAdapter ✅
  - PlatformExtensions ✅

## 📊 Current Test Coverage Status

### Existing Tests (94 tests, 2049 lines)

- ✅ `PlatformAdaptationTests.swift` (25 unit tests)
- ✅ `PlatformExtensionsTests.swift` (22 unit tests)
- ✅ `ContextIntegrationTests.swift` (19 integration tests)
- ✅ `PlatformAdaptationIntegrationTests.swift` (28 integration tests)

### Missing Unit Tests (TO BE CREATED)

- ❌ `SurfaceStyleKeyTests.swift` - Dedicated unit tests for SurfaceStyleKey
- ❌ `ColorSchemeAdapterTests.swift` - Dedicated unit tests for ColorSchemeAdapter

## ✅ Success Criteria

### Test Coverage Requirements

- [ ] SurfaceStyleKey unit tests written (≥12 test cases)
- [ ] ColorSchemeAdapter unit tests written (≥20 test cases)
- [ ] All public APIs tested (100% coverage)
- [ ] Edge cases covered (nil values, unknown variants)
- [ ] Platform-specific behavior validated
- [ ] Environment key propagation tested
- [ ] Color scheme detection tested (light/dark mode)
- [ ] All tests pass with `swift test`
- [ ] SwiftLint reports 0 violations
- [ ] Test execution time <30s for full suite
- [ ] Overall test coverage ≥80% for Context layer

### Code Quality

- [ ] Zero magic numbers (100% DS token usage)
- [ ] 100% DocC documentation for all test cases
- [ ] Descriptive test names following convention `test{Component}_{Scenario}_{ExpectedResult}`
- [ ] Test helpers extracted for reusability
- [ ] Parameterized tests for variants (where applicable)

## 🔧 Implementation Plan

### Step 1: Create SurfaceStyleKeyTests.swift

**File**: `Tests/FoundationUITests/ContextsTests/SurfaceStyleKeyTests.swift`

**Test Categories** (≥12 tests):

1. **Default Value Tests** (2 tests)
   - Test default `.regular` material
   - Test EnvironmentValues default behavior

2. **Environment Propagation Tests** (3 tests)
   - Test parent-to-child propagation
   - Test nested view hierarchies
   - Test override behavior

3. **Material Type Tests** (5 tests)
   - Test all material types (thin, regular, thick, ultraThin, ultraThick)
   - Test material equality
   - Test invalid/edge cases

4. **Integration Tests** (2 tests)
   - Test with SurfaceStyle modifier
   - Test with actual SwiftUI components

**Example Test Structure**:

```swift
import XCTest
@testable import FoundationUI
#if canImport(SwiftUI)
import SwiftUI

final class SurfaceStyleKeyTests: XCTestCase {

    // MARK: - Default Value Tests

    func testSurfaceStyleKey_DefaultValue_IsRegular() {
        // Test that default value is .regular
    }

    func testEnvironmentValues_DefaultSurfaceStyle_IsRegular() {
        // Test EnvironmentValues default
    }

    // MARK: - Environment Propagation Tests

    func testSurfaceStyle_PropagatesFromParentToChild() {
        // Test propagation through view hierarchy
    }

    // ... (more tests)
}
#endif
```

### Step 2: Create ColorSchemeAdapterTests.swift

**File**: `Tests/FoundationUITests/ContextsTests/ColorSchemeAdapterTests.swift`

**Test Categories** (≥20 tests):

1. **Initialization Tests** (2 tests)
   - Test light mode initialization
   - Test dark mode initialization

2. **Color Scheme Detection Tests** (3 tests)
   - Test `isDarkMode` property (light)
   - Test `isDarkMode` property (dark)
   - Test color scheme changes

3. **Adaptive Color Tests** (7 tests)
   - Test `background` color (light/dark)
   - Test `text` color (light/dark)
   - Test `secondaryText` color (light/dark)
   - Test `border` color (light/dark)
   - Test `divider` color (light/dark)
   - Test `elevatedSurface` color (light/dark)
   - Test all colors return non-nil values

4. **Platform-Specific Tests** (4 tests)
   - Test macOS NSColor handling
   - Test iOS UIColor handling
   - Test cross-platform consistency
   - Test system color adaptation

5. **View Modifier Tests** (2 tests)
   - Test `.adaptiveColorScheme()` modifier
   - Test modifier with real views

6. **Edge Case Tests** (2 tests)
   - Test invalid color schemes
   - Test rapid scheme changes

**Example Test Structure**:

```swift
import XCTest
@testable import FoundationUI
#if canImport(SwiftUI)
import SwiftUI

final class ColorSchemeAdapterTests: XCTestCase {

    // MARK: - Initialization Tests

    func testColorSchemeAdapter_InitWithLightMode_ReturnsCorrectScheme() {
        // Test light mode initialization
    }

    func testColorSchemeAdapter_InitWithDarkMode_ReturnsCorrectScheme() {
        // Test dark mode initialization
    }

    // MARK: - Color Scheme Detection Tests

    func testColorSchemeAdapter_IsDarkMode_LightScheme_ReturnsFalse() {
        // Test isDarkMode returns false for light
    }

    func testColorSchemeAdapter_IsDarkMode_DarkScheme_ReturnsTrue() {
        // Test isDarkMode returns true for dark
    }

    // MARK: - Adaptive Color Tests

    func testColorSchemeAdapter_BackgroundColor_LightMode_ReturnsCorrectColor() {
        // Test background in light mode
    }

    func testColorSchemeAdapter_BackgroundColor_DarkMode_ReturnsCorrectColor() {
        // Test background in dark mode
    }

    // ... (more tests)
}
#endif
```

### Step 3: Enhance Existing Test Coverage

**Files to Review and Enhance**:

- `ContextIntegrationTests.swift` - Ensure comprehensive cross-context integration
- `PlatformAdaptationTests.swift` - Verify 100% API coverage
- `PlatformExtensionsTests.swift` - Verify 100% API coverage

**Actions**:

1. Review existing tests for gaps
2. Add missing edge case tests
3. Ensure all public APIs tested
4. Add parameterized tests for variants

### Step 4: Create Test Helpers (if needed)

**File**: `Tests/FoundationUITests/TestHelpers/ContextTestHelpers.swift` (create if needed)

**Utilities**:

- Environment value injection helpers
- Color comparison utilities
- Platform detection mocks
- SwiftUI view testing utilities

### Step 5: Run Full Test Suite and Measure Coverage

```bash
# Run tests
swift test

# Generate coverage report (if using Xcode)
xcodebuild test -scheme FoundationUI -enableCodeCoverage YES

# Verify SwiftLint
swiftlint --strict
```

**Coverage Targets**:

- Overall Context layer coverage: ≥80%
- SurfaceStyleKey coverage: ≥90%
- ColorSchemeAdapter coverage: ≥85%
- PlatformAdaptation coverage: ≥85%
- PlatformExtensions coverage: ≥85%

## 🧠 Design Token Usage

All tests must use DS tokens exclusively:

- **No magic numbers** in test assertions
- Use `DS.Spacing.*` for layout validation
- Use `DS.Animation.*` for timing validation
- Use `DS.Colors.*` for color comparisons
- Use `DS.Radius.*` for corner radius validation

## 🔗 Source References

### FoundationUI Documents

- [FoundationUI Task Plan § Phase 3.2](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md#phase-3-patterns--platform-adaptation-week-5-6)
- [FoundationUI PRD](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md)
- [FoundationUI Test Plan](../../../DOCS/AI/ISOViewer/FoundationUI_TestPlan.md)

### Implementation Files to Test

- `Sources/FoundationUI/Contexts/SurfaceStyleKey.swift` (318 lines)
- `Sources/FoundationUI/Contexts/ColorSchemeAdapter.swift` (525 lines)
- `Sources/FoundationUI/Contexts/PlatformAdaptation.swift` (411 lines)
- `Sources/FoundationUI/Contexts/PlatformExtensions.swift` (551 lines)

### Existing Test Files

- `Tests/FoundationUITests/ContextsTests/ContextIntegrationTests.swift` (19 tests)
- `Tests/FoundationUITests/ContextsTests/PlatformAdaptationIntegrationTests.swift` (28 tests)
- `Tests/FoundationUITests/ContextsTests/PlatformAdaptationTests.swift` (25 tests)
- `Tests/FoundationUITests/ContextsTests/PlatformExtensionsTests.swift` (22 tests)

### Apple Documentation

- [XCTest Framework](https://developer.apple.com/documentation/xctest)
- [SwiftUI Testing](https://developer.apple.com/documentation/swiftui/testing)
- [Environment Values](https://developer.apple.com/documentation/swiftui/environmentvalues)

## 📋 Execution Checklist

### Phase 1: SurfaceStyleKey Tests

- [ ] Create `SurfaceStyleKeyTests.swift` file
- [ ] Write default value tests (2 tests)
- [ ] Write environment propagation tests (3 tests)
- [ ] Write material type tests (5 tests)
- [ ] Write integration tests (2 tests)
- [ ] Run `swift test` to confirm all tests pass
- [ ] Verify SwiftLint compliance (0 violations)

### Phase 2: ColorSchemeAdapter Tests

- [ ] Create `ColorSchemeAdapterTests.swift` file
- [ ] Write initialization tests (2 tests)
- [ ] Write color scheme detection tests (3 tests)
- [ ] Write adaptive color tests (7 tests)
- [ ] Write platform-specific tests (4 tests)
- [ ] Write view modifier tests (2 tests)
- [ ] Write edge case tests (2 tests)
- [ ] Run `swift test` to confirm all tests pass
- [ ] Verify SwiftLint compliance (0 violations)

### Phase 3: Test Enhancement & Coverage

- [ ] Review existing test files for gaps
- [ ] Add missing edge case tests
- [ ] Create test helpers (if needed)
- [ ] Run full test suite (`swift test`)
- [ ] Generate coverage report (target: ≥80%)
- [ ] Verify test execution time (<30s)

### Phase 4: Documentation & Quality

- [ ] Add DocC documentation to all test cases
- [ ] Update Task Plan with completion status
- [ ] Create task archive document
- [ ] Move task to `TASK_ARCHIVE/` folder
- [ ] Update `next_tasks.md` with next priority

### Phase 5: Final Validation

- [ ] All tests pass (`swift test`)
- [ ] SwiftLint reports 0 violations
- [ ] Test coverage ≥80% for Context layer
- [ ] All success criteria met
- [ ] Ready for code review

## 📈 Expected Outcomes

### New Test Files Created

1. `Tests/FoundationUITests/ContextsTests/SurfaceStyleKeyTests.swift` (≥12 tests, ~300 lines)
2. `Tests/FoundationUITests/ContextsTests/ColorSchemeAdapterTests.swift` (≥20 tests, ~500 lines)

### Test Coverage Increase

- **Before**: 94 tests, 2049 lines
- **After**: ≥126 tests, ≥2850 lines
- **Coverage**: ≥80% for Context layer

### Quality Metrics

- ✅ 100% public API coverage
- ✅ Zero magic numbers
- ✅ 100% DocC documentation
- ✅ SwiftLint compliance (0 violations)
- ✅ Test execution time <30s

## 🚧 Known Challenges & Mitigations

### Challenge 1: SwiftUI Testing Limitations

**Issue**: SwiftUI views difficult to test directly in unit tests
**Mitigation**: Focus on testing underlying logic, use integration tests for view validation

### Challenge 2: Platform-Specific Conditional Compilation

**Issue**: `#if os(macOS)` / `#if os(iOS)` code paths difficult to test simultaneously
**Mitigation**: Test on both platforms in CI, use conditional test expectations

### Challenge 3: ColorScheme Environment Testing

**Issue**: ColorScheme is environment-driven, hard to inject in tests
**Mitigation**: Use `.environment(\.colorScheme, .dark)` in test views

### Challenge 4: Runtime iPad Detection

**Issue**: `UIDevice.current.userInterfaceIdiom` requires iOS runtime
**Mitigation**: Test on simulator, document platform-specific behavior

## 🎯 Success Definition

This task is **COMPLETE** when:

1. ✅ All 2 new test files created (SurfaceStyleKeyTests, ColorSchemeAdapterTests)
2. ✅ All tests pass (`swift test`)
3. ✅ SwiftLint reports 0 violations
4. ✅ Test coverage ≥80% for Context layer
5. ✅ All success criteria checklist items marked [x]
6. ✅ Task document archived with completion report
7. ✅ Task Plan updated with [x] completion mark
8. ✅ Ready for Phase 3 completion review

---

**Estimated Effort**: 6-8 hours (Medium task)
**Assigned**: TBD
**Status**: 🚧 IN PROGRESS
**Started**: 2025-10-27
**Target Completion**: TBD

---

## 📝 Progress Notes

### 2025-10-27: Task Created

- Task document created following SELECT_NEXT.md guidelines
- All dependencies verified (4 Context implementations complete)
- Prerequisites validated (test infrastructure, build system, SwiftLint)
- Ready to begin implementation

---

*Last Updated: 2025-10-27*
