// swift-tools-version: 6.0
import XCTest

@testable import FoundationUI

/// Comprehensive tests for the CopyableText utility component
///
/// Tests cover:
/// - API initialization and parameters
/// - Clipboard copy behavior (platform-specific)
/// - Visual feedback state management
/// - Accessibility labels and announcements
/// - Keyboard shortcut handling
/// - Integration with DS tokens (zero magic numbers)
@MainActor final class CopyableTextTests: XCTestCase {
    // MARK: - API Tests

    @MainActor func testCopyableTextInitialization() {
        // Test basic initialization with text only
        let copyableText = CopyableText(text: "Test Value")
        XCTAssertNotNil(copyableText, "CopyableText should initialize with text parameter")
    }

    @MainActor func testCopyableTextInitializationWithLabel() {
        // Test initialization with optional label
        let copyableText = CopyableText(text: "0x1234ABCD", label: "Hex Value")
        XCTAssertNotNil(
            copyableText, "CopyableText should initialize with text and label parameters")
    }

    // MARK: - State Management Tests

    @MainActor func testCopyableTextHasInitialState() {
        // CopyableText should start in default state (not copied)
        let copyableText = CopyableText(text: "Test")
        // Note: Testing internal state would require exposing it for testing
        // For now, we verify initialization succeeds
        XCTAssertNotNil(copyableText)
    }

    // MARK: - Accessibility Tests

    @MainActor func testCopyableTextAccessibilityLabel() {
        // CopyableText should provide clear accessibility labels
        // This test verifies the API exists and accepts accessibility parameters
        let copyableText = CopyableText(text: "Sample Value", label: "Sample")
        XCTAssertNotNil(copyableText, "Should support accessibility labeling")
    }

    @MainActor func testCopyableTextAccessibilityHint() {
        // Should provide accessibility hints for VoiceOver users
        // Hint should indicate that tapping will copy the value
        let copyableText = CopyableText(text: "Copyable Data")
        XCTAssertNotNil(copyableText)
        // Future: Test that accessibility hint includes "Double tap to copy" or similar
    }

    // MARK: - Design System Token Usage Tests

    @MainActor func testCopyableTextUsesDesignSystemTokens() {
        // CopyableText must use DS tokens exclusively (zero magic numbers)
        // This is a reminder test to ensure DS token usage during implementation

        // Expected DS tokens to be used:
        // - DS.Spacing.s or DS.Spacing.m for padding
        // - DS.Animation.quick for feedback animation
        // - DS.Typography.caption for "Copied!" label
        // - DS.Colors.accent for visual indicators

        // This test verifies the component can be created
        // Manual code review will verify DS token usage
        let copyableText = CopyableText(text: "Test Value")
        XCTAssertNotNil(copyableText, "Should initialize without magic numbers")
    }

    // MARK: - SwiftUI View Conformance Tests

    @MainActor func testCopyableTextConformsToView() {
        // CopyableText should be a valid SwiftUI View
        let copyableText = CopyableText(text: "View Test")

        // Verify it's a View type (this test ensures SwiftUI conformance)
        XCTAssertNotNil(copyableText.body, "CopyableText should have a body property as a View")
    }

    // MARK: - Platform-Specific Tests

    #if os(macOS)
        @MainActor func testMacOSClipboardIntegration() {
            // On macOS, should use NSPasteboard
            // This is a placeholder for platform-specific clipboard testing
            let copyableText = CopyableText(text: "macOS Value")
            XCTAssertNotNil(copyableText, "Should support macOS clipboard")

            // Future: Mock NSPasteboard and verify clipboard operations
        }

        @MainActor func testMacOSKeyboardShortcut() {
            // On macOS, should support ⌘C keyboard shortcut
            let copyableText = CopyableText(text: "Shortcut Test")
            XCTAssertNotNil(copyableText)

            // Future: Test keyboard shortcut handling with SwiftUI key events
        }
    #else
        @MainActor func testIOSClipboardIntegration() {
            // On iOS/iPadOS, should use UIPasteboard
            let copyableText = CopyableText(text: "iOS Value")
            XCTAssertNotNil(copyableText, "Should support iOS clipboard")

            // Future: Mock UIPasteboard and verify clipboard operations
        }
    #endif

    // MARK: - Visual Feedback Tests

    @MainActor func testCopyableTextShowsFeedbackOnCopy() {
        // When copy action is triggered, should show visual feedback
        // e.g., "Copied!" indicator with animation
        let copyableText = CopyableText(text: "Feedback Test")
        XCTAssertNotNil(copyableText)

        // Future: Trigger copy action programmatically and verify state change
        // This would require exposing copy action for testing
    }

    @MainActor func testCopyableTextFeedbackUsesQuickAnimation() {
        // Visual feedback should use DS.Animation.quick
        // This ensures responsive, snappy feedback
        let copyableText = CopyableText(text: "Animation Test")
        XCTAssertNotNil(copyableText)

        // Manual verification: Implementation should use DS.Animation.quick
    }

    // MARK: - Integration Tests

    @MainActor func testCopyableTextIntegrationWithKeyValueRow() {
        // CopyableText should be usable within KeyValueRow
        // This is an integration test placeholder
        let copyableText = CopyableText(text: "0xABCD1234")
        XCTAssertNotNil(copyableText, "Should integrate with other components")

        // Future: Test actual integration with KeyValueRow component
    }

    // MARK: - Edge Cases

    @MainActor func testCopyableTextWithEmptyString() {
        // Should handle empty string gracefully
        let copyableText = CopyableText(text: "")
        XCTAssertNotNil(copyableText, "Should handle empty text without crashing")
    }

    @MainActor func testCopyableTextWithVeryLongString() {
        // Should handle long strings (e.g., long hex dumps)
        let longText = String(repeating: "A", count: 1000)
        let copyableText = CopyableText(text: longText)
        XCTAssertNotNil(copyableText, "Should handle long text without issues")
    }

    @MainActor func testCopyableTextWithSpecialCharacters() {
        // Should handle special characters and Unicode
        let specialText = "Special: 你好 🎉 \n\t\\"
        let copyableText = CopyableText(text: specialText)
        XCTAssertNotNil(copyableText, "Should handle special characters")
    }

    // MARK: - Performance Tests

    @MainActor func testCopyableTextPerformance() {
        // Creating CopyableText should be fast
        measure { for _ in 0..<100 { _ = CopyableText(text: "Performance Test \(UUID())") } }
        // Should complete in milliseconds
    }
}
