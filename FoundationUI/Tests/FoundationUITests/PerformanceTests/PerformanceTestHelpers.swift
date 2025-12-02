import SwiftUI
import XCTest

@testable import FoundationUI

/// Helper utilities for performance testing FoundationUI components
///
/// Provides standardized metrics and baselines for measuring render performance
/// and component initialization overhead.
@MainActor enum PerformanceTestHelpers {
    // MARK: - Performance Metrics

    /// CPU-focused metrics for testing component render performance
    /// Uses XCTest's built-in clock and CPU metrics
    static let cpuMetrics: [XCTMetric] = [XCTClockMetric(), XCTCPUMetric()]

    /// Standard metrics to track for component performance testing
    /// Note: XCTest does not provide a memory metric in the public API
    static let standardMetrics: [XCTMetric] = [
        XCTClockMetric(), XCTCPUMetric(), XCTStorageMetric(),
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
    static let typicalScreenMemoryTarget: Int = 5 * 1024 * 1024  // 5MB

    /// Target frame time for 60 FPS (in seconds)
    /// 60 FPS = 16.67ms per frame
    static let targetFrameTime: TimeInterval = 1.0 / 60.0  // ~16.67ms
}

// MARK: - Design System Performance Test Tokens

extension DS {
    /// Performance testing configuration constants
    @MainActor enum PerformanceTest {
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
        static let maxMemoryPerScreen: Int = 5 * 1024 * 1024  // 5MB

        /// Target frame rate (FPS)
        static let targetFPS: Int = 60

        /// Maximum frame time to achieve target FPS (seconds)
        static let maxFrameTime: TimeInterval = 1.0 / Double(targetFPS)
    }
}
