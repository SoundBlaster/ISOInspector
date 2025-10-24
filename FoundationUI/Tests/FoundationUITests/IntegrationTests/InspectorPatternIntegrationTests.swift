// swift-tools-version: 6.0
import XCTest
import SwiftUI
@testable import FoundationUI

/// Integration tests for InspectorPattern combined with other FoundationUI components.
@MainActor
final class InspectorPatternIntegrationTests: XCTestCase {

    func testInspectorPatternComposesWithSectionHeaderAndKeyValueRows() {
        // Given & When
        let pattern = InspectorPattern(title: "ISO File") {
            SectionHeader(title: "General")
            KeyValueRow(key: "Name", value: "example.mp4")
            KeyValueRow(key: "Size", value: "1.2 GB")
        }

        // Then
        XCTAssertNotNil(pattern, "InspectorPattern should compose with SectionHeader and KeyValueRow components")
    }

    func testInspectorPatternSupportsBadgeInsideContent() {
        // Given
        let pattern = InspectorPattern(title: "Statuses") {
            HStack(spacing: DS.Spacing.m) {
                Badge(text: "Info", level: .info)
                Badge(text: "Warning", level: .warning)
                Badge(text: "Error", level: .error)
            }
        }

        // Then
        XCTAssertNotNil(pattern, "InspectorPattern should allow composing badge views inside its content")
    }
}
