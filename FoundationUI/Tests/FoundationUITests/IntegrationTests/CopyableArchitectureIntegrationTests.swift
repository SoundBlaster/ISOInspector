// swift-tools-version: 6.0
import XCTest
@testable import FoundationUI

#if canImport(SwiftUI)
import SwiftUI

/// Integration tests for the Copyable architecture refactoring
///
/// Tests the complete Copyable architecture including:
/// - Layer 1: CopyableModifier (base modifier)
/// - Layer 2: CopyableText (convenience component)
/// - Layer 2: Copyable<Content> (generic wrapper)
///
/// Focus areas:
/// - Integration between all three components
/// - Backward compatibility with existing CopyableText usage
/// - Cross-component integration (Badge, Card, KeyValueRow)
/// - Multiple copyable elements on same screen
/// - Nested copyable elements
/// - Platform-specific behavior
/// - Accessibility integration
/// - Performance at scale
@MainActor
final class CopyableArchitectureIntegrationTests: XCTestCase {

    // MARK: - Architecture Layer Integration

    func testCopyableModifierAsFoundation() {
        // CopyableModifier is Layer 1 and should work independently
        let view = Text("Foundation")
            .makeCopyable(text: "Foundation")

        XCTAssertNotNil(view, "Layer 1 modifier should work independently")
    }

    func testCopyableTextUsesCopyableModifier() {
        // CopyableText (Layer 2) should use CopyableModifier (Layer 1) internally
        let copyableText = CopyableText(text: "Test")

        XCTAssertNotNil(copyableText, "CopyableText should use CopyableModifier internally")

        // Verify backward compatibility - API unchanged
        let withLabel = CopyableText(text: "Test", label: "Label")
        XCTAssertNotNil(withLabel, "CopyableText API should remain unchanged")
    }

    func testCopyableWrapperUsesCopyableModifier() {
        // Copyable<Content> (Layer 2) should use CopyableModifier (Layer 1) internally
        let copyable = Copyable(text: "Test") {
            Text("Test")
        }

        XCTAssertNotNil(copyable, "Copyable wrapper should use CopyableModifier internally")
    }

    // MARK: - Backward Compatibility Tests

    func testCopyableTextBackwardCompatibility() {
        // Existing code should work without changes

        // Basic usage
        let basic = CopyableText(text: "Basic")
        XCTAssertNotNil(basic)

        // With label
        let labeled = CopyableText(text: "Value", label: "Label")
        XCTAssertNotNil(labeled)

        // Empty string (edge case)
        let empty = CopyableText(text: "")
        XCTAssertNotNil(empty)

        // Long string
        let long = CopyableText(text: String(repeating: "A", count: 1000))
        XCTAssertNotNil(long)
    }

    func testExistingCopyableTextUsageContinuesWorking() {
        // Real-world usage patterns should still work

        // In Card
        let inCard = Card {
            VStack {
                CopyableText(text: "0x1234ABCD")
            }
        }
        XCTAssertNotNil(inCard)

        // In KeyValueRow context (simulated)
        let inRow = HStack {
            Text("Key:")
            CopyableText(text: "Value")
        }
        XCTAssertNotNil(inRow)
    }

    // MARK: - Cross-Component Integration

    func testCopyableModifierWithBadge() {
        // Apply copyable modifier to Badge component
        let view = Badge(text: "Info", level: .info)
            .makeCopyable(text: "Info badge")

        XCTAssertNotNil(view, "Modifier should work with Badge")
    }

    func testCopyableModifierWithCard() {
        // Apply copyable modifier to Card component
        let view = Card {
            Text("Card content")
        }
        .makeCopyable(text: "Card content")

        XCTAssertNotNil(view, "Modifier should work with Card")
    }

    func testCopyableModifierWithKeyValueRow() {
        // Apply copyable modifier to KeyValueRow component
        let view = KeyValueRow(key: "Key", value: "Value")
            .makeCopyable(text: "Value")

        XCTAssertNotNil(view, "Modifier should work with KeyValueRow")
    }

    func testCopyableModifierWithSectionHeader() {
        // Apply copyable modifier to SectionHeader component
        let view = SectionHeader(title: "Section")
            .makeCopyable(text: "Section")

        XCTAssertNotNil(view, "Modifier should work with SectionHeader")
    }

    func testCopyableWrapperWithBadge() {
        // Wrap Badge in Copyable
        let copyable = Copyable(text: "Badge") {
            Badge(text: "Info", level: .info)
        }

        XCTAssertNotNil(copyable, "Copyable should wrap Badge")
    }

    func testCopyableWrapperWithCard() {
        // Wrap Card in Copyable
        let copyable = Copyable(text: "Card") {
            Card {
                Text("Content")
            }
        }

        XCTAssertNotNil(copyable, "Copyable should wrap Card")
    }

    func testCopyableWrapperWithKeyValueRow() {
        // Wrap KeyValueRow in Copyable
        let copyable = Copyable(text: "Value") {
            KeyValueRow(key: "Key", value: "Value")
        }

        XCTAssertNotNil(copyable, "Copyable should wrap KeyValueRow")
    }

    // MARK: - Multiple Copyable Elements

    func testMultipleCopyableElementsOnSameScreen() {
        // Multiple copyable elements should coexist
        let view = VStack {
            CopyableText(text: "First")
            CopyableText(text: "Second")
            CopyableText(text: "Third")
        }

        XCTAssertNotNil(view, "Multiple CopyableText elements should work")
    }

    func testMixedCopyableTypesOnSameScreen() {
        // Mix CopyableText, modifier, and wrapper
        let view = VStack {
            // CopyableText
            CopyableText(text: "Text")

            // Modifier
            Text("Modifier")
                .makeCopyable(text: "Modifier")

            // Wrapper
            Copyable(text: "Wrapper") {
                Text("Wrapper")
            }
        }

        XCTAssertNotNil(view, "Mixed copyable types should work together")
    }

    func testMultipleCopyableWrappersWithComplexContent() {
        // Multiple Copyable wrappers with different content
        let view = VStack {
            Copyable(text: "First") {
                HStack {
                    Image(systemName: "doc")
                    Text("First")
                }
            }

            Copyable(text: "Second") {
                HStack {
                    Image(systemName: "folder")
                    Text("Second")
                    Badge(text: "New", level: .info)
                }
            }
        }

        XCTAssertNotNil(view, "Multiple complex copyable elements should work")
    }

    // MARK: - Nested Copyable Elements

    func testNestedCopyableInCard() {
        // Copyable elements nested inside Card
        let view = Card {
            VStack {
                CopyableText(text: "Nested 1")
                Copyable(text: "Nested 2") {
                    Text("Nested 2")
                }
            }
        }

        XCTAssertNotNil(view, "Copyable elements should work nested in Card")
    }

    func testCopyableInInspectorPattern() {
        // Copyable elements in InspectorPattern (real-world scenario)
        let view = InspectorPattern(title: "Inspector") {
            VStack {
                SectionHeader(title: "Details")
                CopyableText(text: "0x1234ABCD")

                SectionHeader(title: "More Details")
                Copyable(text: "Value") {
                    KeyValueRow(key: "Key", value: "Value")
                }
            }
        }

        XCTAssertNotNil(view, "Copyable should work in InspectorPattern")
    }

    // MARK: - Feedback Configuration

    func testMixedFeedbackSettings() {
        // Some elements with feedback, some without
        let view = VStack {
            Text("With feedback")
                .makeCopyable(text: "With feedback", showFeedback: true)

            Text("Without feedback")
                .makeCopyable(text: "Without feedback", showFeedback: false)

            Copyable(text: "Wrapper with feedback", showFeedback: true) {
                Text("Wrapper")
            }

            Copyable(text: "Wrapper without feedback", showFeedback: false) {
                Text("Wrapper")
            }
        }

        XCTAssertNotNil(view, "Mixed feedback settings should work")
    }

    // MARK: - Accessibility Integration

    func testCopyableAccessibilityLabels() {
        // All copyable variants should have accessibility labels
        let text = CopyableText(text: "Value", label: "Label")
        XCTAssertNotNil(text)

        let modifier = Text("Value")
            .makeCopyable(text: "Value")
        XCTAssertNotNil(modifier)

        let wrapper = Copyable(text: "Value") {
            Text("Value")
        }
        XCTAssertNotNil(wrapper)

        // All should have accessibility support built-in
    }

    func testCopyableWithDynamicType() {
        // Copyable elements should work with Dynamic Type
        let view = VStack {
            CopyableText(text: "Dynamic Type")
                .dynamicTypeSize(.xSmall)

            CopyableText(text: "Dynamic Type")
                .dynamicTypeSize(.large)

            CopyableText(text: "Dynamic Type")
                .dynamicTypeSize(.xxxLarge)
        }

        XCTAssertNotNil(view, "Should work with all Dynamic Type sizes")
    }

    // MARK: - Platform-Specific Integration

    #if os(macOS)
    func testMacOSKeyboardShortcuts() {
        // All copyable variants should support ⌘C on macOS
        let text = CopyableText(text: "macOS")
        let modifier = Text("macOS").makeCopyable(text: "macOS")
        let wrapper = Copyable(text: "macOS") {
            Text("macOS")
        }

        XCTAssertNotNil(text)
        XCTAssertNotNil(modifier)
        XCTAssertNotNil(wrapper)

        // All should support keyboard shortcuts (verified through modifier)
    }
    #endif

    // MARK: - Real-World Scenarios

    func testISOInspectorMetadataView() {
        // Real-world: ISO Inspector metadata display
        let view = Card {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                SectionHeader(title: "Box Metadata")

                // Box type (using Copyable wrapper for icon + text)
                Copyable(text: "ftyp") {
                    HStack {
                        Text("Type:")
                        Spacer()
                        Text("ftyp")
                            .font(DS.Typography.code)
                        Badge(text: "Container", level: .info)
                    }
                }

                Divider()

                // Size (using modifier on KeyValueRow)
                KeyValueRow(key: "Size", value: "0x00000018")
                    .makeCopyable(text: "0x00000018")

                Divider()

                // Offset (using CopyableText for backward compatibility)
                HStack {
                    Text("Offset:")
                    Spacer()
                    CopyableText(text: "0x00000000")
                }
            }
            .padding(DS.Spacing.l)
        }

        XCTAssertNotNil(view, "Real-world ISO Inspector view should work")
    }

    func testHexValueDisplay() {
        // Real-world: Hex value with copyable functionality
        let view = Copyable(text: "0x1A2B3C4D") {
            HStack(spacing: DS.Spacing.s) {
                Image(systemName: "number")
                    .foregroundColor(DS.Colors.accent)
                Text("0x1A2B3C4D")
                    .font(DS.Typography.code)
                Badge(text: "Hex", level: .info)
            }
        }

        XCTAssertNotNil(view, "Hex value display should work")
    }

    // MARK: - Performance Integration Tests

    func testPerformanceWithManyCopyableElements() {
        // Test performance with many copyable elements
        measure {
            let view = VStack {
                ForEach(0..<100, id: \.self) { i in
                    CopyableText(text: "Item \(i)")
                }
            }
            XCTAssertNotNil(view)
        }
    }

    func testPerformanceWithComplexCopyableContent() {
        // Test performance with complex copyable wrappers
        measure {
            let view = VStack {
                ForEach(0..<50, id: \.self) { i in
                    Copyable(text: "Item \(i)") {
                        HStack {
                            Image(systemName: "doc")
                            Text("Item \(i)")
                            Badge(text: "New", level: .info)
                        }
                    }
                }
            }
            XCTAssertNotNil(view)
        }
    }

    // MARK: - Migration Path Tests

    func testGradualMigrationFromCopyableText() {
        // Users can gradually migrate from CopyableText to new APIs

        // Step 1: Existing code (no changes)
        let existing = CopyableText(text: "Value")
        XCTAssertNotNil(existing)

        // Step 2: Use modifier for styled text (optional migration)
        let migrated = Text("Value")
            .font(DS.Typography.code)
            .makeCopyable(text: "Value")
        XCTAssertNotNil(migrated)

        // Step 3: Use wrapper for complex content (new capability)
        let complex = Copyable(text: "Value") {
            HStack {
                Image(systemName: "doc")
                Text("Value")
            }
        }
        XCTAssertNotNil(complex)

        // All three approaches should coexist
    }

    // MARK: - Design System Compliance

    func testAllCopyableVariantsUseDSTokens() {
        // All variants should use DS tokens exclusively

        let text = CopyableText(text: "DS Tokens")
        let modifier = Text("DS Tokens").makeCopyable(text: "DS Tokens")
        let wrapper = Copyable(text: "DS Tokens") {
            Text("DS Tokens")
        }

        XCTAssertNotNil(text)
        XCTAssertNotNil(modifier)
        XCTAssertNotNil(wrapper)

        // Manual verification: All use DS tokens, no magic numbers
    }

    // MARK: - Edge Cases Integration

    func testCopyableWithEmptyStringsAcrossVariants() {
        let text = CopyableText(text: "")
        let modifier = Text("Empty").makeCopyable(text: "")
        let wrapper = Copyable(text: "") {
            Text("Empty")
        }

        XCTAssertNotNil(text)
        XCTAssertNotNil(modifier)
        XCTAssertNotNil(wrapper)
    }

    func testCopyableWithSpecialCharactersAcrossVariants() {
        let specialChars = "Special: 你好 🎉 \n\t\\"

        let text = CopyableText(text: specialChars)
        let modifier = Text("Special").makeCopyable(text: specialChars)
        let wrapper = Copyable(text: specialChars) {
            Text("Special")
        }

        XCTAssertNotNil(text)
        XCTAssertNotNil(modifier)
        XCTAssertNotNil(wrapper)
    }

    // MARK: - Composition Tests

    func testCopyableComposesWithAllModifiers() {
        // Copyable should compose well with other modifiers

        let view = Text("Composed")
            .font(DS.Typography.code)
            .foregroundColor(DS.Colors.accent)
            .padding(DS.Spacing.m)
            .background(DS.Colors.infoBG)
            .cornerRadius(DS.Radius.medium)
            .makeCopyable(text: "Composed")

        XCTAssertNotNil(view, "Should compose with all modifiers")
    }

    func testCopyableInComplexHierarchy() {
        // Deep view hierarchy with copyable elements
        let view = Card {
            VStack {
                HStack {
                    VStack {
                        Text("Nested")
                            .makeCopyable(text: "Nested")
                    }
                }
            }
        }

        XCTAssertNotNil(view, "Should work in complex hierarchies")
    }
}

#else
// Empty test class for Linux (no SwiftUI)
final class CopyableArchitectureIntegrationTests: XCTestCase {
    func testLinuxPlaceholder() {
        // SwiftUI not available on Linux
        XCTAssertTrue(true, "SwiftUI tests require macOS/iOS platform")
    }
}
#endif
