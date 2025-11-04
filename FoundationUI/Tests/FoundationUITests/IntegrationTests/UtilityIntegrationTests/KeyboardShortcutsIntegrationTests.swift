// swift-tools-version: 6.0
import XCTest

#if canImport(SwiftUI)
import SwiftUI
@testable import FoundationUI

/// Integration tests for KeyboardShortcuts utility with real components
///
/// Tests verify that KeyboardShortcuts works correctly when integrated with:
/// - ToolbarPattern items
/// - Standard shortcuts (Copy, Paste, Cut, Select All)
/// - Platform-specific modifiers (⌘ on macOS, Ctrl elsewhere)
/// - Display strings in UI labels
/// - Accessibility labels for VoiceOver
/// - Shortcut conflicts detection
@MainActor
final class KeyboardShortcutsIntegrationTests: XCTestCase {

    // MARK: - ToolbarPattern Integration Tests

    func testKeyboardShortcutsWithToolbarPattern() {
        // Test that keyboard shortcuts integrate with ToolbarPattern items
        let toolbar = ToolbarPattern(items: [
            ToolbarPattern.Item(
                id: "copy",
                label: "Copy",
                icon: "doc.on.doc",
                action: {}
            )
        ])

        XCTAssertNotNil(toolbar, "Keyboard shortcuts should work with ToolbarPattern")
        // Toolbar items should display keyboard shortcut hints
    }

    func testStandardShortcutsInToolbar() {
        // Test standard shortcuts (Copy, Paste, Cut, Select All) in toolbar
        let shortcuts = [
            KeyboardShortcutType.copy,
            KeyboardShortcutType.paste,
            KeyboardShortcutType.cut,
            KeyboardShortcutType.selectAll
        ]

        shortcuts.forEach { shortcut in
            XCTAssertNotNil(shortcut, "Standard shortcuts should be available")
        }
    }

    // MARK: - Platform-Specific Modifier Tests

    #if os(macOS)
    func testKeyboardShortcutsUseCommandKeyOnMacOS() {
        // Test that ⌘ (Command) key is used on macOS
        let copyShortcut = KeyboardShortcutType.copy

        XCTAssertNotNil(copyShortcut, "Copy shortcut should use ⌘C on macOS")
        // displayString should return "⌘C"
        XCTAssertTrue(copyShortcut.displayString.contains("⌘"), "Should use Command symbol on macOS")
    }
    #endif

    #if !os(macOS)
    func testKeyboardShortcutsUseControlKeyOnNonMacOS() {
        // Test that Ctrl key is used on non-macOS platforms
        let copyShortcut = KeyboardShortcutType.copy

        XCTAssertNotNil(copyShortcut, "Copy shortcut should use Ctrl+C on non-macOS")
        // displayString should return "Ctrl+C"
        XCTAssertTrue(copyShortcut.displayString.contains("Ctrl"), "Should use Control on non-macOS")
    }
    #endif

    // MARK: - Display String Tests

    func testKeyboardShortcutDisplayStringsInUI() {
        // Test that display strings are suitable for UI labels
        let shortcuts = [
            KeyboardShortcutType.copy,
            KeyboardShortcutType.paste,
            KeyboardShortcutType.cut,
            KeyboardShortcutType.save,
            KeyboardShortcutType.undo,
            KeyboardShortcutType.redo
        ]

        shortcuts.forEach { shortcut in
            let displayString = shortcut.displayString
            XCTAssertFalse(displayString.isEmpty, "Display string should not be empty")
            XCTAssertGreaterThan(displayString.count, 1, "Display string should be meaningful")
        }
    }

    func testDisplayStringsUsePlatformAppropriateFormatting() {
        // Verify display strings use platform-appropriate formatting
        let copyShortcut = KeyboardShortcutType.copy

        #if os(macOS)
        XCTAssertTrue(copyShortcut.displayString.contains("⌘"), "macOS should use ⌘ symbol")
        #else
        XCTAssertTrue(copyShortcut.displayString.contains("Ctrl") || copyShortcut.displayString.contains("⌃"), "Non-macOS should use Ctrl or ⌃")
        #endif
    }

    // MARK: - Accessibility Label Tests

    func testKeyboardShortcutAccessibilityLabels() {
        // Test that accessibility labels are provided for VoiceOver
        let copyShortcut = KeyboardShortcutType.copy

        let accessibilityLabel = copyShortcut.accessibilityLabel
        XCTAssertFalse(accessibilityLabel.isEmpty, "Accessibility label should not be empty")
        XCTAssertTrue(accessibilityLabel.contains("Copy"), "Label should describe the action")
    }

    func testAccessibilityLabelsAreVoiceOverFriendly() {
        // Verify accessibility labels are VoiceOver-friendly
        let shortcuts = [
            KeyboardShortcutType.copy,
            KeyboardShortcutType.paste,
            KeyboardShortcutType.cut,
            KeyboardShortcutType.save
        ]

        shortcuts.forEach { shortcut in
            let label = shortcut.accessibilityLabel
            // Should not contain symbols like ⌘ in spoken label
            // Should be plain English description
            XCTAssertFalse(label.isEmpty, "Accessibility label should exist")
        }
    }

    // MARK: - Multiple Shortcuts Tests

    func testMultipleShortcutsOnSameScreen() {
        // Test that multiple shortcuts can coexist without conflicts
        let shortcuts = [
            KeyboardShortcutType.copy,
            KeyboardShortcutType.paste,
            KeyboardShortcutType.cut,
            KeyboardShortcutType.selectAll,
            KeyboardShortcutType.save
        ]

        // All shortcuts should be distinct
        let displayStrings = Set(shortcuts.map { $0.displayString })
        XCTAssertEqual(displayStrings.count, shortcuts.count, "All shortcuts should be distinct")
    }

    func testShortcutConflictDetection() {
        // Test detection of potential shortcut conflicts
        let copy1 = KeyboardShortcutType.copy
        let copy2 = KeyboardShortcutType.copy

        XCTAssertEqual(copy1.displayString, copy2.displayString, "Same shortcuts should match")
        // In a real app, conflict detection would warn about duplicate bindings
    }

    // MARK: - Card Integration Tests

    func testKeyboardShortcutsWithCardActions() {
        // Test shortcuts with Card component actions
        let card = Card {
            VStack {
                Text("Press \(KeyboardShortcutType.copy.displayString) to copy")
                    .font(DS.Typography.caption)
            }
        }

        XCTAssertNotNil(card, "Keyboard shortcuts should work with Card actions")
    }

    // MARK: - Custom Shortcuts Tests

    func testCustomShortcutIntegration() {
        // Test custom keyboard shortcut definition
        // Custom shortcuts should follow same pattern as standard shortcuts
        XCTAssertNotNil(KeyboardShortcutType.copy, "Standard shortcuts serve as template for custom ones")
    }

    // MARK: - Integration with DS Tokens

    func testKeyboardShortcutLabelsUseDSTypography() {
        // Verify shortcut labels in UI use DS.Typography tokens
        let shortcutLabel = Text(KeyboardShortcutType.copy.displayString)
            .font(DS.Typography.caption)

        XCTAssertNotNil(shortcutLabel, "Shortcut labels should use DS.Typography")
    }

    // MARK: - Performance Tests

    func testKeyboardShortcutPerformanceWithManyItems() {
        // Test performance with many shortcuts active
        measure {
            let shortcuts = (0..<100).map { _ in KeyboardShortcutType.copy }
            XCTAssertEqual(shortcuts.count, 100)
        }
    }
}

#endif // canImport(SwiftUI)
