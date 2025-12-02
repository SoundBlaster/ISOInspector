//
//  ComponentAgentDescribableTests.swift
//  FoundationUI
//
//  Created by AI Assistant on 2025-11-09.
//  Copyright © 2025 ISO Inspector. All rights reserved.
//

#if canImport(SwiftUI)
    @testable import FoundationUI
    import SwiftUI
    import XCTest

    /// Unit tests for AgentDescribable conformance in Layer 2 components (Badge, Card, KeyValueRow, SectionHeader)
    ///
    /// These tests verify that all components correctly implement the AgentDescribable protocol
    /// and provide accurate, JSON-serializable property descriptions for AI agent consumption.
    @available(iOS 17.0, macOS 14.0, *) @MainActor
    final class ComponentAgentDescribableTests: XCTestCase {
        // MARK: - Badge Component Tests

        func testBadgeComponentType() {
            let badge = Badge(text: "Info", level: .info)
            XCTAssertEqual(badge.componentType, "Badge", "Badge should have componentType 'Badge'")
        }

        func testBadgeProperties() {
            let badge = Badge(text: "Warning", level: .warning, showIcon: true)

            XCTAssertEqual(badge.properties["text"] as? String, "Warning")
            XCTAssertEqual(badge.properties["level"] as? String, "warning")
            XCTAssertEqual(badge.properties["showIcon"] as? Bool, true)
        }

        func testBadgePropertiesUsesStringValue() {
            let badge = Badge(text: "Test", level: .info)
            // Verify that stringValue is used, not rawValue
            XCTAssertEqual(badge.properties["level"] as? String, BadgeLevel.info.stringValue)
        }

        func testBadgeSemantics() {
            let badge = Badge(text: "Error", level: .error)

            XCTAssertFalse(badge.semantics.isEmpty, "Badge semantics should not be empty")
            XCTAssertTrue(
                badge.semantics.contains("Error"), "Badge semantics should contain the text")
            XCTAssertTrue(
                badge.semantics.contains("error"), "Badge semantics should contain the level")
        }

        func testBadgeJSONSerialization() {
            let badge = Badge(text: "Success", level: .success, showIcon: false)

            XCTAssertTrue(
                badge.isJSONSerializable(), "Badge properties should be JSON serializable")
        }

        func testBadgeAllLevels() {
            let levels: [BadgeLevel] = [.info, .warning, .error, .success]

            for level in levels {
                let badge = Badge(text: "Test", level: level)
                XCTAssertEqual(badge.properties["level"] as? String, level.stringValue)
            }
        }

        // MARK: - Card Component Tests

        func testCardComponentType() {
            let card = Card { Text("Content") }
            XCTAssertEqual(card.componentType, "Card", "Card should have componentType 'Card'")
        }

        func testCardProperties() {
            let card = Card(elevation: .medium, cornerRadius: DS.Radius.card, material: .regular) {
                Text("Content")
            }

            XCTAssertEqual(card.properties["elevation"] as? String, "medium")
            XCTAssertEqual(card.properties["cornerRadius"] as? CGFloat, DS.Radius.card)
            XCTAssertNotNil(card.properties["material"], "Card should include material property")
        }

        func testCardElevationLevels() {
            let elevations: [CardElevation] = [.none, .low, .medium, .high]

            for elevation in elevations {
                let card = Card(elevation: elevation) { Text("Content") }
                XCTAssertEqual(card.properties["elevation"] as? String, elevation.stringValue)
            }
        }

        func testCardSemantics() {
            let card = Card(elevation: .high) { Text("Content") }

            XCTAssertFalse(card.semantics.isEmpty, "Card semantics should not be empty")
            XCTAssertTrue(
                card.semantics.contains("high"), "Card semantics should contain elevation level")
        }

        func testCardJSONSerialization() {
            let card = Card(elevation: .low, cornerRadius: DS.Radius.small) { Text("Content") }

            XCTAssertTrue(card.isJSONSerializable(), "Card properties should be JSON serializable")
        }

        // MARK: - KeyValueRow Component Tests

        func testKeyValueRowComponentType() {
            let row = KeyValueRow(key: "Type", value: "ftyp")
            XCTAssertEqual(
                row.componentType, "KeyValueRow",
                "KeyValueRow should have componentType 'KeyValueRow'")
        }

        func testKeyValueRowProperties() {
            let row = KeyValueRow(
                key: "Size", value: "1024 bytes", layout: .vertical, copyable: true)

            XCTAssertEqual(row.properties["key"] as? String, "Size")
            XCTAssertEqual(row.properties["value"] as? String, "1024 bytes")
            XCTAssertEqual(row.properties["layout"] as? String, "vertical")
            XCTAssertEqual(row.properties["isCopyable"] as? Bool, true)
        }

        func testKeyValueRowLayoutOptions() {
            let horizontalRow = KeyValueRow(key: "Type", value: "ftyp", layout: .horizontal)
            XCTAssertEqual(horizontalRow.properties["layout"] as? String, "horizontal")

            let verticalRow = KeyValueRow(key: "Description", value: "Long text", layout: .vertical)
            XCTAssertEqual(verticalRow.properties["layout"] as? String, "vertical")
        }

        func testKeyValueRowSemantics() {
            let row = KeyValueRow(key: "Offset", value: "0x1000", copyable: true)

            XCTAssertFalse(row.semantics.isEmpty, "KeyValueRow semantics should not be empty")
            XCTAssertTrue(
                row.semantics.contains("Offset"), "KeyValueRow semantics should contain the key")
            XCTAssertTrue(
                row.semantics.contains("0x1000"), "KeyValueRow semantics should contain the value")
        }

        func testKeyValueRowJSONSerialization() {
            let row = KeyValueRow(
                key: "Hash", value: "0xDEADBEEF", layout: .vertical, copyable: true)

            XCTAssertTrue(
                row.isJSONSerializable(), "KeyValueRow properties should be JSON serializable")
        }

        // MARK: - SectionHeader Component Tests

        func testSectionHeaderComponentType() {
            let header = SectionHeader(title: "File Properties")
            XCTAssertEqual(
                header.componentType, "SectionHeader",
                "SectionHeader should have componentType 'SectionHeader'")
        }

        func testSectionHeaderProperties() {
            let header = SectionHeader(title: "Metadata", showDivider: true)

            XCTAssertEqual(header.properties["title"] as? String, "Metadata")
            XCTAssertEqual(header.properties["showDivider"] as? Bool, true)
        }

        func testSectionHeaderDefaultDivider() {
            let header = SectionHeader(title: "Box Structure")
            XCTAssertEqual(
                header.properties["showDivider"] as? Bool, false,
                "Default showDivider should be false")
        }

        func testSectionHeaderSemantics() {
            let header = SectionHeader(title: "Technical Details", showDivider: true)

            XCTAssertFalse(header.semantics.isEmpty, "SectionHeader semantics should not be empty")
            XCTAssertTrue(
                header.semantics.contains("Technical Details"),
                "SectionHeader semantics should contain the title")
        }

        func testSectionHeaderJSONSerialization() {
            let header = SectionHeader(title: "Box Information", showDivider: false)

            XCTAssertTrue(
                header.isJSONSerializable(), "SectionHeader properties should be JSON serializable")
        }

        // MARK: - Edge Cases Tests

        func testBadgeEmptyText() {
            let badge = Badge(text: "", level: .info)
            XCTAssertEqual(badge.properties["text"] as? String, "")
            XCTAssertTrue(badge.isJSONSerializable())
        }

        func testCardDefaultValues() {
            let card = Card { Text("Content") }

            // Should use default values from initializer
            XCTAssertNotNil(card.properties["elevation"])
            XCTAssertNotNil(card.properties["cornerRadius"])
        }

        func testKeyValueRowDefaultValues() {
            let row = KeyValueRow(key: "Type", value: "ftyp")

            XCTAssertEqual(row.properties["layout"] as? String, "horizontal")
            XCTAssertEqual(row.properties["isCopyable"] as? Bool, false)
        }

        func testSectionHeaderLongTitle() {
            let longTitle = String(repeating: "A", count: 100)
            let header = SectionHeader(title: longTitle)

            XCTAssertEqual(header.properties["title"] as? String, longTitle)
            XCTAssertTrue(header.isJSONSerializable())
        }

        // MARK: - agentDescription() Tests

        func testBadgeAgentDescription() {
            let badge = Badge(text: "Warning", level: .warning)
            let description = badge.agentDescription()

            XCTAssertFalse(description.isEmpty)
            XCTAssertTrue(description.contains("Badge"))
            XCTAssertTrue(description.contains("Warning"))
        }

        func testCardAgentDescription() {
            let card = Card(elevation: .high) { Text("Content") }
            let description = card.agentDescription()

            XCTAssertFalse(description.isEmpty)
            XCTAssertTrue(description.contains("Card"))
        }

        func testKeyValueRowAgentDescription() {
            let row = KeyValueRow(key: "Size", value: "1024")
            let description = row.agentDescription()

            XCTAssertFalse(description.isEmpty)
            XCTAssertTrue(description.contains("KeyValueRow"))
            XCTAssertTrue(description.contains("Size"))
        }

        func testSectionHeaderAgentDescription() {
            let header = SectionHeader(title: "Metadata")
            let description = header.agentDescription()

            XCTAssertFalse(description.isEmpty)
            XCTAssertTrue(description.contains("SectionHeader"))
            XCTAssertTrue(description.contains("Metadata"))
        }
    }
#endif
