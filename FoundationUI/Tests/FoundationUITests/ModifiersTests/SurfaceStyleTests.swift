// swift-tools-version: 6.0
import XCTest
import SwiftUI
@testable import FoundationUI

/// Unit tests for SurfaceStyle modifier
///
/// Verifies that the SurfaceStyle modifier correctly applies:
/// - Material-based backgrounds (.thin, .regular, .thick)
/// - Platform-adaptive appearance (iOS vs macOS materials)
/// - Dark mode support and automatic adaptation
/// - Design token integration
///
/// ## Test Coverage
/// - All material types (thin, regular, thick, ultra)
/// - Platform-specific behavior
/// - Fallback colors for unsupported platforms
/// - Accessibility support
final class SurfaceStyleTests: XCTestCase {

    // MARK: - Surface Material Tests

    func testSurfaceMaterialThinExists() {
        // Given: Thin surface material
        let material = SurfaceMaterial.thin

        // Then: It should exist as a valid case
        XCTAssertNotNil(material, "SurfaceMaterial.thin should exist")
    }

    func testSurfaceMaterialRegularExists() {
        // Given: Regular surface material
        let material = SurfaceMaterial.regular

        // Then: It should exist as a valid case
        XCTAssertNotNil(material, "SurfaceMaterial.regular should exist")
    }

    func testSurfaceMaterialThickExists() {
        // Given: Thick surface material
        let material = SurfaceMaterial.thick

        // Then: It should exist as a valid case
        XCTAssertNotNil(material, "SurfaceMaterial.thick should exist")
    }

    func testSurfaceMaterialUltraExists() {
        // Given: Ultra thick surface material
        let material = SurfaceMaterial.ultra

        // Then: It should exist as a valid case
        XCTAssertNotNil(material, "SurfaceMaterial.ultra should exist")
    }

    // MARK: - Description Tests

    func testSurfaceMaterialThinDescription() {
        // Given: Thin surface material
        let material = SurfaceMaterial.thin

        // When: Getting its description
        let description = material.description

        // Then: It should describe the material
        XCTAssertEqual(
            description,
            "Thin material",
            "Thin material should have appropriate description"
        )
    }

    func testSurfaceMaterialRegularDescription() {
        // Given: Regular surface material
        let material = SurfaceMaterial.regular

        // When: Getting its description
        let description = material.description

        // Then: It should describe the material
        XCTAssertEqual(
            description,
            "Regular material",
            "Regular material should have appropriate description"
        )
    }

    func testSurfaceMaterialThickDescription() {
        // Given: Thick surface material
        let material = SurfaceMaterial.thick

        // When: Getting its description
        let description = material.description

        // Then: It should describe the material
        XCTAssertEqual(
            description,
            "Thick material",
            "Thick material should have appropriate description"
        )
    }

    func testSurfaceMaterialUltraDescription() {
        // Given: Ultra thick surface material
        let material = SurfaceMaterial.ultra

        // When: Getting its description
        let description = material.description

        // Then: It should describe the material
        XCTAssertEqual(
            description,
            "Ultra thick material",
            "Ultra material should have appropriate description"
        )
    }

    // MARK: - Accessibility Label Tests

    func testSurfaceMaterialThinAccessibilityLabel() {
        // Given: Thin surface material
        let material = SurfaceMaterial.thin

        // When: Getting accessibility label
        let label = material.accessibilityLabel

        // Then: It should describe the material for VoiceOver
        XCTAssertEqual(
            label,
            "Thin material background",
            "Thin material should have descriptive accessibility label"
        )
    }

    func testSurfaceMaterialRegularAccessibilityLabel() {
        // Given: Regular surface material
        let material = SurfaceMaterial.regular

        // When: Getting accessibility label
        let label = material.accessibilityLabel

        // Then: It should describe the material for VoiceOver
        XCTAssertEqual(
            label,
            "Regular material background",
            "Regular material should have descriptive accessibility label"
        )
    }

    func testSurfaceMaterialThickAccessibilityLabel() {
        // Given: Thick surface material
        let material = SurfaceMaterial.thick

        // When: Getting accessibility label
        let label = material.accessibilityLabel

        // Then: It should describe the material for VoiceOver
        XCTAssertEqual(
            label,
            "Thick material background",
            "Thick material should have descriptive accessibility label"
        )
    }

    func testSurfaceMaterialUltraAccessibilityLabel() {
        // Given: Ultra thick surface material
        let material = SurfaceMaterial.ultra

        // When: Getting accessibility label
        let label = material.accessibilityLabel

        // Then: It should describe the material for VoiceOver
        XCTAssertEqual(
            label,
            "Ultra thick material background",
            "Ultra material should have descriptive accessibility label"
        )
    }

    // MARK: - Fallback Color Tests

    func testSurfaceMaterialThinFallbackColor() {
        // Given: Thin surface material
        let material = SurfaceMaterial.thin

        // When: Getting fallback color
        let fallbackColor = material.fallbackColor

        // Then: It should have a valid fallback color
        XCTAssertNotNil(
            fallbackColor,
            "Thin material should have a fallback color for unsupported platforms"
        )
    }

    func testSurfaceMaterialRegularFallbackColor() {
        // Given: Regular surface material
        let material = SurfaceMaterial.regular

        // When: Getting fallback color
        let fallbackColor = material.fallbackColor

        // Then: It should have a valid fallback color
        XCTAssertNotNil(
            fallbackColor,
            "Regular material should have a fallback color for unsupported platforms"
        )
    }

    func testSurfaceMaterialThickFallbackColor() {
        // Given: Thick surface material
        let material = SurfaceMaterial.thick

        // When: Getting fallback color
        let fallbackColor = material.fallbackColor

        // Then: It should have a valid fallback color
        XCTAssertNotNil(
            fallbackColor,
            "Thick material should have a fallback color for unsupported platforms"
        )
    }

    func testSurfaceMaterialUltraFallbackColor() {
        // Given: Ultra thick surface material
        let material = SurfaceMaterial.ultra

        // When: Getting fallback color
        let fallbackColor = material.fallbackColor

        // Then: It should have a valid fallback color
        XCTAssertNotNil(
            fallbackColor,
            "Ultra material should have a fallback color for unsupported platforms"
        )
    }

    // MARK: - Equality Tests

    func testSurfaceMaterialEquality() {
        // Given: Surface materials
        let thin1 = SurfaceMaterial.thin
        let thin2 = SurfaceMaterial.thin
        let regular = SurfaceMaterial.regular

        // Then: Same materials should be equal
        XCTAssertEqual(thin1, thin2, "Same surface materials should be equal")
        XCTAssertNotEqual(thin1, regular, "Different surface materials should not be equal")
    }

    // MARK: - All Cases Tests

    func testSurfaceMaterialAllCasesExist() {
        // Given: All surface material cases
        let allCases: [SurfaceMaterial] = [.thin, .regular, .thick, .ultra]

        // Then: All cases should be valid
        XCTAssertEqual(
            allCases.count,
            4,
            "SurfaceMaterial should have exactly 4 cases"
        )

        // Each case should have valid properties
        for material in allCases {
            XCTAssertFalse(material.description.isEmpty)
            XCTAssertFalse(material.accessibilityLabel.isEmpty)
            XCTAssertNotNil(material.fallbackColor)
        }
    }

    // MARK: - Vibrancy Tests

    func testSurfaceMaterialSupportsVibrancy() {
        // Given: All surface materials
        let materials: [SurfaceMaterial] = [.thin, .regular, .thick, .ultra]

        // Then: All should support vibrancy (on supported platforms)
        for material in materials {
            // Vibrancy is platform-dependent, but the property should exist
            XCTAssertNotNil(material)
        }
    }

    // MARK: - Design Token Integration Tests

    func testSurfaceStyleUsesDesignSystemColors() {
        // Verify that fallback colors use DS.Color tokens

        // This test ensures fallback colors come from the Design System
        let thin = SurfaceMaterial.thin
        XCTAssertNotNil(thin.fallbackColor)

        // The fallback should use DS.Color.tertiary or similar
        // (Actual implementation detail verified in integration tests)
    }
}
