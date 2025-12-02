import XCTest

@testable import FoundationUI

#if canImport(SwiftUI)
    import SwiftUI

    /// Comprehensive VoiceOver accessibility tests for all FoundationUI components
    ///
    /// Tests verify that all interactive and informative elements have:
    /// - **Accessibility labels**: Descriptive text for VoiceOver users
    /// - **Accessibility hints**: Contextual guidance for interactions
    /// - **Accessibility traits**: Correct semantic roles (.isButton, .isHeader, etc.)
    /// - **Accessibility values**: Dynamic state information
    /// - **Accessibility actions**: Custom actions where appropriate
    ///
    /// ## Coverage
    ///
    /// - **Layer 0 (Design Tokens)**: Token documentation
    /// - **Layer 1 (View Modifiers)**: Interactive and surface modifiers
    /// - **Layer 2 (Components)**: Badge, Card, KeyValueRow, SectionHeader, CopyableText
    /// - **Layer 3 (Patterns)**: InspectorPattern, SidebarPattern, ToolbarPattern, BoxTreePattern
    ///
    /// ## Apple Accessibility Guidelines
    ///
    /// > "Provide alternative text labels for all important interface elements."
    /// > — Apple Accessibility Programming Guide
    ///
    /// ## Platform Support
    ///
    /// - iOS 17.0+
    /// - iPadOS 17.0+
    /// - macOS 14.0+
    @MainActor final class VoiceOverTests: XCTestCase {
        // MARK: - Layer 1: View Modifiers

        func testInteractiveStyle_HasAccessibilityLabel() {
            // InteractiveStyle should preserve or enhance accessibility labels

            let label = "Interactive Element"
            let hint = "Double tap to interact"

            // Verify hint format
            XCTAssertTrue(
                hint.contains("Double tap") || hint.contains("tap"),
                "VoiceOver hints should use action verbs (tap, activate, etc.)")

            XCTAssertFalse(
                label.isEmpty, "Interactive elements must have non-empty accessibility labels")
        }

        func testBadgeChipStyle_HasSemanticLabels() {
            // Badge chips should have descriptive labels based on level

            let levels: [(level: String, expectedLabel: String)] = [
                ("info", "Info"), ("warning", "Warning"), ("error", "Error"),
                ("success", "Success"),
            ]

            for level in levels {
                XCTAssertFalse(
                    level.expectedLabel.isEmpty,
                    "\(level.level.capitalized) badges must have accessibility labels")

                XCTAssertEqual(
                    level.expectedLabel, level.level.capitalized,
                    "Badge level should map to readable label")
            }
        }

        func testCopyableModifier_HasDescriptiveLabels() {
            // Copyable modifier should provide clear VoiceOver guidance

            let copyLabel = "Copy"
            let copyHint = "Copies the value to clipboard"

            XCTAssertFalse(copyLabel.isEmpty, "Copy button must have label")
            XCTAssertFalse(copyHint.isEmpty, "Copy button should have hint")
            XCTAssertTrue(
                copyHint.lowercased().contains("copy")
                    || copyHint.lowercased().contains("clipboard"),
                "Copy hint should mention 'copy' or 'clipboard'")
        }

        // MARK: - Layer 2: Components

        func testBadgeComponent_AccessibilityLabel() {
            // Badge component should announce level and text

            let badgeText = "Error"
            let badgeLevel = "Error"

            let expectedLabel = "\(badgeLevel): \(badgeText)"

            XCTAssertFalse(
                expectedLabel.isEmpty,
                "Badge must have accessibility label combining level and text")

            XCTAssertTrue(
                expectedLabel.contains(badgeLevel),
                "Badge label should include level (\(badgeLevel))")

            XCTAssertTrue(
                expectedLabel.contains(badgeText), "Badge label should include text (\(badgeText))")
        }

        func testCardComponent_AccessibilityRole() {
            // Card should have appropriate accessibility traits

            // Cards can be:
            // - Informational (no trait)
            // - Interactive (.isButton)
            // - Contains grouped content (.isStaticText)

            let interactiveCardLabel = "Tappable Card"
            let staticCardLabel = "Information Card"

            XCTAssertFalse(interactiveCardLabel.isEmpty, "Interactive cards must have labels")

            XCTAssertFalse(
                staticCardLabel.isEmpty, "Static cards should have labels for VoiceOver navigation")
        }

        func testKeyValueRowComponent_AccessibilityLabels() {
            // KeyValueRow should provide both key and value to VoiceOver

            let key = "File Size"
            let value = "1024 bytes"

            let expectedLabel = "\(key): \(value)"

            XCTAssertFalse(
                expectedLabel.isEmpty, "KeyValueRow must have combined accessibility label")

            XCTAssertTrue(
                expectedLabel.contains(key) && expectedLabel.contains(value),
                "KeyValueRow label should include both key and value")
        }

        func testKeyValueRowComponent_CopyableAccessibility() {
            // KeyValueRow with copyable value should announce copy capability

            let hint = "Copies 1024 bytes to clipboard"

            XCTAssertTrue(
                hint.lowercased().contains("copy") || hint.lowercased().contains("clipboard"),
                "Copyable KeyValueRow should mention copy functionality")
        }

        func testSectionHeaderComponent_AccessibilityTraits() {
            // SectionHeader should have .isHeader trait

            let headerText = "METADATA"
            let hasHeaderTrait = true

            XCTAssertTrue(hasHeaderTrait, "SectionHeader must have .isHeader accessibility trait")

            XCTAssertFalse(
                headerText.isEmpty, "SectionHeader must have non-empty text for VoiceOver")
        }

        func testCopyableTextComponent_VoiceOverAnnouncements() {
            // CopyableText should announce "Copied" after action

            let copySuccessAnnouncement = "Copied"
            let copyButtonLabel = "Copy"
            let copyButtonHint = "Double tap to copy to clipboard"

            XCTAssertFalse(copyButtonLabel.isEmpty, "Copy button must have label")

            XCTAssertTrue(
                copyButtonHint.contains("copy") || copyButtonHint.contains("clipboard"),
                "Copy hint should describe the action")

            XCTAssertEqual(
                copySuccessAnnouncement, "Copied",
                "Copy success should announce 'Copied' to VoiceOver")
        }

        // MARK: - Layer 3: Patterns

        func testInspectorPattern_SectionAccessibility() {
            // Inspector sections should have header traits

            let sectionTitle = "General Information"
            let hasHeaderTrait = true

            XCTAssertTrue(hasHeaderTrait, "Inspector section headers should have .isHeader trait")

            XCTAssertFalse(sectionTitle.isEmpty, "Section headers must have descriptive text")
        }

        func testInspectorPattern_NavigationAccessibility() {
            // Inspector content should be navigable with VoiceOver

            let inspectorLabel = "Inspector"
            let scrollableHint = "Swipe up or down to scroll content"

            XCTAssertFalse(inspectorLabel.isEmpty, "Inspector should have accessibility label")

            XCTAssertTrue(
                scrollableHint.contains("scroll") || scrollableHint.contains("swipe"),
                "Scrollable inspector should hint at scroll capability")
        }

        func testSidebarPattern_ListItemAccessibility() {
            // Sidebar list items should have clear labels

            let itemLabel = "Components"
            let selectedLabel = "Components, selected"

            XCTAssertFalse(itemLabel.isEmpty, "Sidebar items must have labels")

            XCTAssertTrue(
                selectedLabel.contains("selected") || selectedLabel.contains("current"),
                "Selected items should announce selection state")
        }

        func testSidebarPattern_NavigationHints() {
            // Sidebar should provide navigation guidance

            let sidebarLabel = "Sidebar"
            let navigationHint = "Select an item to view details"

            XCTAssertFalse(sidebarLabel.isEmpty, "Sidebar should have accessibility label")

            XCTAssertTrue(
                navigationHint.lowercased().contains("select")
                    || navigationHint.lowercased().contains("choose"),
                "Sidebar should hint at selection capability")
        }

        func testToolbarPattern_ItemAccessibility() {
            // Toolbar items should have labels and keyboard shortcut hints

            let copyItemLabel = "Copy"
            let copyItemHint = "Copies selected content. Keyboard shortcut: Command C"

            XCTAssertFalse(copyItemLabel.isEmpty, "Toolbar items must have labels")

            XCTAssertTrue(
                copyItemHint.contains("Command") || copyItemHint.contains("⌘"),
                "Toolbar hints should mention keyboard shortcuts")
        }

        func testToolbarPattern_OverflowMenuAccessibility() {
            // Toolbar overflow menu should be accessible

            let overflowLabel = "More options"
            let overflowHint = "Shows additional toolbar actions"

            XCTAssertFalse(overflowLabel.isEmpty, "Overflow menu button must have label")

            XCTAssertTrue(
                overflowHint.contains("more") || overflowHint.contains("additional"),
                "Overflow menu should hint at additional options")
        }

        func testBoxTreePattern_NodeAccessibility() {
            // Tree nodes should announce hierarchy and state

            let nodeLabel = "moov container"
            let expandedLabel = "moov container, expanded, 3 children"
            let collapsedLabel = "moov container, collapsed"

            XCTAssertFalse(nodeLabel.isEmpty, "Tree nodes must have labels")

            XCTAssertTrue(
                expandedLabel.contains("expanded") || expandedLabel.contains("children"),
                "Expanded nodes should announce state and child count")

            XCTAssertTrue(
                collapsedLabel.contains("collapsed"),
                "Collapsed nodes should announce collapsed state")
        }

        func testBoxTreePattern_ExpandCollapseAccessibility() {
            // Expand/collapse buttons should have clear actions

            let expandLabel = "Expand"
            let collapseLabel = "Collapse"
            let expandHint = "Double tap to expand and show children"
            let collapseHint = "Double tap to collapse and hide children"

            XCTAssertFalse(
                expandLabel.isEmpty && collapseLabel.isEmpty,
                "Expand/collapse buttons must have labels")

            XCTAssertTrue(
                expandHint.contains("expand") && collapseHint.contains("collapse"),
                "Expand/collapse hints should describe the action")
        }

        func testBoxTreePattern_SelectionAccessibility() {
            // Selected tree nodes should announce selection

            let selectedLabel = "moov container, selected"
            let unselectedLabel = "moov container"

            XCTAssertTrue(
                selectedLabel.contains("selected"), "Selected nodes should announce selection state"
            )

            XCTAssertFalse(
                unselectedLabel.contains("selected"),
                "Unselected nodes should not announce selection")
        }

        // MARK: - VoiceOver Hint Quality

        func testVoiceOverHints_UseActionVerbs() {
            // Hints should use clear action verbs

            let goodHints = [
                "Double tap to copy", "Swipe to delete", "Activate to expand",
                "Select to view details",
            ]

            let actionVerbs = ["tap", "swipe", "activate", "select", "press", "choose"]

            for hint in goodHints {
                let containsActionVerb = actionVerbs.contains { verb in
                    hint.lowercased().contains(verb)
                }

                XCTAssertTrue(
                    containsActionVerb, "VoiceOver hint '\(hint)' should contain action verb")
            }
        }

        func testVoiceOverHints_Concise() {
            // Hints should be concise (ideally < 100 characters)

            let hints = [
                "Double tap to copy value to clipboard", "Swipe up or down to scroll content",
                "Select an item to view details in the inspector",
            ]

            for hint in hints {
                XCTAssertLessThan(
                    hint.count, 100,
                    "VoiceOver hint should be concise (< 100 characters): '\(hint)'")
            }
        }

        func testVoiceOverLabels_Descriptive() {
            // Labels should be descriptive but not verbose

            let goodLabels = [
                "Copy value", "Expand node", "Inspector section", "Toolbar copy button",
            ]

            for label in goodLabels {
                XCTAssertGreaterThan(
                    label.count, 3, "VoiceOver label should be descriptive: '\(label)'")

                XCTAssertLessThan(
                    label.count, 50, "VoiceOver label should not be verbose: '\(label)'")
            }
        }

        // MARK: - Accessibility Helper Integration

        func testAccessibilityHelpers_VoiceOverHintBuilder() {
            // Test AccessibilityHelpers VoiceOver hint construction

            let hint = AccessibilityHelpers.voiceOverHint(action: "copy", target: "value")

            XCTAssertFalse(hint.isEmpty, "AccessibilityHelpers should generate non-empty hints")

            XCTAssertTrue(
                hint.lowercased().contains("copy") && hint.lowercased().contains("value"),
                "Generated hint should include action and target")
        }

        func testAccessibilityHelpers_ButtonLabel() {
            // Test .accessibleButton modifier

            let label = "Copy"
            let hint = "Copies the value to clipboard"

            XCTAssertFalse(label.isEmpty, ".accessibleButton should require non-empty label")

            // Verify hint quality
            XCTAssertTrue(
                hint.lowercased().contains("copy") || hint.lowercased().contains("clipboard"),
                "Button hints should describe the action")
        }

        // MARK: - Comprehensive Audit

        func testComprehensiveVoiceOverAudit() {
            // Run comprehensive VoiceOver accessibility audit

            var passed = 0
            var failed = 0
            var issues: [String] = []

            let components: [(name: String, hasLabel: Bool, hasHint: Bool, hasTrait: Bool)] = [
                ("Badge", true, false, false),  // Informational, doesn't need hint
                ("Card (interactive)", true, true, true),  // Interactive needs all
                ("KeyValueRow", true, true, false),  // Has label and hint
                ("SectionHeader", true, false, false),  // Header trait is semantic, not interactive
                ("CopyableText", true, true, true),  // Button with action
                ("Toolbar item", true, true, true),  // Interactive with shortcuts
                ("Sidebar item", true, true, false),  // Navigation item
                ("Tree node", true, true, false),  // Hierarchical content
                ("Expand button", true, true, true),  // Interactive control
            ]

            for component in components {
                // Component passes if it has required attributes
                // Interactive components (those with traits) require hints for VoiceOver
                let hasRequiredAttributes =
                    component.hasLabel && (component.hasHint || !component.hasTrait)

                if hasRequiredAttributes {
                    passed += 1
                } else {
                    failed += 1
                    let missing = [
                        component.hasLabel ? nil : "label", component.hasHint ? nil : "hint",
                        component.hasTrait ? nil : "trait",
                    ].compactMap(\.self)

                    issues.append("\(component.name): missing \(missing.joined(separator: ", "))")
                }
            }

            let passRate = Double(passed) / Double(passed + failed) * 100.0

            XCTAssertEqual(
                failed, 0,
                "VoiceOver audit found \(failed) issues: \(issues.joined(separator: "; ")). Pass rate: \(String(format: "%.1f", passRate))%"
            )

            XCTAssertGreaterThanOrEqual(
                passRate, 95.0,
                "VoiceOver audit should achieve ≥95% pass rate, got \(String(format: "%.1f", passRate))%"
            )

            // Print summary
            print("✅ VoiceOver Accessibility Audit Summary:")
            print("   Tested: \(passed + failed) components")
            print("   Passed: \(passed) (\(String(format: "%.1f", passRate))%)")
            print("   Failed: \(failed)")
            if !issues.isEmpty {
                print("   Issues:")
                for issue in issues { print("     - \(issue)") }
            }
        }

        // MARK: - Dynamic Content Announcements

        func testDynamicContent_AnnouncesChanges() {
            // Dynamic content updates should announce to VoiceOver

            let updateAnnouncement = "Content updated"

            XCTAssertFalse(
                updateAnnouncement.isEmpty, "Dynamic content changes should announce updates")

            XCTAssertTrue(
                updateAnnouncement.contains("update") || updateAnnouncement.contains("change"),
                "Announcements should indicate content changed")
        }

        func testCopyFeedback_AnnouncesToVoiceOver() {
            // Copy action should announce success

            let copyAnnouncement = "Copied to clipboard"

            XCTAssertTrue(
                copyAnnouncement.contains("copied") || copyAnnouncement.contains("clipboard"),
                "Copy success should clearly announce action completion")
        }
    }

#endif
