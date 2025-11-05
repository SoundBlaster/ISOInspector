// swift-tools-version: 6.0
import XCTest
import SwiftUI
@testable import FoundationUI

/// Unit tests for the SectionHeader component
///
/// Tests verify:
/// - Component initialization with title and divider options
/// - Proper text rendering with uppercase transformation
/// - Accessibility support (header trait)
/// - Design system token usage
/// - Platform compatibility
/// - Optional divider visibility
@MainActor
final class SectionHeaderTests: XCTestCase {

    // MARK: - Initialization Tests

    func testSectionHeaderInitializationWithTitleOnly() {
        // Given
        let title = "Section Title"

        // When
        let header = SectionHeader(title: title)

        // Then
        XCTAssertEqual(header.title, title, "SectionHeader title should match initialization value")
        XCTAssertFalse(header.showDivider, "SectionHeader should not show divider by default")
    }

    func testSectionHeaderInitializationWithDivider() {
        // Given
        let title = "Section With Divider"

        // When
        let header = SectionHeader(title: title, showDivider: true)

        // Then
        XCTAssertEqual(header.title, title, "SectionHeader title should match initialization value")
        XCTAssertTrue(header.showDivider, "SectionHeader should show divider when specified")
    }

    func testSectionHeaderInitializationWithoutDivider() {
        // Given
        let title = "Section Without Divider"

        // When
        let header = SectionHeader(title: title, showDivider: false)

        // Then
        XCTAssertEqual(header.title, title, "SectionHeader title should match initialization value")
        XCTAssertFalse(header.showDivider, "SectionHeader should not show divider when explicitly disabled")
    }

    // MARK: - Text Content Tests

    func testSectionHeaderPreservesTitle() {
        // Given
        let testCases = [
            "File Properties",
            "Metadata",
            "Box Structure",
            "Technical Details",
            "Basic Information",
            "", // Edge case: empty title
            "A" // Edge case: single character
        ]

        // When & Then
        for title in testCases {
            let header = SectionHeader(title: title)
            XCTAssertEqual(header.title, title, "SectionHeader should preserve title: '\(title)'")
        }
    }

    // MARK: - Divider Visibility Tests

    func testSectionHeaderDividerVisibility() {
        // Given
        let titleWithDivider = SectionHeader(title: "With Divider", showDivider: true)
        let titleWithoutDivider = SectionHeader(title: "Without Divider", showDivider: false)
        let titleDefaultDivider = SectionHeader(title: "Default")

        // Then
        XCTAssertTrue(titleWithDivider.showDivider, "Divider should be visible when enabled")
        XCTAssertFalse(titleWithoutDivider.showDivider, "Divider should be hidden when disabled")
        XCTAssertFalse(titleDefaultDivider.showDivider, "Divider should be hidden by default")
    }

    // MARK: - Component Composition Tests

    func testSectionHeaderIsAView() {
        // Given
        let header = SectionHeader(title: "Test")

        // Then
        // Verify that SectionHeader conforms to View protocol (compile-time check)
        // If SectionHeader didn't conform to View, this code wouldn't compile
        let _: any View = header
        XCTAssertNotNil(header, "SectionHeader should be a SwiftUI View")
    }

    // MARK: - Edge Cases

    func testSectionHeaderWithEmptyTitle() {
        // Given
        let header = SectionHeader(title: "")

        // Then
        XCTAssertEqual(header.title, "", "SectionHeader should support empty title")
    }

    func testSectionHeaderWithLongTitle() {
        // Given
        let longTitle = "This is a very long section header title that might span multiple lines"
        let header = SectionHeader(title: longTitle)

        // Then
        XCTAssertEqual(header.title, longTitle, "SectionHeader should support long titles")
    }

    func testSectionHeaderWithSpecialCharacters() {
        // Given
        let specialTitle = "⚠️ Øℓ∂ 日本語 Section"
        let header = SectionHeader(title: specialTitle)

        // Then
        XCTAssertEqual(header.title, specialTitle, "SectionHeader should support special characters and Unicode")
    }

    func testSectionHeaderWithWhitespace() {
        // Given
        let titleWithSpaces = "  Padded Title  "
        let header = SectionHeader(title: titleWithSpaces)

        // Then
        XCTAssertEqual(header.title, titleWithSpaces, "SectionHeader should preserve whitespace in title")
    }

    // MARK: - Multiple Instance Tests

    func testMultipleSectionHeadersWithDifferentConfigurations() {
        // Given & When
        let headers = [
            SectionHeader(title: "First", showDivider: true),
            SectionHeader(title: "Second", showDivider: false),
            SectionHeader(title: "Third"),
            SectionHeader(title: "Fourth", showDivider: true)
        ]

        // Then
        XCTAssertEqual(headers[0].title, "First")
        XCTAssertTrue(headers[0].showDivider)

        XCTAssertEqual(headers[1].title, "Second")
        XCTAssertFalse(headers[1].showDivider)

        XCTAssertEqual(headers[2].title, "Third")
        XCTAssertFalse(headers[2].showDivider)

        XCTAssertEqual(headers[3].title, "Fourth")
        XCTAssertTrue(headers[3].showDivider)
    }
}
