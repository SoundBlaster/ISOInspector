// swift-tools-version: 6.0
#if canImport(SwiftUI)
import XCTest
import SwiftUI
@testable import FoundationUI

/// Tests for DynamicTypeSize extensions
///
/// Verifies semantic naming extensions for Dynamic Type sizes.
/// Note: DynamicTypeSize is already Comparable in SwiftUI, these tests verify
/// that our semantic names work correctly with built-in comparison operators.
@MainActor
final class DynamicTypeSizeExtensionsTests: XCTestCase {

    // MARK: - Semantic Names Tests

    func testAccessibilityMediumMapsToAccessibility1() {
        XCTAssertEqual(DynamicTypeSize.accessibilityMedium, .accessibility1,
                       "accessibilityMedium should map to accessibility1")
    }

    func testAccessibilityLargeMapsToAccessibility2() {
        XCTAssertEqual(DynamicTypeSize.accessibilityLarge, .accessibility2,
                       "accessibilityLarge should map to accessibility2")
    }

    func testAccessibilityXLargeMapsToAccessibility3() {
        XCTAssertEqual(DynamicTypeSize.accessibilityXLarge, .accessibility3,
                       "accessibilityXLarge should map to accessibility3")
    }

    func testAccessibilityXxLargeMapsToAccessibility4() {
        XCTAssertEqual(DynamicTypeSize.accessibilityXxLarge, .accessibility4,
                       "accessibilityXxLarge should map to accessibility4")
    }

    func testAccessibilityXxxLargeMapsToAccessibility5() {
        XCTAssertEqual(DynamicTypeSize.accessibilityXxxLarge, .accessibility5,
                       "accessibilityXxxLarge should map to accessibility5")
    }

    // MARK: - Comparable Tests (using SwiftUI's built-in Comparable conformance)

    func testLessThanOperator() {
        XCTAssertTrue(DynamicTypeSize.small < .large,
                      "small should be less than large")
        XCTAssertTrue(DynamicTypeSize.large < .accessibilityMedium,
                      "large should be less than accessibilityMedium")
        XCTAssertFalse(DynamicTypeSize.xLarge < .medium,
                       "xLarge should not be less than medium")
    }

    func testGreaterThanOperator() {
        XCTAssertTrue(DynamicTypeSize.large > .small,
                      "large should be greater than small")
        XCTAssertTrue(DynamicTypeSize.accessibilityLarge > .xLarge,
                      "accessibilityLarge should be greater than xLarge")
        XCTAssertFalse(DynamicTypeSize.medium > .xxLarge,
                       "medium should not be greater than xxLarge")
    }

    func testLessThanOrEqualOperator() {
        XCTAssertTrue(DynamicTypeSize.small <= .large,
                      "small should be <= large")
        XCTAssertTrue(DynamicTypeSize.large <= .large,
                      "large should be <= large (equal)")
        XCTAssertFalse(DynamicTypeSize.accessibilityXLarge <= .medium,
                       "accessibilityXLarge should not be <= medium")
    }

    func testGreaterThanOrEqualOperator() {
        XCTAssertTrue(DynamicTypeSize.large >= .small,
                      "large should be >= small")
        XCTAssertTrue(DynamicTypeSize.accessibilityMedium >= .accessibilityMedium,
                      "accessibilityMedium should be >= accessibilityMedium (equal)")
        XCTAssertFalse(DynamicTypeSize.xSmall >= .xxxLarge,
                       "xSmall should not be >= xxxLarge")
    }

    func testEqualityOperator() {
        XCTAssertTrue(DynamicTypeSize.large == .large,
                      "large should equal large")
        XCTAssertTrue(DynamicTypeSize.accessibilityMedium == .accessibility1,
                      "accessibilityMedium should equal accessibility1")
        XCTAssertFalse(DynamicTypeSize.small == .large,
                       "small should not equal large")
    }

    // MARK: - Sorting Tests

    func testSortingAllSizes() {
        let unsorted: [DynamicTypeSize] = [
            .accessibilityLarge,
            .small,
            .xxxLarge,
            .xSmall,
            .accessibilityMedium,
            .large,
            .medium
        ]

        let sorted = unsorted.sorted()

        // Verify ordering
        XCTAssertEqual(sorted[0], .xSmall, "First should be xSmall")
        XCTAssertEqual(sorted[1], .small, "Second should be small")
        XCTAssertEqual(sorted[2], .medium, "Third should be medium")
        XCTAssertEqual(sorted[3], .large, "Fourth should be large")
        XCTAssertEqual(sorted[4], .xxxLarge, "Fifth should be xxxLarge")
        XCTAssertEqual(sorted[5], .accessibilityMedium, "Sixth should be accessibilityMedium")
        XCTAssertEqual(sorted[6], .accessibilityLarge, "Seventh should be accessibilityLarge")
    }

    func testCompleteOrderingSequence() {
        let completeSequence: [DynamicTypeSize] = [
            .xSmall,
            .small,
            .medium,
            .large,
            .xLarge,
            .xxLarge,
            .xxxLarge,
            .accessibilityMedium,
            .accessibilityLarge,
            .accessibilityXLarge,
            .accessibilityXxLarge,
            .accessibilityXxxLarge
        ]

        // Verify each element is less than the next
        for i in 0..<(completeSequence.count - 1) {
            XCTAssertTrue(completeSequence[i] < completeSequence[i + 1],
                          "\(completeSequence[i]) should be < \(completeSequence[i + 1])")
        }
    }

    // MARK: - Range Tests

    func testAccessibilitySizeRange() {
        let allSizes: [DynamicTypeSize] = [
            .xSmall, .small, .medium, .large, .xLarge,
            .xxLarge, .xxxLarge,
            .accessibilityMedium, .accessibilityLarge,
            .accessibilityXLarge, .accessibilityXxLarge,
            .accessibilityXxxLarge
        ]

        let accessibilitySizes = allSizes.filter { $0 >= .accessibilityMedium }

        XCTAssertEqual(accessibilitySizes.count, 5,
                       "Should have 5 accessibility sizes")
        XCTAssertTrue(accessibilitySizes.contains(.accessibilityMedium))
        XCTAssertTrue(accessibilitySizes.contains(.accessibilityLarge))
        XCTAssertTrue(accessibilitySizes.contains(.accessibilityXLarge))
        XCTAssertTrue(accessibilitySizes.contains(.accessibilityXxLarge))
        XCTAssertTrue(accessibilitySizes.contains(.accessibilityXxxLarge))
    }

    func testMinMaxSizes() {
        let sizes: [DynamicTypeSize] = [.large, .xSmall, .accessibilityLarge, .medium]

        let minSize = sizes.min()
        let maxSize = sizes.max()

        XCTAssertEqual(minSize, .xSmall, "min() should return xSmall")
        XCTAssertEqual(maxSize, .accessibilityLarge, "max() should return accessibilityLarge")
    }

    // MARK: - Integration with AccessibilityHelpers

    func testIntegrationWithIsAccessibilitySize() {
        XCTAssertFalse(AccessibilityHelpers.isAccessibilitySize(.small),
                       "small should not be accessibility size")
        XCTAssertFalse(AccessibilityHelpers.isAccessibilitySize(.large),
                       "large should not be accessibility size")
        XCTAssertFalse(AccessibilityHelpers.isAccessibilitySize(.xxxLarge),
                       "xxxLarge should not be accessibility size")

        XCTAssertTrue(AccessibilityHelpers.isAccessibilitySize(.accessibilityMedium),
                      "accessibilityMedium should be accessibility size")
        XCTAssertTrue(AccessibilityHelpers.isAccessibilitySize(.accessibilityLarge),
                      "accessibilityLarge should be accessibility size")
        XCTAssertTrue(AccessibilityHelpers.isAccessibilitySize(.accessibilityXxxLarge),
                      "accessibilityXxxLarge should be accessibility size")
    }
}
#endif
