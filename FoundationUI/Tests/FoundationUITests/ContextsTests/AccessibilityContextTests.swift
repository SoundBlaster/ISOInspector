#if canImport(SwiftUI)
import SwiftUI
import XCTest
@testable import FoundationUI

/// Tests for the AccessibilityContext helper that aggregates
/// common accessibility environment preferences.
///
/// The tests follow FoundationUI's TDD workflow by defining the
/// desired behaviour before the implementation exists. Each test
/// focuses on one responsibility and uses DS tokens to ensure we
/// avoid magic numbers.
final class AccessibilityContextTests: XCTestCase {

    // MARK: - Default Behaviour

    /// The default context should mirror the system defaults and
    /// use DS spacing tokens for baseline layout metrics.
    func testDefaultContext_UsesSystemDefaults() {
        let context = AccessibilityContext()

        XCTAssertFalse(context.prefersReducedMotion, "Default should not reduce motion")
        XCTAssertFalse(context.prefersIncreasedContrast, "Default should not increase contrast")
        XCTAssertFalse(context.prefersBoldText, "Default should not force bold text")
        XCTAssertEqual(context.dynamicTypeSize, .large, "Default Dynamic Type should match system large")
        XCTAssertEqual(context.preferredSpacing, DS.Spacing.m, "Default spacing should use DS.Spacing.m")
        XCTAssertEqual(context.preferredFontWeight, .regular, "Default font weight should be regular")
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

        XCTAssertEqual(context.preferredSpacing, DS.Spacing.l, "High contrast should map to DS.Spacing.l")
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

        XCTAssertEqual(context.preferredFontWeight, .bold, "Bold text preference should request bold weight")
    }

    // MARK: - Environment Propagation

    /// Environment values should store and retrieve the context to
    /// allow propagation through the SwiftUI view hierarchy.
    func testEnvironmentValues_AccessibilityContextRoundTrip() {
        var environment = EnvironmentValues()
        let context = AccessibilityContext(
            prefersReducedMotion: true,
            prefersIncreasedContrast: true,
            prefersBoldText: true,
            dynamicTypeSize: .accessibility3
        )

        environment.accessibilityContext = context
        XCTAssertEqual(environment.accessibilityContext, context, "Environment should round-trip the accessibility context")
    }

    /// When no explicit context is provided the environment should
    /// derive preferences from the existing accessibility values.
    func testEnvironmentValues_DerivesDefaultsFromEnvironment() {
        var environment = EnvironmentValues()
        environment.accessibilityReduceMotion = true
        environment.accessibilityContrast = .high
        environment.legibilityWeight = .bold
        environment.dynamicTypeSize = .accessibility2

        let context = environment.accessibilityContext

        XCTAssertTrue(context.prefersReducedMotion, "Reduce Motion preference should be respected")
        XCTAssertTrue(context.prefersIncreasedContrast, "High Contrast preference should be respected")
        XCTAssertTrue(context.prefersBoldText, "Bold text preference should be respected")
        XCTAssertEqual(context.dynamicTypeSize, .accessibility2, "Dynamic Type preference should match the environment")
    }

    /// The view modifier helper should be chainable within SwiftUI
    /// hierarchies. We validate this by creating a simple text view
    /// and verifying the modifier returns a non-nil view type.
    @MainActor
    func testViewModifier_IsComposable() {
        let context = AccessibilityContext(
            prefersReducedMotion: true,
            prefersIncreasedContrast: true,
            prefersBoldText: true,
            dynamicTypeSize: .accessibility3
        )

        let view = Text("Preview").accessibilityContext(context)
        XCTAssertNotNil(view, "The accessibilityContext view modifier should return a view")
    }
}
#endif
