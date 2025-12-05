#if canImport(SwiftUI)
    import XCTest
    import SwiftUI
    @testable import FoundationUI

    /// Comprehensive test suite for the Badge component
    ///
    /// Tests cover:
    /// - Component initialization and rendering
    /// - All semantic levels (info, warning, error, success)
    /// - Icon display variations
    /// - Accessibility labels and semantic descriptions
    /// - Design token integration
    /// - Platform compatibility
    /// - State variations
    ///
    /// **Phase:** I0.2 - Create Integration Test Suite
    /// **Coverage Target:** ≥80% for Badge component
    final class BadgeComponentTests: XCTestCase {

        // MARK: - Initialization Tests

        /// Verifies that Badge can be initialized with all required parameters
        func testBadgeInitialization() {
            let badge = Badge(text: "TEST", level: .info)

            XCTAssertEqual(badge.text, "TEST")
            XCTAssertEqual(badge.level, .info)
            XCTAssertFalse(badge.showIcon)
        }

        /// Verifies that Badge can be initialized with optional icon parameter
        func testBadgeInitializationWithIcon() {
            let badge = Badge(text: "TEST", level: .warning, showIcon: true)

            XCTAssertEqual(badge.text, "TEST")
            XCTAssertEqual(badge.level, .warning)
            XCTAssertTrue(badge.showIcon)
        }

        // MARK: - Semantic Level Tests

        /// Verifies that all BadgeLevel cases are available
        func testBadgeLevelAllCasesAvailable() {
            let levels = BadgeLevel.allCases

            XCTAssertEqual(levels.count, 4, "Badge should have exactly 4 semantic levels")
            XCTAssertTrue(levels.contains(.info))
            XCTAssertTrue(levels.contains(.warning))
            XCTAssertTrue(levels.contains(.error))
            XCTAssertTrue(levels.contains(.success))
        }

        /// Verifies that info level Badge can be created
        func testBadgeInfoLevel() {
            let badge = Badge(text: "INFO", level: .info)

            XCTAssertEqual(badge.level, .info)
            XCTAssertNotNil(badge.body)
        }

        /// Verifies that warning level Badge can be created
        func testBadgeWarningLevel() {
            let badge = Badge(text: "WARNING", level: .warning)

            XCTAssertEqual(badge.level, .warning)
            XCTAssertNotNil(badge.body)
        }

        /// Verifies that error level Badge can be created
        func testBadgeErrorLevel() {
            let badge = Badge(text: "ERROR", level: .error)

            XCTAssertEqual(badge.level, .error)
            XCTAssertNotNil(badge.body)
        }

        /// Verifies that success level Badge can be created
        func testBadgeSuccessLevel() {
            let badge = Badge(text: "SUCCESS", level: .success)

            XCTAssertEqual(badge.level, .success)
            XCTAssertNotNil(badge.body)
        }

        // MARK: - BadgeLevel Properties Tests

        /// Verifies that each BadgeLevel has a background color
        func testBadgeLevelBackgroundColors() {
            let infoColor = BadgeLevel.info.backgroundColor
            let warningColor = BadgeLevel.warning.backgroundColor
            let errorColor = BadgeLevel.error.backgroundColor
            let successColor = BadgeLevel.success.backgroundColor

            // Verify colors are not nil (they're Color instances)
            XCTAssertNotNil(infoColor)
            XCTAssertNotNil(warningColor)
            XCTAssertNotNil(errorColor)
            XCTAssertNotNil(successColor)
        }

        /// Verifies that each BadgeLevel has a foreground color
        func testBadgeLevelForegroundColors() {
            let infoColor = BadgeLevel.info.foregroundColor
            let warningColor = BadgeLevel.warning.foregroundColor
            let errorColor = BadgeLevel.error.foregroundColor
            let successColor = BadgeLevel.success.foregroundColor

            // Verify colors are not nil (they're Color instances)
            XCTAssertNotNil(infoColor)
            XCTAssertNotNil(warningColor)
            XCTAssertNotNil(errorColor)
            XCTAssertNotNil(successColor)
        }

        /// Verifies that each BadgeLevel has an accessibility label
        func testBadgeLevelAccessibilityLabels() {
            XCTAssertEqual(BadgeLevel.info.accessibilityLabel, "Information")
            XCTAssertEqual(BadgeLevel.warning.accessibilityLabel, "Warning")
            XCTAssertEqual(BadgeLevel.error.accessibilityLabel, "Error")
            XCTAssertEqual(BadgeLevel.success.accessibilityLabel, "Success")
        }

        /// Verifies that each BadgeLevel has a string value for serialization
        func testBadgeLevelStringValues() {
            XCTAssertEqual(BadgeLevel.info.stringValue, "info")
            XCTAssertEqual(BadgeLevel.warning.stringValue, "warning")
            XCTAssertEqual(BadgeLevel.error.stringValue, "error")
            XCTAssertEqual(BadgeLevel.success.stringValue, "success")
        }

        /// Verifies that each BadgeLevel has an associated SF Symbol icon
        func testBadgeLevelIcons() {
            XCTAssertEqual(BadgeLevel.info.iconName, "info.circle.fill")
            XCTAssertEqual(BadgeLevel.warning.iconName, "exclamationmark.triangle.fill")
            XCTAssertEqual(BadgeLevel.error.iconName, "xmark.circle.fill")
            XCTAssertEqual(BadgeLevel.success.iconName, "checkmark.circle.fill")
        }

        // MARK: - Text Content Tests

        /// Verifies that Badge displays short text correctly
        func testBadgeShortText() {
            let badge = Badge(text: "OK", level: .success)

            XCTAssertEqual(badge.text, "OK")
        }

        /// Verifies that Badge displays medium-length text correctly
        func testBadgeMediumText() {
            let badge = Badge(text: "PENDING", level: .info)

            XCTAssertEqual(badge.text, "PENDING")
        }

        /// Verifies that Badge displays long text correctly
        func testBadgeLongText() {
            let badge = Badge(text: "ATTENTION REQUIRED", level: .warning)

            XCTAssertEqual(badge.text, "ATTENTION REQUIRED")
        }

        /// Verifies that Badge handles empty text string
        func testBadgeEmptyText() {
            let badge = Badge(text: "", level: .info)

            XCTAssertEqual(badge.text, "")
            XCTAssertNotNil(badge.body)
        }

        // MARK: - Icon Display Tests

        /// Verifies that Badge without icon has showIcon set to false
        func testBadgeWithoutIcon() {
            let badge = Badge(text: "TEST", level: .info)

            XCTAssertFalse(badge.showIcon)
        }

        /// Verifies that Badge with icon has showIcon set to true
        func testBadgeWithIcon() {
            let badge = Badge(text: "TEST", level: .info, showIcon: true)

            XCTAssertTrue(badge.showIcon)
        }

        /// Verifies that Badge with icon for each level
        func testBadgeIconForAllLevels() {
            let infoBadge = Badge(text: "INFO", level: .info, showIcon: true)
            let warningBadge = Badge(text: "WARNING", level: .warning, showIcon: true)
            let errorBadge = Badge(text: "ERROR", level: .error, showIcon: true)
            let successBadge = Badge(text: "SUCCESS", level: .success, showIcon: true)

            XCTAssertTrue(infoBadge.showIcon)
            XCTAssertTrue(warningBadge.showIcon)
            XCTAssertTrue(errorBadge.showIcon)
            XCTAssertTrue(successBadge.showIcon)
        }

        // MARK: - View Rendering Tests

        /// Verifies that Badge body is not nil
        func testBadgeBodyNotNil() {
            let badge = Badge(text: "TEST", level: .info)

            XCTAssertNotNil(badge.body)
        }

        /// Verifies that Badge body renders for all levels
        func testBadgeBodyRendersForAllLevels() {
            for level in BadgeLevel.allCases {
                let badge = Badge(text: "TEST", level: level)
                XCTAssertNotNil(badge.body, "Badge body should render for level: \(level)")
            }
        }

        /// Verifies that Badge body renders with icon for all levels
        func testBadgeBodyRendersWithIconForAllLevels() {
            for level in BadgeLevel.allCases {
                let badge = Badge(text: "TEST", level: level, showIcon: true)
                XCTAssertNotNil(
                    badge.body, "Badge body with icon should render for level: \(level)")
            }
        }

        // MARK: - Platform Compatibility Tests

        /// Verifies Badge works on current platform
        func testBadgePlatformCompatibility() {
            #if os(iOS)
                let badge = Badge(text: "iOS", level: .success)
                XCTAssertNotNil(badge.body, "Badge should work on iOS")
            #elseif os(macOS)
                let badge = Badge(text: "macOS", level: .success)
                XCTAssertNotNil(badge.body, "Badge should work on macOS")
            #else
                XCTFail("Unsupported platform")
            #endif
        }

        // MARK: - AgentDescribable Tests (iOS 17+/macOS 14+)

        @available(iOS 17.0, macOS 14.0, *) @MainActor func testBadgeAgentDescribableComponentType()
        {
            let badge = Badge(text: "TEST", level: .info)

            XCTAssertEqual(badge.componentType, "Badge")
        }

        @available(iOS 17.0, macOS 14.0, *) @MainActor func testBadgeAgentDescribableProperties() {
            let badge = Badge(text: "TEST", level: .warning, showIcon: true)
            let properties = badge.properties

            XCTAssertEqual(properties["text"] as? String, "TEST")
            XCTAssertEqual(properties["level"] as? String, "warning")
            XCTAssertEqual(properties["showIcon"] as? Bool, true)
        }

        @available(iOS 17.0, macOS 14.0, *) @MainActor func testBadgeAgentDescribableSemantics() {
            let badge = Badge(text: "ERROR", level: .error, showIcon: true)
            let semantics = badge.semantics

            XCTAssertTrue(semantics.contains("ERROR"))
            XCTAssertTrue(semantics.contains("error"))
            XCTAssertTrue(semantics.contains("true") || semantics.contains("icon"))
        }

        // MARK: - Real-World Usage Tests

        /// Verifies Badge usage as file type indicator
        func testBadgeAsFileTypeIndicator() {
            let validBadge = Badge(text: "VALID", level: .success, showIcon: true)
            let invalidBadge = Badge(text: "INVALID", level: .error, showIcon: true)

            XCTAssertEqual(validBadge.text, "VALID")
            XCTAssertEqual(validBadge.level, .success)
            XCTAssertEqual(invalidBadge.text, "INVALID")
            XCTAssertEqual(invalidBadge.level, .error)
        }

        /// Verifies Badge usage as status indicator
        func testBadgeAsStatusIndicator() {
            let processingBadge = Badge(text: "PROCESSING", level: .info)
            let completedBadge = Badge(text: "COMPLETED", level: .success)
            let failedBadge = Badge(text: "FAILED", level: .error)

            XCTAssertEqual(processingBadge.level, .info)
            XCTAssertEqual(completedBadge.level, .success)
            XCTAssertEqual(failedBadge.level, .error)
        }

        /// Verifies Badge usage in warning scenarios
        func testBadgeAsWarningIndicator() {
            let reviewBadge = Badge(text: "NEEDS REVIEW", level: .warning, showIcon: true)
            let attentionBadge = Badge(text: "ATTENTION", level: .warning)

            XCTAssertEqual(reviewBadge.level, .warning)
            XCTAssertTrue(reviewBadge.showIcon)
            XCTAssertEqual(attentionBadge.level, .warning)
            XCTAssertFalse(attentionBadge.showIcon)
        }

        // MARK: - BadgeLevel Equatable Tests

        /// Verifies that BadgeLevel conforms to Equatable
        func testBadgeLevelEquatable() {
            XCTAssertEqual(BadgeLevel.info, BadgeLevel.info)
            XCTAssertEqual(BadgeLevel.warning, BadgeLevel.warning)
            XCTAssertEqual(BadgeLevel.error, BadgeLevel.error)
            XCTAssertEqual(BadgeLevel.success, BadgeLevel.success)

            XCTAssertNotEqual(BadgeLevel.info, BadgeLevel.warning)
            XCTAssertNotEqual(BadgeLevel.error, BadgeLevel.success)
        }

        // MARK: - Edge Case Tests

        /// Verifies Badge behavior with special characters
        func testBadgeWithSpecialCharacters() {
            let badge = Badge(text: "⚠️ WARNING", level: .warning)

            XCTAssertEqual(badge.text, "⚠️ WARNING")
            XCTAssertNotNil(badge.body)
        }

        /// Verifies Badge behavior with numeric text
        func testBadgeWithNumericText() {
            let badge = Badge(text: "404", level: .error)

            XCTAssertEqual(badge.text, "404")
            XCTAssertNotNil(badge.body)
        }

        /// Verifies Badge behavior with mixed case text
        func testBadgeWithMixedCaseText() {
            let badge = Badge(text: "New Feature", level: .info)

            XCTAssertEqual(badge.text, "New Feature")
            XCTAssertNotNil(badge.body)
        }
    }

// MARK: - Test Documentation

/*
 ## Badge Component Test Coverage for I0.2

 This comprehensive test suite covers:

 ### Initialization & Properties (8 tests)
 - Basic initialization with required parameters
 - Initialization with optional icon parameter
 - Text content variations (short, medium, long, empty)
 - Icon display flag

 ### Semantic Levels (11 tests)
 - All four badge levels (info, warning, error, success)
 - BadgeLevel enum case availability and count
 - Background and foreground colors for each level
 - Accessibility labels for each level
 - String values for serialization
 - SF Symbol icons for each level
 - Equatable conformance

 ### View Rendering (3 tests)
 - Body rendering for all levels
 - Body rendering with icons
 - Non-nil body verification

 ### Platform Compatibility (1 test)
 - iOS and macOS platform support

 ### AgentDescribable Protocol (3 tests, iOS 17+/macOS 14+)
 - Component type identification
 - Properties serialization
 - Semantic description generation

 ### Real-World Usage (3 tests)
 - File type indicators
 - Status indicators
 - Warning scenarios

 ### Edge Cases (3 tests)
 - Special characters in text
 - Numeric text
 - Mixed case text

 **Total Tests:** 32
 **Coverage Target:** ≥80% of Badge component code paths
 **Phase:** I0.2 - Create Integration Test Suite

 ## Related Files
 - FoundationUI/Sources/FoundationUI/Components/Badge.swift
 - FoundationUI/Sources/FoundationUI/Modifiers/BadgeChipStyle.swift
 - DOCS/INPROGRESS/212_I0_2_Create_Integration_Test_Suite.md
 */#endif
