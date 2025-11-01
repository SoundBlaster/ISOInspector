import SwiftUI

// MARK: - AccessibilityContext

/// Aggregates key accessibility preferences from the SwiftUI environment.
///
/// `AccessibilityContext` centralises Reduce Motion, Increase Contrast, Bold Text,
/// and Dynamic Type preferences so that patterns and components can adapt their
/// behaviour consistently across the FoundationUI design system.
///
/// ## Overview
/// - **Reduce Motion**: Disable non-essential animations when users request
///   reduced motion. The ``animation(for:)`` helper bridges to `DS.Animation` tokens
///   and returns `nil` when motion should be avoided.
/// - **Increase Contrast**: Expand spacing using design system tokens to maintain
///   visual separation when high contrast is enabled.
/// - **Bold Text**: Surface the appropriate `Font.Weight` so typography can respond
///   to the user's bold text preference without guessing weights.
/// - **Dynamic Type**: Expose the requested `DynamicTypeSize` and provide spacing
///   helpers that scale layouts for accessibility categories.
///
/// ## Usage
/// ```swift
/// struct InspectorRow: View {
///     @Environment(\.accessibilityContext) private var accessibilityContext
///     @State private var isExpanded = false
///
///     var body: some View {
///         HStack(spacing: accessibilityContext.preferredSpacing) {
///             Text("Label")
///                 .font(DS.Typography.body)
///                 .fontWeight(accessibilityContext.preferredFontWeight)
///
///             Text("Value")
///         }
///         .animation(accessibilityContext.animation(for: DS.Animation.quick), value: isExpanded)
///     }
/// }
/// ```
public struct AccessibilityContext: Equatable, Sendable {

    // MARK: - Stored Properties

    /// Indicates whether the user prefers reduced motion.
    public let prefersReducedMotion: Bool

    /// Indicates whether the user prefers increased contrast.
    public let prefersIncreasedContrast: Bool

    /// Indicates whether the user prefers bold text.
    public let prefersBoldText: Bool

    /// The requested Dynamic Type size from the environment.
    public let dynamicTypeSize: DynamicTypeSize

    // MARK: - Initialisation

    /// Creates a new accessibility context.
    ///
    /// - Parameters:
    ///   - prefersReducedMotion: Whether motion should be reduced.
    ///   - prefersIncreasedContrast: Whether contrast should be increased.
    ///   - prefersBoldText: Whether bold text should be used.
    ///   - dynamicTypeSize: The dynamic type size to apply.
    public init(
        prefersReducedMotion: Bool = false,
        prefersIncreasedContrast: Bool = false,
        prefersBoldText: Bool = false,
        dynamicTypeSize: DynamicTypeSize = .large
    ) {
        self.prefersReducedMotion = prefersReducedMotion
        self.prefersIncreasedContrast = prefersIncreasedContrast
        self.prefersBoldText = prefersBoldText
        self.dynamicTypeSize = dynamicTypeSize
    }

    // MARK: - Animation Support

    /// Returns an animation if motion is allowed, otherwise `nil`.
    ///
    /// - Parameter animation: The base animation to evaluate.
    /// - Returns: The provided animation or `nil` when motion should be avoided.
    public func animation(for animation: Animation) -> Animation? {
        guard !prefersReducedMotion else {
            return nil
        }
        return animation
    }

    // MARK: - Typography Support

    /// Preferred font weight derived from the bold text preference.
    public var preferredFontWeight: Font.Weight {
        prefersBoldText ? .bold : .regular
    }

    // MARK: - Spacing Support

    /// Baseline spacing that respects contrast and dynamic type preferences.
    public var preferredSpacing: CGFloat {
        spacing(for: DS.Spacing.m)
    }

    /// Returns spacing derived from DS tokens, adjusted for accessibility preferences.
    ///
    /// - Parameter baseSpacing: The starting spacing value (expected to be a DS token).
    /// - Returns: Spacing adjusted for increased contrast and larger Dynamic Type sizes.
    public func spacing(for baseSpacing: CGFloat) -> CGFloat {
        var spacing = baseSpacing

        if prefersIncreasedContrast {
            spacing = max(spacing, DS.Spacing.l)
        }

        if dynamicTypeSize.isAccessibilityCategory {
            spacing = max(spacing, DS.Spacing.xl)
        }

        return spacing
    }
}

private extension DynamicTypeSize {
    /// Indicates whether the dynamic type size is an accessibility category.
    var isAccessibilityCategory: Bool {
        self >= .accessibility1
    }
}

// MARK: - Environment Support

private struct AccessibilityContextKey: EnvironmentKey {
    static let defaultValue = AccessibilityContext()
}

public extension EnvironmentValues {
    /// Accessibility preferences used by FoundationUI components.
    var accessibilityContext: AccessibilityContext {
        get { self[AccessibilityContextKey.self] }
        set { self[AccessibilityContextKey.self] = newValue }
    }
}

private struct AccessibilityContextModifier: ViewModifier {
    let context: AccessibilityContext

    func body(content: Content) -> some View {
        content
            .environment(\.accessibilityContext, context)
            .dynamicTypeSize(context.dynamicTypeSize)
    }
}

public extension View {
    /// Applies the provided accessibility context to the view hierarchy.
    ///
    /// The modifier stores the context in the environment and sets the
    /// dynamic type size so previews and unit tests can simulate different
    /// accessibility scenarios.
    ///
    /// - Parameter context: The accessibility context to apply.
    /// - Returns: A view configured with the provided accessibility context.
    func accessibilityContext(_ context: AccessibilityContext) -> some View {
        modifier(AccessibilityContextModifier(context: context))
    }
}
