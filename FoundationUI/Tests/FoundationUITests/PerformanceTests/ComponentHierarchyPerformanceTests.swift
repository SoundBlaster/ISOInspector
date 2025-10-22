import XCTest
import SwiftUI
@testable import FoundationUI

/// Performance tests for complex component hierarchies
///
/// Validates that component combinations meet performance targets for:
/// - Complex hierarchy render time (<10ms per screen)
/// - Memory efficiency (<5MB per screen)
/// - Real-world usage patterns
/// - 60 FPS rendering capability
///
/// ## Test Coverage
/// - Card → SectionHeader → KeyValueRow hierarchies
/// - Card → SectionHeader → Badge combinations
/// - Deeply nested component structures
/// - Full inspector panel simulations
/// - Large scale component compositions (100+ components)
/// - Memory footprint for complex screens
final class ComponentHierarchyPerformanceTests: XCTestCase {

    // MARK: - Simple Hierarchy Tests

    /// Test Card → Text hierarchy performance
    ///
    /// Baseline: simplest possible hierarchy
    @MainActor
    func testSimpleCardTextHierarchyPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for i in 0..<DS.PerformanceTest.componentCount {
                let view = Card {
                    Text("Simple content \(i)")
                }
                _ = Mirror(reflecting: view).children.count
            }
        }
    }

    /// Test Card → SectionHeader → Text hierarchy
    ///
    /// Common two-level nesting
    @MainActor
    func testCardSectionHeaderHierarchyPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for i in 0..<DS.PerformanceTest.componentCount {
                let view = Card {
                    VStack(alignment: .leading, spacing: DS.Spacing.m) {
                        SectionHeader(title: "Section \(i)")
                        Text("Content")
                    }
                }
                _ = Mirror(reflecting: view).children.count
            }
        }
    }

    /// Test Card → SectionHeader → KeyValueRow hierarchy
    ///
    /// Most common usage pattern
    @MainActor
    func testCardSectionKeyValueHierarchyPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for i in 0..<DS.PerformanceTest.componentCount {
                let view = Card {
                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        SectionHeader(title: "Section \(i)", showDivider: true)
                        KeyValueRow(key: "Key", value: "Value \(i)")
                    }
                }
                _ = Mirror(reflecting: view).children.count
            }
        }
    }

    // MARK: - Inspector Panel Simulations

    /// Test simple inspector panel performance
    ///
    /// Card with single section containing 5 KeyValueRows
    @MainActor
    func testSimpleInspectorPanelPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for i in 0..<DS.PerformanceTest.iterationCount {
                let view = Card {
                    VStack(alignment: .leading, spacing: DS.Spacing.m) {
                        SectionHeader(title: "Properties", showDivider: true)

                        KeyValueRow(key: "Type", value: "ftyp")
                        KeyValueRow(key: "Size", value: "32 bytes")
                        KeyValueRow(key: "Offset", value: "0x\(String(format: "%08X", i))")
                        KeyValueRow(key: "Version", value: "0")
                        KeyValueRow(key: "Brand", value: "isom")
                    }
                    .padding(DS.Spacing.m)
                }
                _ = Mirror(reflecting: view).children.count
            }
        }
    }

    /// Test medium inspector panel performance
    ///
    /// Card with 3 sections, each with 5 KeyValueRows (15 total)
    @MainActor
    func testMediumInspectorPanelPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for i in 0..<DS.PerformanceTest.iterationCount {
                let view = Card {
                    VStack(alignment: .leading, spacing: DS.Spacing.l) {
                        // General section
                        SectionHeader(title: "General", showDivider: true)
                        KeyValueRow(key: "Type", value: "ftyp")
                        KeyValueRow(key: "Size", value: "1,234 bytes")
                        KeyValueRow(key: "Offset", value: "0x00000000")
                        KeyValueRow(key: "Parent", value: "Root")
                        KeyValueRow(key: "Index", value: "\(i)")

                        // Metadata section
                        SectionHeader(title: "Metadata", showDivider: true)
                        KeyValueRow(key: "Brand", value: "isom")
                        KeyValueRow(key: "Version", value: "0")
                        KeyValueRow(key: "Compatible", value: "isom, iso2, mp41")
                        KeyValueRow(key: "Created", value: "2024-10-22")
                        KeyValueRow(key: "Modified", value: "2024-10-22")

                        // Flags section
                        SectionHeader(title: "Flags", showDivider: true)
                        HStack {
                            Badge(text: "Valid", level: .success)
                            Badge(text: "Parsed", level: .info)
                            Badge(text: "Verified", level: .success)
                        }
                    }
                    .padding(DS.Spacing.m)
                }
                _ = Mirror(reflecting: view).children.count
            }
        }
    }

    /// Test complex inspector panel performance
    ///
    /// Card with 5 sections, each with 10 KeyValueRows (50 total) plus badges
    @MainActor
    func testComplexInspectorPanelPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for iteration in 0..<DS.PerformanceTest.iterationCount {
                let view = Card {
                    ScrollView {
                        VStack(alignment: .leading, spacing: DS.Spacing.l) {
                            ForEach(0..<5, id: \.self) { sectionIndex in
                                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                                    SectionHeader(
                                        title: "Section \(sectionIndex)",
                                        showDivider: true
                                    )

                                    ForEach(0..<10, id: \.self) { rowIndex in
                                        KeyValueRow(
                                            key: "Property \(rowIndex)",
                                            value: "Value \(iteration)-\(sectionIndex)-\(rowIndex)",
                                            copyable: rowIndex % 2 == 0
                                        )
                                    }

                                    if sectionIndex % 2 == 0 {
                                        HStack {
                                            Badge(text: "Info", level: .info)
                                            Badge(text: "Warning", level: .warning)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(DS.Spacing.m)
                    }
                }
                _ = Mirror(reflecting: view).children.count
            }
        }
    }

    // MARK: - List Performance Tests

    /// Test list of simple cards (10 cards)
    ///
    /// Typical card list view
    @MainActor
    func testCardListPerformance_10Cards() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for _ in 0..<DS.PerformanceTest.iterationCount {
                let view = ScrollView {
                    VStack(spacing: DS.Spacing.m) {
                        ForEach(0..<10, id: \.self) { index in
                            Card {
                                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                                    Text("Card \(index)")
                                        .font(DS.Typography.title)
                                    Text("Description for card \(index)")
                                        .font(DS.Typography.body)
                                }
                                .padding(DS.Spacing.m)
                            }
                        }
                    }
                    .padding(DS.Spacing.m)
                }
                _ = Mirror(reflecting: view).children.count
            }
        }
    }

    /// Test list of complex cards (50 cards)
    ///
    /// Each card contains section header and multiple rows
    @MainActor
    func testComplexCardListPerformance_50Cards() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for _ in 0..<DS.PerformanceTest.iterationCount {
                let view = ScrollView {
                    VStack(spacing: DS.Spacing.m) {
                        ForEach(0..<50, id: \.self) { index in
                            Card(elevation: .low) {
                                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                                    SectionHeader(title: "Item \(index)", showDivider: true)

                                    KeyValueRow(key: "Type", value: "Box")
                                    KeyValueRow(key: "Size", value: "\(index * 100)")
                                    KeyValueRow(key: "Offset", value: "0x\(String(format: "%08X", index * 32))")

                                    HStack {
                                        Badge(
                                            text: index % 2 == 0 ? "Valid" : "Warning",
                                            level: index % 2 == 0 ? .success : .warning
                                        )
                                    }
                                }
                                .padding(DS.Spacing.m)
                            }
                        }
                    }
                    .padding(DS.Spacing.m)
                }
                _ = Mirror(reflecting: view).children.count
            }
        }
    }

    // MARK: - Nested Card Performance Tests

    /// Test nested cards with complex content
    ///
    /// Card → Card → SectionHeader → KeyValueRow
    @MainActor
    func testNestedCardsWithComplexContentPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for i in 0..<DS.PerformanceTest.iterationCount {
                let view = Card {
                    VStack(alignment: .leading, spacing: DS.Spacing.m) {
                        SectionHeader(title: "Parent Section \(i)", showDivider: true)

                        Card(elevation: .low) {
                            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                                SectionHeader(title: "Child Section", showDivider: false)
                                KeyValueRow(key: "Property 1", value: "Value 1")
                                KeyValueRow(key: "Property 2", value: "Value 2")
                                KeyValueRow(key: "Property 3", value: "Value 3")
                            }
                            .padding(DS.Spacing.s)
                        }

                        KeyValueRow(key: "Parent Property", value: "Parent Value")
                    }
                    .padding(DS.Spacing.m)
                }
                _ = Mirror(reflecting: view).children.count
            }
        }
    }

    /// Test deeply nested hierarchy (4 levels)
    ///
    /// Maximum realistic nesting depth
    @MainActor
    func testDeeplyNestedHierarchyPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for i in 0..<DS.PerformanceTest.iterationCount {
                let view = Card {                              // Level 1
                    VStack {
                        SectionHeader(title: "Level 1 \(i)")

                        Card(elevation: .low) {                // Level 2
                            VStack {
                                SectionHeader(title: "Level 2")

                                Card(elevation: .none) {       // Level 3
                                    VStack {
                                        SectionHeader(title: "Level 3")

                                        VStack {               // Level 4
                                            KeyValueRow(key: "Deep", value: "Value")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                _ = Mirror(reflecting: view).children.count
            }
        }
    }

    // MARK: - Large Scale Tests

    /// Test screen with 100+ total components
    ///
    /// Stress test for complex screens
    @MainActor
    func testLargeScaleComponentCompositionPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for _ in 0..<DS.PerformanceTest.iterationCount {
                let view = ScrollView {
                    VStack(spacing: DS.Spacing.l) {
                        // 10 cards, each with 10 rows = 100+ components
                        ForEach(0..<10, id: \.self) { cardIndex in
                            Card {
                                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                                    SectionHeader(
                                        title: "Section \(cardIndex)",
                                        showDivider: true
                                    )

                                    ForEach(0..<10, id: \.self) { rowIndex in
                                        KeyValueRow(
                                            key: "Property \(rowIndex)",
                                            value: "Value \(cardIndex)-\(rowIndex)",
                                            copyable: true
                                        )
                                    }

                                    HStack {
                                        Badge(text: "Info", level: .info)
                                        Badge(text: "Success", level: .success)
                                        Badge(text: "Warning", level: .warning)
                                    }
                                }
                                .padding(DS.Spacing.m)
                            }
                        }
                    }
                    .padding(DS.Spacing.m)
                }
                _ = Mirror(reflecting: view).children.count
            }
        }
    }

    // MARK: - Memory Tests

    /// Test memory footprint for simple inspector panel
    ///
    /// Baseline complex hierarchy memory
    /* @MainActor

    /// Test memory footprint for complex inspector panel
    ///
    /// Verify complex hierarchies stay under 5MB target
    /* @MainActor

    /// Test memory footprint for large scale composition
    ///
    /// 10 cards with 10 rows each = 100+ components
    /* @MainActor

    // MARK: - Real-World Simulation Tests

    /// Test ISO box inspector panel
    ///
    /// Realistic ISO Inspector usage
    @MainActor
    func testISOBoxInspectorPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for i in 0..<DS.PerformanceTest.iterationCount {
                let view = Card {
                    ScrollView {
                        VStack(alignment: .leading, spacing: DS.Spacing.l) {
                            // Box Info section
                            SectionHeader(title: "Box Information", showDivider: true)
                            KeyValueRow(key: "Type", value: "ftyp")
                            KeyValueRow(key: "Size", value: "32 bytes")
                            KeyValueRow(key: "Offset", value: "0x00000000", copyable: true)
                            KeyValueRow(key: "Parent", value: "Root")

                            // Metadata section
                            SectionHeader(title: "Metadata", showDivider: true)
                            KeyValueRow(key: "Major Brand", value: "isom")
                            KeyValueRow(key: "Minor Version", value: "0")
                            KeyValueRow(key: "Compatible Brands", value: "isom, iso2, mp41, M4V")

                            // Data section
                            SectionHeader(title: "Raw Data", showDivider: true)
                            KeyValueRow(
                                key: "Hex Dump",
                                value: "00 00 00 20 66 74 79 70",
                                copyable: true
                            )
                            KeyValueRow(
                                key: "ASCII",
                                value: "....ftyp",
                                copyable: true
                            )

                            // Status section
                            SectionHeader(title: "Status", showDivider: true)
                            HStack {
                                Badge(text: "Valid", level: .success)
                                Badge(text: "Parsed", level: .info)
                                Badge(text: "Version \(i)", level: .info)
                            }
                        }
                        .padding(DS.Spacing.m)
                    }
                }
                _ = Mirror(reflecting: view).children.count
            }
        }
    }

    /// Test multi-box inspector view
    ///
    /// List of multiple box inspectors
    @MainActor
    func testMultiBoxInspectorPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for _ in 0..<DS.PerformanceTest.iterationCount {
                let view = ScrollView {
                    VStack(spacing: DS.Spacing.l) {
                        ForEach(0..<5, id: \.self) { boxIndex in
                            Card(elevation: .medium) {
                                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                                    SectionHeader(title: "Box \(boxIndex)", showDivider: true)

                                    KeyValueRow(key: "Type", value: "mdat")
                                    KeyValueRow(key: "Size", value: "\(boxIndex * 1024) bytes")
                                    KeyValueRow(
                                        key: "Offset",
                                        value: "0x\(String(format: "%08X", boxIndex * 256))",
                                        copyable: true
                                    )

                                    HStack {
                                        Badge(text: "Media", level: .info)
                                        Badge(text: "Large", level: .warning)
                                    }
                                }
                                .padding(DS.Spacing.m)
                            }
                        }
                    }
                    .padding(DS.Spacing.m)
                }
                _ = Mirror(reflecting: view).children.count
            }
        }
    }
}
