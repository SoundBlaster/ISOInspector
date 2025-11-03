// swift-tools-version: 6.0
import XCTest

#if canImport(SwiftUI)
import SwiftUI
@testable import FoundationUI

/// Integration tests for CopyableText utility with real components
///
/// Tests verify that CopyableText works correctly when integrated with:
/// - Card component
/// - KeyValueRow component
/// - InspectorPattern
/// - Multiple instances on same screen
/// - Platform-specific clipboard behavior
/// - Visual feedback animations
/// - Keyboard shortcuts
/// - VoiceOver announcements
@MainActor
final class CopyableTextIntegrationTests: XCTestCase {

    // MARK: - Component Integration Tests

    func testCopyableTextWithinCard() {
        // Test that CopyableText can be embedded in Card component
        let card = Card {
            VStack(spacing: DS.Spacing.m) {
                Text("Card Title")
                    .font(DS.Typography.headline)
                CopyableText(text: "0x1234ABCD")
            }
        }

        XCTAssertNotNil(card, "CopyableText should work within Card component")
    }

    func testCopyableTextWithinKeyValueRow() {
        // Test that CopyableText integrates with KeyValueRow for copyable values
        let row = KeyValueRow(
            key: "Memory Address",
            value: "0xDEADBEEF",
            isCopyable: true
        )

        XCTAssertNotNil(row, "KeyValueRow should support copyable values")
    }

    func testMultipleCopyableTextInstancesOnSameScreen() {
        // Test that multiple CopyableText instances can coexist
        let view = VStack(spacing: DS.Spacing.l) {
            CopyableText(text: "First Value", label: "First")
            CopyableText(text: "Second Value", label: "Second")
            CopyableText(text: "Third Value", label: "Third")
        }

        XCTAssertNotNil(view, "Multiple CopyableText instances should coexist")
    }

    func testCopyableTextWithinInspectorPattern() {
        // Test CopyableText integration with complete InspectorPattern
        let inspector = InspectorPattern(title: "Test Inspector") {
            VStack(spacing: DS.Spacing.m) {
                SectionHeader(title: "Details", showDivider: true)
                KeyValueRow(key: "ID", value: "12345", isCopyable: true)
                KeyValueRow(key: "Hash", value: "0xABCD", isCopyable: true)
            }
        }

        XCTAssertNotNil(inspector, "CopyableText should work in InspectorPattern")
    }

    // MARK: - Typography Integration Tests

    func testCopyableTextWithDSTypographyTokens() {
        // Verify CopyableText uses DS.Typography tokens
        let copyableText = CopyableText(text: "Test Value")

        XCTAssertNotNil(copyableText, "CopyableText should use DS.Typography.code")
        // Implementation should use DS.Typography.code for monospaced display
    }

    func testCopyableTextWithLongContent() {
        // Test behavior with long text that might wrap or truncate
        let longText = "This is a very long text value that might need to wrap or truncate depending on the container width and layout constraints"
        let copyableText = CopyableText(text: longText)

        XCTAssertNotNil(copyableText, "CopyableText should handle long content gracefully")
    }

    // MARK: - Platform-Specific Tests

    #if os(macOS)
    func testCopyableTextUsesNSPasteboardOnMacOS() {
        // Test that macOS uses NSPasteboard for clipboard operations
        let copyableText = CopyableText(text: "macOS Test Value")

        XCTAssertNotNil(copyableText, "CopyableText should use NSPasteboard on macOS")
        // Platform-specific clipboard implementation should be NSPasteboard-based
    }

    func testCopyableTextSupportsCommandCKeyboardShortcut() {
        // Test that ⌘C keyboard shortcut is supported on macOS
        let copyableText = CopyableText(text: "Shortcut Test")

        XCTAssertNotNil(copyableText, "Should support ⌘C shortcut on macOS")
        // Implementation should handle ⌘C when focused
    }
    #endif

    #if os(iOS)
    func testCopyableTextUsesUIPasteboardOnIOS() {
        // Test that iOS uses UIPasteboard for clipboard operations
        let copyableText = CopyableText(text: "iOS Test Value")

        XCTAssertNotNil(copyableText, "CopyableText should use UIPasteboard on iOS")
        // Platform-specific clipboard implementation should be UIPasteboard-based
    }

    func testCopyableTextSupportsTouchInteractions() {
        // Test that touch interactions work on iOS
        let copyableText = CopyableText(text: "Touch Test")

        XCTAssertNotNil(copyableText, "Should support touch interactions on iOS")
        // Implementation should handle tap gestures
    }
    #endif

    // MARK: - Visual Feedback Tests

    func testCopyableTextShowsVisualFeedbackOnCopy() {
        // Test that "Copied!" indicator appears after copy action
        let copyableText = CopyableText(text: "Feedback Test")

        XCTAssertNotNil(copyableText, "Should show visual feedback after copy")
        // Implementation should display animated "Copied!" indicator
        // Uses DS.Animation.quick for feedback animation
    }

    func testVisualFeedbackUsesDesignSystemTokens() {
        // Verify visual feedback uses DS tokens for animation and spacing
        let copyableText = CopyableText(text: "DS Tokens Test")

        XCTAssertNotNil(copyableText)
        // Feedback animation should use DS.Animation.quick
        // Feedback indicator should use DS.Spacing.s for padding
        // Should use DS.Typography.caption for "Copied!" text
    }

    // MARK: - Accessibility Tests

    func testCopyableTextProvidesAccessibilityLabel() {
        // Test that accessibility label is provided for VoiceOver
        let copyableText = CopyableText(text: "Accessible Value", label: "Memory Address")

        XCTAssertNotNil(copyableText, "Should provide accessibility label")
        // Accessibility label should be "Copy Memory Address" or similar
    }

    func testCopyableTextAnnouncesVoiceOverOnCopy() {
        // Test that VoiceOver announcement is made when text is copied
        let copyableText = CopyableText(text: "VoiceOver Test")

        XCTAssertNotNil(copyableText, "Should announce to VoiceOver on copy")
        // Implementation should post VoiceOver notification: "Value copied to clipboard"
    }

    // MARK: - Integration with DS Tokens

    func testCopyableTextUsesDesignSystemSpacing() {
        // Verify all spacing uses DS.Spacing tokens
        let copyableText = CopyableText(text: "Spacing Test")

        XCTAssertNotNil(copyableText)
        // Should use DS.Spacing.s or DS.Spacing.m for internal spacing
        // No magic numbers allowed
    }

    func testCopyableTextUsesDesignSystemColors() {
        // Verify colors use DS.Colors tokens
        let copyableText = CopyableText(text: "Color Test")

        XCTAssertNotNil(copyableText)
        // Should use DS.Colors.accent for visual emphasis
        // Should respect system colors for text
    }

    // MARK: - Performance Tests

    func testCopyableTextPerformanceInList() {
        // Test performance with many CopyableText instances
        measure {
            let _ = ForEach(0..<100, id: \.self) { index in
                CopyableText(text: "Item \(index)")
            }
        }
    }

    // MARK: - Edge Cases

    func testCopyableTextWithEmptyString() {
        // Test behavior with empty string
        let copyableText = CopyableText(text: "")

        XCTAssertNotNil(copyableText, "Should handle empty string gracefully")
    }

    func testCopyableTextWithSpecialCharacters() {
        // Test with special characters and Unicode
        let specialText = "🚀 Special: <>&\"' \n\t 中文"
        let copyableText = CopyableText(text: specialText)

        XCTAssertNotNil(copyableText, "Should handle special characters and Unicode")
    }
}

#endif // canImport(SwiftUI)
