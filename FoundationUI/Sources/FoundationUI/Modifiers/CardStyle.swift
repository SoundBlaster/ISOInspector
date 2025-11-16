import SwiftUI

/// Card elevation levels for visual hierarchy
///
/// Defines elevation levels that create visual depth through shadows and materials.
/// Following Material Design principles adapted for Apple platforms.
///
/// ## Usage
/// ```swift
/// VStack {
///     Text("Content")
/// }
/// .cardStyle(elevation: .medium, cornerRadius: DS.Radius.card)
/// ```
///
/// ## Accessibility
/// Each elevation level includes descriptive labels for assistive technologies,
/// helping users understand the visual hierarchy even when shadows aren't visible.
///
/// ## Design System Integration
/// Shadow properties use consistent values that work harmoniously with DS tokens
/// for spacing, colors, and radius.
public enum CardElevation: Equatable, Sendable, CaseIterable {
    /// No elevation - flat appearance with no shadow
    case none

    /// Low elevation - subtle shadow for slight depth
    case low

    /// Medium elevation - moderate shadow for standard cards
    case medium

    /// High elevation - prominent shadow for emphasized content
    case high

    /// Whether this elevation level applies a shadow effect
    public var hasShadow: Bool {
        switch self {
        case .none:
            false
        case .low, .medium, .high:
            true
        }
    }

    /// Shadow blur radius for the elevation level
    ///
    /// Larger values create more diffuse, softer shadows.
    /// Values are calibrated to work on both iOS and macOS.
    public var shadowRadius: CGFloat {
        switch self {
        case .none:
            0
        case .low:
            2
        case .medium:
            4
        case .high:
            8
        }
    }

    /// Shadow opacity for the elevation level
    ///
    /// Controls the intensity of the shadow.
    /// Values are subtle to avoid overwhelming the interface.
    public var shadowOpacity: Double {
        switch self {
        case .none:
            0
        case .low:
            0.1
        case .medium:
            0.15
        case .high:
            0.2
        }
    }

    /// Vertical offset of the shadow
    ///
    /// Creates the illusion of height by offsetting the shadow downward.
    /// Higher elevations have larger offsets for more dramatic depth.
    public var shadowYOffset: CGFloat {
        switch self {
        case .none:
            0
        case .low:
            1
        case .medium:
            2
        case .high:
            4
        }
    }

    /// String representation for serialization and agent consumption
    ///
    /// Provides a lowercase string identifier for the elevation level,
    /// suitable for JSON serialization and agent-driven UI generation.
    public var stringValue: String {
        switch self {
        case .none:
            "none"
        case .low:
            "low"
        case .medium:
            "medium"
        case .high:
            "high"
        }
    }

    /// Accessibility label describing the elevation level
    ///
    /// Provides semantic information for VoiceOver users about the
    /// visual prominence of the card.
    public var accessibilityLabel: String {
        switch self {
        case .none:
            "Flat card"
        case .low:
            "Card with subtle elevation"
        case .medium:
            "Card with medium elevation"
        case .high:
            "Card with high elevation"
        }
    }
}

/// View modifier that applies card styling with elevation and corner radius
///
/// Transforms any view into a card with:
/// - Configurable elevation (shadow depth)
/// - Configurable corner radius using DS tokens
/// - Platform-adaptive background materials
/// - Accessibility support
///
/// ## Design System Usage
/// - **Corner Radius**: Typically uses `DS.Radius.card` or `DS.Radius.small`
/// - **Background**: Uses system materials or DS.Colors.tertiary
/// - **Shadows**: Calibrated values that work on all platforms
///
/// ## Platform Adaptation
/// - macOS: Uses stronger shadows for desktop aesthetics
/// - iOS/iPadOS: Uses lighter shadows optimized for touch interfaces
///
/// ## Accessibility
/// - Maintains semantic structure for assistive technologies
/// - Shadow effects are supplementary, not required for comprehension
/// - Supports Dynamic Type for content scaling
public struct CardStyle: ViewModifier {
    /// The elevation level determining shadow depth
    let elevation: CardElevation

    /// The corner radius for the card shape
    let cornerRadius: CGFloat

    /// Whether to use a material background
    let useMaterial: Bool

    public func body(content: Content) -> some View {
        content
            .background(
                Group {
                    if useMaterial {
                        // Use system material for depth and vibrancy
                        #if os(iOS)
                        Color.clear
                            .background(.regularMaterial)
                        #elseif os(macOS)
                        Color.clear
                            .background(.regularMaterial)
                        #else
                        DS.Colors.tertiary
                        #endif
                    } else {
                        DS.Colors.tertiary
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(
                color: elevation.hasShadow ? Color.black.opacity(elevation.shadowOpacity) : .clear,
                radius: elevation.shadowRadius,
                x: 0,
                y: elevation.shadowYOffset
            )
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - View Extension

public extension View {
    /// Applies card styling to the view
    ///
    /// Transforms the view into a card with configurable elevation and corner radius.
    ///
    /// ## Example
    /// ```swift
    /// VStack {
    ///     Text("Title")
    ///         .font(.headline)
    ///     Text("Content")
    ///         .font(.body)
    /// }
    /// .padding()
    /// .cardStyle(elevation: .medium, cornerRadius: DS.Radius.card)
    /// ```
    ///
    /// ## Parameters
    /// - elevation: Visual depth level (none, low, medium, high)
    /// - cornerRadius: Corner rounding using DS.Radius tokens
    /// - useMaterial: Whether to use system material background (default: true on supported platforms)
    ///
    /// ## Design Tokens Used
    /// - `DS.Radius.card`
    /// - `DS.Radius.small`
    /// - `DS.Radius.medium`
    /// - `DS.Colors.tertiary`
    ///
    /// ## Platform Adaptation
    /// - macOS: Stronger shadows for desktop UI
    /// - iOS/iPadOS: Lighter shadows for touch interfaces
    /// - Material backgrounds adapt to light/dark mode
    ///
    /// ## Accessibility
    /// - Maintains semantic structure
    /// - Shadow is purely visual, not semantic
    /// - Supports Dynamic Type scaling
    ///
    /// - Returns: A view styled as a card with elevation
    func cardStyle(
        elevation: CardElevation = .medium,
        cornerRadius: CGFloat = DS.Radius.card,
        useMaterial: Bool = true
    ) -> some View {
        modifier(
            CardStyle(
                elevation: elevation,
                cornerRadius: cornerRadius,
                useMaterial: useMaterial
            )
        )
    }
}

// MARK: - SwiftUI Previews

#Preview("Card Styles - Elevation Levels") {
    VStack(spacing: DS.Spacing.xl) {
        VStack {
            Text("No Elevation")
                .font(.headline)
            Text("Flat appearance")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .cardStyle(elevation: .none)

        VStack {
            Text("Low Elevation")
                .font(.headline)
            Text("Subtle shadow")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .cardStyle(elevation: .low)

        VStack {
            Text("Medium Elevation")
                .font(.headline)
            Text("Standard card")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .cardStyle(elevation: .medium)

        VStack {
            Text("High Elevation")
                .font(.headline)
            Text("Prominent shadow")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .cardStyle(elevation: .high)
    }
    .padding()
}

#Preview("Card Styles - Corner Radius Variants") {
    VStack(spacing: DS.Spacing.l) {
        VStack {
            Text("Small Radius")
            Text("6pt corners")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .cardStyle(elevation: .medium, cornerRadius: DS.Radius.small)

        VStack {
            Text("Medium Radius")
            Text("8pt corners")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .cardStyle(elevation: .medium, cornerRadius: DS.Radius.medium)

        VStack {
            Text("Card Radius")
            Text("10pt corners (default)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .cardStyle(elevation: .medium, cornerRadius: DS.Radius.card)
    }
    .padding()
}

#Preview("Card Styles - Dark Mode") {
    VStack(spacing: DS.Spacing.l) {
        VStack {
            Text("Low Elevation")
                .font(.headline)
        }
        .padding()
        .cardStyle(elevation: .low)

        VStack {
            Text("Medium Elevation")
                .font(.headline)
        }
        .padding()
        .cardStyle(elevation: .medium)

        VStack {
            Text("High Elevation")
                .font(.headline)
        }
        .padding()
        .cardStyle(elevation: .high)
    }
    .padding()
    .preferredColorScheme(.dark)
}

#Preview("Card Styles - Content Examples") {
    ScrollView {
        VStack(spacing: DS.Spacing.l) {
            // Simple text card
            VStack(alignment: .leading) {
                Text("Simple Card")
                    .font(.headline)
                Text("This is a basic card with text content.")
                    .font(.body)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .cardStyle(elevation: .low)

            // Card with badge
            VStack(alignment: .leading) {
                HStack {
                    Text("Status Card")
                        .font(.headline)
                    Spacer()
                    Text("ACTIVE")
                        .badgeChipStyle(level: .success)
                }
                Text("Card showing integration with badge components.")
                    .font(.body)
            }
            .padding()
            .cardStyle(elevation: .medium)

            // Complex content card
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                Text("Feature Card")
                    .font(.headline)
                Divider()
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Feature enabled")
                    }
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundStyle(.orange)
                        Text("Last updated: Today")
                    }
                }
                .font(.caption)
            }
            .padding()
            .cardStyle(elevation: .high)
        }
        .padding()
    }
}

#Preview("Card Styles - No Material Background") {
    VStack(spacing: DS.Spacing.l) {
        VStack {
            Text("Without Material")
                .font(.headline)
            Text("Uses solid background color")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .cardStyle(elevation: .medium, useMaterial: false)

        VStack {
            Text("With Material")
                .font(.headline)
            Text("Uses system material")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .cardStyle(elevation: .medium, useMaterial: true)
    }
    .padding()
}
