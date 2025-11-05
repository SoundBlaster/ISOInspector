# Phase 4.3: Implement CopyableModifier (Layer 1)

## 🎯 Objective

Create a universal `.copyable()` view modifier that adds copy-to-clipboard functionality to any SwiftUI View, following SwiftUI best practices and FoundationUI's Composable Clarity Design System.

## 🧩 Context

- **Phase**: Phase 4.3 - Copyable Architecture Refactoring
- **Layer**: Layer 1 (View Modifiers)
- **Priority**: P2 (Architecture Enhancement)
- **Dependencies**:
  - ✅ Phase 1: Design Tokens (DS) complete
  - ✅ Phase 4.2: CopyableText utility complete
- **Estimated Effort**: 4-6 hours

## ✅ Success Criteria

- [ ] `CopyableModifier` struct implemented with ViewModifier protocol
- [ ] `.copyable(text:showFeedback:)` view extension created
- [ ] Platform-specific clipboard logic (NSPasteboard for macOS, UIPasteboard for iOS)
- [ ] Visual feedback with "Copied!" indicator using DS tokens
- [ ] Keyboard shortcut support (⌘C on macOS)
- [ ] VoiceOver announcements for accessibility
- [ ] Unit tests written and passing (≥20 test cases)
- [ ] Implementation follows DS token usage (zero magic numbers)
- [ ] SwiftUI Preview included (≥3 previews)
- [ ] DocC documentation complete (100% API coverage)
- [ ] SwiftLint reports 0 violations
- [ ] Platform support verified (iOS/macOS/iPadOS)

## 🔧 Implementation Notes

### Architecture Pattern

Following SwiftUI's modifier-based pattern (like `.padding()`, `.background()`), create a composable modifier that can be applied to any View:

```swift
Text("Value")
    .font(DS.Typography.code)
    .copyable(text: "Value")
```

### Files to Create

- `FoundationUI/Sources/FoundationUI/Modifiers/CopyableModifier.swift`
- `FoundationUI/Tests/FoundationUITests/ModifiersTests/CopyableModifierTests.swift`

### Key Components

1. **CopyableModifier struct**: ViewModifier implementation
   - `textToCopy: String` - Text to copy to clipboard
   - `showFeedback: Bool` - Whether to show visual feedback
   - `@State showCopiedIndicator: Bool` - State for feedback animation

2. **View extension**: Convenience method
   - `func copyable(text: String, showFeedback: Bool = true) -> some View`

3. **Platform-specific clipboard**:
   ```swift
   #if os(macOS)
   NSPasteboard.general.clearContents()
   NSPasteboard.general.setString(text, forType: .string)
   #else
   UIPasteboard.general.string = text
   #endif
   ```

4. **Visual feedback**: Overlay with DS tokens
   - Background: `DS.Colors.successBG`
   - Text: `DS.Typography.caption`
   - Padding: `DS.Spacing.s`
   - Radius: `DS.Radius.small`
   - Animation: `DS.Animation.quick`

### Design Token Usage

- **Spacing**: `DS.Spacing.s` (8pt), `DS.Spacing.m` (12pt)
- **Colors**: `DS.Colors.successBG`, `DS.Colors.textPrimary`
- **Typography**: `DS.Typography.caption`, `DS.Typography.code`
- **Radius**: `DS.Radius.small` (6pt)
- **Animation**: `DS.Animation.quick` (0.15s), `DS.Animation.medium` (0.25s)

### Accessibility

- VoiceOver announcement: `UIAccessibility.post(notification: .announcement, argument: "Copied")`
- macOS: `NSAccessibility.post(element: self, notification: .announcementRequested)`
- Keyboard shortcut: `.keyboardShortcut("c", modifiers: .command)` (macOS only)

### Test Coverage Requirements

**Unit Tests** (≥20 test cases):
- Modifier applies correctly to Text views
- Modifier applies correctly to complex views (HStack, VStack)
- Platform-specific clipboard integration (macOS/iOS)
- Visual feedback appears and disappears correctly
- Feedback animation timing (should disappear after ~2 seconds)
- Keyboard shortcut works (⌘C on macOS)
- VoiceOver announcements (platform-specific)
- Feedback can be disabled (`showFeedback: false`)
- Multiple copyable views on same screen
- State management (no memory leaks)
- Edge cases: empty string, very long string (>1000 chars)

**SwiftUI Previews** (≥3 previews):
- Simple Text with modifier
- Complex view (HStack with icon) with modifier
- Multiple copyable elements
- Dark mode variant
- Platform comparison (macOS vs iOS)

## 🧠 Source References

- [FoundationUI Task Plan § Phase 4.3](../../../DOCS/AI/ISOViewer/FoundationUI_TaskPlan.md#43-copyable-architecture-refactoring)
- [PRD: Copyable Architecture](../../PRD_CopyableArchitecture.md)
- [Apple SwiftUI ViewModifier](https://developer.apple.com/documentation/swiftui/viewmodifier)
- [Apple Human Interface Guidelines - Clipboard](https://developer.apple.com/design/human-interface-guidelines/patterns/managing-data/)
- [Existing CopyableText implementation](../../../Sources/FoundationUI/Utilities/CopyableText.swift)

## 📋 Checklist

### Phase 1: Implementation
- [ ] Read PRD and understand architecture requirements
- [ ] Study existing CopyableText implementation
- [ ] Create `CopyableModifier.swift` file
- [ ] Implement `CopyableModifier` struct with ViewModifier protocol
- [ ] Add platform-specific clipboard logic (`#if os(macOS)`)
- [ ] Implement visual feedback with DS tokens
- [ ] Add keyboard shortcut support (macOS)
- [ ] Create View extension `.copyable(text:showFeedback:)`
- [ ] Run `swift build` to verify compilation

### Phase 2: Testing
- [ ] Create `CopyableModifierTests.swift` file
- [ ] Write failing unit tests (TDD approach)
- [ ] Run `swift test` to confirm failures
- [ ] Implement code to pass tests
- [ ] Add platform-specific tests (macOS/iOS)
- [ ] Add accessibility tests (VoiceOver)
- [ ] Add edge case tests
- [ ] Verify ≥20 test cases implemented
- [ ] Run `swift test` to confirm all tests pass

### Phase 3: Previews & Documentation
- [ ] Add SwiftUI Previews (≥3 variations)
- [ ] Add DocC triple-slash comments (`///`)
- [ ] Document all parameters with examples
- [ ] Add usage examples in documentation
- [ ] Add "See Also" references to CopyableText
- [ ] Verify preview compilation in Xcode

### Phase 4: Quality Assurance
- [ ] Run `swiftlint` to check for violations (target: 0)
- [ ] Fix any SwiftLint violations
- [ ] Verify zero magic numbers (100% DS token usage)
- [ ] Test on iOS simulator
- [ ] Test on macOS
- [ ] Test Dark Mode on both platforms
- [ ] Test VoiceOver on iOS
- [ ] Test keyboard shortcuts on macOS

### Phase 5: Integration
- [ ] Update Task Plan with [x] completion mark
- [ ] Create task archive directory
- [ ] Document implementation decisions
- [ ] Prepare for next task (Refactor CopyableText)
- [ ] Commit with descriptive message

## 🚀 Next Steps After Completion

After completing this task, proceed to:

**Phase 4.3 Task 2**: Refactor CopyableText component to use CopyableModifier internally, maintaining 100% backward compatibility.

## 📊 Related Tasks

- Phase 4.3 Task 2: Refactor CopyableText component
- Phase 4.3 Task 3: Implement Copyable generic wrapper
- Phase 4.3 Task 4: Copyable architecture integration tests
- Phase 4.3 Task 5: Copyable architecture documentation

## 🔍 Implementation References

### Example Structure

```swift
// FoundationUI/Sources/FoundationUI/Modifiers/CopyableModifier.swift

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// View modifier that adds copy-to-clipboard functionality to any view.
///
/// Use this modifier to make any SwiftUI view copyable with a single tap or click.
/// The modifier provides visual feedback and platform-specific clipboard integration.
///
/// ## Usage
///
/// ```swift
/// Text("Value to copy")
///     .font(DS.Typography.code)
///     .copyable(text: "Value to copy")
/// ```
///
/// You can disable visual feedback if needed:
///
/// ```swift
/// Text("Silent copy")
///     .copyable(text: "Silent copy", showFeedback: false)
/// ```
///
/// ## Accessibility
///
/// The modifier automatically announces "Copied" to VoiceOver users when content is copied.
/// On macOS, keyboard shortcuts (⌘C) are supported.
///
/// ## Platform Support
///
/// - iOS 17+
/// - iPadOS 17+
/// - macOS 14+
///
/// - SeeAlso: `CopyableText`
/// - SeeAlso: `Copyable`
public struct CopyableModifier: ViewModifier {
    // Implementation here
}

public extension View {
    /// Adds copy-to-clipboard functionality to any view.
    ///
    /// - Parameters:
    ///   - text: The text to copy to the clipboard
    ///   - showFeedback: Whether to show visual "Copied!" feedback (default: true)
    /// - Returns: A view with copy functionality
    func copyable(text: String, showFeedback: Bool = true) -> some View {
        modifier(CopyableModifier(textToCopy: text, showFeedback: showFeedback))
    }
}
```

## ⚠️ Important Notes

- **Zero magic numbers**: All spacing, colors, fonts must use DS tokens
- **Platform-specific code**: Use `#if os(macOS)` for platform differences
- **Accessibility first**: VoiceOver announcements are required, not optional
- **Test-driven**: Write tests before implementation (TDD workflow)
- **Documentation**: Every public API must have DocC comments

---

**Status**: ⏳ Ready to Start
**Created**: 2025-11-05
**Last Updated**: 2025-11-05
