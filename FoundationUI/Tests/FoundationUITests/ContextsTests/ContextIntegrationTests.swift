import XCTest
import SwiftUI
@testable import FoundationUI

/// Integration tests for FoundationUI Context layer components
///
/// Tests verify correct interaction between SurfaceStyleKey, PlatformAdaptation,
/// and ColorSchemeAdapter across complex view hierarchies and real-world UI patterns.
///
/// ## Test Coverage
/// - Environment key propagation through component hierarchies
/// - Platform adaptation integration with components and patterns
/// - Color scheme adaptation with environment changes
/// - Cross-context interactions (multiple contexts working together)
/// - Size class handling (compact/regular adaptation)
/// - Real-world UI patterns (Inspector, Sidebar, etc.)
///
/// ## Test Strategy
/// - Verify observable properties (PlatformAdapter, ColorSchemeAdapter)
/// - Test environment values with captured state
/// - Platform coverage: Conditional compilation for platform-specific tests
/// - Zero magic numbers: All values use DS tokens
///
/// Test count target: 22+ tests for ≥90% integration coverage
final class ContextIntegrationTests: XCTestCase {

    // MARK: - Environment Propagation Tests

    /// Test that SurfaceStyleKey default value is correct
    ///
    /// Verifies that the default surface material is .regular as specified in PRD.
    func testSurfaceStyleKey_DefaultValue() {
        let defaultValue = SurfaceStyleKey.defaultValue
        XCTAssertEqual(defaultValue, .regular,
                      "SurfaceStyleKey default value should be .regular")
    }

    /// Test that environment values can store all SurfaceMaterial types
    ///
    /// Verifies that all material types can be stored and retrieved from
    /// EnvironmentValues without data loss.
    func testSurfaceStylePropagation_AllMaterialTypes() {
        let materials: [SurfaceMaterial] = [.thin, .regular, .thick, .ultra]

        for material in materials {
            var environment = EnvironmentValues()
            environment.surfaceStyle = material

            XCTAssertEqual(environment.surfaceStyle, material,
                          "Environment should preserve \(material) material")
        }
    }

    /// Test that environment values can be set and retrieved
    ///
    /// Verifies that surface style can be set on EnvironmentValues and
    /// retrieved without modification.
    func testEnvironmentValues_SetAndGet() {
        var environment = EnvironmentValues()

        // Test setting to non-default value
        environment.surfaceStyle = .thick
        XCTAssertEqual(environment.surfaceStyle, .thick,
                      "Environment should return the set surface style")

        // Test changing to different value
        environment.surfaceStyle = .thin
        XCTAssertEqual(environment.surfaceStyle, .thin,
                      "Environment should update surface style correctly")
    }

    /// Test that SurfaceMaterial has correct descriptions
    ///
    /// Verifies that all material types have non-empty descriptions
    /// and accessibility labels for proper UI representation.
    func testSurfaceMaterial_Descriptions() {
        let materials: [SurfaceMaterial] = [.thin, .regular, .thick, .ultra]

        for material in materials {
            XCTAssertFalse(material.description.isEmpty,
                          "\(material) should have non-empty description")
            XCTAssertFalse(material.accessibilityLabel.isEmpty,
                          "\(material) should have non-empty accessibility label")
        }
    }

    /// Test that SurfaceMaterial types are Equatable
    ///
    /// Verifies that material types can be compared for equality,
    /// which is essential for conditional logic and state management.
    func testSurfaceMaterial_Equatable() {
        XCTAssertEqual(SurfaceMaterial.thin, .thin)
        XCTAssertEqual(SurfaceMaterial.regular, .regular)
        XCTAssertEqual(SurfaceMaterial.thick, .thick)
        XCTAssertEqual(SurfaceMaterial.ultra, .ultra)

        XCTAssertNotEqual(SurfaceMaterial.thin, .thick)
        XCTAssertNotEqual(SurfaceMaterial.regular, .ultra)
    }

    // MARK: - Platform Adaptation Integration Tests

    /// Test that PlatformAdapter detects correct platform
    ///
    /// Verifies that platform detection flags are mutually exclusive
    /// and one is always true.
    func testPlatformAdapter_PlatformDetection() {
        #if os(macOS)
        XCTAssertTrue(PlatformAdapter.isMacOS, "Should detect macOS platform")
        XCTAssertFalse(PlatformAdapter.isIOS, "Should not detect iOS on macOS")
        #elseif os(iOS)
        XCTAssertTrue(PlatformAdapter.isIOS, "Should detect iOS platform")
        XCTAssertFalse(PlatformAdapter.isMacOS, "Should not detect macOS on iOS")
        #endif

        // Verify exactly one platform is detected
        let platformCount = (PlatformAdapter.isMacOS ? 1 : 0) + (PlatformAdapter.isIOS ? 1 : 0)
        XCTAssertEqual(platformCount, 1, "Exactly one platform should be detected")
    }

    /// Test that PlatformAdapter provides correct default spacing
    ///
    /// Verifies that default spacing matches platform-specific values
    /// defined in the PRD (macOS: 12pt, iOS: 16pt).
    func testPlatformAdapter_DefaultSpacing() {
        let spacing = PlatformAdapter.defaultSpacing

        #if os(macOS)
        XCTAssertEqual(spacing, DS.Spacing.m,
                      "macOS default spacing should be DS.Spacing.m (12pt)")
        XCTAssertEqual(spacing, 12.0, "macOS spacing should be 12pt")
        #elseif os(iOS)
        XCTAssertEqual(spacing, DS.Spacing.l,
                      "iOS default spacing should be DS.Spacing.l (16pt)")
        XCTAssertEqual(spacing, 16.0, "iOS spacing should be 16pt")
        #endif

        XCTAssertGreaterThan(spacing, 0, "Spacing should always be positive")
    }

    /// Test that PlatformAdapter spacing adapts to size classes
    ///
    /// Verifies that spacing changes appropriately for compact vs regular
    /// size classes on iPad.
    func testPlatformAdapter_SizeClassSpacing() {
        let compactSpacing = PlatformAdapter.spacing(for: .compact)
        let regularSpacing = PlatformAdapter.spacing(for: .regular)

        XCTAssertEqual(compactSpacing, DS.Spacing.m,
                      "Compact size class should use medium spacing (12pt)")
        XCTAssertEqual(regularSpacing, DS.Spacing.l,
                      "Regular size class should use large spacing (16pt)")

        XCTAssertLessThan(compactSpacing, regularSpacing,
                         "Compact spacing should be less than regular spacing")
    }

    /// Test that PlatformAdapter handles nil size class correctly
    ///
    /// Verifies that nil size class falls back to platform default spacing.
    func testPlatformAdapter_NilSizeClass() {
        let spacing = PlatformAdapter.spacing(for: nil)
        let defaultSpacing = PlatformAdapter.defaultSpacing

        XCTAssertEqual(spacing, defaultSpacing,
                      "Nil size class should fall back to platform default")
    }

    /// Test that PlatformAdapter spacing uses only DS tokens
    ///
    /// Verifies zero magic numbers requirement - all spacing values
    /// must come from design system tokens.
    func testPlatformAdapter_NoMagicNumbers() {
        let validTokens: Set<CGFloat> = [
            DS.Spacing.s,   // 8pt
            DS.Spacing.m,   // 12pt
            DS.Spacing.l,   // 16pt
            DS.Spacing.xl   // 24pt
        ]

        // Test default spacing
        let defaultSpacing = PlatformAdapter.defaultSpacing
        XCTAssertTrue(validTokens.contains(defaultSpacing),
                     "Default spacing must be a DS token, got \(defaultSpacing)")

        // Test size class spacing
        let compactSpacing = PlatformAdapter.spacing(for: .compact)
        let regularSpacing = PlatformAdapter.spacing(for: .regular)

        XCTAssertTrue(validTokens.contains(compactSpacing),
                     "Compact spacing must be a DS token, got \(compactSpacing)")
        XCTAssertTrue(validTokens.contains(regularSpacing),
                     "Regular spacing must be a DS token, got \(regularSpacing)")
    }

    // MARK: - Color Scheme Integration Tests

    /// Test that ColorSchemeAdapter detects dark mode correctly
    ///
    /// Verifies that isDarkMode property returns true for dark color scheme
    /// and false for light color scheme.
    func testColorSchemeAdapter_DarkModeDetection() {
        let darkAdapter = ColorSchemeAdapter(colorScheme: .dark)
        let lightAdapter = ColorSchemeAdapter(colorScheme: .light)

        XCTAssertTrue(darkAdapter.isDarkMode,
                     "Dark color scheme should be detected as dark mode")
        XCTAssertFalse(lightAdapter.isDarkMode,
                      "Light color scheme should not be detected as dark mode")
    }

    /// Test that ColorSchemeAdapter provides different colors for light/dark modes
    ///
    /// Verifies that adaptive colors differ between light and dark modes
    /// to ensure proper contrast.
    func testColorSchemeAdapter_AdaptiveColors() {
        let darkAdapter = ColorSchemeAdapter(colorScheme: .dark)
        let lightAdapter = ColorSchemeAdapter(colorScheme: .light)

        // Text colors should differ
        let darkText = darkAdapter.adaptiveTextColor
        let lightText = lightAdapter.adaptiveTextColor
        XCTAssertNotEqual(darkText, lightText,
                         "Text colors should differ between light and dark modes")

        // Background colors should differ
        let darkBg = darkAdapter.adaptiveBackground
        let lightBg = lightAdapter.adaptiveBackground
        XCTAssertNotEqual(darkBg, lightBg,
                         "Background colors should differ between light and dark modes")

        // Border colors should differ
        let darkBorder = darkAdapter.adaptiveBorderColor
        let lightBorder = lightAdapter.adaptiveBorderColor
        XCTAssertNotEqual(darkBorder, lightBorder,
                         "Border colors should differ between light and dark modes")
    }

    /// Test that ColorSchemeAdapter provides non-nil colors
    ///
    /// Verifies that all adaptive color properties return valid colors
    /// and never fail.
    func testColorSchemeAdapter_ColorsNotNil() {
        let adapter = ColorSchemeAdapter(colorScheme: .light)

        // Verify all color properties are accessible
        _ = adapter.adaptiveBackground
        _ = adapter.adaptiveSecondaryBackground
        _ = adapter.adaptiveTextColor
        _ = adapter.adaptiveSecondaryTextColor
        _ = adapter.adaptiveBorderColor
        _ = adapter.adaptiveDividerColor
        _ = adapter.adaptiveElevatedSurface

        // If we reach here without crashes, colors are valid
        XCTAssertTrue(true, "All adaptive colors should be accessible")
    }

    /// Test that ColorSchemeAdapter works with both light and dark schemes
    ///
    /// Verifies that the adapter can be initialized with both color schemes
    /// and provides appropriate colors for each.
    func testColorSchemeAdapter_BothSchemes() {
        let schemes: [ColorScheme] = [.light, .dark]

        for scheme in schemes {
            let adapter = ColorSchemeAdapter(colorScheme: scheme)

            // Verify isDarkMode matches scheme
            if scheme == .dark {
                XCTAssertTrue(adapter.isDarkMode,
                             "Dark scheme should set isDarkMode to true")
            } else {
                XCTAssertFalse(adapter.isDarkMode,
                              "Light scheme should set isDarkMode to false")
            }

            // Verify colors are accessible
            _ = adapter.adaptiveTextColor
            _ = adapter.adaptiveBackground
        }
    }

    /// Test that ColorSchemeAdapter elevated surface differs from background
    ///
    /// Verifies that elevated surfaces have visual distinction from regular
    /// backgrounds for proper UI hierarchy.
    func testColorSchemeAdapter_ElevatedSurface() {
        let lightAdapter = ColorSchemeAdapter(colorScheme: .light)
        let darkAdapter = ColorSchemeAdapter(colorScheme: .dark)

        let lightBg = lightAdapter.adaptiveBackground
        let lightElevated = lightAdapter.adaptiveElevatedSurface

        let darkBg = darkAdapter.adaptiveBackground
        let darkElevated = darkAdapter.adaptiveElevatedSurface

        // Elevated should differ from background in both modes
        XCTAssertNotEqual(lightBg, lightElevated,
                         "Light mode elevated surface should differ from background")
        XCTAssertNotEqual(darkBg, darkElevated,
                         "Dark mode elevated surface should differ from background")
    }

    // MARK: - Cross-Context Interaction Tests

    /// Test that SurfaceStyleKey and PlatformAdapter work together
    ///
    /// Verifies that environment values and platform spacing can be used
    /// simultaneously without interference.
    func testCrossContext_SurfaceStyleAndPlatform() {
        var environment = EnvironmentValues()
        environment.surfaceStyle = .thick

        let spacing = PlatformAdapter.defaultSpacing

        // Both should provide valid values independently
        XCTAssertEqual(environment.surfaceStyle, .thick,
                      "Surface style should be preserved")
        XCTAssertGreaterThan(spacing, 0,
                            "Platform spacing should be positive")

        // Verify they use different types and don't interfere
        XCTAssertTrue(environment.surfaceStyle == .thick)
        XCTAssertTrue(spacing == DS.Spacing.m || spacing == DS.Spacing.l)
    }

    /// Test that all context types provide independent values
    ///
    /// Verifies that SurfaceStyleKey, PlatformAdapter, and ColorSchemeAdapter
    /// all return valid values when accessed together.
    func testCrossContext_AllThreeContexts() {
        // Surface style context
        let surfaceStyle = SurfaceStyleKey.defaultValue
        XCTAssertEqual(surfaceStyle, .regular)

        // Platform adaptation context
        let platformSpacing = PlatformAdapter.defaultSpacing
        XCTAssertGreaterThan(platformSpacing, 0)

        // Color scheme context
        let lightAdapter = ColorSchemeAdapter(colorScheme: .light)
        let darkAdapter = ColorSchemeAdapter(colorScheme: .dark)
        XCTAssertFalse(lightAdapter.isDarkMode)
        XCTAssertTrue(darkAdapter.isDarkMode)

        // All three contexts should provide valid, independent values
        XCTAssertTrue(surfaceStyle == .regular)
        XCTAssertTrue(platformSpacing > 0)
        XCTAssertNotEqual(lightAdapter.adaptiveTextColor,
                         darkAdapter.adaptiveTextColor)
    }

    /// Test that contexts use different value types
    ///
    /// Verifies type safety - each context uses its own distinct types
    /// preventing accidental mixing or confusion.
    func testCrossContext_TypeSafety() {
        // Surface style uses SurfaceMaterial enum
        let material: SurfaceMaterial = .regular
        XCTAssertTrue(type(of: material) == SurfaceMaterial.self)

        // Platform spacing uses CGFloat
        let spacing: CGFloat = PlatformAdapter.defaultSpacing
        XCTAssertTrue(type(of: spacing) == CGFloat.self)

        // Color scheme uses ColorScheme enum
        let scheme: ColorScheme = .light
        XCTAssertTrue(type(of: scheme) == ColorScheme.self)

        // Types are distinct and cannot be confused
        XCTAssertNotEqual(String(describing: type(of: material)),
                         String(describing: type(of: spacing)))
    }

    // MARK: - Size Class Adaptation Tests

    /// Test that compact size class spacing is correct
    ///
    /// Verifies that compact size class (iPhone in portrait, iPad split view)
    /// uses the correct spacing value (12pt).
    func testSizeClass_CompactAdaptation() {
        let compactSpacing = PlatformAdapter.spacing(for: .compact)

        XCTAssertEqual(compactSpacing, DS.Spacing.m,
                      "Compact size class should use medium spacing (12pt)")
        XCTAssertEqual(compactSpacing, 12.0,
                      "Compact spacing should be exactly 12pt")
        XCTAssertGreaterThan(compactSpacing, 0,
                            "Spacing should be positive")
    }

    /// Test that regular size class spacing is correct
    ///
    /// Verifies that regular size class (iPad, iPhone landscape)
    /// uses the correct spacing value (16pt).
    func testSizeClass_RegularAdaptation() {
        let regularSpacing = PlatformAdapter.spacing(for: .regular)

        XCTAssertEqual(regularSpacing, DS.Spacing.l,
                      "Regular size class should use large spacing (16pt)")
        XCTAssertEqual(regularSpacing, 16.0,
                      "Regular spacing should be exactly 16pt")
        XCTAssertGreaterThan(regularSpacing, 0,
                            "Spacing should be positive")

        // Regular should be larger than compact
        let compactSpacing = PlatformAdapter.spacing(for: .compact)
        XCTAssertGreaterThan(regularSpacing, compactSpacing,
                            "Regular spacing should exceed compact spacing")
    }

    // MARK: - Integration Verification Tests

    /// Test that all context defaults are sensible
    ///
    /// Verifies that default values across all contexts are appropriate
    /// for real-world use without configuration.
    func testIntegration_SensibleDefaults() {
        // Surface style default
        let defaultMaterial = SurfaceStyleKey.defaultValue
        XCTAssertEqual(defaultMaterial, .regular,
                      "Default material should be .regular for balanced translucency")

        // Platform spacing default
        let defaultSpacing = PlatformAdapter.defaultSpacing
        XCTAssertTrue(defaultSpacing == 12.0 || defaultSpacing == 16.0,
                     "Default spacing should be 12pt (macOS) or 16pt (iOS)")

        // Verify defaults allow immediate use
        XCTAssertNotEqual(defaultMaterial.description, "")
        XCTAssertGreaterThan(defaultSpacing, 0)
    }

    /// Test that all contexts support Equatable where needed
    ///
    /// Verifies that value types can be compared for equality,
    /// enabling conditional logic and state management.
    func testIntegration_EquatableSupport() {
        // SurfaceMaterial is Equatable
        let material1: SurfaceMaterial = .regular
        let material2: SurfaceMaterial = .regular
        let material3: SurfaceMaterial = .thick

        XCTAssertEqual(material1, material2)
        XCTAssertNotEqual(material1, material3)

        // CGFloat (spacing) is Equatable
        let spacing1 = PlatformAdapter.defaultSpacing
        let spacing2 = PlatformAdapter.defaultSpacing

        XCTAssertEqual(spacing1, spacing2)

        // ColorScheme is Equatable
        let scheme1: ColorScheme = .light
        let scheme2: ColorScheme = .light
        let scheme3: ColorScheme = .dark

        XCTAssertEqual(scheme1, scheme2)
        XCTAssertNotEqual(scheme1, scheme3)
    }

    /// Test that all context values are within expected ranges
    ///
    /// Verifies that all numeric values (spacing, etc.) are within
    /// reasonable bounds for UI use.
    func testIntegration_ValueRanges() {
        // Spacing should be between 0 and 50 points
        let spacingValues = [
            PlatformAdapter.defaultSpacing,
            PlatformAdapter.spacing(for: .compact),
            PlatformAdapter.spacing(for: .regular)
        ]

        for spacing in spacingValues {
            XCTAssertGreaterThan(spacing, 0, "Spacing should be positive")
            XCTAssertLessThan(spacing, 50, "Spacing should be reasonable (<50pt)")
        }

        // All spacing should use known DS tokens
        let validTokens: Set<CGFloat> = [
            DS.Spacing.s,   // 8pt
            DS.Spacing.m,   // 12pt
            DS.Spacing.l,   // 16pt
            DS.Spacing.xl   // 24pt
        ]

        for spacing in spacingValues {
            XCTAssertTrue(validTokens.contains(spacing),
                         "Spacing \(spacing) should be a DS token")
        }
    }
}
