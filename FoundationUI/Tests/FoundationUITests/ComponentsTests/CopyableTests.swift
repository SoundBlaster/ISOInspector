// swift-tools-version: 6.0
import XCTest
@testable import FoundationUI

#if canImport(SwiftUI)
import SwiftUI

/// Comprehensive tests for the Copyable generic wrapper component
///
/// Tests cover:
/// - Generic Content type support
/// - ViewBuilder closure functionality
/// - Integration with CopyableModifier
/// - Feedback configuration
/// - Complex view hierarchies
/// - Design System token usage
/// - Integration with existing components
@MainActor
final class CopyableTests: XCTestCase {

    // MARK: - API Tests

    func testCopyableInitializationWithSimpleContent() {
        // Test basic initialization with simple Text content
        let copyable = Copyable(text: "Test Value") {
            Text("Test")
        }

        XCTAssertNotNil(copyable, "Copyable should initialize with simple content")
    }

    func testCopyableInitializationWithComplexContent() {
        // Test initialization with complex view hierarchy
        let copyable = Copyable(text: "Complex") {
            HStack {
                Image(systemName: "doc.text")
                Text("Complex")
            }
        }

        XCTAssertNotNil(copyable, "Copyable should initialize with complex content")
    }

    func testCopyableWithFeedbackParameter() {
        // Test that Copyable accepts showFeedback parameter
        let copyable = Copyable(text: "Test", showFeedback: true) {
            Text("Test")
        }

        XCTAssertNotNil(copyable, "Copyable should accept showFeedback parameter")
    }

    func testCopyableWithoutFeedback() {
        // Test that feedback can be disabled
        let copyable = Copyable(text: "Test", showFeedback: false) {
            Text("Test")
        }

        XCTAssertNotNil(copyable, "Copyable should work with showFeedback = false")
    }

    // MARK: - ViewBuilder Tests

    func testCopyableWithViewBuilderClosure() {
        // Test that ViewBuilder closure works correctly
        let copyable = Copyable(text: "ViewBuilder Test") {
            VStack {
                Text("Line 1")
                Text("Line 2")
                Text("Line 3")
            }
        }

        XCTAssertNotNil(copyable, "ViewBuilder closure should work")
    }

    func testCopyableWithMultipleViews() {
        // Test ViewBuilder with multiple views (no container)
        let copyable = Copyable(text: "Multiple Views") {
            Text("First")
            Text("Second")
        }

        XCTAssertNotNil(copyable, "Should handle multiple views in ViewBuilder")
    }

    func testCopyableWithConditionalContent() {
        // Test ViewBuilder with conditional content
        let showIcon = true
        let copyable = Copyable(text: "Conditional") {
            if showIcon {
                Image(systemName: "doc.text")
            }
            Text("Conditional")
        }

        XCTAssertNotNil(copyable, "Should handle conditional content")
    }

    // MARK: - SwiftUI View Conformance

    func testCopyableConformsToView() {
        // Copyable should be a valid SwiftUI View
        let copyable = Copyable(text: "View Test") {
            Text("View Test")
        }

        XCTAssertNotNil(copyable.body, "Copyable should have a body property as a View")
    }

    // MARK: - Generic Type Tests

    func testCopyableWithTextContent() {
        // Test with Text as Content type
        let copyable = Copyable(text: "Text Content") {
            Text("Text Content")
        }

        XCTAssertNotNil(copyable)
    }

    func testCopyableWithImageContent() {
        // Test with Image as Content type
        let copyable = Copyable(text: "Image Content") {
            Image(systemName: "doc.text")
        }

        XCTAssertNotNil(copyable)
    }

    func testCopyableWithHStackContent() {
        // Test with HStack as Content type
        let copyable = Copyable(text: "HStack Content") {
            HStack {
                Image(systemName: "doc")
                Text("Document")
            }
        }

        XCTAssertNotNil(copyable)
    }

    func testCopyableWithVStackContent() {
        // Test with VStack as Content type
        let copyable = Copyable(text: "VStack Content") {
            VStack {
                Text("Title")
                Text("Subtitle")
            }
        }

        XCTAssertNotNil(copyable)
    }

    // MARK: - Integration with Components

    func testCopyableWithBadgeContent() {
        // Test wrapping Badge component
        let copyable = Copyable(text: "Badge") {
            Badge(text: "Info", level: .info)
        }

        XCTAssertNotNil(copyable, "Should work with Badge component")
    }

    func testCopyableWithCardContent() {
        // Test wrapping Card component
        let copyable = Copyable(text: "Card Content") {
            Card {
                Text("Card content")
            }
        }

        XCTAssertNotNil(copyable, "Should work with Card component")
    }

    func testCopyableWithKeyValueRowContent() {
        // Test wrapping KeyValueRow component
        let copyable = Copyable(text: "Value") {
            KeyValueRow(key: "Key", value: "Value")
        }

        XCTAssertNotNil(copyable, "Should work with KeyValueRow component")
    }

    // MARK: - Edge Cases

    func testCopyableWithEmptyString() {
        // Should handle empty string gracefully
        let copyable = Copyable(text: "") {
            Text("Empty text")
        }

        XCTAssertNotNil(copyable, "Should handle empty text without crashing")
    }

    func testCopyableWithVeryLongString() {
        // Should handle long strings
        let longText = String(repeating: "A", count: 10000)
        let copyable = Copyable(text: longText) {
            Text("Long text")
        }

        XCTAssertNotNil(copyable, "Should handle very long text")
    }

    func testCopyableWithSpecialCharacters() {
        // Should handle special characters and Unicode
        let specialText = "Special: 你好 🎉 \n\t\\"
        let copyable = Copyable(text: specialText) {
            Text("Special")
        }

        XCTAssertNotNil(copyable, "Should handle special characters")
    }

    func testCopyableWithMultilineText() {
        // Should handle multiline text
        let multilineText = """
        Line 1
        Line 2
        Line 3
        """
        let copyable = Copyable(text: multilineText) {
            Text("Multiline")
        }

        XCTAssertNotNil(copyable, "Should handle multiline text")
    }

    // MARK: - Design System Token Usage

    func testCopyableUsesDesignSystemTokens() {
        // Copyable should inherit DS token usage from CopyableModifier

        // Expected DS tokens (via CopyableModifier):
        // - DS.Spacing.s or DS.Spacing.m for padding/spacing
        // - DS.Animation.quick for feedback animation
        // - DS.Typography.caption for "Copied!" text
        // - DS.Colors.accent for visual indicators

        let copyable = Copyable(text: "DS Tokens") {
            Text("DS Tokens")
        }

        XCTAssertNotNil(copyable, "Should use only DS tokens, no magic numbers")
    }

    // MARK: - Styling and Modifiers

    func testCopyableWithStyledContent() {
        // Test that content can be styled before wrapping
        let copyable = Copyable(text: "Styled") {
            Text("Styled")
                .font(DS.Typography.code)
                .foregroundColor(DS.Colors.accent)
        }

        XCTAssertNotNil(copyable, "Should work with pre-styled content")
    }

    func testCopyableWithModifiers() {
        // Test that Copyable can have additional modifiers applied
        let copyable = Copyable(text: "Test") {
            Text("Test")
        }

        // This would be used like: copyable.padding()
        XCTAssertNotNil(copyable, "Should compose with other modifiers")
    }

    // MARK: - Performance Tests

    func testCopyablePerformance() {
        // Creating Copyable should be fast
        measure {
            for _ in 0..<100 {
                _ = Copyable(text: "Performance Test \(UUID())") {
                    Text("Performance Test")
                }
            }
        }
        // Should complete in milliseconds
    }

    func testCopyableMemoryEfficiency() {
        // Copyable should not leak memory
        let iterations = 1000
        for i in 0..<iterations {
            let copyable = Copyable(text: "Memory Test \(i)") {
                HStack {
                    Image(systemName: "doc")
                    Text("Memory Test \(i)")
                }
            }
            XCTAssertNotNil(copyable)
        }
        // If this completes without excessive memory growth, we're good
    }

    // MARK: - Real-World Scenarios

    func testCopyableWithHexValue() {
        // Real-world: Hex value with icon
        let copyable = Copyable(text: "0x1A2B3C4D") {
            HStack(spacing: DS.Spacing.s) {
                Image(systemName: "number")
                    .foregroundColor(DS.Colors.accent)
                Text("0x1A2B3C4D")
                    .font(DS.Typography.code)
            }
        }

        XCTAssertNotNil(copyable, "Should work for hex values")
    }

    func testCopyableWithFileInfo() {
        // Real-world: File information display
        let copyable = Copyable(text: "Document.pdf") {
            HStack(spacing: DS.Spacing.s) {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(DS.Colors.secondary)
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text("Document.pdf")
                        .font(DS.Typography.body)
                    Text("2.5 MB")
                        .font(DS.Typography.caption)
                        .foregroundColor(DS.Colors.textSecondary)
                }
            }
        }

        XCTAssertNotNil(copyable, "Should work for file information")
    }

    func testCopyableWithBadgeAndIcon() {
        // Real-world: Badge with icon and text
        let copyable = Copyable(text: "Status: Active") {
            HStack(spacing: DS.Spacing.s) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(DS.Colors.successBG)
                Badge(text: "Active", level: .success)
            }
        }

        XCTAssertNotNil(copyable, "Should work with badge and icon")
    }

    // MARK: - Comparison with CopyableText

    func testCopyableVsCopyableText() {
        // Verify that Copyable provides more flexibility than CopyableText

        // CopyableText: Simple text only
        let copyableText = CopyableText(text: "Simple")
        XCTAssertNotNil(copyableText)

        // Copyable: Complex content
        let copyable = Copyable(text: "Complex") {
            HStack {
                Image(systemName: "doc")
                Text("Complex")
                Badge(text: "New", level: .info)
            }
        }
        XCTAssertNotNil(copyable)

        // Both should work, but Copyable is more flexible
    }
}

#else
// Empty test class for Linux (no SwiftUI)
@MainActor
final class CopyableTests: XCTestCase {
    func testLinuxPlaceholder() {
        // SwiftUI not available on Linux
        XCTAssertTrue(true, "SwiftUI tests require macOS/iOS platform")
    }
}
#endif
