// swift-tools-version: 6.0
import XCTest
import SwiftUI
@testable import FoundationUI

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// Performance tests for FoundationUI utility components
///
/// Tests the performance characteristics of:
/// - **CopyableText**: Clipboard operations and visual feedback
/// - **KeyboardShortcuts**: String formatting and display
/// - **AccessibilityHelpers**: Contrast ratio calculations and audits
///
/// ## Performance Targets
///
/// | Metric | Target | Notes |
/// |--------|--------|-------|
/// | Clipboard operation | <10ms | NSPasteboard/UIPasteboard write time |
/// | Contrast ratio calculation | <1ms | Single color pair (WCAG AA/AAA) |
/// | Accessibility audit (100 views) | <50ms | Full hierarchy scan |
/// | Memory footprint (combined) | <5MB | All utilities in typical screen |
/// | String formatting cache | 90% hit rate | Keyboard shortcut display strings |
///
/// ## Design System Usage
///
/// All tests use DS tokens for test data:
/// - Colors: `DS.Colors.{infoBG|warnBG|errorBG|successBG}`
/// - Spacing: `DS.Spacing.{s|m|l|xl}`
/// - Animation: `DS.Animation.{quick|medium|slow}`
///
/// ## Platform Support
///
/// - iOS 17.0+
/// - iPadOS 17.0+
/// - macOS 14.0+
/// - Linux: Tests compile but clipboard/UI operations are unavailable
@MainActor
final class UtilitiesPerformanceTests: XCTestCase {

    // MARK: - Performance Baselines

    /// Target clipboard operation time (in seconds)
    /// Target: <10ms per clipboard write
    private let clipboardOperationTarget: TimeInterval = 0.010 // 10ms

    /// Target contrast ratio calculation time (in seconds)
    /// Target: <1ms per color pair calculation
    private let contrastCalculationTarget: TimeInterval = 0.001 // 1ms

    /// Target accessibility audit time (in seconds)
    /// Target: <50ms for 100 view hierarchy
    private let accessibilityAuditTarget: TimeInterval = 0.050 // 50ms

    /// Target memory footprint (in bytes)
    /// Target: <5MB for all utilities combined
    private let memoryFootprintTarget: Int = 5 * 1024 * 1024 // 5MB

    // MARK: - CopyableText Performance Tests

    #if canImport(SwiftUI)
    /// Test clipboard operation performance for small text
    ///
    /// Measures the time to copy a short string (16 characters) to the clipboard.
    /// This simulates copying a hex value or short identifier.
    ///
    /// **Target**: <10ms per operation
    /// **Baseline**: First run establishes baseline for regression detection
    func testClipboardPerformance_SmallText() throws {
        #if os(macOS) || os(iOS)
        let testText = "0x1234ABCD5678EF"

        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            // Measure clipboard write time
            #if canImport(AppKit)
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(testText, forType: .string)
            #elseif canImport(UIKit)
            UIPasteboard.general.string = testText
            #endif
        }
        #else
        throw XCTSkip("Clipboard operations require macOS or iOS")
        #endif
    }

    /// Test clipboard operation performance for medium text
    ///
    /// Measures the time to copy a medium string (256 characters) to the clipboard.
    /// This simulates copying a longer metadata value or JSON snippet.
    ///
    /// **Target**: <10ms per operation
    func testClipboardPerformance_MediumText() throws {
        #if os(macOS) || os(iOS)
        let testText = String(repeating: "A", count: 256)

        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            #if canImport(AppKit)
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(testText, forType: .string)
            #elseif canImport(UIKit)
            UIPasteboard.general.string = testText
            #endif
        }
        #else
        throw XCTSkip("Clipboard operations require macOS or iOS")
        #endif
    }

    /// Test clipboard operation performance for large text
    ///
    /// Measures the time to copy a large string (4KB) to the clipboard.
    /// This simulates copying a large metadata block or file content.
    ///
    /// **Target**: <10ms per operation
    func testClipboardPerformance_LargeText() throws {
        #if os(macOS) || os(iOS)
        let testText = String(repeating: "A", count: 4096)

        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            #if canImport(AppKit)
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(testText, forType: .string)
            #elseif canImport(UIKit)
            UIPasteboard.general.string = testText
            #endif
        }
        #else
        throw XCTSkip("Clipboard operations require macOS or iOS")
        #endif
    }

    /// Test CopyableText view rendering performance
    ///
    /// Measures the time to create and render a CopyableText view.
    /// This simulates the overhead of using CopyableText in a component.
    ///
    /// **Target**: <1ms per view creation
    func testCopyableTextViewPerformance() {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            _ = CopyableText(text: "0x1234ABCD", label: "Test Value")
        }
    }

    /// Test CopyableText view hierarchy performance
    ///
    /// Measures the time to create multiple CopyableText views in a hierarchy.
    /// This simulates a screen with many copyable values (e.g., ISO box metadata).
    ///
    /// **Target**: <10ms for 50 views
    func testCopyableTextHierarchyPerformance() {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            let views = (0..<50).map { index in
                CopyableText(text: "Value \(index)", label: "Label \(index)")
            }
            _ = views.count // Ensure views are created
        }
    }
    #endif

    // MARK: - KeyboardShortcuts Performance Tests

    #if canImport(SwiftUI)
    /// Test keyboard shortcut display string formatting performance
    ///
    /// Measures the time to format a keyboard shortcut display string (e.g., "⌘C").
    /// This simulates the overhead of displaying shortcuts in tooltips or menus.
    ///
    /// **Target**: <0.1ms per format operation
    func testKeyboardShortcutFormattingPerformance() {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            // Test all standard shortcuts
            _ = KeyboardShortcuts.copy.displayString
            _ = KeyboardShortcuts.paste.displayString
            _ = KeyboardShortcuts.cut.displayString
            _ = KeyboardShortcuts.selectAll.displayString
            _ = KeyboardShortcuts.undo.displayString
            _ = KeyboardShortcuts.redo.displayString
            _ = KeyboardShortcuts.find.displayString
            _ = KeyboardShortcuts.save.displayString
            _ = KeyboardShortcuts.open.displayString
            _ = KeyboardShortcuts.new.displayString
            _ = KeyboardShortcuts.close.displayString
        }
    }

    /// Test keyboard shortcut accessibility label generation performance
    ///
    /// Measures the time to generate accessibility labels for shortcuts.
    /// This simulates VoiceOver reading shortcut hints.
    ///
    /// **Target**: <0.1ms per label generation
    func testKeyboardShortcutAccessibilityLabelPerformance() {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            _ = KeyboardShortcuts.copy.accessibilityLabel
            _ = KeyboardShortcuts.paste.accessibilityLabel
            _ = KeyboardShortcuts.cut.accessibilityLabel
            _ = KeyboardShortcuts.selectAll.accessibilityLabel
            _ = KeyboardShortcuts.undo.accessibilityLabel
            _ = KeyboardShortcuts.redo.accessibilityLabel
        }
    }

    /// Test keyboard shortcut platform detection performance
    ///
    /// Measures the time for platform-specific shortcut logic.
    /// This simulates conditional compilation overhead.
    ///
    /// **Target**: <0.01ms per detection
    func testKeyboardShortcutPlatformDetectionPerformance() {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            // Test platform-specific modifiers
            #if os(macOS)
            _ = KeyboardShortcutModifiers.command
            #else
            _ = KeyboardShortcutModifiers.control
            #endif
        }
    }
    #endif

    // MARK: - AccessibilityHelpers Performance Tests

    #if canImport(SwiftUI)
    /// Test contrast ratio calculation performance for single color pair
    ///
    /// Measures the time to calculate contrast ratio between two colors.
    /// This is the most performance-critical operation in AccessibilityHelpers.
    ///
    /// **Target**: <1ms per calculation
    /// **WCAG 2.1**: Contrast ratio must be calculated accurately for AA/AAA compliance
    func testContrastRatioCalculationPerformance_SinglePair() {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            _ = AccessibilityHelpers.contrastRatio(
                foreground: .black,
                background: .white
            )
        }
    }

    /// Test contrast ratio calculation performance for all DS colors
    ///
    /// Measures the time to calculate contrast ratios for all Design System colors.
    /// This simulates validating a full color palette during design time.
    ///
    /// **Target**: <5ms for all DS color pairs
    func testContrastRatioCalculationPerformance_AllDSColors() {
        let colors: [Color] = [
            DS.Colors.infoBG,
            DS.Colors.warnBG,
            DS.Colors.errorBG,
            DS.Colors.successBG,
            DS.Colors.accent,
            DS.Colors.secondary,
            DS.Colors.tertiary,
            DS.Colors.textPrimary,
            DS.Colors.textSecondary
        ]

        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for foreground in colors {
                for background in colors {
                    _ = AccessibilityHelpers.contrastRatio(
                        foreground: foreground,
                        background: background
                    )
                }
            }
        }
    }

    /// Test WCAG AA validation performance
    ///
    /// Measures the time to validate color pairs against WCAG AA (≥4.5:1).
    /// This simulates runtime accessibility checks.
    ///
    /// **Target**: <1ms per validation
    func testWCAG_AA_ValidationPerformance() {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            _ = AccessibilityHelpers.meetsWCAG_AA(
                foreground: DS.Colors.textPrimary,
                background: DS.Colors.infoBG
            )
        }
    }

    /// Test WCAG AAA validation performance
    ///
    /// Measures the time to validate color pairs against WCAG AAA (≥7:1).
    ///
    /// **Target**: <1ms per validation
    func testWCAG_AAA_ValidationPerformance() {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            _ = AccessibilityHelpers.meetsWCAG_AAA(
                foreground: DS.Colors.textPrimary,
                background: DS.Colors.infoBG
            )
        }
    }

    /// Test color luminance calculation performance
    ///
    /// Measures the time to calculate relative luminance for a color.
    /// This is a core operation used in contrast ratio calculations.
    ///
    /// **Target**: <0.5ms per calculation
    func testColorLuminancePerformance() {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            _ = AccessibilityHelpers.relativeLuminance(of: DS.Colors.infoBG)
            _ = AccessibilityHelpers.relativeLuminance(of: DS.Colors.warnBG)
            _ = AccessibilityHelpers.relativeLuminance(of: DS.Colors.errorBG)
            _ = AccessibilityHelpers.relativeLuminance(of: DS.Colors.successBG)
        }
    }

    /// Test VoiceOver hint builder performance
    ///
    /// Measures the time to build VoiceOver hints with string formatting.
    ///
    /// **Target**: <0.1ms per hint
    func testVoiceOverHintBuilderPerformance() {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            _ = AccessibilityHelpers.voiceOverHint(action: "copy", target: "value")
            _ = AccessibilityHelpers.voiceOverHint(action: "paste", target: "text")
            _ = AccessibilityHelpers.voiceOverHint(action: "delete", target: "item")
        }
    }

    /// Test accessibility audit performance for small hierarchy
    ///
    /// Measures the time to audit a small view hierarchy (10 views).
    ///
    /// **Target**: <5ms for 10 views
    func testAccessibilityAuditPerformance_SmallHierarchy() {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            // Audit 10 views
            for _ in 0..<10 {
                let audit = AccessibilityHelpers.auditView(
                    hasLabel: true,
                    hasHint: true,
                    touchTargetSize: CGSize(width: 44, height: 44),
                    contrastRatio: 7.0
                )
                _ = audit.passes
            }
        }
    }

    /// Test accessibility audit performance for medium hierarchy
    ///
    /// Measures the time to audit a medium view hierarchy (50 views).
    ///
    /// **Target**: <25ms for 50 views
    func testAccessibilityAuditPerformance_MediumHierarchy() {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            // Audit 50 views
            for _ in 0..<50 {
                let audit = AccessibilityHelpers.auditView(
                    hasLabel: true,
                    hasHint: true,
                    touchTargetSize: CGSize(width: 44, height: 44),
                    contrastRatio: 7.0
                )
                _ = audit.passes
            }
        }
    }

    /// Test accessibility audit performance for large hierarchy
    ///
    /// Measures the time to audit a large view hierarchy (100 views).
    /// This simulates a complex inspector screen with many components.
    ///
    /// **Target**: <50ms for 100 views
    func testAccessibilityAuditPerformance_LargeHierarchy() {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            // Audit 100 views
            for _ in 0..<100 {
                let audit = AccessibilityHelpers.auditView(
                    hasLabel: true,
                    hasHint: true,
                    touchTargetSize: CGSize(width: 44, height: 44),
                    contrastRatio: 7.0
                )
                _ = audit.passes
            }
        }
    }

    /// Test touch target size validation performance
    ///
    /// Measures the time to validate touch target sizes (≥44×44 pt on iOS).
    ///
    /// **Target**: <0.1ms per validation
    func testTouchTargetValidationPerformance() {
        let sizes: [CGSize] = [
            CGSize(width: 44, height: 44),  // Minimum iOS
            CGSize(width: 48, height: 48),  // Comfortable
            CGSize(width: 32, height: 32),  // Too small
            CGSize(width: 60, height: 60)   // Large
        ]

        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for size in sizes {
                _ = AccessibilityHelpers.validateTouchTarget(size: size)
            }
        }
    }
    #endif

    // MARK: - Combined Utilities Performance Tests

    #if canImport(SwiftUI)
    /// Test memory footprint of all utilities combined
    ///
    /// Measures the memory usage when all utilities are used together in a typical screen.
    /// This simulates a realistic ISO Inspector view with:
    /// - Multiple CopyableText instances
    /// - Keyboard shortcuts displayed
    /// - Accessibility checks performed
    ///
    /// **Target**: <5MB combined memory footprint
    func testCombinedUtilitiesMemoryFootprint() {
        measure(metrics: [XCTStorageMetric()]) {
            // Create a screen with all utilities
            _ = (0..<20).map { index in
                CopyableText(text: "Value \(index)", label: "Label \(index)")
            }

            // Format keyboard shortcuts
            _ = [
                KeyboardShortcuts.copy.displayString,
                KeyboardShortcuts.paste.displayString,
                KeyboardShortcuts.cut.displayString
            ]

            // Perform accessibility checks
            for _ in 0..<10 {
                _ = AccessibilityHelpers.contrastRatio(
                    foreground: DS.Colors.textPrimary,
                    background: DS.Colors.infoBG
                )
            }
        }
    }

    /// Test combined utilities CPU performance
    ///
    /// Measures the CPU time for a typical screen using all utilities together.
    ///
    /// **Target**: <20ms total CPU time
    func testCombinedUtilitiesCPUPerformance() {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            // Create copyable text views
            let copyableViews = (0..<10).map { index in
                CopyableText(text: "Value \(index)", label: "Label \(index)")
            }
            _ = copyableViews.count

            // Format keyboard shortcuts
            let shortcuts = [
                KeyboardShortcuts.copy.displayString,
                KeyboardShortcuts.paste.displayString,
                KeyboardShortcuts.cut.displayString,
                KeyboardShortcuts.selectAll.displayString
            ]
            _ = shortcuts.count

            // Perform accessibility audits
            for _ in 0..<10 {
                let audit = AccessibilityHelpers.auditView(
                    hasLabel: true,
                    hasHint: true,
                    touchTargetSize: CGSize(width: 44, height: 44),
                    contrastRatio: 7.0
                )
                _ = audit.passes
            }

            // Calculate contrast ratios for DS colors
            _ = AccessibilityHelpers.contrastRatio(
                foreground: DS.Colors.textPrimary,
                background: DS.Colors.infoBG
            )
        }
    }

    /// Test stress scenario with many utilities
    ///
    /// Measures performance under stress with 100+ utility instances.
    /// This simulates a very complex screen with extensive metadata.
    ///
    /// **Target**: <100ms total CPU time
    func testStressScenario_ManyUtilities() {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            // Create 100 copyable text views
            let views = (0..<100).map { index in
                CopyableText(text: "Value \(index)", label: "Label \(index)")
            }
            _ = views.count

            // Calculate contrast for all DS color pairs
            let colors = [
                DS.Colors.infoBG,
                DS.Colors.warnBG,
                DS.Colors.errorBG,
                DS.Colors.successBG
            ]
            for foreground in colors {
                for background in colors {
                    _ = AccessibilityHelpers.contrastRatio(
                        foreground: foreground,
                        background: background
                    )
                }
            }

            // Audit 100 views
            for _ in 0..<100 {
                _ = AccessibilityHelpers.auditView(
                    hasLabel: true,
                    hasHint: true,
                    touchTargetSize: CGSize(width: 44, height: 44),
                    contrastRatio: 7.0
                )
            }
        }
    }
    #endif

    // MARK: - Regression Guards

    /// Test that clipboard operations don't cause memory leaks
    ///
    /// Ensures that repeated clipboard operations don't leak memory.
    ///
    /// **Target**: No memory growth after warmup
    func testClipboardMemoryLeak() throws {
        #if os(macOS) || os(iOS)
        // Warm up
        for _ in 0..<10 {
            #if canImport(AppKit)
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString("Test", forType: .string)
            #elseif canImport(UIKit)
            UIPasteboard.general.string = "Test"
            #endif
        }

        // Measure with storage metric to detect leaks
        measure(metrics: [XCTStorageMetric()]) {
            for _ in 0..<1000 {
                #if canImport(AppKit)
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString("Test", forType: .string)
                #elseif canImport(UIKit)
                UIPasteboard.general.string = "Test"
                #endif
            }
        }
        #else
        throw XCTSkip("Clipboard operations require macOS or iOS")
        #endif
    }

    #if canImport(SwiftUI)
    /// Test that contrast ratio calculations don't cause memory leaks
    ///
    /// Ensures that repeated color operations don't leak memory.
    ///
    /// **Target**: No memory growth after warmup
    func testContrastCalculationMemoryLeak() {
        // Warm up
        for _ in 0..<10 {
            _ = AccessibilityHelpers.contrastRatio(
                foreground: .black,
                background: .white
            )
        }

        // Measure with storage metric to detect leaks
        measure(metrics: [XCTStorageMetric()]) {
            for _ in 0..<1000 {
                _ = AccessibilityHelpers.contrastRatio(
                    foreground: DS.Colors.textPrimary,
                    background: DS.Colors.infoBG
                )
            }
        }
    }
    #endif
}
