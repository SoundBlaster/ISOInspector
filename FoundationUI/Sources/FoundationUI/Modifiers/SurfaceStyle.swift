import SwiftUI

/// Material-based surface types for backgrounds
///
/// Provides system materials with automatic light/dark mode adaptation
/// and platform-specific appearance. Materials create depth and visual
/// hierarchy through translucency and vibrancy effects.
///
/// ## Usage
/// ```swift
/// VStack {
///     Text("Content")
/// }
/// .surfaceStyle(material: .regular)
///
/// InspectorView()
///     .surfaceStyle(material: .thin)
/// ```
///
/// ## Platform Support
/// - iOS 17.0+: Full material support with vibrancy
/// - macOS 14.0+: Full material support with window integration
/// - Fallback: Solid colors from DS.Color on unsupported platforms
///
/// ## Accessibility
/// Materials respect system preferences:
/// - Reduce Transparency: Falls back to solid colors
/// - Increase Contrast: Enhanced vibrancy and separation
/// - Dark Mode: Automatically adapts material appearance
public enum SurfaceMaterial: Equatable, Sendable {
    /// Thin material - maximum translucency, subtle depth
    case thin

    /// Regular material - balanced translucency and vibrancy
    case regular

    /// Thick material - reduced translucency, prominent depth
    case thick

    /// Ultra thick material - minimal translucency, strong separation
    case ultra

    /// Human-readable description of the material
    public var description: String {
        switch self {
        case .thin:
            return "Thin material"
        case .regular:
            return "Regular material"
        case .thick:
            return "Thick material"
        case .ultra:
            return "Ultra thick material"
        }
    }

    /// Accessibility label for VoiceOver
    ///
    /// Describes the visual appearance for users who cannot see
    /// the translucency effects.
    public var accessibilityLabel: String {
        switch self {
        case .thin:
            return "Thin material background"
        case .regular:
            return "Regular material background"
        case .thick:
            return "Thick material background"
        case .ultra:
            return "Ultra thick material background"
        }
    }

    /// Fallback color for platforms that don't support materials
    ///
    /// Uses Design System colors to maintain visual consistency
    /// when materials are unavailable or disabled (e.g., Reduce Transparency).
    public var fallbackColor: Color {
        switch self {
        case .thin:
            // Very light, almost transparent
            return Color.gray.opacity(0.05)
        case .regular:
            // Standard background from Design System
            return DS.Colors.tertiary
        case .thick:
            // More opaque for stronger separation
            return Color.gray.opacity(0.15)
        case .ultra:
            // Nearly opaque for maximum separation
            return Color.gray.opacity(0.20)
        }
    }

    /// SwiftUI Material corresponding to this surface material
    ///
    /// Maps surface materials to SwiftUI's Material types for
    /// consistent appearance across the system.
    @available(iOS 17.0, macOS 14.0, *)
    public var swiftUIMaterial: Material {
        switch self {
        case .thin:
            return .thinMaterial
        case .regular:
            return .regularMaterial
        case .thick:
            return .thickMaterial
        case .ultra:
            return .ultraThickMaterial
        }
    }
}

/// View modifier that applies material-based surface styling
///
/// Applies system materials for backgrounds with automatic adaptation to:
/// - Light/Dark mode
/// - Reduce Transparency accessibility setting
/// - Platform-specific appearance (iOS vs macOS)
///
/// ## Design System Usage
/// - **Fallback Colors**: Uses DS.Colors.tertiary and gray opacity for solid fallbacks
/// - **Platform Adaptation**: Conditional materials based on OS availability
///
/// ## Accessibility
/// - Respects Reduce Transparency (falls back to solid colors)
/// - Respects Increase Contrast (enhanced material vibrancy)
/// - Provides descriptive labels for assistive technologies
///
/// ## Platform Support
/// - iOS 17.0+: Full material support
/// - macOS 14.0+: Full material support
/// - Earlier versions: Solid color fallback
private struct SurfaceStyleModifier: ViewModifier {
    /// The material type for the surface
    let material: SurfaceMaterial

    /// Whether to allow fallback to solid color
    let allowFallback: Bool

    /// Whether reduce transparency is enabled (for fallback)
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        content
            .background(backgroundView)
            .accessibilityElement(children: .contain)
    }

    /// The background view with material or fallback
    @ViewBuilder
    private var backgroundView: some View {
        if #available(iOS 17.0, macOS 14.0, *), !reduceTransparency {
            // Use system material on supported platforms
            Color.clear
                .background(material.swiftUIMaterial)
        } else if allowFallback {
            // Fall back to solid color when materials unavailable
            // or when Reduce Transparency is enabled
            material.fallbackColor
        } else {
            // No background if fallback is disabled
            Color.clear
        }
    }
}

// MARK: - View Extension

public extension View {
    /// Applies material-based surface styling to the view
    ///
    /// Adds a translucent material background that adapts to light/dark mode
    /// and respects accessibility preferences.
    ///
    /// ## Example
    /// ```swift
    /// VStack {
    ///     Text("Content")
    /// }
    /// .padding()
    /// .surfaceStyle(material: .regular)
    ///
    /// InspectorPanel {
    ///     // Panel content
    /// }
    /// .surfaceStyle(material: .thin)
    /// ```
    ///
    /// ## Parameters
    /// - material: The material type (thin, regular, thick, ultra)
    /// - allowFallback: Whether to use solid color on unsupported platforms (default: true)
    ///
    /// ## Design Tokens Used
    /// - `DS.Colors.tertiary`: Fallback for regular material
    /// - Gray opacity: Fallbacks for thin/thick/ultra materials
    ///
    /// ## Platform Adaptation
    /// - iOS 17.0+/macOS 14.0+: Uses system materials
    /// - Earlier versions: Uses fallback colors
    /// - Reduce Transparency ON: Always uses fallback colors
    ///
    /// ## Accessibility
    /// - Automatically respects Reduce Transparency
    /// - Materials adapt to Increase Contrast
    /// - Maintains hierarchy even with solid fallbacks
    /// - VoiceOver describes the surface appearance
    ///
    /// ## Material Guidelines
    /// - **Thin**: Use for temporary overlays, popovers, tooltips
    /// - **Regular**: Use for panels, inspector views, sidebars
    /// - **Thick**: Use for modal sheets, prominent containers
    /// - **Ultra**: Use for critical modals, blocking overlays
    ///
    /// - Returns: A view with material-based surface styling
    func surfaceStyle(
        material: SurfaceMaterial = .regular,
        allowFallback: Bool = true
    ) -> some View {
        modifier(
            SurfaceStyleModifier(
                material: material,
                allowFallback: allowFallback
            )
        )
    }
}

// MARK: - SwiftUI Previews

#Preview("Surface Styles - All Materials") {
    ZStack {
        // Background image to show translucency
        Image(systemName: "grid.circle.fill")
            .resizable()
            .frame(width: 200, height: 200)
            .foregroundStyle(.blue)
            .opacity(0.3)

        VStack(spacing: DS.Spacing.xl) {
            VStack {
                Text("Thin Material")
                    .font(.headline)
                Text("Maximum translucency")
                    .font(.caption)
            }
            .padding()
            .surfaceStyle(material: .thin)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))

            VStack {
                Text("Regular Material")
                    .font(.headline)
                Text("Balanced vibrancy")
                    .font(.caption)
            }
            .padding()
            .surfaceStyle(material: .regular)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))

            VStack {
                Text("Thick Material")
                    .font(.headline)
                Text("Reduced translucency")
                    .font(.caption)
            }
            .padding()
            .surfaceStyle(material: .thick)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))

            VStack {
                Text("Ultra Thick Material")
                    .font(.headline)
                Text("Minimal translucency")
                    .font(.caption)
            }
            .padding()
            .surfaceStyle(material: .ultra)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
        }
        .padding()
    }
}

#Preview("Surface Styles - With Card Elevation") {
    ZStack {
        LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: DS.Spacing.l) {
            VStack {
                Text("Surface + Low Elevation")
                    .font(.headline)
            }
            .padding()
            .surfaceStyle(material: .regular)
            .cardStyle(elevation: .low, useMaterial: false)

            VStack {
                Text("Surface + Medium Elevation")
                    .font(.headline)
            }
            .padding()
            .surfaceStyle(material: .regular)
            .cardStyle(elevation: .medium, useMaterial: false)

            VStack {
                Text("Surface + High Elevation")
                    .font(.headline)
            }
            .padding()
            .surfaceStyle(material: .thick)
            .cardStyle(elevation: .high, useMaterial: false)
        }
        .padding()
    }
}

#Preview("Surface Styles - Dark Mode") {
    ZStack {
        Color.blue.opacity(0.2)
            .ignoresSafeArea()

        VStack(spacing: DS.Spacing.l) {
            Text("Thin")
                .padding()
                .surfaceStyle(material: .thin)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))

            Text("Regular")
                .padding()
                .surfaceStyle(material: .regular)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))

            Text("Thick")
                .padding()
                .surfaceStyle(material: .thick)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))

            Text("Ultra")
                .padding()
                .surfaceStyle(material: .ultra)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}

#Preview("Surface Styles - Inspector Pattern") {
    HStack(spacing: 0) {
        // Main content area
        VStack {
            Text("Main Content")
                .font(.largeTitle)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.1))

        // Inspector panel with surface style
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text("Inspector")
                .font(.headline)

            Divider()

            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                Text("Property")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Value")
            }

            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                Text("Status")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("ACTIVE")
                    .badgeChipStyle(level: .success)
            }

            Spacer()
        }
        .padding()
        .frame(width: 250)
        .surfaceStyle(material: .regular)
    }
}

#Preview("Surface Styles - Layered Panels") {
    ZStack {
        // Background layer
        Color.blue.opacity(0.1)
            .ignoresSafeArea()

        // Back panel
        VStack {
            Text("Back Panel")
                .font(.title)
            Spacer()
        }
        .padding()
        .frame(width: 350, height: 450)
        .surfaceStyle(material: .regular)
        .cardStyle(elevation: .low)
        .offset(x: -20, y: -20)

        // Middle panel
        VStack {
            Text("Middle Panel")
                .font(.title2)
            Spacer()
        }
        .padding()
        .frame(width: 320, height: 400)
        .surfaceStyle(material: .thick)
        .cardStyle(elevation: .medium)
        .offset(x: 0, y: 0)

        // Front panel
        VStack {
            Text("Front Panel")
                .font(.headline)
            Text("Ultra thick material")
                .font(.caption)
        }
        .padding()
        .frame(width: 250, height: 150)
        .surfaceStyle(material: .ultra)
        .cardStyle(elevation: .high)
        .offset(x: 20, y: 100)
    }
}

#Preview("Surface Styles - No Fallback") {
    VStack(spacing: DS.Spacing.l) {
        Text("With Fallback")
            .padding()
            .surfaceStyle(material: .regular, allowFallback: true)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))

        Text("Without Fallback")
            .padding()
            .surfaceStyle(material: .regular, allowFallback: false)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .stroke(Color.gray, lineWidth: 1)
            )
    }
    .padding()
}
