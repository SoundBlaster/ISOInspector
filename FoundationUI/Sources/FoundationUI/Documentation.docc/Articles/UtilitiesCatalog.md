# Utilities Catalog

Helper utilities for common tasks.

## Overview

FoundationUI Utilities provide helper functions and components for common tasks like copying text, keyboard shortcuts, and accessibility testing. These utilities complement the core components and patterns.

## Available Utilities

### CopyableText

Text component with copy-to-clipboard button.

```swift
CopyableText(
    text: "550e8400-e29b-41d4-a716-446655440000",
    label: "UUID"
)
```

**Features**:
- Visual "Copied!" feedback (animated)
- Platform-specific clipboard (NSPasteboard/UIPasteboard)
- Keyboard shortcut (⌘C on macOS)
- VoiceOver announcements
- Automatic success indicator (fades out after 2s)

**Use Cases**: UUIDs, hex values, file paths, technical strings

**API**:

```swift
public struct CopyableText: View {
    public init(
        text: String,
        label: String? = nil
    )
}
```

### Copyable

Generic wrapper for making any view copyable.

```swift
Copyable(text: "Value to copy") {
    HStack {
        Image(systemName: "doc")
        Text("Custom View")
    }
}
.showFeedback(true)
```

**Features**:
- Generic ViewBuilder support
- Works with any content type
- Uses CopyableModifier internally
- Optional visual feedback
- Full accessibility support

**Use Cases**: Custom copyable layouts, complex views, Badge + copyable combinations

**API**:

```swift
public struct Copyable<Content: View>: View {
    public init(
        text: String,
        @ViewBuilder content: () -> Content
    )

    public func showFeedback(_ show: Bool) -> Self
}
```

### KeyboardShortcuts

Platform-specific keyboard shortcut definitions.

```swift
// Use predefined shortcuts
KeyboardShortcuts.copy        // ⌘C on macOS, Ctrl+C elsewhere
KeyboardShortcuts.paste       // ⌘V
KeyboardShortcuts.selectAll   // ⌘A

// Display string
let displayString = KeyboardShortcuts.copy.displayString
// macOS: "⌘C"
// Other: "Ctrl+C"
```

**Predefined Shortcuts**

| Shortcut | Action |
| --- | --- |
| `copy` | Copy (⌘C / Ctrl+C) |
| `paste` | Paste (⌘V / Ctrl+V) |
| `cut` | Cut (⌘X / Ctrl+X) |
| `selectAll` | Select All (⌘A / Ctrl+A) |
| `undo` | Undo (⌘Z / Ctrl+Z) |
| `redo` | Redo (⌘⇧Z / Ctrl+Y) |
| `find` | Find (⌘F / Ctrl+F) |
| `save` | Save (⌘S / Ctrl+S) |
| `open` | Open (⌘O / Ctrl+O) |
| `newWindow` | New Window (⌘N / Ctrl+N) |
| `closeWindow` | Close Window (⌘W / Ctrl+W) |

**Features**:
- Platform-specific key modifiers (Command/Control)
- Display string formatting (⌘C vs Ctrl+C)
- Accessibility labels for VoiceOver
- SwiftUI integration with `.shortcut()` modifier

**Use Cases**: Toolbar actions, menu items, keyboard navigation

### AccessibilityHelpers

Accessibility testing and validation utilities.

```swift
// Check contrast ratio
let ratio = AccessibilityHelpers.contrastRatio(
    foreground: Color.white,
    background: DS.Colors.infoBG
)

// Validate WCAG compliance
let isAA = ratio >= 4.5   // Level AA
let isAAA = ratio >= 7.0  // Level AAA
```

**Features**:
- **Contrast ratio validation** (WCAG 2.1 AA/AAA)
- **Touch target audit** (≥44×44 pt iOS)
- **VoiceOver label collection**
- **Focus management helpers**
- **Dynamic Type support**

**Contrast Ratio Validator**:

```swift
let ratio = AccessibilityHelpers.contrastRatio(
    foreground: DS.Colors.textPrimary,
    background: DS.Colors.infoBG
)

if ratio >= 4.5 {
    print("WCAG AA compliant ✅")
}
```

**Touch Target Audit**:

```swift
let audit = AccessibilityHelpers.auditTouchTargets(in: myView)

if !audit.violations.isEmpty {
    for violation in audit.violations {
        print("Touch target too small: \(violation.label)")
    }
}
```

**VoiceOver Testing**:

```swift
let labels = AccessibilityHelpers.collectLabels(in: myView)

XCTAssertEqual(labels.count, expectedCount)
XCTAssertTrue(labels.contains("Error badge"))
```

**Use Cases**: Accessibility testing, WCAG validation, VoiceOver testing, contrast checking

## Utility Composition

Utilities work together:

```swift
// Copyable KeyValueRow
Copyable(text: uuid) {
    KeyValueRow(key: "UUID", value: uuid)
}

// With accessibility validation
let ratio = AccessibilityHelpers.contrastRatio(
    foreground: .primary,
    background: .secondary
)
XCTAssertGreaterThanOrEqual(ratio, 4.5)

// With keyboard shortcut
Button("Copy") {
    copyToClipboard()
}
.keyboardShortcut(KeyboardShortcuts.copy.key, modifiers: KeyboardShortcuts.copy.modifiers)
```

## Design Principles

### 1. Platform-Specific

Utilities handle platform differences:

```swift
// CopyableText uses correct clipboard
#if os(macOS)
    NSPasteboard.general.setString(text, forType: .string)
#else
    UIPasteboard.general.string = text
#endif
```

### 2. Accessibility-First

All utilities include accessibility support:

```swift
CopyableText(text: "UUID")
// VoiceOver: "UUID, copyable, button. Double tap to copy."

// Accessibility helpers validate WCAG compliance
AccessibilityHelpers.contrastRatio(/* ... */)  // ≥4.5:1
```

### 3. Reusable

Utilities are generic and reusable:

```swift
// Copyable works with any view
Copyable(text: "Value") {
    Text("Any View")
}

// KeyboardShortcuts work with any action
Button("Action") { }
    .keyboardShortcut(KeyboardShortcuts.save.key)
```

## Complete Example

Using utilities together:

```swift
struct MetadataView: View {
    let uuid: String
    let checksum: String

    var body: some View {
        VStack(spacing: DS.Spacing.l) {
            // Copyable with custom layout
            Copyable(text: uuid) {
                HStack {
                    Image(systemName: "doc.text")
                    KeyValueRow(key: "UUID", value: uuid)
                }
            }
            .showFeedback(true)

            // CopyableText utility
            CopyableText(text: checksum, label: "Checksum")

            // Keyboard shortcut button
            Button("Copy All") {
                copyAllMetadata()
            }
            .keyboardShortcut(KeyboardShortcuts.copy.key, modifiers: KeyboardShortcuts.copy.modifiers)
            .accessibilityLabel("Copy all metadata")
            .accessibilityHint(KeyboardShortcuts.copy.accessibilityLabel)
        }
    }
}

// Accessibility testing
class MetadataViewTests: XCTestCase {
    func testAccessibility() {
        let view = MetadataView(uuid: "test", checksum: "abc123")

        // Validate contrast
        let ratio = AccessibilityHelpers.contrastRatio(
            foreground: DS.Colors.textPrimary,
            background: DS.Colors.tertiary
        )
        XCTAssertGreaterThanOrEqual(ratio, 4.5, "Must meet WCAG AA")

        // Validate touch targets
        let audit = AccessibilityHelpers.auditTouchTargets(in: view)
        XCTAssertTrue(audit.violations.isEmpty, "All touch targets must be ≥44×44 pt")

        // Validate VoiceOver
        let labels = AccessibilityHelpers.collectLabels(in: view)
        XCTAssertTrue(labels.contains("UUID"))
        XCTAssertTrue(labels.contains("Checksum"))
    }
}
```

## Further Reading

- <doc:Components>
- <doc:Accessibility>
- <doc:PlatformAdaptation>
- ``CopyableText``
- ``Copyable``
- ``KeyboardShortcuts``
- ``AccessibilityHelpers``

## See Also

- <doc:Components>
- <doc:Accessibility>
- <doc:Modifiers>
- ``CopyableText``
- ``Copyable``
- ``KeyboardShortcuts``
- ``AccessibilityHelpers``
