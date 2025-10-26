import SwiftUI

// MARK: - SurfaceStyleKey Environment Key

/// Environment key for surface material styling
///
/// Provides a way to propagate surface material preferences through the SwiftUI
/// view hierarchy using the environment system. This enables consistent material
/// usage across nested views and supports flexible UI composition.
///
/// ## Overview
///
/// The surface style environment key allows parent views to specify a material
/// type that child views can inherit or override. This is particularly useful
/// for creating cohesive UI patterns like inspectors, sidebars, and panels.
///
/// ## Design System Integration
///
/// This key works seamlessly with:
/// - **SurfaceMaterial**: The material type enum (thin, regular, thick, ultra)
/// - **SurfaceStyle Modifier**: The `.surfaceStyle()` modifier for applying materials
/// - **Design Tokens**: All fallback colors use DS tokens
///
/// ## Usage
///
/// ### Reading the Environment Value
///
/// ```swift
/// struct MyView: View {
///     @Environment(\.surfaceStyle) var surfaceStyle
///
///     var body: some View {
///         VStack {
///             Text("Content")
///         }
///         .surfaceStyle(material: surfaceStyle)
///     }
/// }
/// ```
///
/// ### Setting a Custom Value
///
/// ```swift
/// struct ParentView: View {
///     var body: some View {
///         ChildView()
///             .environment(\.surfaceStyle, .thick)
///     }
/// }
/// ```
///
/// ### Overriding in Nested Views
///
/// ```swift
/// VStack {
///     // Uses .regular from parent
///     ContentView()
///
///     // Overrides to .thin
///     InspectorView()
///         .environment(\.surfaceStyle, .thin)
/// }
/// .environment(\.surfaceStyle, .regular)
/// ```
///
/// ## Use Cases
///
/// ### Inspector Pattern
/// ```swift
/// HStack(spacing: 0) {
///     // Main content
///     ContentView()
///         .environment(\.surfaceStyle, .regular)
///
///     // Inspector sidebar
///     InspectorPanel()
///         .environment(\.surfaceStyle, .thick)
/// }
/// ```
///
/// ### Layered Modals
/// ```swift
/// ZStack {
///     // Background
///     MainView()
///         .environment(\.surfaceStyle, .regular)
///
///     // Modal overlay
///     if showModal {
///         ModalView()
///             .environment(\.surfaceStyle, .ultra)
///     }
/// }
/// ```
///
/// ### Platform Adaptation
/// ```swift
/// #if os(macOS)
/// content.environment(\.surfaceStyle, .thin)
/// #else
/// content.environment(\.surfaceStyle, .regular)
/// #endif
/// ```
///
/// ## Default Value
///
/// The default surface style is `.regular`, which provides a balanced
/// translucency suitable for most use cases. This default ensures that
/// views have a consistent appearance even when no explicit surface
/// style is specified.
///
/// ## Platform Support
/// - iOS 17.0+: Full material support with vibrancy
/// - macOS 14.0+: Full material support with window integration
/// - All platforms: Environment propagation works universally
///
/// ## Accessibility
///
/// Surface materials respect system accessibility preferences:
/// - **Reduce Transparency**: Automatically falls back to solid colors
/// - **Increase Contrast**: Materials enhance vibrancy and separation
/// - **Dark Mode**: Materials adapt automatically
///
/// ## Performance
///
/// Environment values are efficient and lightweight. Reading an environment
/// value has no performance overhead, and SwiftUI automatically optimizes
/// environment propagation.
///
/// ## Best Practices
///
/// 1. **Use Semantic Materials**: Choose materials based on UI hierarchy
///    - `.thin`: Overlays, popovers, tooltips
///    - `.regular`: Panels, inspectors, sidebars
///    - `.thick`: Modal sheets, prominent containers
///    - `.ultra`: Critical modals, blocking overlays
///
/// 2. **Minimize Overrides**: Let materials propagate naturally when possible
///
/// 3. **Test Accessibility**: Always verify appearance with Reduce Transparency
///
/// 4. **Platform Adaptation**: Consider platform-specific defaults
///
/// ## See Also
/// - ``SurfaceMaterial``: The material type enum
/// - ``SurfaceStyleModifier``: The modifier that applies materials
/// - `EnvironmentValues/surfaceStyle`: The environment value accessor
public struct SurfaceStyleKey: EnvironmentKey {
    /// The default surface material
    ///
    /// Set to `.regular` to provide a balanced translucency suitable for
    /// most UI contexts. This value is used when no explicit surface style
    /// is specified in the environment hierarchy.
    ///
    /// ## Design Rationale
    ///
    /// The `.regular` material provides:
    /// - **Moderate translucency**: Shows context without being distracting
    /// - **Good vibrancy**: Text and content remain readable
    /// - **Platform consistency**: Works well on both iOS and macOS
    /// - **Accessibility**: Falls back gracefully with Reduce Transparency
    ///
    /// ## Example
    ///
    /// ```swift
    /// // This view uses the default .regular material
    /// struct MyView: View {
    ///     @Environment(\.surfaceStyle) var surfaceStyle
    ///
    ///     var body: some View {
    ///         Text("Content")
    ///             .surfaceStyle(material: surfaceStyle)
    ///     }
    /// }
    /// ```
    public static let defaultValue: SurfaceMaterial = .regular
}

// MARK: - EnvironmentValues Extension

public extension EnvironmentValues {
    /// The current surface material style from the environment
    ///
    /// Use this property to read or set the surface material for a view hierarchy.
    /// Child views inherit the surface style from their parents unless explicitly
    /// overridden.
    ///
    /// ## Reading the Value
    ///
    /// ```swift
    /// struct MyView: View {
    ///     @Environment(\.surfaceStyle) var surfaceStyle
    ///
    ///     var body: some View {
    ///         VStack {
    ///             Text("Using \(surfaceStyle.description)")
    ///         }
    ///         .surfaceStyle(material: surfaceStyle)
    ///     }
    /// }
    /// ```
    ///
    /// ## Setting the Value
    ///
    /// ```swift
    /// struct ParentView: View {
    ///     var body: some View {
    ///         ChildView()
    ///             .environment(\.surfaceStyle, .thick)
    ///     }
    /// }
    /// ```
    ///
    /// ## Default Value
    ///
    /// If no surface style is specified, views use `.regular` by default,
    /// as defined by ``SurfaceStyleKey/defaultValue``.
    ///
    /// ## Platform Adaptation
    ///
    /// You can set platform-specific defaults using conditional compilation:
    ///
    /// ```swift
    /// #if os(macOS)
    /// view.environment(\.surfaceStyle, .thin)
    /// #else
    /// view.environment(\.surfaceStyle, .regular)
    /// #endif
    /// ```
    ///
    /// ## Accessibility
    ///
    /// The surface material automatically respects accessibility preferences:
    /// - Reduce Transparency: Falls back to solid colors
    /// - Increase Contrast: Enhances material vibrancy
    /// - Dark Mode: Adapts material appearance
    ///
    /// ## See Also
    /// - ``SurfaceStyleKey``: The environment key definition
    /// - ``SurfaceMaterial``: Available material types
    /// - ``View/surfaceStyle(material:allowFallback:)``: Modifier to apply materials
    public var surfaceStyle: SurfaceMaterial {
        get { self[SurfaceStyleKey.self] }
        set { self[SurfaceStyleKey.self] = newValue }
    }
}

// MARK: - SwiftUI Previews

#Preview("SurfaceStyleKey - Default Value") {
    /// Demonstrates the default surface style (.regular)
    struct DefaultView: View {
        @Environment(\.surfaceStyle) var surfaceStyle

        var body: some View {
            VStack(spacing: DS.Spacing.l) {
                Text("Default Surface Style")
                    .font(DS.Typography.headline)

                Text(surfaceStyle.description)
                    .font(DS.Typography.body)
                    .foregroundStyle(.secondary)

                Text("No explicit environment set")
                    .font(DS.Typography.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(DS.Spacing.xl)
            .surfaceStyle(material: surfaceStyle)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
        }
    }

    return DefaultView()
        .padding()
}

#Preview("SurfaceStyleKey - Custom Values") {
    /// Demonstrates setting custom surface styles via environment
    VStack(spacing: DS.Spacing.l) {
        ForEach([SurfaceMaterial.thin, .regular, .thick, .ultra], id: \.self) { material in
            MaterialCard(material: material)
        }
    }
    .padding()
}

#Preview("SurfaceStyleKey - Environment Propagation") {
    /// Demonstrates how surface styles propagate through view hierarchy
    struct ParentView: View {
        var body: some View {
            VStack(spacing: DS.Spacing.l) {
                Text("Parent (.thick)")
                    .font(DS.Typography.headline)

                // Child inherits .thick from parent
                ChildView(label: "Child (inherited)")

                // Child overrides to .thin
                ChildView(label: "Child (override to .thin)")
                    .environment(\.surfaceStyle, .thin)
            }
            .padding(DS.Spacing.xl)
            .surfaceStyle(material: .thick)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
            .environment(\.surfaceStyle, .thick)
        }
    }

    struct ChildView: View {
        let label: String
        @Environment(\.surfaceStyle) var surfaceStyle

        var body: some View {
            VStack(spacing: DS.Spacing.s) {
                Text(label)
                    .font(DS.Typography.body)
                Text(surfaceStyle.description)
                    .font(DS.Typography.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(DS.Spacing.m)
            .surfaceStyle(material: surfaceStyle)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium))
        }
    }

    return ParentView()
        .padding()
}

#Preview("SurfaceStyleKey - Inspector Pattern") {
    /// Demonstrates surface style in a typical inspector UI pattern
    HStack(spacing: 0) {
        // Main content area - regular surface
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text("Main Content")
                .font(DS.Typography.title)

            Text("Uses .regular surface")
                .font(DS.Typography.body)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .surfaceStyle(material: .regular)
        .environment(\.surfaceStyle, .regular)

        // Inspector panel - thick surface for visual separation
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text("Inspector")
                .font(DS.Typography.headline)

            Divider()

            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                Text("Surface Style")
                    .font(DS.Typography.caption)
                    .foregroundStyle(.secondary)
                Text(".thick material")
                    .font(DS.Typography.body)
            }

            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                Text("Purpose")
                    .font(DS.Typography.caption)
                    .foregroundStyle(.secondary)
                Text("Visual separation")
                    .font(DS.Typography.body)
            }

            Spacer()
        }
        .padding()
        .frame(width: 250, maxHeight: .infinity)
        .surfaceStyle(material: .thick)
        .environment(\.surfaceStyle, .thick)
    }
    .frame(height: 400)
}

#Preview("SurfaceStyleKey - Layered Modals") {
    /// Demonstrates surface style for layered UI elements
    struct LayeredView: View {
        @State private var showModal = true

        var body: some View {
            ZStack {
                // Background content - regular
                VStack {
                    Text("Background Content")
                        .font(DS.Typography.title)
                    Text("Regular surface")
                        .font(DS.Typography.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .surfaceStyle(material: .regular)
                .environment(\.surfaceStyle, .regular)

                // Modal overlay - ultra thick for prominence
                if showModal {
                    VStack(spacing: DS.Spacing.m) {
                        Text("Modal Dialog")
                            .font(DS.Typography.headline)

                        Text("Ultra thick surface")
                            .font(DS.Typography.caption)
                            .foregroundStyle(.secondary)

                        Text("Maximum visual separation")
                            .font(DS.Typography.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(DS.Spacing.xl)
                    .frame(width: 300)
                    .surfaceStyle(material: .ultra)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
                    .cardStyle(elevation: .high, useMaterial: false)
                    .environment(\.surfaceStyle, .ultra)
                }
            }
            .frame(height: 400)
        }
    }

    return LayeredView()
}

#Preview("SurfaceStyleKey - Dark Mode") {
    /// Demonstrates surface styles in dark mode
    VStack(spacing: DS.Spacing.l) {
        Text("Dark Mode Surface Styles")
            .font(DS.Typography.headline)

        ForEach([SurfaceMaterial.thin, .regular, .thick, .ultra], id: \.self) { material in
            MaterialCard(material: material)
        }
    }
    .padding()
    .preferredColorScheme(.dark)
}

// MARK: - Preview Helpers

/// Helper view for material card previews
private struct MaterialCard: View {
    let material: SurfaceMaterial
    @Environment(\.surfaceStyle) var surfaceStyle

    var body: some View {
        VStack(spacing: DS.Spacing.s) {
            Text(material.description)
                .font(DS.Typography.body)

            Text(material.accessibilityLabel)
                .font(DS.Typography.caption)
                .foregroundStyle(.secondary)
        }
        .padding(DS.Spacing.m)
        .frame(maxWidth: .infinity)
        .surfaceStyle(material: material)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
        .environment(\.surfaceStyle, material)
    }
}
