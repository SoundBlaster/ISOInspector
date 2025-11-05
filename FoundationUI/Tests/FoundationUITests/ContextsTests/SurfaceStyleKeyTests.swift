import XCTest
@testable import FoundationUI
#if canImport(SwiftUI)
import SwiftUI

/// Comprehensive unit tests for SurfaceStyleKey environment key
///
/// Tests environment key behavior, propagation, and integration with
/// SwiftUI's environment system following FoundationUI principles:
/// - **Zero magic numbers**: All values use DS tokens
/// - **100% API coverage**: Tests all public APIs
/// - **Edge cases**: Tests all material types and scenarios
///
/// ## Test Categories
/// - Default value tests
/// - Environment propagation tests
/// - Material type tests
/// - Integration tests with views
@MainActor
final class SurfaceStyleKeyTests: XCTestCase {

    // MARK: - Default Value Tests

    /// Tests that SurfaceStyleKey default value is .regular
    ///
    /// **Given**: SurfaceStyleKey class
    /// **When**: Reading defaultValue property
    /// **Then**: Should return .regular material
    ///
    /// **Design Rationale**: .regular provides balanced translucency
    /// suitable for most UI contexts
    func testSurfaceStyleKey_DefaultValue_IsRegular() {
        // Act
        let defaultValue = SurfaceStyleKey.defaultValue

        // Assert
        XCTAssertEqual(
            defaultValue,
            .regular,
            "SurfaceStyleKey default value should be .regular material"
        )
    }

    /// Tests that EnvironmentValues uses correct default surface style
    ///
    /// **Given**: Fresh EnvironmentValues instance
    /// **When**: Reading surfaceStyle property without explicit setting
    /// **Then**: Should return .regular (the default)
    ///
    /// **Importance**: Ensures views have consistent appearance when
    /// no explicit surface style is specified
    func testEnvironmentValues_DefaultSurfaceStyle_IsRegular() {
        // Arrange
        let environment = EnvironmentValues()

        // Act
        let surfaceStyle = environment.surfaceStyle

        // Assert
        XCTAssertEqual(
            surfaceStyle,
            .regular,
            "EnvironmentValues should default to .regular surface style"
        )
    }

    // MARK: - Environment Propagation Tests

    /// Tests that custom surface style can be set on EnvironmentValues
    ///
    /// **Given**: EnvironmentValues instance
    /// **When**: Setting surfaceStyle to a specific value
    /// **Then**: Should store and return that value
    ///
    /// **Coverage**: Tests setter functionality of environment property
    func testEnvironmentValues_SetSurfaceStyle_StoresValue() {
        // Arrange
        var environment = EnvironmentValues()

        // Act
        environment.surfaceStyle = .thick

        // Assert
        XCTAssertEqual(
            environment.surfaceStyle,
            .thick,
            "EnvironmentValues should store and return set surface style"
        )
    }

    /// Tests that all material types can be set and retrieved
    ///
    /// **Given**: EnvironmentValues instance
    /// **When**: Setting each material type (.thin, .regular, .thick, .ultra)
    /// **Then**: Each should be stored and retrieved correctly
    ///
    /// **Coverage**: Ensures all SurfaceMaterial cases work with environment
    func testEnvironmentValues_AllMaterialTypes_CanBeSetAndRetrieved() {
        // Arrange
        let materialTypes: [SurfaceMaterial] = [.thin, .regular, .thick, .ultra]
        var environment = EnvironmentValues()

        // Act & Assert
        for material in materialTypes {
            environment.surfaceStyle = material
            XCTAssertEqual(
                environment.surfaceStyle,
                material,
                "Material type \(material.description) should be stored correctly"
            )
        }
    }

    /// Tests that surface style changes can be detected
    ///
    /// **Given**: EnvironmentValues with initial surface style
    /// **When**: Changing surface style multiple times
    /// **Then**: Each change should be reflected correctly
    ///
    /// **Use Case**: Views may need to react to surface style changes
    func testEnvironmentValues_SurfaceStyleChanges_AreDetected() {
        // Arrange
        var environment = EnvironmentValues()

        // Act & Assert - Initial state
        XCTAssertEqual(environment.surfaceStyle, .regular, "Should start with default .regular")

        // Change 1: thin
        environment.surfaceStyle = .thin
        XCTAssertEqual(environment.surfaceStyle, .thin, "Should update to .thin")

        // Change 2: ultra
        environment.surfaceStyle = .ultra
        XCTAssertEqual(environment.surfaceStyle, .ultra, "Should update to .ultra")

        // Change 3: back to regular
        environment.surfaceStyle = .regular
        XCTAssertEqual(environment.surfaceStyle, .regular, "Should update back to .regular")
    }

    // MARK: - Material Type Tests

    /// Tests that .thin material type works with environment key
    ///
    /// **Given**: EnvironmentValues
    /// **When**: Setting surface style to .thin
    /// **Then**: Should store .thin correctly
    func testSurfaceStyleKey_ThinMaterial_WorksCorrectly() {
        // Arrange
        var environment = EnvironmentValues()

        // Act
        environment.surfaceStyle = .thin

        // Assert
        XCTAssertEqual(environment.surfaceStyle, .thin)
        XCTAssertEqual(environment.surfaceStyle.description, "Thin material")
    }

    /// Tests that .regular material type works with environment key
    ///
    /// **Given**: EnvironmentValues
    /// **When**: Setting surface style to .regular
    /// **Then**: Should store .regular correctly
    func testSurfaceStyleKey_RegularMaterial_WorksCorrectly() {
        // Arrange
        var environment = EnvironmentValues()

        // Act
        environment.surfaceStyle = .regular

        // Assert
        XCTAssertEqual(environment.surfaceStyle, .regular)
        XCTAssertEqual(environment.surfaceStyle.description, "Regular material")
    }

    /// Tests that .thick material type works with environment key
    ///
    /// **Given**: EnvironmentValues
    /// **When**: Setting surface style to .thick
    /// **Then**: Should store .thick correctly
    func testSurfaceStyleKey_ThickMaterial_WorksCorrectly() {
        // Arrange
        var environment = EnvironmentValues()

        // Act
        environment.surfaceStyle = .thick

        // Assert
        XCTAssertEqual(environment.surfaceStyle, .thick)
        XCTAssertEqual(environment.surfaceStyle.description, "Thick material")
    }

    /// Tests that .ultra material type works with environment key
    ///
    /// **Given**: EnvironmentValues
    /// **When**: Setting surface style to .ultra
    /// **Then**: Should store .ultra correctly
    func testSurfaceStyleKey_UltraMaterial_WorksCorrectly() {
        // Arrange
        var environment = EnvironmentValues()

        // Act
        environment.surfaceStyle = .ultra

        // Assert
        XCTAssertEqual(environment.surfaceStyle, .ultra)
        XCTAssertEqual(environment.surfaceStyle.description, "Ultra thick material")
    }

    /// Tests that material types are equatable
    ///
    /// **Given**: Two material type instances
    /// **When**: Comparing same and different types
    /// **Then**: Equality should work correctly
    ///
    /// **Importance**: Enables conditional logic based on material type
    func testSurfaceMaterial_Equality_WorksCorrectly() {
        // Assert - Same types are equal
        XCTAssertEqual(SurfaceMaterial.thin, SurfaceMaterial.thin)
        XCTAssertEqual(SurfaceMaterial.regular, SurfaceMaterial.regular)
        XCTAssertEqual(SurfaceMaterial.thick, SurfaceMaterial.thick)
        XCTAssertEqual(SurfaceMaterial.ultra, SurfaceMaterial.ultra)

        // Assert - Different types are not equal
        XCTAssertNotEqual(SurfaceMaterial.thin, SurfaceMaterial.regular)
        XCTAssertNotEqual(SurfaceMaterial.regular, SurfaceMaterial.thick)
        XCTAssertNotEqual(SurfaceMaterial.thick, SurfaceMaterial.ultra)
    }

    // MARK: - Integration Tests

    /// Tests that surface style description matches expected values
    ///
    /// **Given**: All material types
    /// **When**: Reading description property
    /// **Then**: Should return human-readable descriptions
    ///
    /// **Coverage**: Validates SurfaceMaterial.description API
    func testSurfaceMaterial_Description_ReturnsCorrectValues() {
        // Assert
        XCTAssertEqual(SurfaceMaterial.thin.description, "Thin material")
        XCTAssertEqual(SurfaceMaterial.regular.description, "Regular material")
        XCTAssertEqual(SurfaceMaterial.thick.description, "Thick material")
        XCTAssertEqual(SurfaceMaterial.ultra.description, "Ultra thick material")
    }

    /// Tests that accessibility labels are provided for all materials
    ///
    /// **Given**: All material types
    /// **When**: Reading accessibilityLabel property
    /// **Then**: Should return descriptive VoiceOver labels
    ///
    /// **Accessibility**: Critical for screen reader users
    /// **WCAG Requirement**: Meaningful labels for UI elements
    func testSurfaceMaterial_AccessibilityLabel_ReturnsCorrectValues() {
        // Assert
        XCTAssertEqual(
            SurfaceMaterial.thin.accessibilityLabel,
            "Thin material background"
        )
        XCTAssertEqual(
            SurfaceMaterial.regular.accessibilityLabel,
            "Regular material background"
        )
        XCTAssertEqual(
            SurfaceMaterial.thick.accessibilityLabel,
            "Thick material background"
        )
        XCTAssertEqual(
            SurfaceMaterial.ultra.accessibilityLabel,
            "Ultra thick material background"
        )
    }

    // MARK: - Edge Case Tests

    /// Tests that environment key conforms to EnvironmentKey protocol
    ///
    /// **Given**: SurfaceStyleKey type
    /// **When**: Checking protocol conformance
    /// **Then**: Should conform to EnvironmentKey
    ///
    /// **Importance**: Required for SwiftUI environment system
    func testSurfaceStyleKey_ConformsToEnvironmentKey() {
        // Assert - Type check for protocol conformance
        // If SurfaceStyleKey didn't conform to EnvironmentKey, this code wouldn't compile
        let _: any EnvironmentKey.Type = SurfaceStyleKey.self
        XCTAssertNotNil(SurfaceStyleKey.defaultValue, "SurfaceStyleKey should conform to EnvironmentKey protocol")
    }

    /// Tests that default value is accessible at compile time
    ///
    /// **Given**: SurfaceStyleKey type
    /// **When**: Accessing defaultValue as static property
    /// **Then**: Should be accessible without instance
    ///
    /// **Importance**: SwiftUI requires static defaultValue
    func testSurfaceStyleKey_DefaultValueIsStatic() {
        // Act - Access static property
        let _ = SurfaceStyleKey.defaultValue

        // Assert - If compilation succeeds, test passes
        XCTAssertTrue(true, "defaultValue should be accessible as static property")
    }
}

#endif
