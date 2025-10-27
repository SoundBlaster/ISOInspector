// swift-tools-version: 6.0
import SwiftUI

/// Interaction feedback intensity levels
///
/// Defines how prominently an element responds to user interaction.
/// Different platforms apply these effects differently:
/// - macOS: Primarily hover effects with cursor feedback
/// - iOS/iPadOS: Touch feedback with optional haptics
///
/// ## Usage
/// ```swift
/// Button("Click me") { }
///     .interactiveStyle(type: .standard)
///
/// NavigationLink("Details") { }
///     .interactiveStyle(type: .subtle)
/// ```
///
/// ## Accessibility
/// Each interaction type includes:
/// - Descriptive hints for VoiceOver
/// - Keyboard navigation support
/// - Focus indicators for assistive technologies
///
/// ## Design System Integration
/// Uses DS.Animation.quick for responsive, snappy feedback that matches
/// the Composable Clarity animation principles.
public enum InteractionType: Equatable, Sendable {
    /// No interaction feedback
    case none

    /// Subtle interaction feedback (minimal scale/opacity change)
    case subtle

    /// Standard interaction feedback (moderate scale/opacity change)
    case standard

    /// Prominent interaction feedback (significant scale/opacity change)
    case prominent

    /// Whether this interaction type applies any effects
    public var hasEffect: Bool {
        switch self {
        case .none:
            return false
        case .subtle, .standard, .prominent:
            return true
        }
    }

    /// Scale factor applied on interaction (1.0 = no scaling)
    ///
    /// Scales up the view slightly to provide tactile feedback.
    /// Larger values create more noticeable interaction.
    public var scaleFactor: CGFloat {
        switch self {
        case .none:
            return 1.0
        case .subtle:
            return 1.02  // 2% increase
        case .standard:
            return 1.05  // 5% increase
        case .prominent:
            return 1.08  // 8% increase
        }
    }

    /// Opacity applied on hover/touch (1.0 = full opacity)
    ///
    /// Slightly reduces opacity to indicate interactivity.
    /// Lower values create more prominent dimming effect.
    public var hoverOpacity: Double {
        switch self {
        case .none:
            return 1.0
        case .subtle:
            return 0.95  // 5% reduction
        case .standard:
            return 0.9   // 10% reduction
        case .prominent:
            return 0.85  // 15% reduction
        }
    }

    /// Accessibility hint describing the interaction
    ///
    /// Provides context for VoiceOver users about how the element
    /// responds to interaction.
    public var accessibilityHint: String {
        switch self {
        case .none:
            return ""
        case .subtle:
            return "Interactive element with subtle feedback"
        case .standard:
            return "Interactive element"
        case .prominent:
            return "Primary interactive element with prominent feedback"
        }
    }

    /// Whether this interaction type supports keyboard focus
    ///
    /// Interactive elements should be keyboard-navigable for accessibility.
    public var supportsKeyboardFocus: Bool {
        return hasEffect
    }

    /// Focus ring color for keyboard navigation
    ///
    /// Uses system accent color for consistency with platform conventions.
    public var focusRingColor: Color {
        return DS.Color.accent
    }

    /// Focus ring width in points
    ///
    /// Larger values create more prominent focus indicators.
    public var focusRingWidth: CGFloat {
        switch self {
        case .none:
            return 0
        case .subtle:
            return 1
        case .standard:
            return 2
        case .prominent:
            return 3
        }
    }
}

/// View modifier that applies interactive feedback styling
///
/// Provides platform-adaptive interaction feedback:
/// - **macOS**: Hover effects with cursor changes
/// - **iOS/iPadOS**: Touch feedback with scale animation
///
/// ## Design System Usage
/// - **Animation**: Uses `DS.Animation.quick` for snappy responsiveness
/// - **Colors**: Uses `DS.Color.accent` for focus indicators
///
/// ## Accessibility
/// - Adds keyboard focus indicators
/// - Provides VoiceOver hints
/// - Supports full keyboard navigation
///
/// ## Platform Support
/// - iOS 17.0+: Touch feedback with button traits
/// - macOS 14.0+: Hover effects with pointer interactions
/// - iPadOS 17.0+: Touch and pointer feedback (hybrid)
private struct InteractiveStyleModifier: ViewModifier {
    /// The interaction type determining feedback intensity
    let type: InteractionType

    /// Whether to show a focus ring during keyboard navigation
    let showFocusRing: Bool

    /// State tracking whether the view is currently hovered (macOS)
    @State private var isHovered: Bool = false

    /// State tracking whether the view is currently pressed
    @State private var isPressed: Bool = false

    /// State tracking whether the view has keyboard focus
    @FocusState private var isFocused: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(effectiveScale)
            .opacity(effectiveOpacity)
            .overlay(
                Group {
                    if showFocusRing && isFocused && type.supportsKeyboardFocus {
                        RoundedRectangle(cornerRadius: DS.Radius.small)
                            .strokeBorder(type.focusRingColor, lineWidth: type.focusRingWidth)
                    }
                }
            )
            .animation(DS.Animation.quick, value: isHovered)
            .animation(DS.Animation.quick, value: isPressed)
            .animation(DS.Animation.quick, value: isFocused)
            .modifier(
                FocusableIfAvailable(
                    isEnabled: type.supportsKeyboardFocus,
                    focusBinding: $isFocused
                )
            )
            #if os(macOS)
            .onHover { hovering in
                isHovered = hovering
            }
            #endif
            .accessibilityHint(type.accessibilityHint)
            .accessibilityAddTraits(.isButton)
    }

    /// Effective scale factor based on current interaction state
    private var effectiveScale: CGFloat {
        guard type.hasEffect else { return 1.0 }

        if isPressed {
            // Slightly smaller scale when pressed for "push down" effect
            return type.scaleFactor * 0.98
        } else if isHovered || isFocused {
            return type.scaleFactor
        } else {
            return 1.0
        }
    }

    /// Effective opacity based on current interaction state
    private var effectiveOpacity: Double {
        guard type.hasEffect else { return 1.0 }

        if isPressed {
            // More opacity reduction when pressed
            return type.hoverOpacity * 0.95
        } else if isHovered {
            return type.hoverOpacity
        } else {
            return 1.0
        }
    }
}

/// Applies the focusable modifier only when supported on the current platform
private struct FocusableIfAvailable: ViewModifier {
    /// Whether keyboard focus should be enabled
    let isEnabled: Bool

    /// Binding used to track the current focus state
    let focusBinding: FocusState<Bool>.Binding

    func body(content: Content) -> some View {
        #if os(iOS)
        if #available(iOS 17, *) {
            content
                .focusable(isEnabled)
                .focused(focusBinding)
        } else {
            content
                .focused(focusBinding)
        }
        #else
        content
            .focusable(isEnabled)
            .focused(focusBinding)
        #endif
    }
}

// MARK: - View Extension

public extension View {
    /// Applies interactive styling with platform-adaptive feedback
    ///
    /// Adds visual feedback for user interactions, adapting to the platform:
    /// - macOS: Hover effects with cursor changes
    /// - iOS/iPadOS: Touch feedback with scale animation
    ///
    /// ## Example
    /// ```swift
    /// Button("Submit") { }
    ///     .interactiveStyle(type: .standard)
    ///
    /// Card {
    ///     Text("Click me")
    /// }
    /// .interactiveStyle(type: .subtle, showFocusRing: true)
    /// ```
    ///
    /// ## Parameters
    /// - type: Interaction feedback intensity (none, subtle, standard, prominent)
    /// - showFocusRing: Whether to show focus indicator for keyboard navigation (default: true)
    ///
    /// ## Design Tokens Used
    /// - `DS.Animation.quick`: Fast, snappy animation for responsiveness
    /// - `DS.Color.accent`: Focus ring color
    /// - `DS.Radius.small`: Focus ring corner radius
    ///
    /// ## Platform Adaptation
    /// - macOS: Uses `.onHover()` for cursor-based interaction
    /// - iOS/iPadOS: Uses touch-based state tracking
    /// - All platforms: Keyboard focus support with visible indicators
    ///
    /// ## Accessibility
    /// - Adds `.isButton` accessibility trait
    /// - Provides descriptive hints for VoiceOver
    /// - Fully keyboard navigable with focus indicators
    /// - Works with Switch Control and Voice Control
    ///
    /// - Returns: A view with interactive feedback styling
    func interactiveStyle(
        type: InteractionType = .standard,
        showFocusRing: Bool = true
    ) -> some View {
        modifier(
            InteractiveStyleModifier(
                type: type,
                showFocusRing: showFocusRing
            )
        )
    }
}

// MARK: - SwiftUI Previews

#Preview("Interactive Styles - All Types") {
    VStack(spacing: DS.Spacing.xl) {
        Text("No Interaction")
            .padding()
            .background(DS.Color.tertiary)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
            .interactiveStyle(type: .none)

        Text("Subtle Interaction")
            .padding()
            .background(DS.Color.tertiary)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
            .interactiveStyle(type: .subtle)

        Text("Standard Interaction")
            .padding()
            .background(DS.Color.tertiary)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
            .interactiveStyle(type: .standard)

        Text("Prominent Interaction")
            .padding()
            .background(DS.Color.tertiary)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
            .interactiveStyle(type: .prominent)
    }
    .padding()
}

#Preview("Interactive Styles - With Card Style") {
    VStack(spacing: DS.Spacing.l) {
        VStack {
            Text("Clickable Card")
                .font(.headline)
            Text("Hover or click to see interaction")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .cardStyle(elevation: .low)
        .interactiveStyle(type: .standard)

        VStack {
            Text("Button-Like Card")
                .font(.headline)
            Text("Prominent interaction feedback")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .cardStyle(elevation: .medium)
        .interactiveStyle(type: .prominent)
    }
    .padding()
}

#Preview("Interactive Styles - With Badges") {
    VStack(spacing: DS.Spacing.l) {
        HStack(spacing: DS.Spacing.m) {
            Text("INFO")
                .badgeChipStyle(level: .info)
                .interactiveStyle(type: .subtle)

            Text("WARNING")
                .badgeChipStyle(level: .warning)
                .interactiveStyle(type: .subtle)

            Text("ERROR")
                .badgeChipStyle(level: .error)
                .interactiveStyle(type: .subtle)

            Text("SUCCESS")
                .badgeChipStyle(level: .success)
                .interactiveStyle(type: .subtle)
        }

        Text("Interactive badges with subtle feedback")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
}

#Preview("Interactive Styles - Focus Ring") {
    VStack(spacing: DS.Spacing.l) {
        Text("Tab to focus")
            .padding()
            .background(DS.Color.tertiary)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
            .interactiveStyle(type: .standard, showFocusRing: true)

        Text("No focus ring")
            .padding()
            .background(DS.Color.tertiary)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
            .interactiveStyle(type: .standard, showFocusRing: false)
    }
    .padding()
}

#Preview("Interactive Styles - Dark Mode") {
    VStack(spacing: DS.Spacing.l) {
        Text("Subtle")
            .padding()
            .cardStyle(elevation: .medium)
            .interactiveStyle(type: .subtle)

        Text("Standard")
            .padding()
            .cardStyle(elevation: .medium)
            .interactiveStyle(type: .standard)

        Text("Prominent")
            .padding()
            .cardStyle(elevation: .medium)
            .interactiveStyle(type: .prominent)
    }
    .padding()
    .preferredColorScheme(.dark)
}

#Preview("Interactive Styles - List Items") {
    List {
        ForEach(1...5, id: \.self) { index in
            HStack {
                Image(systemName: "\(index).circle.fill")
                    .foregroundStyle(DS.Color.accent)
                Text("Item \(index)")
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, DS.Spacing.s)
            .interactiveStyle(type: .subtle)
        }
    }
}
