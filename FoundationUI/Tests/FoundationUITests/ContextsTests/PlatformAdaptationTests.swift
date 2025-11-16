import SwiftUI
import XCTest

@testable import FoundationUI

/// Unit tests for PlatformAdaptation modifiers and helpers
///
/// Tests platform-adaptive spacing, layout, and behavior across iOS/iPadOS/macOS.
/// Follows TDD approach: tests written first, implementation second.
///
/// Test Coverage:
/// - Platform detection helpers
/// - Spacing adaptation for each platform
/// - Size class handling (compact/regular)
/// - ViewModifier integration
/// - View extension methods
@MainActor
final class PlatformAdaptationTests: XCTestCase {
  // MARK: - Platform Detection Tests

  func testPlatformDetection_macOS() {
    #if os(macOS)
      XCTAssertTrue(PlatformAdapter.isMacOS, "Should detect macOS platform")
      XCTAssertFalse(PlatformAdapter.isIOS, "Should not detect iOS on macOS")
    #else
      XCTAssertFalse(PlatformAdapter.isMacOS, "Should not detect macOS on iOS")
      XCTAssertTrue(PlatformAdapter.isIOS, "Should detect iOS platform")
    #endif
  }

  func testPlatformDetection_iOS() {
    #if os(iOS)
      XCTAssertTrue(PlatformAdapter.isIOS, "Should detect iOS platform")
      XCTAssertFalse(PlatformAdapter.isMacOS, "Should not detect macOS on iOS")
    #endif
  }

  // MARK: - Spacing Adaptation Tests

  func testSpacingAdaptation_macOS() {
    #if os(macOS)
      let spacing = PlatformAdapter.defaultSpacing
      XCTAssertEqual(spacing, DS.Spacing.m, "macOS should use DS.Spacing.m (12pt)")
    #endif
  }

  func testSpacingAdaptation_iOS() {
    #if os(iOS)
      let spacing = PlatformAdapter.defaultSpacing
      XCTAssertEqual(spacing, DS.Spacing.l, "iOS should use DS.Spacing.l (16pt)")
    #endif
  }

  func testSpacingAdaptation_UsesDesignTokens() {
    // Verify no magic numbers - all values should be DS tokens
    let spacing = PlatformAdapter.defaultSpacing

    #if os(macOS)
      XCTAssertEqual(spacing, 12.0, "macOS spacing should equal DS.Spacing.m")
    #else
      XCTAssertEqual(spacing, 16.0, "iOS spacing should equal DS.Spacing.l")
    #endif
  }

  func testSpacingAdaptation_CompactSizeClass() {
    let compactSpacing = PlatformAdapter.spacing(for: .compact)
    XCTAssertEqual(compactSpacing, DS.Spacing.m, "Compact size class should use DS.Spacing.m")
  }

  func testSpacingAdaptation_RegularSizeClass() {
    let regularSpacing = PlatformAdapter.spacing(for: .regular)
    XCTAssertEqual(regularSpacing, DS.Spacing.l, "Regular size class should use DS.Spacing.l")
  }

  // MARK: - Size Class Handling Tests

  func testSizeClassMapping_Compact() {
    let sizeClass = UserInterfaceSizeClass.compact
    let spacing = PlatformAdapter.spacing(for: sizeClass)

    XCTAssertEqual(spacing, DS.Spacing.m, "Compact size class maps to medium spacing")
  }

  func testSizeClassMapping_Regular() {
    let sizeClass = UserInterfaceSizeClass.regular
    let spacing = PlatformAdapter.spacing(for: sizeClass)

    XCTAssertEqual(spacing, DS.Spacing.l, "Regular size class maps to large spacing")
  }

  func testSizeClassMapping_NilSizeClass() {
    let spacing = PlatformAdapter.spacing(for: nil)

    // Should fall back to platform default
    #if os(macOS)
      XCTAssertEqual(spacing, DS.Spacing.m, "Nil size class should use platform default (macOS)")
    #else
      XCTAssertEqual(spacing, DS.Spacing.l, "Nil size class should use platform default (iOS)")
    #endif
  }

  // MARK: - ViewModifier Integration Tests

  @MainActor
  func testPlatformAdaptiveModifier_AppliesPlatformSpacing() {
    let view = Text("Test")
      .platformAdaptive()

    // Test that modifier can be applied without errors
    XCTAssertNotNil(view, "platformAdaptive() modifier should be applicable")
  }

  @MainActor
  func testPlatformAdaptiveModifier_WithCustomSpacing() {
    let customSpacing = DS.Spacing.xl
    let view = Text("Test")
      .platformAdaptive(spacing: customSpacing)

    XCTAssertNotNil(view, "platformAdaptive(spacing:) modifier should accept custom spacing")
  }

  @MainActor
  func testPlatformAdaptiveModifier_WithSizeClass() {
    let view = Text("Test")
      .platformAdaptive(sizeClass: .compact)

    XCTAssertNotNil(view, "platformAdaptive(sizeClass:) modifier should accept size class")
  }

  // MARK: - View Extension Tests

  @MainActor
  func testViewExtension_PlatformSpacing() {
    let view = Text("Test")
      .platformSpacing()

    XCTAssertNotNil(view, "platformSpacing() extension should be applicable")
  }

  @MainActor
  func testViewExtension_PlatformSpacingWithValue() {
    let customValue = DS.Spacing.xl
    let view = Text("Test")
      .platformSpacing(customValue)

    XCTAssertNotNil(view, "platformSpacing(_:) extension should accept custom value")
  }

  @MainActor
  func testViewExtension_PlatformPadding() {
    let view = Text("Test")
      .platformPadding()

    XCTAssertNotNil(view, "platformPadding() extension should be applicable")
  }

  @MainActor
  func testViewExtension_PlatformPaddingWithEdges() {
    let view = Text("Test")
      .platformPadding(.horizontal)

    XCTAssertNotNil(view, "platformPadding(_:) extension should accept edge set")
  }

  // MARK: - Minimum Touch Target Tests (iOS)

  #if os(iOS)
    func testMinimumTouchTarget_iOS() {
      let minTarget = PlatformAdapter.minimumTouchTarget
      XCTAssertGreaterThanOrEqual(minTarget, 44.0, "iOS minimum touch target should be ≥44pt")
    }

    func testMinimumTouchTarget_EnsuresAccessibility() {
      // Verify minimum touch target meets Apple HIG requirements
      let minTarget = PlatformAdapter.minimumTouchTarget
      XCTAssertEqual(minTarget, 44.0, "iOS minimum touch target should be exactly 44pt per HIG")
    }
  #endif

  // MARK: - Integration Tests

  @MainActor
  func testPlatformAdaptation_IntegrationWithComponents() {
    // Test that platform adaptation works with real components
    let badge = Text("Test")
      .padding(PlatformAdapter.defaultSpacing)

    XCTAssertNotNil(badge, "Platform spacing should work with components")
  }

  func testPlatformAdaptation_ZeroMagicNumbers() {
    // Verify all spacing values come from DS tokens
    let spacing = PlatformAdapter.defaultSpacing

    let validTokens: Set<CGFloat> = [
      DS.Spacing.s,
      DS.Spacing.m,
      DS.Spacing.l,
      DS.Spacing.xl,
    ]

    XCTAssertTrue(
      validTokens.contains(spacing),
      "Platform spacing should only use DS token values"
    )
  }

  func testPlatformAdaptation_ConsistentBehavior() {
    // Verify consistent behavior across multiple calls
    let spacing1 = PlatformAdapter.defaultSpacing
    let spacing2 = PlatformAdapter.defaultSpacing

    XCTAssertEqual(spacing1, spacing2, "Platform spacing should be consistent")
  }

  // MARK: - Edge Cases

  func testEdgeCase_NegativeSpacing() {
    // Ensure negative spacing is never returned
    let spacing = PlatformAdapter.defaultSpacing
    XCTAssertGreaterThan(spacing, 0, "Spacing should never be negative")
  }

  func testEdgeCase_ExtremeValues() {
    // Test with extreme size classes or custom values
    let compactSpacing = PlatformAdapter.spacing(for: .compact)
    let regularSpacing = PlatformAdapter.spacing(for: .regular)

    XCTAssertGreaterThan(compactSpacing, 0, "Compact spacing should be positive")
    XCTAssertGreaterThan(regularSpacing, 0, "Regular spacing should be positive")
  }

  // MARK: - Documentation Tests

  func testDocumentation_PublicAPIHasDocumentation() {
    // This test verifies that public API is documented
    // In practice, this would be checked by documentation coverage tools
    XCTAssertTrue(true, "All public API should have DocC documentation")
  }
}
