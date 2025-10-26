# SwiftUI Testing Guidelines

## Mission Statement

SwiftUI views are value types, not reference types. This fundamental difference requires a different testing approach than UIKit/AppKit. Tests must verify **observable properties and behavior**, not just view construction.

---

## Core Principle: No No-Op Assertions

### ❌ Anti-Pattern: Testing View Construction

```swift
// ❌ BAD: This test always passes
func testMyView() {
    let view = MyView()
    XCTAssertNotNil(view, "View should be created")
}
```

**Why this fails:**
- SwiftUI views are value types (structs)
- Value types **cannot be nil** in Swift
- `XCTAssertNotNil(view)` always passes, even if the view is completely broken
- This provides **false coverage** - tests pass but detect no bugs

### ✅ Pattern: Testing Observable Properties

```swift
// ✅ GOOD: Test actual behavior
func testViewModel_InitialState() {
    let viewModel = MyViewModel()
    XCTAssertEqual(viewModel.count, 0, "Initial count should be 0")
    XCTAssertFalse(viewModel.isLoading, "Should not be loading initially")
}

// ✅ GOOD: Test state transitions
func testViewModel_Increment() {
    let viewModel = MyViewModel()
    viewModel.increment()
    XCTAssertEqual(viewModel.count, 1, "Count should increment to 1")
}

// ✅ GOOD: Test environment values
func testEnvironmentKey_DefaultValue() {
    let defaultValue = MyEnvironmentKey.defaultValue
    XCTAssertEqual(defaultValue, .expected)
}
```

---

## What to Test in SwiftUI

### 1. Environment Keys

**Test:** Default values, storage, retrieval

```swift
// ✅ Test default value
func testSurfaceStyleKey_DefaultValue() {
    XCTAssertEqual(SurfaceStyleKey.defaultValue, .regular,
                  "Default should be .regular")
}

// ✅ Test EnvironmentValues integration
func testEnvironmentValues_SurfaceStyle() {
    var env = EnvironmentValues()
    env.surfaceStyle = .thick
    XCTAssertEqual(env.surfaceStyle, .thick,
                  "Environment should preserve surface style")
}

// ❌ Don't test view construction
func testEnvironmentKey_BAD() {
    struct TestView: View {
        @Environment(\.surfaceStyle) var surfaceStyle
        var body: some View { Text("Test") }
    }
    let view = TestView()
    XCTAssertNotNil(view) // ❌ Always passes
}
```

### 2. ViewModels / ObservableObjects

**Test:** State, computed properties, actions, side effects

```swift
final class MyViewModel: ObservableObject {
    @Published var count: Int = 0
    @Published var isLoading: Bool = false

    var isEven: Bool { count % 2 == 0 }

    func increment() {
        count += 1
    }
}

// ✅ Test initial state
func testViewModel_InitialState() {
    let vm = MyViewModel()
    XCTAssertEqual(vm.count, 0)
    XCTAssertFalse(vm.isLoading)
    XCTAssertTrue(vm.isEven)
}

// ✅ Test computed properties
func testViewModel_IsEven() {
    let vm = MyViewModel()
    XCTAssertTrue(vm.isEven, "0 should be even")

    vm.increment()
    XCTAssertFalse(vm.isEven, "1 should be odd")

    vm.increment()
    XCTAssertTrue(vm.isEven, "2 should be even")
}

// ✅ Test actions
func testViewModel_Increment() {
    let vm = MyViewModel()
    vm.increment()
    XCTAssertEqual(vm.count, 1)
}
```

### 3. Platform Adapters / Utility Types

**Test:** Platform detection, value calculations, type conversions

```swift
// ✅ Test platform detection
func testPlatformAdapter_Detection() {
    #if os(macOS)
    XCTAssertTrue(PlatformAdapter.isMacOS)
    XCTAssertFalse(PlatformAdapter.isIOS)
    #elseif os(iOS)
    XCTAssertTrue(PlatformAdapter.isIOS)
    XCTAssertFalse(PlatformAdapter.isMacOS)
    #endif
}

// ✅ Test value calculations
func testPlatformAdapter_Spacing() {
    let spacing = PlatformAdapter.defaultSpacing

    #if os(macOS)
    XCTAssertEqual(spacing, 12.0, "macOS should use 12pt")
    #elseif os(iOS)
    XCTAssertEqual(spacing, 16.0, "iOS should use 16pt")
    #endif
}

// ✅ Test size class adaptation
func testPlatformAdapter_SizeClass() {
    let compact = PlatformAdapter.spacing(for: .compact)
    let regular = PlatformAdapter.spacing(for: .regular)

    XCTAssertEqual(compact, 12.0)
    XCTAssertEqual(regular, 16.0)
    XCTAssertLessThan(compact, regular)
}
```

### 4. Color Scheme Adapters

**Test:** Mode detection, color values, contrast

```swift
// ✅ Test mode detection
func testColorSchemeAdapter_DarkModeDetection() {
    let dark = ColorSchemeAdapter(colorScheme: .dark)
    let light = ColorSchemeAdapter(colorScheme: .light)

    XCTAssertTrue(dark.isDarkMode)
    XCTAssertFalse(light.isDarkMode)
}

// ✅ Test color differences
func testColorSchemeAdapter_ColorsVary() {
    let dark = ColorSchemeAdapter(colorScheme: .dark)
    let light = ColorSchemeAdapter(colorScheme: .light)

    XCTAssertNotEqual(dark.adaptiveTextColor,
                     light.adaptiveTextColor,
                     "Text colors should differ between modes")
}

// ✅ Test all color properties accessible
func testColorSchemeAdapter_AllColorsAccessible() {
    let adapter = ColorSchemeAdapter(colorScheme: .light)

    // Verify all properties can be accessed without crashes
    _ = adapter.adaptiveBackground
    _ = adapter.adaptiveTextColor
    _ = adapter.adaptiveBorderColor

    XCTAssertTrue(true, "All colors should be accessible")
}
```

### 5. Enums and Value Types

**Test:** Equality, descriptions, all cases, properties

```swift
enum SurfaceMaterial: Equatable {
    case thin, regular, thick, ultra

    var description: String { /* ... */ }
    var accessibilityLabel: String { /* ... */ }
}

// ✅ Test Equatable conformance
func testSurfaceMaterial_Equatable() {
    XCTAssertEqual(SurfaceMaterial.thin, .thin)
    XCTAssertNotEqual(SurfaceMaterial.thin, .thick)
}

// ✅ Test all cases
func testSurfaceMaterial_AllCases() {
    let materials: [SurfaceMaterial] = [.thin, .regular, .thick, .ultra]

    for material in materials {
        XCTAssertFalse(material.description.isEmpty,
                      "\(material) should have description")
        XCTAssertFalse(material.accessibilityLabel.isEmpty,
                      "\(material) should have accessibility label")
    }
}
```

---

## Testing Strategies by Component Type

### Environment Keys

**What to test:**
- ✅ Default value correctness
- ✅ EnvironmentValues get/set operations
- ✅ Value preservation through environment hierarchy
- ✅ Type safety (correct types stored/retrieved)

**What NOT to test:**
- ❌ View construction with environment modifiers
- ❌ SwiftUI's internal environment propagation mechanism

### ViewModifiers

**What to test:**
- ✅ Modifier can be applied to views (type checking)
- ✅ Underlying logic (if modifier wraps a function)
- ✅ State changes triggered by modifier

**What NOT to test:**
- ❌ SwiftUI's modifier composition system
- ❌ View rendering (unless using snapshot testing)

### ObservableObjects / ViewModels

**What to test:**
- ✅ Initial state correctness
- ✅ State transitions from actions
- ✅ Computed property calculations
- ✅ Side effects (network calls, etc.) with mocks
- ✅ Published property changes

**What NOT to test:**
- ❌ SwiftUI's @Published observation mechanism
- ❌ View updates (that's SwiftUI's responsibility)

---

## Anti-Patterns to Avoid

### ❌ Anti-Pattern 1: No-Op View Construction Tests

```swift
// ❌ BAD: Always passes
func testCardView() {
    let card = Card {
        Text("Content")
    }
    XCTAssertNotNil(card)
}
```

**Why it's bad:** SwiftUI views are structs, never nil. Test provides zero value.

**Fix:** Test the card's underlying properties or data model:

```swift
// ✅ GOOD: Test actual state
func testCardViewModel_InitialState() {
    let viewModel = CardViewModel()
    XCTAssertEqual(viewModel.elevation, .medium)
    XCTAssertTrue(viewModel.useMaterial)
}
```

### ❌ Anti-Pattern 2: Testing SwiftUI Framework Behavior

```swift
// ❌ BAD: Testing SwiftUI's environment propagation
func testEnvironmentPropagation() {
    struct Parent: View {
        var body: some View {
            Child().environment(\.surfaceStyle, .thick)
        }
    }
    // Trying to verify Child receives .thick from Parent
}
```

**Why it's bad:** You're testing Apple's SwiftUI framework, not your code.

**Fix:** Test your environment key implementation:

```swift
// ✅ GOOD: Test your environment key
func testSurfaceStyleKey_Storage() {
    var env = EnvironmentValues()
    env.surfaceStyle = .thick
    XCTAssertEqual(env.surfaceStyle, .thick)
}
```

### ❌ Anti-Pattern 3: Testing View Rendering

```swift
// ❌ BAD: Trying to test rendering without tools
func testCardView_Renders() {
    let card = Card { Text("Test") }
    // How do we verify it renders correctly? We can't!
}
```

**Why it's bad:** Unit tests don't have rendering context.

**Fix:** Either:
1. Use snapshot testing (SwiftUI-Snapshot-Testing, SnapshotTesting)
2. Test the underlying data/state that drives rendering

```swift
// ✅ GOOD: Test the state that affects rendering
func testCardState_ElevationAffectsAppearance() {
    let lowCard = Card(elevation: .low)
    let highCard = Card(elevation: .high)

    XCTAssertLessThan(lowCard.shadowRadius,
                     highCard.shadowRadius,
                     "Higher elevation should have larger shadow")
}
```

---

## Integration Testing

### Testing Multiple Contexts Together

When testing integration of multiple systems (e.g., Environment + Platform + ColorScheme):

```swift
// ✅ Test contexts provide independent values
func testAllContexts_Independent() {
    // Surface style context
    let surfaceStyle = SurfaceStyleKey.defaultValue
    XCTAssertEqual(surfaceStyle, .regular)

    // Platform context
    let spacing = PlatformAdapter.defaultSpacing
    XCTAssertGreaterThan(spacing, 0)

    // Color scheme context
    let light = ColorSchemeAdapter(colorScheme: .light)
    let dark = ColorSchemeAdapter(colorScheme: .dark)
    XCTAssertNotEqual(light.adaptiveTextColor, dark.adaptiveTextColor)

    // All three should work simultaneously
    XCTAssertTrue(surfaceStyle == .regular)
    XCTAssertTrue(spacing > 0)
}

// ✅ Test type safety
func testContexts_TypeSafety() {
    let material: SurfaceMaterial = .regular
    let spacing: CGFloat = PlatformAdapter.defaultSpacing
    let scheme: ColorScheme = .light

    // Verify types are distinct
    XCTAssertTrue(type(of: material) == SurfaceMaterial.self)
    XCTAssertTrue(type(of: spacing) == CGFloat.self)
    XCTAssertTrue(type(of: scheme) == ColorScheme.self)
}
```

---

## Design System Token Validation

Always verify "zero magic numbers" requirement:

```swift
// ✅ Test all values use design tokens
func testSpacing_NoMagicNumbers() {
    let validTokens: Set<CGFloat> = [
        DS.Spacing.s,   // 8pt
        DS.Spacing.m,   // 12pt
        DS.Spacing.l,   // 16pt
        DS.Spacing.xl   // 24pt
    ]

    let spacing = PlatformAdapter.defaultSpacing
    XCTAssertTrue(validTokens.contains(spacing),
                 "Spacing must be a DS token, got \(spacing)")
}

// ✅ Test value ranges
func testSpacing_ReasonableRange() {
    let spacing = PlatformAdapter.defaultSpacing

    XCTAssertGreaterThan(spacing, 0,
                        "Spacing must be positive")
    XCTAssertLessThan(spacing, 100,
                     "Spacing should be reasonable (<100pt)")
}
```

---

## Platform-Specific Testing

Use conditional compilation for platform-specific tests:

```swift
#if os(macOS)
func testPlatformAdapter_macOS() {
    XCTAssertTrue(PlatformAdapter.isMacOS)
    XCTAssertEqual(PlatformAdapter.defaultSpacing, 12.0,
                  "macOS should use 12pt spacing")
}
#endif

#if os(iOS)
func testPlatformAdapter_iOS() {
    XCTAssertTrue(PlatformAdapter.isIOS)
    XCTAssertEqual(PlatformAdapter.defaultSpacing, 16.0,
                  "iOS should use 16pt spacing")
}

func testPlatformAdapter_MinimumTouchTarget() {
    let minTarget = PlatformAdapter.minimumTouchTarget
    XCTAssertGreaterThanOrEqual(minTarget, 44.0,
                               "iOS minimum touch target should be ≥44pt per HIG")
}
#endif
```

---

## Test Organization

### File Structure

```
Tests/
├── ComponentsTests/
│   ├── BadgeTests.swift           # Component behavior tests
│   ├── CardTests.swift
│   └── KeyValueRowTests.swift
├── ContextsTests/
│   ├── SurfaceStyleKeyTests.swift        # Unit tests for individual contexts
│   ├── PlatformAdaptationTests.swift
│   ├── ColorSchemeAdapterTests.swift
│   └── ContextIntegrationTests.swift     # Integration tests
└── ViewModelsTests/
    ├── FileInspectorViewModelTests.swift
    └── SettingsViewModelTests.swift
```

### Test Naming Convention

```swift
// Unit tests: test[Type]_[Property/Method]_[Scenario]
func testSurfaceStyleKey_DefaultValue()
func testPlatformAdapter_Spacing_CompactSizeClass()
func testColorSchemeAdapter_AdaptiveColors_DarkMode()

// Integration tests: test[Feature]_[Integration]
func testCrossContext_SurfaceStyleAndPlatform()
func testIntegration_AllContextsIndependent()

// Edge cases: testEdgeCase_[Scenario]
func testEdgeCase_NilSizeClass()
func testEdgeCase_NegativeSpacing()
```

---

## Testing Checklist

Before marking tests as complete, verify:

- [ ] **No XCTAssertNotNil(view) assertions** - These always pass for SwiftUI views
- [ ] **Tests verify observable properties** - Not just construction
- [ ] **Tests can actually fail** - Verify by temporarily breaking implementation
- [ ] **All numeric values checked against DS tokens** - Zero magic numbers
- [ ] **Platform-specific tests use conditional compilation** - #if os(macOS) / os(iOS)
- [ ] **Environment key tests verify storage/retrieval** - Not just construction
- [ ] **ViewModel tests cover state transitions** - Not just initial state
- [ ] **Integration tests verify independence** - Multiple contexts work together
- [ ] **Error messages are descriptive** - Explain what should happen
- [ ] **Test coverage ≥80%** - Use `swift test --enable-code-coverage`

---

## Common Mistakes and Fixes

| ❌ Mistake | ✅ Fix |
|-----------|--------|
| `XCTAssertNotNil(view)` | Test observable properties instead |
| Testing view hierarchy | Test data/state that drives hierarchy |
| Testing SwiftUI framework | Test your code, not Apple's |
| No platform #if guards | Add conditional compilation |
| Magic number assertions | Use DS tokens in assertions |
| Generic error messages | Add descriptive failure messages |
| Only happy path tests | Include edge cases (nil, empty, etc.) |
| No integration tests | Test contexts working together |

---

## Snapshot Testing (Optional)

For visual regression testing, use third-party libraries:

```swift
import SnapshotTesting

func testCardView_Snapshot() {
    let card = Card {
        Text("Test Content")
    }

    assertSnapshot(matching: card, as: .image)
}
```

**When to use snapshot testing:**
- Visual regressions (colors, spacing, layout)
- Cross-platform appearance consistency
- Complex component compositions

**When NOT to use snapshot testing:**
- Logic and behavior (use unit tests)
- Environment values (test directly)
- Platform detection (test properties)

---

## Summary

### ✅ DO

- Test observable properties (state, computed values, etc.)
- Test behavior (actions, transitions, side effects)
- Test environment key storage/retrieval
- Test platform detection and calculations
- Test value types (enums, structs) for equality
- Use conditional compilation for platform-specific tests
- Verify zero magic numbers (all DS tokens)
- Write tests that can actually fail

### ❌ DON'T

- Test view construction with XCTAssertNotNil
- Test SwiftUI's framework behavior
- Use magic numbers in assertions
- Skip platform-specific conditional compilation
- Write tests that always pass
- Test rendering without snapshot tools
- Forget to verify tests can fail

---

## References

- [Apple: Testing Your Apps in Xcode](https://developer.apple.com/documentation/xcode/testing-your-apps-in-xcode)
- [FoundationUI Test Plan](../../AI/ISOViewer/FoundationUI_TestPlan.md)
- [TDD Workflow](02_TDD_XP_Workflow.md)
- [ViewInspector (third-party)](https://github.com/nalexn/ViewInspector)
- [SnapshotTesting (third-party)](https://github.com/pointfreeco/swift-snapshot-testing)

---

**Last Updated:** 2025-10-26
**Status:** Active guideline for all SwiftUI testing
