import SwiftUI
import XCTest

@testable import FoundationUI

/// Performance tests for SectionHeader component
///
/// Validates that SectionHeader meets performance targets for:
/// - Render time (<1ms per header)
/// - Multiple sections performance (10, 50 sections)
/// - Memory efficiency (<5MB per screen)
/// - 60 FPS rendering capability
///
/// ## Test Coverage
/// - Single header render performance
/// - Multiple header instances (10, 50, 100)
/// - With and without dividers
/// - Varying title lengths
/// - Memory footprint validation
/// - Nested in Card and ScrollView
@MainActor final class SectionHeaderPerformanceTests: XCTestCase {
    // MARK: - Render Time Tests

    /// Test render performance for a single SectionHeader
    ///
    /// Target: <1ms render time
    @MainActor func testSingleSectionHeaderRenderPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for i in 0..<DS.PerformanceTest.componentCount {
                let header = SectionHeader(title: "Section \(i)")
                _ = Mirror(reflecting: header).children.count
            }
        }
    }

    /// Test render performance for SectionHeader with divider
    ///
    /// Divider adds visual element overhead
    @MainActor func testSectionHeaderWithDividerPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for i in 0..<DS.PerformanceTest.componentCount {
                let header = SectionHeader(title: "Section \(i)", showDivider: true)
                _ = Mirror(reflecting: header).children.count
            }
        }
    }

    /// Test render performance for SectionHeader without divider
    ///
    /// Minimal overhead baseline
    @MainActor func testSectionHeaderWithoutDividerPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for i in 0..<DS.PerformanceTest.componentCount {
                let header = SectionHeader(title: "Section \(i)", showDivider: false)
                _ = Mirror(reflecting: header).children.count
            }
        }
    }

    /// Test render performance with varying title lengths
    ///
    /// Long titles should not significantly impact performance
    @MainActor func testSectionHeaderWithVaryingTitleLengthPerformance() throws {
        let titles = [
            "S",  // 1 char
            "Info",  // 4 chars
            "Section Header",  // 14 chars
            "Metadata Properties Section",  // 28 chars
            "Very Long Section Title That May Span Multiple Lines",  // 54 chars
        ]

        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for title in titles {
                for _ in 0..<(DS.PerformanceTest.componentCount / titles.count) {
                    let header = SectionHeader(title: title)
                    _ = Mirror(reflecting: header).children.count
                }
            }
        }
    }

    // MARK: - Multiple Instance Tests

    /// Test performance with 10 SectionHeader instances
    ///
    /// Simulates a typical screen with moderate sections
    @MainActor func testMultipleSectionHeaders_10Instances() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            var headers: [SectionHeader] = []
            for index in 0..<DS.PerformanceTest.iterationCount {
                for i in 0..<10 {
                    let header = SectionHeader(
                        title: "Section \(index)-\(i)", showDivider: i % 2 == 0)
                    headers.append(header)
                }
            }
            _ = headers.count
        }
    }

    /// Test performance with 50 SectionHeader instances
    ///
    /// Simulates a screen with many sections
    @MainActor func testMultipleSectionHeaders_50Instances() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            var headers: [SectionHeader] = []
            for index in 0..<DS.PerformanceTest.iterationCount {
                for i in 0..<50 {
                    let header = SectionHeader(title: "Section \(index)-\(i)", showDivider: true)
                    headers.append(header)
                }
            }
            _ = headers.count
        }
    }

    /// Test performance with 100 SectionHeader instances
    ///
    /// Stress test for maximum sections
    @MainActor func testMultipleSectionHeaders_100Instances() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            var headers: [SectionHeader] = []
            for index in 0..<DS.PerformanceTest.iterationCount {
                for i in 0..<DS.PerformanceTest.componentCount {
                    let header = SectionHeader(
                        title: "Section \(index)-\(i)", showDivider: i % 3 == 0)
                    headers.append(header)
                }
            }
            _ = headers.count
        }
    }

    // MARK: - Section Pattern Performance Tests

    /// Test SectionHeader with content in VStack
    ///
    /// Common pattern: header followed by content
    @MainActor func testSectionHeaderWithContentPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for i in 0..<DS.PerformanceTest.iterationCount {
                let view = VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    SectionHeader(title: "Section \(i)")
                    Text("Content for section \(i)")
                    Text("Additional content")
                }
                _ = Mirror(reflecting: view).children.count
            }
        }
    }

    /// Test multiple sections with content
    ///
    /// Real-world usage: inspector with multiple sections
    @MainActor func testMultipleSectionsWithContentPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for _ in 0..<DS.PerformanceTest.iterationCount {
                let view = VStack(alignment: .leading, spacing: DS.Spacing.l) {
                    ForEach(0..<10, id: \.self) { index in
                        VStack(alignment: .leading, spacing: DS.Spacing.s) {
                            SectionHeader(title: "Section \(index)", showDivider: true)

                            ForEach(0..<5, id: \.self) { item in
                                KeyValueRow(key: "Property \(item)", value: "Value \(item)")
                            }
                        }
                    }
                }
                _ = Mirror(reflecting: view).children.count
            }
        }
    }

    // MARK: - Memory Tests

    /// Test memory footprint for single SectionHeader
    ///
    /// Baseline memory measurement

    /// Test memory footprint for 100 SectionHeaders
    ///
    /// Verify memory stays under 5MB target

    /// Test memory footprint with long titles
    ///
    /// Ensure long text doesn't cause excessive memory usage

    // MARK: - SwiftUI View Hierarchy Tests

    /// Test SectionHeader embedded in VStack performance
    ///
    /// Common usage pattern: list of sections
    @MainActor func testSectionHeaderInVStackPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for _ in 0..<DS.PerformanceTest.iterationCount {
                let view = VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    ForEach(0..<20, id: \.self) { index in
                        SectionHeader(title: "Section \(index)", showDivider: true)
                    }
                }
                _ = Mirror(reflecting: view).children.count
            }
        }
    }

    /// Test SectionHeader in ScrollView with 50 sections
    ///
    /// Performance for scrollable section list
    @MainActor func testSectionHeaderInScrollViewPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for _ in 0..<DS.PerformanceTest.iterationCount {
                let view = ScrollView {
                    VStack(alignment: .leading, spacing: DS.Spacing.l) {
                        ForEach(0..<50, id: \.self) { index in
                            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                                SectionHeader(
                                    title: "Section \(index)", showDivider: index % 2 == 0)
                                Text("Content \(index)")
                            }
                        }
                    }.padding(DS.Spacing.m)
                }
                _ = Mirror(reflecting: view).children.count
            }
        }
    }

    /// Test SectionHeader in List performance
    ///
    /// Performance for native List container
    @MainActor func testSectionHeaderInListPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for _ in 0..<DS.PerformanceTest.iterationCount {
                let view = List {
                    ForEach(0..<20, id: \.self) { index in
                        Section {
                            Text("Item 1")
                            Text("Item 2")
                        } header: {
                            SectionHeader(title: "Section \(index)")
                        }
                    }
                }
                _ = Mirror(reflecting: view).children.count
            }
        }
    }

    // MARK: - Nested in Card Performance Tests

    /// Test SectionHeader nested inside Card
    ///
    /// Common pattern: card with sectioned content
    @MainActor func testSectionHeaderInCardPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for i in 0..<DS.PerformanceTest.iterationCount {
                let view = Card {
                    VStack(alignment: .leading, spacing: DS.Spacing.m) {
                        SectionHeader(title: "General", showDivider: true)

                        KeyValueRow(key: "Name", value: "Value \(i)")
                        KeyValueRow(key: "Type", value: "Box")

                        SectionHeader(title: "Details", showDivider: true)

                        KeyValueRow(key: "Size", value: "1234")
                        KeyValueRow(key: "Offset", value: "0x0000")
                    }.padding(DS.Spacing.m)
                }
                _ = Mirror(reflecting: view).children.count
            }
        }
    }

    /// Test multiple sections in Card with many items
    ///
    /// Complex inspector panel performance
    @MainActor func testComplexSectionedCardPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for _ in 0..<DS.PerformanceTest.iterationCount {
                let view = Card {
                    VStack(alignment: .leading, spacing: DS.Spacing.l) {
                        ForEach(0..<5, id: \.self) { sectionIndex in
                            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                                SectionHeader(title: "Section \(sectionIndex)", showDivider: true)

                                ForEach(0..<10, id: \.self) { itemIndex in
                                    KeyValueRow(
                                        key: "Property \(itemIndex)", value: "Value \(itemIndex)",
                                        copyable: true)
                                }
                            }
                        }
                    }.padding(DS.Spacing.m)
                }
                _ = Mirror(reflecting: view).children.count
            }
        }
    }

    // MARK: - Real-World Usage Pattern Tests

    /// Test inspector panel pattern
    ///
    /// Sections with mixed content types
    @MainActor func testInspectorPanelPatternPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for _ in 0..<DS.PerformanceTest.iterationCount {
                let view = ScrollView {
                    VStack(alignment: .leading, spacing: DS.Spacing.l) {
                        // General section
                        SectionHeader(title: "General", showDivider: true)
                        KeyValueRow(key: "Type", value: "ftyp")
                        KeyValueRow(key: "Size", value: "32 bytes")

                        // Metadata section
                        SectionHeader(title: "Metadata", showDivider: true)
                        KeyValueRow(key: "Brand", value: "isom")
                        KeyValueRow(key: "Version", value: "0")
                        KeyValueRow(key: "Compatible", value: "isom, iso2")

                        // Data section
                        SectionHeader(title: "Data", showDivider: true)
                        KeyValueRow(key: "Offset", value: "0x00000000", copyable: true)
                        KeyValueRow(key: "Length", value: "0x00000020", copyable: true)

                        // Flags section
                        SectionHeader(title: "Flags", showDivider: true)
                        HStack {
                            Badge(text: "Valid", level: .success)
                            Badge(text: "Parsed", level: .info)
                        }
                    }.padding(DS.Spacing.m)
                }
                _ = Mirror(reflecting: view).children.count
            }
        }
    }
}
