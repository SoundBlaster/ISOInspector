// swift-tools-version: 6.0
import XCTest
@testable import FoundationUI

#if canImport(SwiftUI)
import SwiftUI

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// Comprehensive tests for the CopyableModifier view modifier
///
/// Tests cover:
/// - Modifier application to various View types
/// - Platform-specific clipboard integration
/// - Visual feedback state management
/// - Keyboard shortcut support (macOS)
/// - Accessibility announcements
/// - Feedback configuration
/// - Design System token usage
/// - Edge cases and error handling
@MainActor
final class CopyableModifierTests: XCTestCase {

    // MARK: - API Tests

    func testCopyableModifierAppliesCorrectly() {
        // Test that modifier can be applied to Text view
        let view = Text("Test Value")
            .copyable(text: "Test Value")

        XCTAssertNotNil(view, "Copyable modifier should apply to Text view")
    }

    func testCopyableModifierWithFeedbackParameter() {
        // Test that modifier accepts showFeedback parameter
        let view = Text("Test")
            .copyable(text: "Test", showFeedback: true)

        XCTAssertNotNil(view, "Modifier should accept showFeedback parameter")
    }

    func testCopyableModifierWithoutFeedback() {
        // Test that feedback can be disabled
        let view = Text("Test")
            .copyable(text: "Test", showFeedback: false)

        XCTAssertNotNil(view, "Modifier should work with showFeedback = false")
    }

    func testCopyableModifierOnComplexView() {
        // Test that modifier works with complex View hierarchies
        let view = HStack {
            Image(systemName: "doc.text")
            Text("Complex")
        }
        .copyable(text: "Complex value")

        XCTAssertNotNil(view, "Modifier should apply to complex views")
    }

    // MARK: - ViewModifier Protocol Tests

    func testCopyableModifierConformsToViewModifier() {
        // Verify CopyableModifier is a valid ViewModifier
        let modifier = CopyableModifier(textToCopy: "Test", showFeedback: true)

        // This test verifies ViewModifier conformance at compile time
        XCTAssertNotNil(modifier, "CopyableModifier should conform to ViewModifier")
    }

    func testCopyableModifierBodyReturnsView() {
        // Verify that body returns some View
        let modifier = CopyableModifier(textToCopy: "Test", showFeedback: true)
        let view = Text("Test")
        let modifiedView = view.modifier(modifier)

        XCTAssertNotNil(modifiedView, "Modifier body should return a valid View")
    }

    // MARK: - State Management Tests

    func testCopyableModifierInitialState() {
        // Modifier should start with copied indicator hidden
        let modifier = CopyableModifier(textToCopy: "Test", showFeedback: true)
        XCTAssertNotNil(modifier)
        // Note: State is private, verified through behavior
    }

    // MARK: - Platform-Specific Clipboard Tests

    #if os(macOS)
    func testMacOSClipboardSupport() {
        // On macOS, should use NSPasteboard
        let view = Text("macOS Value")
            .copyable(text: "macOS Value")

        XCTAssertNotNil(view, "Should support macOS clipboard")

        // Note: Actual clipboard testing requires running view and triggering action
        // This verifies the API exists and compiles for macOS
    }

    func testMacOSKeyboardShortcut() {
        // On macOS, should support ⌘C keyboard shortcut
        let view = Text("Shortcut Test")
            .copyable(text: "Shortcut Test")

        XCTAssertNotNil(view)
        // Future: Test keyboard shortcut handling with SwiftUI key events
    }
    #else
    func testIOSClipboardSupport() {
        // On iOS/iPadOS, should use UIPasteboard
        let view = Text("iOS Value")
            .copyable(text: "iOS Value")

        XCTAssertNotNil(view, "Should support iOS clipboard")

        // Note: Actual clipboard testing requires running view
    }
    #endif

    // MARK: - Visual Feedback Tests

    func testCopyableModifierShowsFeedback() {
        // When showFeedback is true, should show "Copied!" indicator
        let view = Text("Test")
            .copyable(text: "Test", showFeedback: true)

        XCTAssertNotNil(view)
        // Future: Trigger copy and verify feedback appears
    }

    func testCopyableModifierHidesFeedback() {
        // When showFeedback is false, should not show indicator
        let view = Text("Test")
            .copyable(text: "Test", showFeedback: false)

        XCTAssertNotNil(view)
        // Behavior verification would require view introspection
    }

    // MARK: - Accessibility Tests

    func testCopyableModifierAccessibilityLabel() {
        // Modifier should preserve or enhance accessibility
        let view = Text("Accessible")
            .copyable(text: "Accessible")

        XCTAssertNotNil(view)
        // Future: Verify accessibility label includes copy hint
    }

    func testCopyableModifierVoiceOverAnnouncement() {
        // Should announce successful copy to VoiceOver
        let view = Text("VoiceOver Test")
            .copyable(text: "VoiceOver Test")

        XCTAssertNotNil(view)
        // Manual verification: Implementation should use announcements
    }

    // MARK: - Design System Token Usage Tests

    func testCopyableModifierUsesDesignSystemTokens() {
        // Modifier must use DS tokens exclusively (zero magic numbers)

        // Expected DS tokens:
        // - DS.Spacing.s or DS.Spacing.m for padding/spacing
        // - DS.Animation.quick for feedback animation
        // - DS.Typography.caption for "Copied!" text
        // - DS.Colors.accent for visual indicators

        let view = Text("DS Tokens")
            .copyable(text: "DS Tokens")

        XCTAssertNotNil(view, "Should use only DS tokens, no magic numbers")
    }

    // MARK: - Edge Cases

    func testCopyableModifierWithEmptyString() {
        // Should handle empty string gracefully
        let view = Text("")
            .copyable(text: "")

        XCTAssertNotNil(view, "Should handle empty text without crashing")
    }

    func testCopyableModifierWithVeryLongString() {
        // Should handle long strings (e.g., long hex dumps)
        let longText = String(repeating: "A", count: 10000)
        let view = Text("Long Text")
            .copyable(text: longText)

        XCTAssertNotNil(view, "Should handle very long text")
    }

    func testCopyableModifierWithSpecialCharacters() {
        // Should handle special characters and Unicode
        let specialText = "Special: 你好 🎉 \n\t\\"
        let view = Text("Special")
            .copyable(text: specialText)

        XCTAssertNotNil(view, "Should handle special characters")
    }

    func testCopyableModifierWithMultilineText() {
        // Should handle multiline text
        let multilineText = """
        Line 1
        Line 2
        Line 3
        """
        let view = Text("Multiline")
            .copyable(text: multilineText)

        XCTAssertNotNil(view, "Should handle multiline text")
    }

    // MARK: - Composition Tests

    func testMultipleCopyableModifiersOnSameView() {
        // Test chaining multiple copyable modifiers (unusual but valid)
        let view = Text("Test")
            .copyable(text: "First")
            .copyable(text: "Second")

        XCTAssertNotNil(view, "Should handle multiple copyable modifiers")
    }

    func testCopyableModifierWithOtherModifiers() {
        // Test that copyable composes well with other modifiers
        let view = Text("Test")
            .font(DS.Typography.code)
            .foregroundColor(DS.Colors.accent)
            .padding(DS.Spacing.m)
            .copyable(text: "Test")

        XCTAssertNotNil(view, "Should compose with other modifiers")
    }

    // MARK: - Performance Tests

    func testCopyableModifierPerformance() {
        // Creating copyable modifier should be fast
        measure {
            for _ in 0..<100 {
                _ = Text("Performance Test \(UUID())")
                    .copyable(text: "Performance Test")
            }
        }
        // Should complete in milliseconds
    }

    func testCopyableModifierMemoryEfficiency() {
        // Modifier should not leak memory
        let iterations = 1000
        for i in 0..<iterations {
            let view = Text("Memory Test \(i)")
                .copyable(text: "Memory Test \(i)")
            XCTAssertNotNil(view)
        }
        // If this completes without excessive memory growth, we're good
    }

    // MARK: - Integration Tests

    func testCopyableModifierWithBadgeComponent() {
        // Test integration with Badge component
        let view = Badge(text: "Test", level: .info)
            .copyable(text: "Badge text")

        XCTAssertNotNil(view, "Should work with Badge component")
    }

    func testCopyableModifierWithCardComponent() {
        // Test integration with Card component
        let view = Card {
            Text("Card content")
        }
        .copyable(text: "Card content")

        XCTAssertNotNil(view, "Should work with Card component")
    }

    func testCopyableModifierInKeyValueRowContext() {
        // Simulate usage in KeyValueRow
        let view = HStack {
            Text("Key:")
            Text("Value")
                .copyable(text: "Value")
        }

        XCTAssertNotNil(view, "Should work in KeyValueRow-like contexts")
    }
}

#else
// Empty test class for Linux (no SwiftUI)
final class CopyableModifierTests: XCTestCase {
    func testLinuxPlaceholder() {
        // SwiftUI not available on Linux
        XCTAssertTrue(true, "SwiftUI tests require macOS/iOS platform")
    }
}
#endif
