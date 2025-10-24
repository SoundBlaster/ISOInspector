// swift-tools-version: 6.0
import XCTest
import SwiftUI
@testable import FoundationUI

/// Unit tests for the ToolbarPattern adaptive toolbar implementation.
///
/// These tests validate the data model and layout resolution behaviours that
/// power the pattern prior to full UI composition and integration coverage.
@MainActor
final class ToolbarPatternTests: XCTestCase {

    func testToolbarPatternStoresPrimarySecondaryAndOverflowItems() {
        // Given
        let items = ToolbarPattern.Items(
            primary: [
                .init(id: "inspect", iconSystemName: "magnifyingglass", title: "Inspect"),
                .init(id: "share", iconSystemName: "square.and.arrow.up", title: "Share")
            ],
            secondary: [
                .init(id: "flag", iconSystemName: "flag", title: "Flag")
            ],
            overflow: [
                .init(id: "archive", iconSystemName: "archivebox", title: "Archive")
            ]
        )

        // When
        let pattern = ToolbarPattern(items: items)

        // Then
        XCTAssertEqual(pattern.items.primary.count, 2)
        XCTAssertEqual(pattern.items.secondary.count, 1)
        XCTAssertEqual(pattern.items.overflow.count, 1)
    }

    func testToolbarItemAccessibilityLabelIncludesShortcutDescription() {
        // Given
        let shortcut = ToolbarPattern.Shortcut(key: "f", modifiers: [.command, .shift], description: "Find" )
        let item = ToolbarPattern.Item(id: "find", iconSystemName: "magnifyingglass", title: "Find", shortcut: shortcut)

        // When
        let label = item.accessibilityLabel

        // Then
        XCTAssertTrue(label.contains("Find"), "Accessibility label should include the title text")
        XCTAssertTrue(label.contains("⌘⇧F"), "Accessibility label should embed the formatted shortcut glyphs")
    }

    func testLayoutResolverUsesCompactModeForCompactWidthTraits() {
        // Given
        let traits = ToolbarPattern.Traits(
            horizontalSizeClass: .compact,
            platform: .iOS,
            prefersLargeContent: false
        )

        // When
        let layout = ToolbarPattern.LayoutResolver.layout(for: traits)

        // Then
        XCTAssertEqual(layout, .compact)
    }

    func testLayoutResolverUsesExpandedModeForMacOS() {
        // Given
        let traits = ToolbarPattern.Traits(
            horizontalSizeClass: nil,
            platform: .macOS,
            prefersLargeContent: false
        )

        // When
        let layout = ToolbarPattern.LayoutResolver.layout(for: traits)

        // Then
        XCTAssertEqual(layout, .expanded)
    }
}
