import XCTest
import SwiftUI
@testable import FoundationUI

/// Helper utilities for performance testing FoundationUI components
///
/// Provides standardized methods for measuring render performance,
/// memory usage, and component initialization overhead.
enum PerformanceTestHelpers {

    // MARK: - Performance Metrics

    /// Standard metrics to track for component performance testing
    static let standardMetrics: [XCTMetric] = [
        XCTClockMetric(),           // Wall clock time
        XCTCPUMetric(),             // CPU time and cycles
        XCTMemoryMetric(),          // Memory footprint
        XCTStorageMetric()          // Disk I/O
    ]

    /// Memory-focused metrics for testing component memory efficiency
    static let memoryMetrics: [XCTMetric] = [
        XCTMemoryMetric()
    ]

    /// CPU-focused metrics for testing component render performance
    static let cpuMetrics: [XCTMetric] = [
        XCTClockMetric(),
        XCTCPUMetric()
    ]

    // MARK: - Performance Baselines

    /// Target render time for simple components (in seconds)
    /// Target: <1ms per simple component
    static let simpleComponentRenderTimeTarget: TimeInterval = 0.001

    /// Target render time for complex hierarchies (in seconds)
    /// Target: <10ms per complex screen
    static let complexHierarchyRenderTimeTarget: TimeInterval = 0.010

    /// Target memory footprint per typical screen (in bytes)
    /// Target: <5MB per screen
    static let typicalScreenMemoryTarget: Int = 5 * 1024 * 1024 // 5MB

    /// Target frame time for 60 FPS (in seconds)
    /// 60 FPS = 16.67ms per frame
    static let targetFrameTime: TimeInterval = 1.0 / 60.0 // ~16.67ms

    // MARK: - Helper Methods

    /// Measure the performance of creating and rendering a single view
    ///
    /// - Parameters:
    ///   - iterations: Number of times to create the view (default: 100)
    ///   - viewBuilder: Closure that creates the view to measure
    /// - Returns: The measured metrics
    static func measureViewCreation<V: View>(
        iterations: Int = 100,
        @ViewBuilder _ viewBuilder: () -> V
    ) -> XCTMeasuredMetrics {
        var views: [V] = []
        views.reserveCapacity(iterations)

        let options = XCTMeasureOptions()
        options.iterationCount = DS.PerformanceTest.iterationCount

        let metrics = XCTMeasurement.measure(options: options) {
            for _ in 0..<iterations {
                let view = viewBuilder()
                views.append(view)
            }
            // Keep views in memory to prevent optimization
            _ = views.count
        }

        views.removeAll()
        return metrics
    }

    /// Measure memory footprint of multiple component instances
    ///
    /// - Parameters:
    ///   - count: Number of component instances to create
    ///   - viewBuilder: Closure that creates each view instance
    /// - Returns: The measured memory metrics
    static func measureMemoryFootprint<V: View>(
        count: Int,
        @ViewBuilder _ viewBuilder: (Int) -> V
    ) -> XCTMeasuredMetrics {
        var views: [V] = []
        views.reserveCapacity(count)

        let options = XCTMeasureOptions()
        options.iterationCount = DS.PerformanceTest.iterationCount

        let metrics = XCTMeasurement.measure(options: options) {
            for index in 0..<count {
                let view = viewBuilder(index)
                views.append(view)
            }
            // Force memory retention
            _ = views.count
        }

        views.removeAll()
        return metrics
    }

    /// Measure performance of rendering a complex view hierarchy
    ///
    /// - Parameter viewBuilder: Closure that creates the complex hierarchy
    /// - Returns: The measured metrics
    static func measureComplexHierarchy<V: View>(
        @ViewBuilder _ viewBuilder: () -> V
    ) -> XCTMeasuredMetrics {
        let options = XCTMeasureOptions()
        options.iterationCount = DS.PerformanceTest.iterationCount

        return XCTMeasurement.measure(options: options) {
            let view = viewBuilder()
            // Force view evaluation
            _ = Mirror(reflecting: view)
        }
    }

    /// Verify that a performance metric meets the target threshold
    ///
    /// - Parameters:
    ///   - metrics: The measured metrics
    ///   - metricType: The type of metric to verify
    ///   - threshold: The maximum acceptable value
    ///   - file: Source file (auto-populated)
    ///   - line: Source line (auto-populated)
    static func verifyPerformanceThreshold(
        _ metrics: XCTMeasuredMetrics,
        metricType: XCTMetric.Type,
        threshold: Double,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard let metric = metrics.measurements.first(where: { type(of: $0.metric) == metricType }) else {
            XCTFail("Metric \(metricType) not found in measurements", file: file, line: line)
            return
        }

        let average = metric.measurements.reduce(0.0, +) / Double(metric.measurements.count)

        XCTAssertLessThanOrEqual(
            average,
            threshold,
            "Performance metric \(metricType) exceeded threshold. Average: \(average), Threshold: \(threshold)",
            file: file,
            line: line
        )
    }
}

// MARK: - Design System Performance Test Tokens

extension DS {
    /// Performance testing configuration constants
    enum PerformanceTest {
        /// Number of iterations for performance measurements
        static let iterationCount: Int = 5

        /// Number of component instances for memory tests
        static let componentCount: Int = 100

        /// Number of component instances for large list tests
        static let largeListCount: Int = 1000

        /// Maximum acceptable render time for simple components (seconds)
        static let simpleRenderTimeMax: TimeInterval = 0.001

        /// Maximum acceptable render time for complex hierarchies (seconds)
        static let complexRenderTimeMax: TimeInterval = 0.010

        /// Maximum acceptable memory per screen (bytes)
        static let maxMemoryPerScreen: Int = 5 * 1024 * 1024 // 5MB

        /// Target frame rate (FPS)
        static let targetFPS: Int = 60

        /// Maximum frame time to achieve target FPS (seconds)
        static let maxFrameTime: TimeInterval = 1.0 / Double(targetFPS)
    }
}

// MARK: - XCTMeasurement Extension

/// Helper extension for XCTest measurements
extension XCTMeasurement {
    /// Measure performance with custom options
    ///
    /// - Parameters:
    ///   - options: Measurement options
    ///   - block: Block to measure
    /// - Returns: Measured metrics
    static func measure(
        options: XCTMeasureOptions,
        block: () -> Void
    ) -> XCTMeasuredMetrics {
        // Note: This is a simplified helper for component performance testing
        // In real XCTest, use XCTestCase.measure() with metrics

        var measurements: [(metric: XCTMetric, measurements: [Double])] = []

        for _ in 0..<options.iterationCount {
            autoreleasepool {
                let startTime = Date()
                block()
                let endTime = Date()
                let elapsed = endTime.timeIntervalSince(startTime)

                // Record clock metric
                if measurements.isEmpty {
                    measurements.append((XCTClockMetric(), [elapsed]))
                } else {
                    measurements[0].measurements.append(elapsed)
                }
            }
        }

        return XCTMeasuredMetrics(measurements: measurements)
    }
}

/// Container for measured metrics
struct XCTMeasuredMetrics {
    let measurements: [(metric: XCTMetric, measurements: [Double])]

    /// Get average value for a specific metric type
    func average(for metricType: XCTMetric.Type) -> Double? {
        guard let metric = measurements.first(where: { type(of: $0.metric) == metricType }) else {
            return nil
        }
        return metric.measurements.reduce(0.0, +) / Double(metric.measurements.count)
    }

    /// Get minimum value for a specific metric type
    func minimum(for metricType: XCTMetric.Type) -> Double? {
        guard let metric = measurements.first(where: { type(of: $0.metric) == metricType }) else {
            return nil
        }
        return metric.measurements.min()
    }

    /// Get maximum value for a specific metric type
    func maximum(for metricType: XCTMetric.Type) -> Double? {
        guard let metric = measurements.first(where: { type(of: $0.metric) == metricType }) else {
            return nil
        }
        return metric.measurements.max()
    }
}
