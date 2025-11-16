#if canImport(SwiftUI)
  @testable import FoundationUI
  import SwiftUI
  import XCTest

  /// Tests for the AccessibilityContext helper that aggregates
  /// common accessibility environment preferences.
  ///
  /// The tests follow FoundationUI's TDD workflow by defining the
  /// desired behaviour before the implementation exists. Each test
  /// focuses on one responsibility and uses DS tokens to ensure we
  /// avoid magic numbers.
  @MainActor
  final class AccessibilityContextTests: XCTestCase {
    // MARK: - Default Behaviour

    /// The default context should mirror the system defaults and
    /// use DS spacing tokens for baseline layout metrics.
    func testDefaultContext_UsesSystemDefaults() {
      let context = AccessibilityContext()

      XCTAssertFalse(context.prefersReducedMotion, "Default should not reduce motion")
      XCTAssertFalse(context.prefersIncreasedContrast, "Default should not increase contrast")
      XCTAssertFalse(context.prefersBoldText, "Default should not force bold text")
      XCTAssertEqual(
        context.dynamicTypeSize, .large, "Default Dynamic Type should match system large"
      )
      XCTAssertEqual(
        context.preferredSpacing, DS.Spacing.m, "Default spacing should use DS.Spacing.m"
      )
      XCTAssertEqual(
        context.preferredFontWeight, .regular, "Default font weight should be regular"
      )
    }

    // MARK: - Reduce Motion

    /// When Reduce Motion is enabled the context should disable
    /// animations by returning `nil` for any requested animation.
    func testReduceMotion_DisablesAnimations() {
      let context = AccessibilityContext(
        prefersReducedMotion: true,
        prefersIncreasedContrast: false,
        prefersBoldText: false,
        dynamicTypeSize: .large
      )

      XCTAssertNil(
        context.animation(for: DS.Animation.medium),
        "Reduce motion should disable DS animations"
      )
    }

    /// When Reduce Motion is disabled the context should return
    /// the provided animation unchanged.
    func testReduceMotion_AllowsAnimations() {
      let context = AccessibilityContext(
        prefersReducedMotion: false,
        prefersIncreasedContrast: false,
        prefersBoldText: false,
        dynamicTypeSize: .large
      )

      let animation = context.animation(for: DS.Animation.quick)
      XCTAssertNotNil(animation, "Animations should run when reduce motion is off")
    }

    // MARK: - Increased Contrast

    /// Increased contrast should expand spacing to the DS large
    /// token to ensure clear separation between elements.
    func testIncreasedContrast_UsesLargeSpacing() {
      let context = AccessibilityContext(
        prefersReducedMotion: false,
        prefersIncreasedContrast: true,
        prefersBoldText: false,
        dynamicTypeSize: .large
      )

      XCTAssertEqual(
        context.preferredSpacing, DS.Spacing.l, "High contrast should map to DS.Spacing.l"
      )
    }

    /// High contrast combined with larger Dynamic Type should
    /// expand spacing to the largest DS spacing token.
    func testHighContrastAccessibilitySpacing_UsesXLSpacing() {
      let context = AccessibilityContext(
        prefersReducedMotion: false,
        prefersIncreasedContrast: true,
        prefersBoldText: false,
        dynamicTypeSize: .accessibility2
      )

      XCTAssertEqual(
        context.spacing(for: DS.Spacing.m),
        DS.Spacing.xl,
        "Accessibility sizes should promote spacing to DS.Spacing.xl"
      )
    }

    // MARK: - Bold Text

    /// Bold text preference should surface a bold font weight so
    /// components can opt into heavier typography.
    func testBoldText_UsesBoldWeight() {
      let context = AccessibilityContext(
        prefersReducedMotion: false,
        prefersIncreasedContrast: false,
        prefersBoldText: true,
        dynamicTypeSize: .large
      )

      XCTAssertEqual(
        context.preferredFontWeight, .bold,
        "Bold text preference should request bold weight"
      )
    }

    // MARK: - Environment Propagation

    /// Environment values should store and retrieve the context to
    /// allow propagation through the SwiftUI view hierarchy.
    func testEnvironmentValues_AccessibilityContextRoundTrip() throws {
      #if os(macOS)
        var environment = EnvironmentValues()

        let context = AccessibilityContext(
          prefersReducedMotion: true,
          prefersIncreasedContrast: true,
          prefersBoldText: true,
          dynamicTypeSize: .accessibility3
        )

        // Set the context directly first
        environment.accessibilityContext = context

        // Now retrieve it - this should return the stored value without calling system APIs
        XCTAssertEqual(
          environment.accessibilityContext, context,
          "Environment should round-trip the accessibility context"
        )
      #else
        // Skip on iOS: Direct EnvironmentValues instantiation triggers UIKit accessibility
        // APIs that can deadlock in the iOS Simulator test environment
        throw XCTSkip("Test skipped on iOS due to simulator environment limitations")
      #endif
    }

    /// When no explicit context is provided the environment should
    /// derive preferences from the existing accessibility values.
    func testEnvironmentValues_DerivesDefaultsFromEnvironment() throws {
      #if os(macOS)
        var environment = EnvironmentValues()

        // Set all overrides to prevent system API calls while still testing derivation logic
        environment.accessibilityContextOverrides = AccessibilityContextOverrides(
          prefersReducedMotion: true,
          prefersIncreasedContrast: true,
          prefersBoldText: true,
          dynamicTypeSize: .accessibility2
        )

        let context = environment.accessibilityContext

        XCTAssertTrue(
          context.prefersReducedMotion, "Reduce Motion preference should be respected"
        )
        XCTAssertTrue(
          context.prefersIncreasedContrast, "High Contrast preference should be respected"
        )
        XCTAssertTrue(context.prefersBoldText, "Bold text preference should be respected")
        XCTAssertEqual(
          context.dynamicTypeSize, .accessibility2,
          "Dynamic Type preference should match the environment"
        )
      #else
        // Skip on iOS: Direct EnvironmentValues instantiation triggers UIKit accessibility
        // APIs that can deadlock in the iOS Simulator test environment
        throw XCTSkip("Test skipped on iOS due to simulator environment limitations")
      #endif
    }

    /// The view modifier helper should be chainable within SwiftUI
    /// hierarchies. We validate this by creating a simple text view
    /// and verifying the modifier returns a non-nil view type.
    func testViewModifier_IsComposable() throws {
      #if os(macOS)
        let context = AccessibilityContext(
          prefersReducedMotion: true,
          prefersIncreasedContrast: true,
          prefersBoldText: true,
          dynamicTypeSize: .accessibility3
        )

        let view = Text("Preview").accessibilityContext(context)
        XCTAssertNotNil(view, "The accessibilityContext view modifier should return a view")
      #else
        // Skip on iOS: Creating SwiftUI views with environment modifiers can trigger
        // UIKit accessibility APIs that deadlock in the iOS Simulator test environment
        throw XCTSkip("Test skipped on iOS due to simulator environment limitations")
      #endif
    }

    // MARK: - iOS-Safe Tests

    /// Tests that AccessibilityContext correctly derives spacing based on
    /// increased contrast preference without requiring direct EnvironmentValues access.
    func testContextWithIncreasedContrast_DerivesCorrectSpacing() {
      let standardContext = AccessibilityContext(
        prefersReducedMotion: false,
        prefersIncreasedContrast: false,
        prefersBoldText: false,
        dynamicTypeSize: .large
      )

      let highContrastContext = AccessibilityContext(
        prefersReducedMotion: false,
        prefersIncreasedContrast: true,
        prefersBoldText: false,
        dynamicTypeSize: .large
      )

      XCTAssertEqual(
        standardContext.preferredSpacing, DS.Spacing.m,
        "Standard context should use medium spacing"
      )
      XCTAssertEqual(
        highContrastContext.preferredSpacing, DS.Spacing.l,
        "High contrast context should use large spacing"
      )
    }

    /// Tests that AccessibilityContext correctly combines high contrast
    /// with accessibility sizes to produce maximum spacing.
    func testContextWithHighContrastAndAccessibilitySize_UsesMaximumSpacing() {
      let context = AccessibilityContext(
        prefersReducedMotion: false,
        prefersIncreasedContrast: true,
        prefersBoldText: false,
        dynamicTypeSize: .accessibility3
      )

      let baseSpacing = DS.Spacing.m
      let adjustedSpacing = context.spacing(for: baseSpacing)

      XCTAssertEqual(
        adjustedSpacing, DS.Spacing.xl,
        "Accessibility size with high contrast should use extra-large spacing"
      )
    }

    /// Tests that AccessibilityContext properly handles animation
    /// preferences based on reduce motion setting.
    func testContextAnimation_RespectsReduceMotionSetting() {
      let motionEnabledContext = AccessibilityContext(
        prefersReducedMotion: false,
        prefersIncreasedContrast: false,
        prefersBoldText: false,
        dynamicTypeSize: .large
      )

      let motionReducedContext = AccessibilityContext(
        prefersReducedMotion: true,
        prefersIncreasedContrast: false,
        prefersBoldText: false,
        dynamicTypeSize: .large
      )

      XCTAssertNotNil(
        motionEnabledContext.animation(for: DS.Animation.medium),
        "Context without reduce motion should allow animations"
      )
      XCTAssertNil(
        motionReducedContext.animation(for: DS.Animation.medium),
        "Context with reduce motion should disable animations"
      )
    }

    /// Tests that AccessibilityContext instances with identical
    /// properties are considered equal.
    func testContextEquality_ComparesAllProperties() {
      let context1 = AccessibilityContext(
        prefersReducedMotion: true,
        prefersIncreasedContrast: true,
        prefersBoldText: true,
        dynamicTypeSize: .accessibility2
      )

      let context2 = AccessibilityContext(
        prefersReducedMotion: true,
        prefersIncreasedContrast: true,
        prefersBoldText: true,
        dynamicTypeSize: .accessibility2
      )

      let context3 = AccessibilityContext(
        prefersReducedMotion: false,
        prefersIncreasedContrast: true,
        prefersBoldText: true,
        dynamicTypeSize: .accessibility2
      )

      XCTAssertEqual(context1, context2, "Contexts with identical properties should be equal")
      XCTAssertNotEqual(
        context1, context3, "Contexts with different properties should not be equal"
      )
    }
  }
#endif
