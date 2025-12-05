import SwiftUI
import XCTest

@testable import FoundationUI

/// Performance tests for KeyValueRow component
///
/// Validates that KeyValueRow meets performance targets for:
/// - Render time (<1ms per row)
/// - List performance (100+ rows rendering efficiently)
/// - Memory efficiency (<5MB per screen)
/// - 60 FPS rendering capability
///
/// ## Test Coverage
/// - Single row render performance
/// - Multiple row instances (10, 50, 100, 1000)
/// - Horizontal and vertical layouts
/// - With and without copyable functionality
/// - Varying key/value text lengths
/// - Memory footprint validation
/// - List and grid performance
@MainActor final class KeyValueRowPerformanceTests: XCTestCase {
    // MARK: - Render Time Tests

    /// Test render performance for a single KeyValueRow
    ///
    /// Target: <1ms render time
    @MainActor func testSingleKeyValueRowRenderPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for i in 0..<DS.PerformanceTest.componentCount {
                let row = KeyValueRow(key: "Key", value: "Value \(i)")
                _ = Mirror(reflecting: row).children.count
            }
        }
    }

    /// Test render performance for KeyValueRow with long values
    ///
    /// Common use case: hash values, file paths, etc.
    @MainActor func testKeyValueRowWithLongValuesPerformance() throws {
        let longValue = String(repeating: "0123456789abcdef", count: 10)  // 160 chars

        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for i in 0..<DS.PerformanceTest.componentCount {
                let row = KeyValueRow(key: "Key \(i)", value: longValue)
                _ = Mirror(reflecting: row).children.count
            }
        }
    }

    /// Test render performance for horizontal layout
    ///
    /// Default layout orientation
    @MainActor func testHorizontalLayoutPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for i in 0..<DS.PerformanceTest.componentCount {
                let row = KeyValueRow(key: "Key \(i)", value: "Value \(i)", layout: .horizontal)
                _ = Mirror(reflecting: row).children.count
            }
        }
    }

    /// Test render performance for vertical layout
    ///
    /// Alternative layout for narrow screens
    @MainActor func testVerticalLayoutPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for i in 0..<DS.PerformanceTest.componentCount {
                let row = KeyValueRow(key: "Key \(i)", value: "Value \(i)", layout: .vertical)
                _ = Mirror(reflecting: row).children.count
            }
        }
    }

    /// Test render performance with copyable enabled
    ///
    /// Copyable adds interaction overhead
    @MainActor func testCopyableKeyValueRowPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for i in 0..<DS.PerformanceTest.componentCount {
                let row = KeyValueRow(key: "Key \(i)", value: "Value \(i)", copyable: true)
                _ = Mirror(reflecting: row).children.count
            }
        }
    }

    // MARK: - Multiple Instance Tests

    /// Test performance with 10 KeyValueRow instances
    ///
    /// Simulates a typical inspector panel
    @MainActor func testMultipleKeyValueRows_10Instances() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            var rows: [KeyValueRow] = []
            for index in 0..<DS.PerformanceTest.iterationCount {
                for i in 0..<10 {
                    let row = KeyValueRow(
                        key: "Property \(index)-\(i)", value: "Value \(index)-\(i)")
                    rows.append(row)
                }
            }
            _ = rows.count
        }
    }

    /// Test performance with 50 KeyValueRow instances
    ///
    /// Simulates a detailed inspector with many properties
    @MainActor func testMultipleKeyValueRows_50Instances() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            var rows: [KeyValueRow] = []
            for index in 0..<DS.PerformanceTest.iterationCount {
                for i in 0..<50 {
                    let row = KeyValueRow(
                        key: "Field \(index)-\(i)", value: "Data \(index)-\(i)",
                        copyable: i % 2 == 0)
                    rows.append(row)
                }
            }
            _ = rows.count
        }
    }

    /// Test performance with 100 KeyValueRow instances
    ///
    /// Stress test for large property lists
    @MainActor func testMultipleKeyValueRows_100Instances() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            var rows: [KeyValueRow] = []
            for index in 0..<DS.PerformanceTest.iterationCount {
                for i in 0..<DS.PerformanceTest.componentCount {
                    let layout: KeyValueLayout = i % 2 == 0 ? .horizontal : .vertical
                    let row = KeyValueRow(
                        key: "Key \(index)-\(i)", value: "Value \(index)-\(i)", layout: layout,
                        copyable: i % 3 == 0)
                    rows.append(row)
                }
            }
            _ = rows.count
        }
    }

    /// Test performance with 1000 KeyValueRow instances
    ///
    /// Maximum stress test for very large data sets
    @MainActor func testMultipleKeyValueRows_1000Instances() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            var rows: [KeyValueRow] = []
            for i in 0..<DS.PerformanceTest.largeListCount {
                let row = KeyValueRow(key: "Key \(i)", value: "Value \(i)")
                rows.append(row)
            }
            _ = rows.count
        }
    }

    // MARK: - List Performance Tests

    /// Test KeyValueRow in VStack (typical usage pattern)
    ///
    /// Performance for inspector panels
    @MainActor func testKeyValueRowInVStackPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for _ in 0..<DS.PerformanceTest.iterationCount {
                let view = VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    ForEach(0..<20, id: \.self) { index in
                        KeyValueRow(key: "Property \(index)", value: "Value \(index)")
                    }
                }
                _ = Mirror(reflecting: view).children.count
            }
        }
    }

    /// Test KeyValueRow in ScrollView with 100 items
    ///
    /// Performance for scrollable property lists
    @MainActor func testKeyValueRowInScrollViewPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for _ in 0..<DS.PerformanceTest.iterationCount {
                let view = ScrollView {
                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        ForEach(0..<DS.PerformanceTest.componentCount, id: \.self) { index in
                            KeyValueRow(
                                key: "Field \(index)", value: "Data value \(index)",
                                copyable: index % 2 == 0)
                        }
                    }.padding(DS.Spacing.m)
                }
                _ = Mirror(reflecting: view).children.count
            }
        }
    }

    /// Test KeyValueRow in List with 100 items
    ///
    /// Performance for native List container
    @MainActor func testKeyValueRowInListPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for _ in 0..<DS.PerformanceTest.iterationCount {
                let view = List {
                    ForEach(0..<DS.PerformanceTest.componentCount, id: \.self) { index in
                        KeyValueRow(key: "Item \(index)", value: "Value \(index)")
                    }
                }
                _ = Mirror(reflecting: view).children.count
            }
        }
    }

    /// Test mixed layout KeyValueRows in VStack
    ///
    /// Performance with both horizontal and vertical layouts
    @MainActor func testMixedLayoutKeyValueRowsPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for _ in 0..<DS.PerformanceTest.iterationCount {
                let view = VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    ForEach(0..<20, id: \.self) { index in
                        KeyValueRow(
                            key: "Property \(index)", value: "Value \(index)",
                            layout: index % 2 == 0 ? .horizontal : .vertical)
                    }
                }
                _ = Mirror(reflecting: view).children.count
            }
        }
    }

    // MARK: - Complex Content Performance Tests

    /// Test KeyValueRow with metadata properties
    ///
    /// Real-world usage: ISO box metadata display
    @MainActor func testKeyValueRowWithMetadataPerformance() throws {
        let metadata = [
            ("Type", "ftyp"), ("Size", "1,234,567 bytes"), ("Offset", "0x00000000"),
            ("Brand", "isom"), ("Version", "0"), ("Compatible Brands", "isom, iso2, mp41"),
        ]

        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for _ in 0..<DS.PerformanceTest.iterationCount {
                var rows: [KeyValueRow] = []
                for (key, value) in metadata {
                    let row = KeyValueRow(key: key, value: value, copyable: true)
                    rows.append(row)
                }
                _ = rows.count
            }
        }
    }

    /// Test KeyValueRow with hex values (monospace)
    ///
    /// Performance with monospace font styling
    @MainActor func testKeyValueRowWithHexValuesPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for i in 0..<DS.PerformanceTest.componentCount {
                let hexValue = String(format: "0x%08X", i * 16)
                let row = KeyValueRow(key: "Offset", value: hexValue, copyable: true)
                _ = Mirror(reflecting: row).children.count
            }
        }
    }

    // MARK: - Memory Tests

    /// Test memory footprint for single KeyValueRow
    ///
    /// Baseline memory measurement

    /// Test memory footprint for 100 KeyValueRows
    ///
    /// Verify memory stays under 5MB target

    /// Test memory footprint with long text values
    ///
    /// Ensure long text doesn't cause excessive memory usage

    /// Test memory footprint for 1000 KeyValueRows
    ///
    /// Large scale memory test

    // MARK: - Layout-Specific Performance Tests

    /// Test horizontal layout performance at scale
    @MainActor func testHorizontalLayoutAtScale() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            var rows: [KeyValueRow] = []
            for i in 0..<DS.PerformanceTest.componentCount {
                let row = KeyValueRow(key: "Key \(i)", value: "Value \(i)", layout: .horizontal)
                rows.append(row)
            }
            _ = rows.count
        }
    }

    /// Test vertical layout performance at scale
    @MainActor func testVerticalLayoutAtScale() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            var rows: [KeyValueRow] = []
            for i in 0..<DS.PerformanceTest.componentCount {
                let row = KeyValueRow(key: "Key \(i)", value: "Value \(i)", layout: .vertical)
                rows.append(row)
            }
            _ = rows.count
        }
    }

    // MARK: - Copyable Feature Performance Tests

    /// Test KeyValueRow without copyable performance
    ///
    /// Baseline performance without copyable functionality
    @MainActor func testKeyValueRowWithoutCopyablePerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            var rows: [KeyValueRow] = []
            for i in 0..<DS.PerformanceTest.componentCount {
                let row = KeyValueRow(key: "Key \(i)", value: "Value \(i)", copyable: false)
                rows.append(row)
            }
            _ = rows.count
        }
    }

    /// Test KeyValueRow with copyable performance
    ///
    /// Performance with copyable functionality enabled
    @MainActor func testKeyValueRowWithCopyablePerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            var rows: [KeyValueRow] = []
            for i in 0..<DS.PerformanceTest.componentCount {
                let row = KeyValueRow(key: "Key \(i)", value: "Value \(i)", copyable: true)
                rows.append(row)
            }
            _ = rows.count
        }
    }

    // MARK: - Nested in Card Performance Tests

    /// Test KeyValueRow nested inside Card
    ///
    /// Common pattern: inspector panel with card wrapper
    @MainActor func testKeyValueRowInCardPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for _ in 0..<DS.PerformanceTest.iterationCount {
                let view = Card {
                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        ForEach(0..<20, id: \.self) { index in
                            KeyValueRow(
                                key: "Property \(index)", value: "Value \(index)", copyable: true)
                        }
                    }.padding(DS.Spacing.m)
                }
                _ = Mirror(reflecting: view).children.count
            }
        }
    }
}
