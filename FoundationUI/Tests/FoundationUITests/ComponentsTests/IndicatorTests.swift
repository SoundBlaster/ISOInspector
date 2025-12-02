import SwiftUI
// swift-tools-version: 6.0
import XCTest

@testable import FoundationUI

/// Unit tests for the Indicator component
///
/// These tests ensure the Indicator API follows the Composable Clarity
/// design system guidelines and that semantic information is preserved.
@MainActor final class IndicatorTests: XCTestCase {
    func testIndicatorInitializationStoresParameters() {
        // Given
        let tooltip = Indicator.Tooltip.badge(text: "Checksum mismatch", level: .warning)
        let indicator = Indicator(
            level: .warning, size: .small, reason: "Checksum mismatch", tooltip: tooltip)

        // Then
        XCTAssertEqual(indicator.level, .warning)
        XCTAssertEqual(indicator.size, .small)
        XCTAssertEqual(indicator.reason, "Checksum mismatch")
        XCTAssertEqual(indicator.tooltip, tooltip)
    }

    func testIndicatorSizeMappingsUseDesignTokens() {
        // Then
        XCTAssertEqual(
            Indicator.Size.mini.diameter, DS.Spacing.s, "Mini indicator should use DS.Spacing.s")
        XCTAssertEqual(
            Indicator.Size.small.diameter, DS.Spacing.m, "Small indicator should use DS.Spacing.m")
        XCTAssertEqual(
            Indicator.Size.medium.diameter, DS.Spacing.l, "Medium indicator should use DS.Spacing.l"
        )
    }

    func testIndicatorSizeEnumeratesAllCases() {
        // Given
        let cases = Indicator.Size.allCases

        // Then
        XCTAssertEqual(cases.count, 3, "Indicator should expose three size presets")
        XCTAssertTrue(cases.contains(.mini))
        XCTAssertTrue(cases.contains(.small))
        XCTAssertTrue(cases.contains(.medium))
    }

    func testIndicatorSizeStringValues() {
        XCTAssertEqual(Indicator.Size.mini.stringValue, "mini")
        XCTAssertEqual(Indicator.Size.small.stringValue, "small")
        XCTAssertEqual(Indicator.Size.medium.stringValue, "medium")
    }

    func testAccessibilityConfigurationCombinesLevelAndReason() {
        // When
        let configuration = Indicator.AccessibilityConfiguration.make(
            level: .error, reason: "Integrity failure", tooltip: nil)

        // Then
        XCTAssertEqual(configuration.label, "Error indicator — Integrity failure")
        XCTAssertEqual(configuration.hint, "Integrity failure")
    }

    func testAccessibilityConfigurationOmitReasonWhenMissing() {
        // When
        let configuration = Indicator.AccessibilityConfiguration.make(
            level: .success, reason: nil, tooltip: nil)

        // Then
        XCTAssertEqual(configuration.label, "Success indicator")
        XCTAssertNil(configuration.hint)
    }

    func testTooltipPrefersBadgeContentWhenRequested() {
        // Given
        let tooltip = Indicator.Tooltip.badge(text: "Checksum mismatch", level: .warning)

        // When
        let content = tooltip.preferredContent(style: .badge, fallbackLevel: .warning)

        // Then
        switch content {
        case .badge(let text, let level):
            XCTAssertEqual(text, "Checksum mismatch")
            XCTAssertEqual(level, .warning)
        default: XCTFail("Expected badge tooltip content")
        }
    }

    func testTooltipConvertsTextToBadgeWhenPreferred() {
        // Given
        let tooltip = Indicator.Tooltip.text("Checksum mismatch")

        // When
        let content = tooltip.preferredContent(style: .badge, fallbackLevel: .info)

        // Then
        switch content {
        case .badge(let text, let level):
            XCTAssertEqual(text, "Checksum mismatch")
            XCTAssertEqual(level, .info)
        default: XCTFail("Expected badge tooltip content when badge style is preferred")
        }
    }

    func testIndicatorSupportsCopyableModifier() {
        // Given
        let indicator = Indicator(level: .info, size: .mini, reason: "Idle")

        // When
        let copyableIndicator = indicator.copyable(text: "Idle")

        // Then
        _ = Mirror(reflecting: copyableIndicator).children.count
    }
}
