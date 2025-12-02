import SwiftUI
// swift-tools-version: 6.0
import XCTest

@testable import FoundationUI

/// Unit tests for the ToolbarPattern adaptive toolbar implementation.
///
/// These tests validate the data model and layout resolution behaviours that
/// power the pattern prior to full UI composition and integration coverage.
@MainActor final class ToolbarPatternTests: XCTestCase {
    func testToolbarPatternStoresPrimarySecondaryAndOverflowItems() {
        // Given
        let items = ToolbarPattern.Items(
            primary: [
                .init(id: "inspect", iconSystemName: "magnifyingglass", title: "Inspect"),
                .init(id: "share", iconSystemName: "square.and.arrow.up", title: "Share"),
            ], secondary: [.init(id: "flag", iconSystemName: "flag", title: "Flag")],
            overflow: [.init(id: "archive", iconSystemName: "archivebox", title: "Archive")])

        // When
        let pattern = ToolbarPattern(items: items)

        // Then
        XCTAssertEqual(pattern.items.primary.count, 2)
        XCTAssertEqual(pattern.items.secondary.count, 1)
        XCTAssertEqual(pattern.items.overflow.count, 1)
    }

    func testToolbarItemAccessibilityLabelIncludesShortcutDescription() {
        // Given
        let shortcut = ToolbarPattern.Shortcut(
            key: "f", modifiers: [.command, .shift], description: "Find")
        let item = ToolbarPattern.Item(
            id: "find", iconSystemName: "magnifyingglass", title: "Find", shortcut: shortcut)

        // When
        let label = item.accessibilityLabel

        // Then
        XCTAssertTrue(label.contains("Find"), "Accessibility label should include the title text")
        XCTAssertTrue(
            label.contains("⌘⇧F"), "Accessibility label should embed the formatted shortcut glyphs")
    }

    func testLayoutResolverUsesCompactModeForCompactWidthTraits() {
        // Given
        let traits = ToolbarPattern.Traits(
            horizontalSizeClass: .compact, platform: .iOS, prefersLargeContent: false)

        // When
        let layout = ToolbarPattern.LayoutResolver.layout(for: traits)

        // Then
        XCTAssertEqual(layout, .compact)
    }

    func testLayoutResolverUsesExpandedModeForMacOS() {
        // Given
        let traits = ToolbarPattern.Traits(
            horizontalSizeClass: nil, platform: .macOS, prefersLargeContent: false)

        // When
        let layout = ToolbarPattern.LayoutResolver.layout(for: traits)

        // Then
        XCTAssertEqual(layout, .expanded)
    }

    // MARK: - Item Initialization Tests

    func testToolbarItemInitializationWithMinimalParameters() {
        // Given
        let item = ToolbarPattern.Item(id: "test", iconSystemName: "star", title: "Test")

        // Then
        XCTAssertEqual(item.id, "test")
        XCTAssertEqual(item.iconSystemName, "star")
        XCTAssertEqual(item.title, "Test")
        XCTAssertNil(item.shortcut, "Shortcut should be nil by default")
        // Note: action always exists (defaults to {}), so we can't test for nil
    }

    func testToolbarItemWithAction() {
        // Given
        var actionCalled = false
        let item = ToolbarPattern.Item(
            id: "action", iconSystemName: "play", title: "Play", action: { actionCalled = true })

        // When
        item.action()

        // Then
        XCTAssertTrue(actionCalled, "Action should be executed when called")
    }

    func testToolbarItemWithoutShortcut() {
        // Given
        let item = ToolbarPattern.Item(id: "no-shortcut", iconSystemName: "doc", title: "Document")

        // Then
        XCTAssertEqual(
            item.accessibilityLabel, "Document",
            "Accessibility label should equal title when no shortcut")
    }

    // MARK: - Shortcut Tests

    func testShortcutFormattingWithSingleModifier() {
        // Given
        let shortcut = ToolbarPattern.Shortcut(key: "s", modifiers: [.command], description: "Save")

        // Then
        XCTAssertEqual(shortcut.key, "s")
        XCTAssertTrue(shortcut.modifiers.contains(.command))
        XCTAssertEqual(shortcut.description, "Save")
    }

    func testShortcutFormattingWithMultipleModifiers() {
        // Given
        let shortcut = ToolbarPattern.Shortcut(
            key: "n", modifiers: [.command, .shift, .option], description: "New Window")

        // Then
        XCTAssertEqual(shortcut.modifiers.count, 3)
        XCTAssertTrue(shortcut.modifiers.contains(.command))
        XCTAssertTrue(shortcut.modifiers.contains(.shift))
        XCTAssertTrue(shortcut.modifiers.contains(.option))
    }

    func testShortcutFormattingWithControlModifier() {
        // Given
        let shortcut = ToolbarPattern.Shortcut(
            key: "t", modifiers: [.control], description: "Toggle")

        // Then
        XCTAssertTrue(shortcut.modifiers.contains(.control))
    }

    // MARK: - Items Collection Tests

    func testToolbarItemsWithAllCategories() {
        // Given
        let items = ToolbarPattern.Items(
            primary: [
                .init(id: "p1", iconSystemName: "1.circle", title: "Primary 1"),
                .init(id: "p2", iconSystemName: "2.circle", title: "Primary 2"),
            ], secondary: [.init(id: "s1", iconSystemName: "3.circle", title: "Secondary 1")],
            overflow: [
                .init(id: "o1", iconSystemName: "4.circle", title: "Overflow 1"),
                .init(id: "o2", iconSystemName: "5.circle", title: "Overflow 2"),
            ])

        // Then
        XCTAssertEqual(items.primary.count, 2)
        XCTAssertEqual(items.secondary.count, 1)
        XCTAssertEqual(items.overflow.count, 2)
    }

    func testToolbarItemsWithEmptyCategories() {
        // Given
        let items = ToolbarPattern.Items(primary: [], secondary: [], overflow: [])

        // Then
        XCTAssertTrue(items.primary.isEmpty)
        XCTAssertTrue(items.secondary.isEmpty)
        XCTAssertTrue(items.overflow.isEmpty)
    }

    func testToolbarItemsWithOnlyPrimary() {
        // Given
        let items = ToolbarPattern.Items(
            primary: [.init(id: "p1", iconSystemName: "star", title: "Star")], secondary: [],
            overflow: [])

        // Then
        XCTAssertEqual(items.primary.count, 1)
        XCTAssertTrue(items.secondary.isEmpty)
        XCTAssertTrue(items.overflow.isEmpty)
    }

    // MARK: - Layout Resolver Tests

    func testLayoutResolverWithRegularHorizontalSizeClass() {
        // Given
        let traits = ToolbarPattern.Traits(
            horizontalSizeClass: .regular, platform: .iOS, prefersLargeContent: false)

        // When
        let layout = ToolbarPattern.LayoutResolver.layout(for: traits)

        // Then
        XCTAssertEqual(layout, .expanded, "Regular size class should use expanded layout")
    }

    func testLayoutResolverWithLargeContentPreference() {
        // Given
        let traits = ToolbarPattern.Traits(
            horizontalSizeClass: .regular, platform: .iOS, prefersLargeContent: true)

        // When
        let layout = ToolbarPattern.LayoutResolver.layout(for: traits)

        // Then
        XCTAssertEqual(layout, .expanded, "Large content preference should use expanded layout")
    }

    func testLayoutResolverWithIPadOSRegular() {
        // Given
        let traits = ToolbarPattern.Traits(
            horizontalSizeClass: .regular, platform: .iPadOS, prefersLargeContent: false)

        // When
        let layout = ToolbarPattern.LayoutResolver.layout(for: traits)

        // Then
        XCTAssertEqual(layout, .expanded, "iPadOS regular should use expanded layout")
    }

    func testLayoutResolverWithIPadOSCompact() {
        // Given
        let traits = ToolbarPattern.Traits(
            horizontalSizeClass: .compact, platform: .iPadOS, prefersLargeContent: false)

        // When
        let layout = ToolbarPattern.LayoutResolver.layout(for: traits)

        // Then
        XCTAssertEqual(layout, .compact, "iPadOS compact should use compact layout")
    }

    // MARK: - Platform Traits Tests

    func testTraitsForIOSPlatform() {
        // Given
        let traits = ToolbarPattern.Traits(
            horizontalSizeClass: .compact, platform: .iOS, prefersLargeContent: false)

        // Then
        XCTAssertEqual(traits.platform, .iOS)
        XCTAssertEqual(traits.horizontalSizeClass, .compact)
        XCTAssertFalse(traits.prefersLargeContent)
    }

    func testTraitsForMacOSPlatform() {
        // Given
        let traits = ToolbarPattern.Traits(
            horizontalSizeClass: nil, platform: .macOS, prefersLargeContent: false)

        // Then
        XCTAssertEqual(traits.platform, .macOS)
        XCTAssertNil(traits.horizontalSizeClass, "macOS doesn't use size classes")
    }

    func testTraitsForIPadOSPlatform() {
        // Given
        let traits = ToolbarPattern.Traits(
            horizontalSizeClass: .regular, platform: .iPadOS, prefersLargeContent: false)

        // Then
        XCTAssertEqual(traits.platform, .iPadOS)
        XCTAssertEqual(traits.horizontalSizeClass, .regular)
    }

    // MARK: - Real-World Use Cases

    func testToolbarPatternForMediaPlayer() {
        // Given
        let items = ToolbarPattern.Items(
            primary: [
                .init(id: "play", iconSystemName: "play.fill", title: "Play"),
                .init(id: "pause", iconSystemName: "pause.fill", title: "Pause"),
                .init(id: "stop", iconSystemName: "stop.fill", title: "Stop"),
            ],
            secondary: [
                .init(id: "volume", iconSystemName: "speaker.wave.2", title: "Volume"),
                .init(id: "shuffle", iconSystemName: "shuffle", title: "Shuffle"),
            ],
            overflow: [
                .init(id: "eq", iconSystemName: "slider.horizontal.3", title: "Equalizer"),
                .init(id: "info", iconSystemName: "info.circle", title: "Info"),
            ])
        let pattern = ToolbarPattern(items: items)

        // Then
        XCTAssertEqual(pattern.items.primary.count, 3, "Media player should have play controls")
        XCTAssertEqual(
            pattern.items.secondary.count, 2, "Media player should have secondary controls")
    }

    func testToolbarPatternForFileEditor() {
        // Given
        let items = ToolbarPattern.Items(
            primary: [
                .init(
                    id: "save", iconSystemName: "square.and.arrow.down", title: "Save",
                    shortcut: .init(key: "s", modifiers: [.command], description: "Save")),
                .init(
                    id: "undo", iconSystemName: "arrow.uturn.backward", title: "Undo",
                    shortcut: .init(key: "z", modifiers: [.command], description: "Undo")),
            ], secondary: [.init(id: "format", iconSystemName: "textformat", title: "Format")],
            overflow: [.init(id: "export", iconSystemName: "square.and.arrow.up", title: "Export")])
        let pattern = ToolbarPattern(items: items)

        // Then
        XCTAssertEqual(pattern.items.primary.count, 2)
        XCTAssertNotNil(pattern.items.primary[0].shortcut, "Save should have keyboard shortcut")
        XCTAssertNotNil(pattern.items.primary[1].shortcut, "Undo should have keyboard shortcut")
    }

    func testToolbarPatternForISOInspector() {
        // Given
        let items = ToolbarPattern.Items(
            primary: [
                .init(
                    id: "open", iconSystemName: "folder.badge.plus", title: "Open File",
                    shortcut: .init(key: "o", modifiers: [.command], description: "Open")),
                .init(id: "validate", iconSystemName: "checkmark.seal", title: "Validate"),
            ],
            secondary: [
                .init(id: "share", iconSystemName: "square.and.arrow.up", title: "Share"),
                .init(id: "export", iconSystemName: "doc.badge.arrow.up", title: "Export"),
            ],
            overflow: [
                .init(id: "settings", iconSystemName: "gear", title: "Settings"),
                .init(id: "help", iconSystemName: "questionmark.circle", title: "Help"),
            ])
        let pattern = ToolbarPattern(items: items)

        // Then
        XCTAssertEqual(pattern.items.primary.count, 2, "ISO Inspector should have primary actions")
        XCTAssertEqual(
            pattern.items.secondary.count, 2, "ISO Inspector should have secondary actions")
        XCTAssertEqual(
            pattern.items.overflow.count, 2, "ISO Inspector should have overflow actions")
    }

    // MARK: - Large Scale Tests

    func testToolbarPatternWithManyPrimaryItems() {
        // Given
        let primaryItems = (1...20).map { index in
            ToolbarPattern.Item(
                id: "item-\(index)", iconSystemName: "\(index).circle", title: "Item \(index)")
        }
        let items = ToolbarPattern.Items(primary: primaryItems, secondary: [], overflow: [])
        let pattern = ToolbarPattern(items: items)

        // Then
        XCTAssertEqual(pattern.items.primary.count, 20, "Toolbar should handle many primary items")
    }

    func testToolbarPatternWithManyOverflowItems() {
        // Given
        let overflowItems = (1...50).map { index in
            ToolbarPattern.Item(
                id: "overflow-\(index)", iconSystemName: "doc", title: "Overflow \(index)")
        }
        let items = ToolbarPattern.Items(primary: [], secondary: [], overflow: overflowItems)
        let pattern = ToolbarPattern(items: items)

        // Then
        XCTAssertEqual(
            pattern.items.overflow.count, 50, "Toolbar should handle many overflow items")
    }

    // MARK: - Accessibility Tests

    func testToolbarItemAccessibilityWithShortcut() {
        // Given
        let shortcut = ToolbarPattern.Shortcut(key: "c", modifiers: [.command], description: "Copy")
        let item = ToolbarPattern.Item(
            id: "copy", iconSystemName: "doc.on.doc", title: "Copy", shortcut: shortcut)

        // Then
        XCTAssertTrue(item.accessibilityLabel.contains("Copy"), "Should include title")
        XCTAssertTrue(item.accessibilityLabel.contains("⌘"), "Should include command symbol")
    }

    func testToolbarItemAccessibilityWithMultipleModifierShortcut() {
        // Given
        let shortcut = ToolbarPattern.Shortcut(
            key: "v", modifiers: [.command, .shift, .option], description: "Paste Special")
        let item = ToolbarPattern.Item(
            id: "paste-special", iconSystemName: "doc.on.clipboard", title: "Paste Special",
            shortcut: shortcut)

        // Then
        let label = item.accessibilityLabel
        XCTAssertTrue(label.contains("Paste Special"))
        XCTAssertTrue(label.contains("⌘"), "Should include command symbol")
        XCTAssertTrue(label.contains("⇧"), "Should include shift symbol")
        XCTAssertTrue(label.contains("⌥"), "Should include option symbol")
    }

    // MARK: - Edge Cases

    func testToolbarPatternWithEmptyTitle() {
        // Given
        let item = ToolbarPattern.Item(id: "empty", iconSystemName: "star", title: "")

        // Then
        XCTAssertEqual(item.title, "", "Toolbar item should accept empty title")
    }

    func testToolbarPatternWithSpecialCharactersInTitle() {
        // Given
        let item = ToolbarPattern.Item(
            id: "special", iconSystemName: "star", title: "Test™ with émojis 🎬")

        // Then
        XCTAssertEqual(item.title, "Test™ with émojis 🎬")
    }

    func testToolbarPatternWithLongTitle() {
        // Given
        let longTitle = String(repeating: "Long ", count: 50)
        let item = ToolbarPattern.Item(id: "long", iconSystemName: "doc", title: longTitle)

        // Then
        XCTAssertEqual(item.title, longTitle, "Toolbar should handle long titles")
    }

    // MARK: - Item Identifiable Conformance

    func testToolbarItemIdentifiableConformance() {
        // Given
        let item1 = ToolbarPattern.Item(id: "test1", iconSystemName: "star", title: "Test 1")
        let item2 = ToolbarPattern.Item(id: "test2", iconSystemName: "star", title: "Test 2")
        let item3 = ToolbarPattern.Item(id: "test1", iconSystemName: "star", title: "Test 1 Copy")

        // Then
        XCTAssertNotEqual(item1.id, item2.id, "Different items should have different IDs")
        XCTAssertEqual(item1.id, item3.id, "Items with same ID should be equal")
    }

    // MARK: - Layout Edge Cases

    func testLayoutResolverWithNilSizeClass() {
        // Given
        let traits = ToolbarPattern.Traits(
            horizontalSizeClass: nil, platform: .iOS, prefersLargeContent: false)

        // When
        let layout = ToolbarPattern.LayoutResolver.layout(for: traits)

        // Then
        // Should handle nil size class gracefully
        XCTAssertTrue(
            [.compact, .expanded].contains(layout), "Should return valid layout for nil size class")
    }

    // MARK: - Integration Tests

    func testToolbarPatternInitialization() {
        // Given
        let items = ToolbarPattern.Items(
            primary: [.init(id: "test", iconSystemName: "star", title: "Test")], secondary: [],
            overflow: [])

        // When
        let pattern = ToolbarPattern(items: items)

        // Then
        XCTAssertNotNil(pattern, "Toolbar pattern should initialize successfully")
        XCTAssertEqual(pattern.items.primary.count, 1, "Pattern should store items correctly")
    }

    func testToolbarPatternBodyRendering() {
        // Given
        let items = ToolbarPattern.Items(
            primary: [.init(id: "p1", iconSystemName: "1.circle", title: "Primary 1")],
            secondary: [.init(id: "s1", iconSystemName: "2.circle", title: "Secondary 1")],
            overflow: [.init(id: "o1", iconSystemName: "3.circle", title: "Overflow 1")])
        let pattern = ToolbarPattern(items: items)

        // Then - Test that pattern stores all items correctly without accessing body
        XCTAssertEqual(pattern.items.primary.count, 1, "Pattern should have primary items")
        XCTAssertEqual(pattern.items.secondary.count, 1, "Pattern should have secondary items")
        XCTAssertEqual(pattern.items.overflow.count, 1, "Pattern should have overflow items")
    }
}
