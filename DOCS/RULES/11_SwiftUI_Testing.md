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

## Swift 6 Concurrency: @MainActor Requirements

**CRITICAL**: With Swift 6 strict concurrency enabled, all test methods that work with SwiftUI Views **must** be annotated with `@MainActor`.

### ❌ Common Error Without @MainActor

```swift
// ❌ FAILS in Swift 6 strict concurrency mode
func testView_AdaptiveColorSchemeModifier_Exists() {
    let view = Text("Test")
    let modifiedView = view.adaptiveColorScheme()  // ⚠️ Error here
    XCTAssertNotNil(modifiedView)
}
```

**Error Message:**

```clang
Non-Sendable 'some View'-typed result can not be returned from
main actor-isolated instance method 'adaptiveColorScheme()' to
nonisolated context
```

**Why this happens:**

- SwiftUI Views must be created and accessed on the main thread
- Methods returning `some View` are implicitly `@MainActor` isolated
- Without `@MainActor` on the test, you're accessing main-actor-isolated code from a nonisolated context
- Swift 6's strict concurrency checker catches this at compile time

### ✅ Correct: Add @MainActor to Test Method

```swift
// ✅ PASSES: Test method is MainActor-isolated
@MainActor
func testView_AdaptiveColorSchemeModifier_Exists() {
    let view = Text("Test")
    let modifiedView = view.adaptiveColorScheme()
    XCTAssertNotNil(modifiedView)
}
```

### When to Use @MainActor in Tests

**Always use `@MainActor` when:**

1. **Creating SwiftUI Views**

   ```swift
   @MainActor
   func testView_Creation() {
       let view = MyCustomView()  // ✅ SwiftUI view creation
       // Test view properties...
   }
   ```

2. **Calling View Modifiers**

   ```swift
   @MainActor
   func testView_Modifier() {
       let modified = Text("Test").myCustomModifier()  // ✅ View modifier
       // Test modifier behavior...
   }
   ```

3. **Working with ViewBuilders**

   ```swift
   @MainActor
   func testViewBuilder_Construction() {
       let stack = VStack {  // ✅ ViewBuilder closure
           Text("Line 1")
           Text("Line 2")
       }
       // Test stack construction...
   }
   ```

4. **Testing Environment Values with Views**

   ```swift
   @MainActor
   func testEnvironment_WithView() {
       struct TestView: View {
           @Environment(\.colorScheme) var colorScheme
           var body: some View { Text("Test") }
       }
       let view = TestView()  // ✅ SwiftUI view
       // Test environment integration...
   }
   ```

### When NOT to Use @MainActor

**Do NOT use `@MainActor` when:**

1. **Testing Pure Data/Logic (No Views)**

   ```swift
   // ✅ No @MainActor needed - no SwiftUI Views
   func testColorSchemeAdapter_IsDarkMode() {
       let adapter = ColorSchemeAdapter(colorScheme: .dark)
       XCTAssertTrue(adapter.isDarkMode)
   }
   ```

2. **Testing Environment Keys Directly**

   ```swift
   // ✅ No @MainActor needed - direct property testing
   func testSurfaceStyleKey_DefaultValue() {
       let defaultValue = SurfaceStyleKey.defaultValue
       XCTAssertEqual(defaultValue, .regular)
   }
   ```

3. **Testing ViewModels/ObservableObjects**

   ```swift
   // ✅ No @MainActor needed - testing data model
   func testViewModel_Increment() {
       let vm = MyViewModel()
       vm.increment()
       XCTAssertEqual(vm.count, 1)
   }
   ```

4. **Testing Platform Adapters**

   ```swift
   // ✅ No @MainActor needed - pure logic
   func testPlatformAdapter_Spacing() {
       let spacing = PlatformAdapter.defaultSpacing
       XCTAssertGreaterThan(spacing, 0)
   }
   ```

### Key Principles

1. **Rule of Thumb**: If your test creates, modifies, or returns a SwiftUI `View`, add `@MainActor`

2. **Compilation is Your Guide**: If you get the "Non-Sendable 'some View'" error, add `@MainActor`

3. **Prefer Specific Over Broad**:

   ```swift
   // ✅ GOOD: Only mark methods that need it
   @MainActor
   func testView_WithSwiftUI() { /* ... */ }

   func testLogic_NoSwiftUI() { /* ... */ }

   // ❌ BAD: Don't mark entire test class unless all tests use Views
   @MainActor
   final class MyTests: XCTestCase {
       // This forces ALL tests to run on MainActor
   }
   ```

4. **Performance Consideration**: `@MainActor` tests run on the main thread. Keep them focused and fast.

### Examples from Real Code

#### Example 1: View Modifier Test (Needs @MainActor)

```swift
// From ColorSchemeAdapterTests.swift

@MainActor  // ✅ Required because adaptiveColorScheme() returns 'some View'
func testView_AdaptiveColorSchemeModifier_WorksWithComplexViews() {
    let complexView = VStack {
        Text("Title")
        HStack {
            Text("Left")
            Text("Right")
        }
    }

    let modifiedView = complexView.adaptiveColorScheme()
    XCTAssertNotNil(modifiedView)
}
```

#### Example 2: Adapter Logic Test (No @MainActor Needed)

```swift
// From ColorSchemeAdapterTests.swift

// ✅ No @MainActor - testing pure logic, no Views
func testColorSchemeAdapter_IsDarkMode_DarkScheme_ReturnsTrue() {
    let adapter = ColorSchemeAdapter(colorScheme: .dark)
    XCTAssertTrue(adapter.isDarkMode)
}
```

#### Example 3: Environment Key Test (No @MainActor Needed)

```swift
// From SurfaceStyleKeyTests.swift

// ✅ No @MainActor - testing EnvironmentValues directly, no View construction
func testEnvironmentValues_SetSurfaceStyle_StoresValue() {
    var environment = EnvironmentValues()
    environment.surfaceStyle = .thick
    XCTAssertEqual(environment.surfaceStyle, .thick)
}
```

### Debugging @MainActor Issues

If you encounter concurrency errors:

1. **Read the error carefully**:

   ```clang
   Non-Sendable 'some View'-typed result can not be returned from
   main actor-isolated instance method 'X()' to nonisolated context
   ```

   → The method returning `some View` is MainActor-isolated

2. **Identify the source**:
   - Which method is returning `some View`?
   - Is it a view modifier, ViewBuilder, or view constructor?

3. **Apply @MainActor to the test method**:

   ```swift
   @MainActor  // Add this
   func testProblematicMethod() {
       // Your test code
   }
   ```

4. **Verify the fix**:
   - Re-run tests
   - Ensure compilation succeeds
   - Check CI pipeline passes

### Swift 6 Migration Checklist

When updating tests for Swift 6 strict concurrency:

- [ ] Review all test files for SwiftUI View usage
- [ ] Add `@MainActor` to tests creating/modifying Views
- [ ] Remove unnecessary `@MainActor` from pure logic tests
- [ ] Run `swift build` to catch remaining concurrency issues
- [ ] Verify all tests pass in CI
- [ ] Document any platform-specific MainActor requirements

### Common Patterns

| Test Type | @MainActor Needed? | Example |
|-----------|-------------------|---------|
| View construction | ✅ Yes | `let view = MyView()` |
| View modifier | ✅ Yes | `view.myModifier()` |
| ViewBuilder | ✅ Yes | `VStack { Text("Hi") }` |
| Environment + View | ✅ Yes | `TestView().environment(...)` |
| Environment key alone | ❌ No | `SurfaceStyleKey.defaultValue` |
| ViewModel/ObservableObject | ❌ No | `MyViewModel().increment()` |
| Platform adapter logic | ❌ No | `PlatformAdapter.spacing` |
| Color adapter logic | ❌ No | `ColorSchemeAdapter(...)` |
| Enum/struct properties | ❌ No | `SurfaceMaterial.thin` |

---

## Test Organization

### File Structure

```zsh
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

**Last Updated:** 2025-10-28
**Status:** Active guideline for all SwiftUI testing
**Major Update:** Added Swift 6 @MainActor concurrency requirements section
