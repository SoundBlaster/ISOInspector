# Accessibility

Building accessible UIs with FoundationUI following WCAG 2.1 guidelines.

## Overview

FoundationUI is designed with **accessibility-first** principles, ensuring all components work seamlessly with VoiceOver, keyboard navigation, Dynamic Type, and other assistive technologies. Every component meets or exceeds WCAG 2.1 Level AA standards.

## Accessibility Features

### VoiceOver Support

All FoundationUI components include descriptive VoiceOver labels and hints:

```swift
// Badge automatically includes semantic labels
Badge(text: "Error", level: .error)
// VoiceOver: "Error badge, error"

// KeyValueRow provides structured information
KeyValueRow(key: "Type", value: "ftyp")
// VoiceOver: "Type: ftyp"

// Copyable text announces copy action
CopyableText(text: "UUID")
// VoiceOver: "UUID, copyable, button. Double tap to copy."
```

### Custom VoiceOver Labels

Override default labels when needed:

```swift
Badge(text: "!!", level: .error)
    .accessibilityLabel("Invalid box structure")
    .accessibilityHint("This ISO file has structural errors")
```

### Keyboard Navigation

All interactive components support keyboard navigation:

**macOS**:
- Tab to focus on interactive elements
- Space to activate buttons
- Arrow keys for navigation
- ⌘C to copy (CopyableText, KeyValueRow)

**iOS with Hardware Keyboard**:
- Tab to navigate
- Space or Return to activate
- Arrow keys in lists

```swift
// Components automatically support keyboard focus
Card {
    Button("Action") { }  // Tab to focus, Space to activate
    CopyableText(text: "Value")  // Tab to focus, ⌘C to copy
}
```

### Dynamic Type

All typography scales with user preferences:

```swift
// Automatically scales from XS to XXXL
Text("Hello")
    .font(DS.Typography.body)

// Test all Dynamic Type sizes
#Preview("Extra Small") {
    ContentView()
        .environment(\.sizeCategory, .extraSmall)
}

#Preview("Extra Extra Large") {
    ContentView()
        .environment(\.sizeCategory, .accessibilityExtraExtraLarge)
}
```

### Touch Target Sizes

All interactive elements meet minimum touch target sizes:

- **iOS**: ≥44×44 pt (Apple Human Interface Guidelines)
- **macOS**: ≥24×24 pt (pointer interactions)

```swift
// Button with sufficient touch target
Button("Action") { }
    .frame(minWidth: 44, minHeight: 44)  // iOS minimum

// Or use PlatformAdaptation for automatic sizing
Button("Action") { }
    .platformAdaptive()  // Applies platform-specific minimums
```

### Contrast Ratios

All colors meet WCAG 2.1 Level AA standards (≥4.5:1 contrast):

```swift
// Semantic colors are pre-validated
Badge(text: "Info", level: .info)  // ≥4.5:1 contrast ✅

// Validate custom colors
let ratio = AccessibilityHelpers.contrastRatio(
    foreground: Color.white,
    background: DS.Colors.infoBG
)

if ratio >= 4.5 {
    print("WCAG AA compliant ✅")
}
```

### Reduce Motion

Respect user motion preferences:

```swift
// Disable animations if Reduce Motion is on
Text("Hello")
    .opacity(isVisible ? 1 : 0)
    .animation(DS.Animation.medium.ifMotionEnabled(), value: isVisible)

// Or use AccessibilityContext
@Environment(\.accessibilityReduceMotion) var reduceMotion

var body: some View {
    Text("Hello")
        .opacity(isVisible ? 1 : 0)
        .animation(reduceMotion ? nil : DS.Animation.medium, value: isVisible)
}
```

### Increase Contrast

Support high-contrast mode:

```swift
@Environment(\.accessibilityDifferentiateWithoutColor) var highContrast

var body: some View {
    Badge(text: "Error", level: .error)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.chip)
                .stroke(highContrast ? Color.primary : Color.clear, lineWidth: 2)
        )
}
```

## WCAG 2.1 Compliance

### Level AA Requirements

FoundationUI meets all WCAG 2.1 Level AA requirements:

| Criterion | Requirement | FoundationUI Implementation |
|-----------|-------------|------------------------------|
| **1.4.3 Contrast (Minimum)** | ≥4.5:1 | All DS.Colors validated |
| **1.4.4 Resize Text** | Up to 200% | Dynamic Type support |
| **1.4.11 Non-text Contrast** | ≥3:1 | UI components validated |
| **2.1.1 Keyboard** | Full keyboard access | All components support Tab, Space, Return |
| **2.4.7 Focus Visible** | Visible focus indicators | `.interactiveStyle()` provides focus rings |
| **2.5.5 Target Size** | ≥44×44 pt | All buttons meet minimum size |
| **4.1.2 Name, Role, Value** | Programmatic labels | VoiceOver labels on all components |

### Testing Compliance

```swift
// Automated accessibility tests
func testAccessibilityCompliance() {
    let badge = Badge(text: "Error", level: .error)

    // Test VoiceOver label exists
    XCTAssertNotNil(badge.accessibilityLabel)

    // Test contrast ratio
    let ratio = contrastRatio(
        foreground: DS.Colors.textPrimary,
        background: DS.Colors.errorBG
    )
    XCTAssertGreaterThanOrEqual(ratio, 4.5)

    // Test touch target size
    let frame = badge.frame
    XCTAssertGreaterThanOrEqual(frame.width, 44)
    XCTAssertGreaterThanOrEqual(frame.height, 44)
}
```

## Accessibility Helpers

FoundationUI includes utilities for accessibility testing:

### Contrast Ratio Validation

```swift
// Check contrast ratio
let ratio = AccessibilityHelpers.contrastRatio(
    foreground: Color.white,
    background: DS.Colors.infoBG
)

// Validate WCAG compliance
let isAA = ratio >= 4.5  // Level AA
let isAAA = ratio >= 7.0  // Level AAA
```

### Touch Target Audit

```swift
// Audit touch targets in a view
let audit = AccessibilityHelpers.auditTouchTargets(in: myView)

// Check for violations
if !audit.violations.isEmpty {
    print("Touch target violations found:")
    for violation in audit.violations {
        print("- \(violation.label): \(violation.size)")
    }
}
```

### VoiceOver Testing

```swift
// Test VoiceOver labels
let labels = AccessibilityHelpers.collectLabels(in: myView)

XCTAssertEqual(labels.count, expectedCount)
XCTAssertTrue(labels.contains("Error badge"))
```

## Accessibility Context

Use `AccessibilityContext` to adapt to user preferences:

```swift
@Environment(\.accessibilityContext) var a11yContext

var body: some View {
    Text("Hello")
        .font(a11yContext.scaledFont(for: DS.Typography.body))
        .padding(a11yContext.scaledSpacing(DS.Spacing.m))
        .animation(a11yContext.animation(DS.Animation.quick), value: state)
}
```

Features:
- `reduceMotion`: Disable animations if requested
- `increaseContrast`: Use high-contrast colors
- `boldText`: Use bold font weights (iOS)
- `sizeCategory`: Current Dynamic Type size
- `isAccessibilitySize`: True for extra-large text sizes

## Platform-Specific Accessibility

### macOS

- **Keyboard shortcuts**: ⌘C, ⌘V, ⌘A (built into components)
- **Focus rings**: Visible with Tab navigation
- **VoiceOver**: ⌥⌘F5 to enable

```swift
// macOS keyboard shortcut
KeyboardShortcuts.copy
// VoiceOver: "Copy, ⌘C"
```

### iOS

- **VoiceOver**: Settings > Accessibility > VoiceOver
- **Dynamic Type**: Settings > Accessibility > Display & Text Size
- **Reduce Motion**: Settings > Accessibility > Motion
- **VoiceOver rotor**: Swipe up/down with two fingers

```swift
// iOS-specific VoiceOver hint
Text("Swipe right to continue")
    .accessibilityHint("Swipe right to navigate to the next screen")
```

### iPadOS

- **Pointer interactions**: Hover effects with mouse/trackpad
- **Split View**: Adaptive layouts for multitasking
- **Keyboard shortcuts**: Full keyboard support

```swift
// iPad pointer interaction
Button("Action") { }
    .hoverEffect(.lift)  // Lifts on pointer hover
```

## Testing Accessibility

### Manual Testing

#### VoiceOver Testing Checklist

- [ ] Enable VoiceOver (macOS: ⌥⌘F5, iOS: Triple-click Home/Side button)
- [ ] Navigate with VoiceOver gestures (swipe right/left)
- [ ] Verify all elements are announced correctly
- [ ] Test custom labels and hints
- [ ] Verify reading order is logical
- [ ] Test interactive elements (buttons, text fields)

#### Keyboard Navigation Checklist

- [ ] Tab through all interactive elements
- [ ] Verify focus indicators are visible
- [ ] Test Space/Return to activate buttons
- [ ] Test arrow keys for navigation
- [ ] Test platform shortcuts (⌘C, ⌘V)

#### Dynamic Type Checklist

- [ ] Test XS (Extra Small) size
- [ ] Test M (Default) size
- [ ] Test XXL (Extra Extra Large) size
- [ ] Test XXXL (Accessibility sizes)
- [ ] Verify layouts don't break at any size
- [ ] Verify text is readable at all sizes

#### Color Contrast Checklist

- [ ] Test Light Mode contrast
- [ ] Test Dark Mode contrast
- [ ] Test Increase Contrast mode
- [ ] Verify all text is readable
- [ ] Verify UI elements are distinguishable

### Automated Testing

```swift
import XCTest
@testable import FoundationUI

class AccessibilityTests: XCTestCase {
    func testVoiceOverLabels() {
        let badge = Badge(text: "Error", level: .error)

        // Verify label exists and is descriptive
        XCTAssertNotNil(badge.accessibilityLabel)
        XCTAssertTrue(badge.accessibilityLabel?.contains("Error") ?? false)
    }

    func testContrastRatios() {
        let colors = [
            (DS.Colors.infoBG, "Info"),
            (DS.Colors.warnBG, "Warning"),
            (DS.Colors.errorBG, "Error"),
            (DS.Colors.successBG, "Success")
        ]

        for (color, name) in colors {
            let ratio = AccessibilityHelpers.contrastRatio(
                foreground: DS.Colors.textPrimary,
                background: color
            )
            XCTAssertGreaterThanOrEqual(
                ratio, 4.5,
                "\(name) background fails WCAG AA contrast (ratio: \(ratio))"
            )
        }
    }

    func testTouchTargetSizes() {
        let button = Button("Action") { }
            .platformAdaptive()

        let size = button.intrinsicContentSize

        #if os(iOS)
        XCTAssertGreaterThanOrEqual(size.width, 44)
        XCTAssertGreaterThanOrEqual(size.height, 44)
        #elseif os(macOS)
        XCTAssertGreaterThanOrEqual(size.width, 24)
        XCTAssertGreaterThanOrEqual(size.height, 24)
        #endif
    }

    func testDynamicTypeScaling() {
        let sizes: [ContentSizeCategory] = [
            .extraSmall, .medium, .accessibilityExtraExtraLarge
        ]

        for size in sizes {
            let view = Text("Hello")
                .font(DS.Typography.body)
                .environment(\.sizeCategory, size)

            // Verify view renders without errors
            XCTAssertNoThrow(view)
        }
    }
}
```

## Best Practices

### ✅ Do's

```swift
// ✅ Use semantic labels
Badge(text: "Error", level: .error)
// VoiceOver: "Error badge"

// ✅ Provide hints for complex interactions
Button("Copy") { }
    .accessibilityHint("Copies the value to clipboard")

// ✅ Group related content
VStack {
    Text("Type")
    Text("ftyp")
}
.accessibilityElement(children: .combine)
// VoiceOver: "Type ftyp"

// ✅ Use heading traits
Text("Section Title")
    .accessibilityAddTraits(.isHeader)

// ✅ Hide decorative elements
Image(decorative: "background")
    .accessibilityHidden(true)

// ✅ Respect user preferences
.animation(DS.Animation.quick.ifMotionEnabled(), value: state)
```

### ❌ Don'ts

```swift
// ❌ Don't use poor contrast
Text("Hello")
    .foregroundColor(.gray)
    .background(Color.lightGray)  // Low contrast ❌

// ❌ Don't forget VoiceOver labels
Image("icon")  // No label ❌
// Fix: .accessibilityLabel("Error icon")

// ❌ Don't make touch targets too small
Button { } label: {
    Image(systemName: "plus")
        .frame(width: 20, height: 20)  // Too small ❌
}

// ❌ Don't ignore Dynamic Type
Text("Hello")
    .font(.system(size: 14))  // Fixed size ❌
// Fix: .font(DS.Typography.body)

// ❌ Don't use color alone to convey information
Circle()
    .fill(isError ? .red : .green)  // Color-only indicator ❌
// Fix: Add icon or label
```

## Accessibility Resources

### Apple Documentation

- [Accessibility for SwiftUI](https://developer.apple.com/documentation/swiftui/view-accessibility)
- [Human Interface Guidelines - Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [VoiceOver Testing](https://developer.apple.com/library/archive/technotes/TestingAccessibilityOfiOSApps/)

### WCAG 2.1 Guidelines

- [WCAG 2.1 Quick Reference](https://www.w3.org/WAI/WCAG21/quickref/)
- [Contrast Ratio Calculator](https://webaim.org/resources/contrastchecker/)
- [WCAG Color Contrast Checker](https://webaim.org/resources/contrastchecker/)

### Testing Tools

- **Xcode Accessibility Inspector**: Debug > Accessibility Inspector
- **VoiceOver**: macOS/iOS built-in screen reader
- **Simulator Accessibility Settings**: Settings > Accessibility

## Further Reading

- <doc:DesignTokens> — WCAG-compliant color tokens
- <doc:Components> — Accessible component APIs
- ``AccessibilityHelpers`` — Accessibility testing utilities
- ``AccessibilityContext`` — User preference adaptation

## See Also

- ``AccessibilityHelpers``
- ``AccessibilityContext``
- ``DS/Colors``
- ``Badge``
- ``CopyableText``
