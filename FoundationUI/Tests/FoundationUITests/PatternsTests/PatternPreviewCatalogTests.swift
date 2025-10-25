// swift-tools-version: 6.0
import XCTest
import SwiftUI
@testable import FoundationUI

/// Unit tests validating the pattern preview catalog metadata.
///
/// These tests ensure the preview catalogue covers all patterns,
/// provides platform variations, and surfaces accessibility-focused
/// examples to satisfy the Composable Clarity requirements before
/// implementation.
@MainActor
final class PatternPreviewCatalogTests: XCTestCase {

    func testCatalogCoversAllPatterns() {
        // Given
        let configuration = PatternPreviewCatalogConfiguration.default

        // When
        let patterns = Set(configuration.sections.map(\.pattern))

        // Then
        XCTAssertEqual(
            patterns,
            Set(PatternPreviewCatalogConfiguration.Section.Pattern.allCases),
            "Preview catalogue should surface every pattern section"
        )
    }

    func testEachPatternHasMultipleScenarios() {
        // Given
        let configuration = PatternPreviewCatalogConfiguration.default

        // Then
        for section in configuration.sections {
            XCTAssertGreaterThanOrEqual(
                section.scenarios.count,
                2,
                "Each pattern should provide multiple preview scenarios"
            )
        }
    }

    func testCatalogProvidesPlatformCoverage() {
        // Given
        let configuration = PatternPreviewCatalogConfiguration.default

        // When
        let platforms = Set(configuration.sections.flatMap { section in
            section.scenarios.flatMap { scenario in
                scenario.traits.compactMap { trait -> PatternPreviewCatalogConfiguration.Scenario.Trait.Platform? in
                    if case let .platform(platform) = trait {
                        return platform
                    }
                    return nil
                }
            }
        })

        // Then
        XCTAssertEqual(
            platforms,
            Set(PatternPreviewCatalogConfiguration.Scenario.Trait.Platform.allCases),
            "Preview catalogue should highlight iOS, iPadOS, and macOS variations"
        )
    }

    func testCatalogIncludesAccessibilityScenario() {
        // Given
        let configuration = PatternPreviewCatalogConfiguration.default

        // When
        let containsAccessibilityScenario = configuration.sections.contains { section in
            section.scenarios.contains { scenario in
                scenario.traits.contains(.accessibility)
            }
        }

        // Then
        XCTAssertTrue(
            containsAccessibilityScenario,
            "Preview catalogue should include at least one accessibility-focused scenario"
        )
    }

    func testCatalogIncludesDarkModeScenario() {
        // Given
        let configuration = PatternPreviewCatalogConfiguration.default

        // When
        let containsDarkModeScenario = configuration.sections.contains { section in
            section.scenarios.contains { scenario in
                scenario.traits.contains(.darkMode)
            }
        }

        // Then
        XCTAssertTrue(
            containsDarkModeScenario,
            "Preview catalogue should demonstrate Dark Mode rendering"
        )
    }
}
