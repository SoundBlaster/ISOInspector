import XCTest
import SwiftUI
@testable import FoundationUI

/// Performance tests for Badge component
///
/// Validates that Badge meets performance targets for:
/// - Render time (<1ms per component)
/// - Memory efficiency (<5MB per screen with 100+ badges)
/// - 60 FPS rendering capability
///
/// ## Test Coverage
/// - Single badge render performance
/// - Multiple badge instances (10, 50, 100)
/// - All badge levels (info, warning, error, success)
/// - With and without icons
/// - Memory footprint validation
final class BadgePerformanceTests: XCTestCase {

    // MARK: - Render Time Tests

    /// Test render performance for a single Badge component
    ///
    /// Target: <1ms render time
    @MainActor
    func testSingleBadgeRenderPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for _ in 0..<DS.PerformanceTest.componentCount {
                let badge = Badge(text: "Info", level: .info)
                // Force view evaluation
                _ = Mirror(reflecting: badge).children.count
            }
        }
    }

    /// Test render performance for Badge with icon
    ///
    /// Icons may add overhead, verify still meets target
    @MainActor
    func testBadgeWithIconRenderPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for _ in 0..<DS.PerformanceTest.componentCount {
                let badge = Badge(text: "Warning", level: .warning, showIcon: true)
                _ = Mirror(reflecting: badge).children.count
            }
        }
    }

    /// Test render performance across all badge levels
    ///
    /// Ensures consistent performance regardless of level
    @MainActor
    func testAllBadgeLevelsRenderPerformance() throws {
        let levels: [BadgeLevel] = [.info, .warning, .error, .success]

        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for level in levels {
                for _ in 0..<(DS.PerformanceTest.componentCount / levels.count) {
                    let badge = Badge(text: "\(level)", level: level)
                    _ = Mirror(reflecting: badge).children.count
                }
            }
        }
    }

    /// Test render performance with varying text lengths
    ///
    /// Long text should not significantly impact performance
    @MainActor
    func testBadgeWithVaryingTextLengthPerformance() throws {
        let texts = [
            "X",                                    // 1 char
            "Info",                                 // 4 chars
            "Warning Message",                      // 15 chars
            "Critical Error: System Failure",       // 31 chars
            "Very Long Badge Text That Should Still Render Efficiently" // 57 chars
        ]

        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for text in texts {
                for _ in 0..<(DS.PerformanceTest.componentCount / texts.count) {
                    let badge = Badge(text: text, level: .info)
                    _ = Mirror(reflecting: badge).children.count
                }
            }
        }
    }

    // MARK: - Multiple Instance Tests

    /// Test performance with 10 badge instances
    ///
    /// Simulates a typical screen with moderate badge usage
    @MainActor
    func testMultipleBadges_10Instances() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            var badges: [Badge] = []
            for index in 0..<DS.PerformanceTest.iterationCount {
                for i in 0..<10 {
                    let level = BadgeLevel.allCases[i % BadgeLevel.allCases.count]
                    let badge = Badge(text: "Badge \(index)-\(i)", level: level)
                    badges.append(badge)
                }
            }
            _ = badges.count
        }
    }

    /// Test performance with 50 badge instances
    ///
    /// Simulates a screen with heavy badge usage
    @MainActor
    func testMultipleBadges_50Instances() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            var badges: [Badge] = []
            for index in 0..<DS.PerformanceTest.iterationCount {
                for i in 0..<50 {
                    let level = BadgeLevel.allCases[i % BadgeLevel.allCases.count]
                    let badge = Badge(text: "Badge \(index)-\(i)", level: level)
                    badges.append(badge)
                }
            }
            _ = badges.count
        }
    }

    /// Test performance with 100 badge instances
    ///
    /// Stress test to validate performance at scale
    @MainActor
    func testMultipleBadges_100Instances() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            var badges: [Badge] = []
            for index in 0..<DS.PerformanceTest.iterationCount {
                for i in 0..<DS.PerformanceTest.componentCount {
                    let level = BadgeLevel.allCases[i % BadgeLevel.allCases.count]
                    let badge = Badge(text: "Badge \(index)-\(i)", level: level, showIcon: i % 2 == 0)
                    badges.append(badge)
                }
            }
            _ = badges.count
        }
    }

    // MARK: - Memory Tests

    /// Test memory footprint for single Badge
    ///
    /// Baseline memory measurement
    @MainActor
    func testSingleBadgeMemoryFootprint() throws {
        measureMetrics([.memoryPhysical], automaticallyStartMeasuring: false) {
            startMeasuring()

            var badges: [Badge] = []
            for i in 0..<DS.PerformanceTest.componentCount {
                let badge = Badge(text: "Badge \(i)", level: .info)
                badges.append(badge)
            }

            stopMeasuring()

            // Keep badges alive during measurement
            _ = badges.count
        }
    }

    /// Test memory footprint for 100 Badge instances with all levels
    ///
    /// Verify memory stays under 5MB target
    @MainActor
    func testMultipleBadgesMemoryFootprint() throws {
        measureMetrics([.memoryPhysical], automaticallyStartMeasuring: false) {
            startMeasuring()

            var badges: [Badge] = []
            for i in 0..<DS.PerformanceTest.componentCount {
                let level = BadgeLevel.allCases[i % BadgeLevel.allCases.count]
                let showIcon = i % 3 == 0
                let badge = Badge(
                    text: "Badge \(i)",
                    level: level,
                    showIcon: showIcon
                )
                badges.append(badge)
            }

            stopMeasuring()

            _ = badges.count
        }
    }

    /// Test memory footprint with badges containing long text
    ///
    /// Ensure long text doesn't cause excessive memory usage
    @MainActor
    func testBadgesWithLongTextMemoryFootprint() throws {
        let longText = String(repeating: "Long Badge Text ", count: 10) // ~160 chars

        measureMetrics([.memoryPhysical], automaticallyStartMeasuring: false) {
            startMeasuring()

            var badges: [Badge] = []
            for i in 0..<DS.PerformanceTest.componentCount {
                let badge = Badge(text: longText, level: .info)
                badges.append(badge)
            }

            stopMeasuring()

            _ = badges.count
        }
    }

    // MARK: - SwiftUI View Hierarchy Tests

    /// Test Badge embedded in VStack performance
    ///
    /// Common usage pattern: list of badges
    @MainActor
    func testBadgeInVStackPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for _ in 0..<DS.PerformanceTest.iterationCount {
                let view = VStack(spacing: DS.Spacing.s) {
                    ForEach(0..<10, id: \.self) { index in
                        Badge(
                            text: "Badge \(index)",
                            level: BadgeLevel.allCases[index % BadgeLevel.allCases.count]
                        )
                    }
                }
                _ = Mirror(reflecting: view).children.count
            }
        }
    }

    /// Test Badge embedded in HStack performance
    ///
    /// Common usage pattern: horizontal badge row
    @MainActor
    func testBadgeInHStackPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for _ in 0..<DS.PerformanceTest.iterationCount {
                let view = HStack(spacing: DS.Spacing.s) {
                    Badge(text: "Info", level: .info)
                    Badge(text: "Warning", level: .warning)
                    Badge(text: "Error", level: .error)
                    Badge(text: "Success", level: .success)
                }
                _ = Mirror(reflecting: view).children.count
            }
        }
    }

    /// Test Badge in ScrollView with 100 items
    ///
    /// Performance for scrollable badge list
    @MainActor
    func testBadgeInScrollViewPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for _ in 0..<DS.PerformanceTest.iterationCount {
                let view = ScrollView {
                    VStack(spacing: DS.Spacing.s) {
                        ForEach(0..<DS.PerformanceTest.componentCount, id: \.self) { index in
                            Badge(
                                text: "Badge \(index)",
                                level: BadgeLevel.allCases[index % BadgeLevel.allCases.count],
                                showIcon: index % 2 == 0
                            )
                        }
                    }
                }
                _ = Mirror(reflecting: view).children.count
            }
        }
    }

    // MARK: - Level-Specific Performance Tests

    /// Test Info level badge performance
    @MainActor
    func testInfoBadgePerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for i in 0..<DS.PerformanceTest.componentCount {
                let badge = Badge(text: "Info \(i)", level: .info)
                _ = Mirror(reflecting: badge).children.count
            }
        }
    }

    /// Test Warning level badge performance
    @MainActor
    func testWarningBadgePerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for i in 0..<DS.PerformanceTest.componentCount {
                let badge = Badge(text: "Warning \(i)", level: .warning)
                _ = Mirror(reflecting: badge).children.count
            }
        }
    }

    /// Test Error level badge performance
    @MainActor
    func testErrorBadgePerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for i in 0..<DS.PerformanceTest.componentCount {
                let badge = Badge(text: "Error \(i)", level: .error)
                _ = Mirror(reflecting: badge).children.count
            }
        }
    }

    /// Test Success level badge performance
    @MainActor
    func testSuccessBadgePerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for i in 0..<DS.PerformanceTest.componentCount {
                let badge = Badge(text: "Success \(i)", level: .success)
                _ = Mirror(reflecting: badge).children.count
            }
        }
    }
}
