import SwiftUI
import XCTest

@testable import FoundationUI

/// Performance validation for the Indicator component.
///
/// Ensures render time and allocation characteristics meet the design
/// system performance baselines defined in `DS.PerformanceTest`.
@MainActor final class IndicatorPerformanceTests: XCTestCase {
    func testIndicatorRenderPerformance() {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for _ in 0..<DS.PerformanceTest.componentCount {
                let indicator = Indicator(level: .info, size: .small, reason: "Parsing")
                _ = Mirror(reflecting: indicator).children.count
            }
        }
    }

    func testIndicatorPerformanceAcrossLevels() {
        let levels = BadgeLevel.allCases

        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for level in levels {
                for _ in 0..<(DS.PerformanceTest.componentCount / levels.count) {
                    let indicator = Indicator(
                        level: level, size: .small, reason: level.accessibilityLabel)
                    _ = Mirror(reflecting: indicator).children.count
                }
            }
        }
    }

    func testIndicatorPerformanceAcrossSizes() {
        let sizes = Indicator.Size.allCases

        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for size in sizes {
                for _ in 0..<(DS.PerformanceTest.componentCount / sizes.count) {
                    let indicator = Indicator(
                        level: .warning, size: size, reason: "Checksum mismatch")
                    _ = Mirror(reflecting: indicator).children.count
                }
            }
        }
    }

    func testIndicatorWithTooltipPerformance() {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for _ in 0..<DS.PerformanceTest.componentCount {
                let tooltip = Indicator.Tooltip.badge(text: "Checksum mismatch", level: .warning)
                let indicator = Indicator(
                    level: .warning, size: .small, reason: "Checksum mismatch", tooltip: tooltip)
                _ = Mirror(reflecting: indicator).children.count
            }
        }
    }
}
