# Platform Adaptation Integration Tests

## 🎯 Objective
Create comprehensive integration tests that verify platform-specific behavior (macOS, iOS, iPadOS) across all FoundationUI components and patterns, ensuring consistent cross-platform adaptation.

## 🧩 Context
- **Phase**: Phase 3.2 - Layer 4: Contexts & Platform Adaptation
- **Layer**: Layer 4 (Contexts)
- **Priority**: P0
- **Dependencies**:
  - ✅ PlatformAdaptation.swift (completed)
  - ✅ ColorSchemeAdapter.swift (completed)
  - ✅ SurfaceStyleKey.swift (completed)
  - ✅ All Pattern implementations (InspectorPattern, SidebarPattern, ToolbarPattern, BoxTreePattern)
  - ✅ All Component implementations (Badge, Card, KeyValueRow, SectionHeader, CopyableText)
  - ✅ ContextIntegrationTests.swift (completed)

## ✅ Success Criteria
- [ ] Integration tests written for macOS-specific behavior
- [ ] Integration tests written for iOS-specific behavior
- [ ] Integration tests written for iPad adaptive layout (size classes)
- [ ] Cross-platform consistency verification tests
- [ ] Tests verify platform detection logic in real components
- [ ] Tests verify spacing adaptation (macOS: 12pt, iOS: 16pt)
- [ ] Tests verify touch target sizes (iOS: ≥44pt)
- [ ] Tests verify keyboard shortcuts work on macOS
- [ ] Tests verify gestures work on iOS/iPadOS
- [ ] All tests use DS tokens exclusively (zero magic numbers)
- [ ] SwiftLint reports 0 violations
- [ ] 100% DocC documentation for test methods
- [ ] Test coverage ≥90% for platform-specific code paths

## 🔧 Implementation Notes

### Test Scope
The integration tests should verify:

1. **macOS-specific behavior**:
   - Compact spacing (12pt default)
   - Keyboard shortcut integration (⌘ keys)
   - NSPasteboard clipboard operations
   - Hover effects on interactive elements
   - Window-based navigation

2. **iOS-specific behavior**:
   - Larger spacing (16pt default)
   - Touch target enforcement (≥44pt)
   - UIPasteboard clipboard operations
   - Touch gestures
   - Navigation stack behavior

3. **iPad adaptive layout**:
   - Compact size class behavior (portrait, split view)
   - Regular size class behavior (landscape, full screen)
   - Spacing adaptation based on size class
   - Sidebar collapse/expand behavior
   - Pointer interaction support

4. **Cross-platform consistency**:
   - Same components render correctly on all platforms
   - DS token usage is platform-agnostic
   - Environment values propagate correctly
   - Dark mode works identically
   - Accessibility features work across platforms

### Files to Create/Modify
- `Tests/FoundationUITests/ContextsTests/PlatformAdaptationIntegrationTests.swift` (create)
- Update existing test infrastructure if needed

### Design Token Usage
- Spacing: `DS.Spacing.{s|m|l|xl}` (platform-agnostic)
- Platform-specific: `PlatformAdapter.defaultSpacing` (12pt macOS, 16pt iOS)
- Touch targets: `PlatformAdapter.minimumTouchTarget` (44pt iOS)
- Colors: `DS.Colors.*` (works identically across platforms)
- Animations: `DS.Animation.*` (platform-agnostic timing)

### Test Structure
```swift
import XCTest
@testable import FoundationUI

final class PlatformAdaptationIntegrationTests: XCTestCase {
    // MARK: - macOS-Specific Tests

    func testMacOSDefaultSpacing() { }
    func testMacOSKeyboardShortcuts() { }
    func testMacOSClipboardIntegration() { }
    func testMacOSHoverEffects() { }

    // MARK: - iOS-Specific Tests

    func testIOSDefaultSpacing() { }
    func testIOSTouchTargetSizes() { }
    func testIOSClipboardIntegration() { }
    func testIOSGestureSupport() { }

    // MARK: - iPad Adaptive Tests

    func testIPadCompactSizeClass() { }
    func testIPadRegularSizeClass() { }
    func testSidebarAdaptation() { }
    func testPointerInteraction() { }

    // MARK: - Cross-Platform Consistency

    func testComponentRenderingConsistency() { }
    func testDarkModeConsistency() { }
    func testAccessibilityConsistency() { }
    func testEnvironmentValuePropagation() { }
    func testZeroMagicNumbers() { }
}
```

### Platform Detection Strategy
Use conditional compilation to verify platform-specific code paths:
```swift
#if os(macOS)
    // macOS-specific tests
#elseif os(iOS)
    // iOS-specific tests (including iPad)
    #if targetEnvironment(macCatalyst)
        // Catalyst-specific tests
    #endif
#endif
```

### Size Class Testing
Test size class adaptation using SwiftUI environment:
```swift
struct TestView: View {
    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        // Component under test
    }
}

// In test:
let view = TestView()
    .environment(\.horizontalSizeClass, .compact)
```

## 🧠 Source References
- [FoundationUI Task Plan § 3.2](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md#32-layer-4-contexts--platform-adaptation)
- [FoundationUI PRD § Platform Adaptation](../../../DOCS/AI/ISOViewer/FoundationUI_PRD.md)
- [PlatformAdaptation.swift](../../../Sources/FoundationUI/Contexts/PlatformAdaptation.swift)
- [ContextIntegrationTests.swift](../../../Tests/FoundationUITests/ContextsTests/ContextIntegrationTests.swift)
- [Apple Human Interface Guidelines - Platform Considerations](https://developer.apple.com/design/human-interface-guidelines/)
- [SwiftUI Environment Documentation](https://developer.apple.com/documentation/swiftui/environment)

## 📋 Checklist
- [ ] Read task requirements from Task Plan
- [ ] Review existing ContextIntegrationTests for patterns
- [ ] Review PlatformAdaptation.swift implementation
- [ ] Create test file: `PlatformAdaptationIntegrationTests.swift`
- [ ] Write macOS-specific integration tests (≥4 tests)
- [ ] Write iOS-specific integration tests (≥4 tests)
- [ ] Write iPad adaptive layout tests (≥4 tests)
- [ ] Write cross-platform consistency tests (≥4 tests)
- [ ] Run `swift test --filter PlatformAdaptationIntegrationTests` to confirm tests compile
- [ ] Verify all tests use DS tokens (zero magic numbers)
- [ ] Add comprehensive DocC comments to all test methods
- [ ] Run `swiftlint` and fix any violations (target: 0 violations)
- [ ] Test on macOS (if available)
- [ ] Test on iOS simulator (if available)
- [ ] Test on iPad simulator with different size classes (if available)
- [ ] Verify ≥90% coverage for platform-specific code paths
- [ ] Update Task Plan with [x] completion mark
- [ ] Archive task documentation
- [ ] Commit with descriptive message
- [ ] Push to feature branch

## 🎨 Example Test Cases

### macOS Spacing Test
```swift
func testMacOSDefaultSpacing() throws {
    #if os(macOS)
    let spacing = PlatformAdapter.defaultSpacing
    XCTAssertEqual(spacing, 12.0, "macOS should use 12pt default spacing")

    let card = Card {
        Text("Test")
    }
    .platformAdaptive()

    // Verify the card uses platform-appropriate spacing
    // ... test implementation
    #endif
}
```

### iOS Touch Target Test
```swift
func testIOSTouchTargetSizes() throws {
    #if os(iOS)
    let minTarget = PlatformAdapter.minimumTouchTarget
    XCTAssertEqual(minTarget, 44.0, "iOS minimum touch target must be 44pt per HIG")

    let badge = Badge(text: "Test", level: .info)
        .platformAdaptive()

    // Verify badge meets minimum touch target size
    // ... test implementation
    #endif
}
```

### iPad Size Class Test
```swift
func testIPadCompactSizeClass() throws {
    #if os(iOS)
    let view = InspectorPattern(title: "Test") {
        Text("Content")
    }
    .environment(\.horizontalSizeClass, .compact)

    // Verify compact layout behavior
    // ... test implementation
    #endif
}
```

### Cross-Platform Consistency Test
```swift
func testDarkModeConsistency() throws {
    let adapter = ColorSchemeAdapter(colorScheme: .dark)

    // All platforms should produce identical dark mode colors
    XCTAssertNotNil(adapter.adaptiveBackground)
    XCTAssertNotNil(adapter.adaptiveTextColor)

    // Verify colors work on current platform
    #if os(macOS)
    // macOS-specific color verification
    #elseif os(iOS)
    // iOS-specific color verification
    #endif
}
```

## 📝 Notes
- Focus on **integration** tests, not unit tests (those already exist)
- Test real-world component compositions (e.g., InspectorPattern with Card and Badge)
- Verify environment value propagation through deep hierarchies
- Test edge cases: nil size class, unknown platform, etc.
- Ensure tests are platform-aware and skip appropriately using `#if os(...)`
- Document platform-specific behavior differences clearly
- All tests must be independent and repeatable
- No flaky tests allowed - use deterministic assertions

## 🚀 Next Steps After Completion
1. Run full test suite: `swift test`
2. Generate coverage report: `./Scripts/coverage.sh`
3. Verify ≥90% coverage for platform adaptation code
4. Archive task to `TASK_ARCHIVE/26_Phase3.2_PlatformAdaptationIntegrationTests/`
5. Update `next_tasks.md` with next priority
6. Select next task from Phase 3.2 or Phase 3.1 (pattern performance optimization)
