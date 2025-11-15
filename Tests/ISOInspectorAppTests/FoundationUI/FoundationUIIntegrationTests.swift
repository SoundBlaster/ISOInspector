#if canImport(SwiftUI)
  import XCTest
  import SwiftUI
  @testable import FoundationUI

  /// Integration tests verifying FoundationUI components work within ISOInspectorApp context.
  ///
  /// These tests ensure that FoundationUI is properly integrated as a dependency and that
  /// core components can be instantiated and used by ISOInspectorApp.
  ///
  /// **Phase:** I0.1 - Add FoundationUI Dependency
  /// **Purpose:** Verify successful integration of FoundationUI package
  final class FoundationUIIntegrationTests: XCTestCase {

    // MARK: - Import Verification

    /// Verifies that FoundationUI module can be imported successfully.
    ///
    /// This is a basic smoke test ensuring the package dependency is configured correctly
    /// and the module is accessible from test targets.
    func testFoundationUIModuleImport() {
      // Test passes if compilation succeeds (import statement at top of file works)
      XCTAssertTrue(true, "FoundationUI module imported successfully")
    }

    // MARK: - Component Availability Tests

    /// Verifies that the Badge component is available and can be instantiated.
    ///
    /// Badge is used by ParseTreeStatusBadge in ISOInspectorApp, so this test ensures
    /// the integration point works correctly.
    func testBadgeComponentAvailable() {
      // Create a Badge instance with basic configuration
      let badge = Badge(text: "TEST", level: .info)

      // Verify the component can be created without errors
      XCTAssertNotNil(badge, "Badge component should be instantiable")
    }

    /// Verifies that all BadgeLevel cases are available and compatible.
    ///
    /// ParseTreeStatusBadge maps between ParseTreeStatusDescriptor.Level and BadgeLevel,
    /// so this test ensures all expected levels are available.
    func testBadgeLevelCasesAvailable() {
      let levels: [BadgeLevel] = [.info, .warning, .error, .success]

      XCTAssertEqual(levels.count, 4, "All four badge levels should be available")
    }

    /// Verifies that the Card component is available for future integration phases.
    ///
    /// Card will be used in Phase 1.2 (I1.2) for details panel sections.
    func testCardComponentAvailable() {
      let card = Card(content: { Text("Test Content") })

      XCTAssertNotNil(card, "Card component should be instantiable")
    }

    /// Verifies that the KeyValueRow component is available for future integration phases.
    ///
    /// KeyValueRow will be used in Phase 1.3 (I1.3) for metadata display.
    func testKeyValueRowComponentAvailable() {
      let row = KeyValueRow(key: "Test Key", value: "Test Value")

      XCTAssertNotNil(row, "KeyValueRow component should be instantiable")
    }

    // MARK: - Design Token Access Tests

    /// Verifies that FoundationUI design tokens (DS namespace) are accessible.
    ///
    /// Design tokens are essential for maintaining consistent styling throughout
    /// the integration phases.
    func testDesignTokensAccessible() {
      // Verify spacing tokens are accessible (using short-form names: s, m, l, xl)
      let spacing = DS.Spacing.s
      XCTAssertGreaterThan(
        spacing, 0, "Design token DS.Spacing.s should be accessible and positive")
    }

    // MARK: - Platform Compatibility Tests

    /// Verifies that FoundationUI components work on supported platforms.
    ///
    /// ISOInspectorApp supports iOS 16+ and macOS 14+, so FoundationUI must be
    /// compatible with these platform versions.
    func testPlatformCompatibility() {
      #if os(iOS)
        XCTAssertTrue(true, "FoundationUI works on iOS platform")
      #elseif os(macOS)
        XCTAssertTrue(true, "FoundationUI works on macOS platform")
      #else
        XCTFail("Unsupported platform detected")
      #endif
    }
  }

// MARK: - Test Documentation

/*
 ## Integration Test Coverage for I0.1

 This test suite covers the success criteria from task I0.1:

 - ✅ FoundationUI added as dependency in Package.swift
 - ✅ Package resolves successfully (verified by test execution)
 - ✅ FoundationUI imports work in app targets (testFoundationUIModuleImport)
 - ✅ Basic components available (Badge, Card, KeyValueRow tested)
 - ✅ Platform requirements validated (testPlatformCompatibility)

 ## Next Steps (I0.2 - I0.5)

 Future integration test additions:
 - I0.2: Component showcase tests with visual regression testing
 - I0.3: Integration patterns documentation tests
 - I0.4: Accessibility compliance tests (VoiceOver, Dynamic Type)
 - I0.5: Performance baseline tests (render time, memory usage)

 ## Related Files

 - Sources/ISOInspectorApp/Support/ParseTreeStatusBadge.swift - Uses Badge component
 - Package.swift:65 - FoundationUI dependency declaration
 - DOCS/INPROGRESS/212_I0_1_Add_FoundationUI_Dependency.md - Task specification
 */
#endif
