#if canImport(SwiftUI)
import SwiftUI

/// Environment key that stores the preferred `Material` for a view hierarchy.
///
/// Use this key to propagate a surface style from a parent container to all of
/// its descendants. Views can read the material with
/// `@Environment(\.surfaceStyle)` and apply it to their backgrounds or other
/// decorations that accept a `ShapeStyle`.
///
/// ```swift
/// struct InspectorPane: View {
///     @Environment(\.surfaceStyle) private var surfaceStyle
///
///     var body: some View {
///         VStack(alignment: .leading) {
///             Text("Inspector")
///                 .font(.headline)
///             Text("Material driven background")
///                 .font(.subheadline)
///                 .foregroundStyle(.secondary)
///         }
///         .padding()
///         .background(surfaceStyle)
///         .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
///     }
/// }
///
/// InspectorPane()
///     .surfaceStyle(.thick)
/// ```
public struct SurfaceStyleKey: EnvironmentKey {
    /// Default material applied when no explicit preference is provided.
    ///
    /// `.regular` offers a balanced translucency that works across iOS and
    /// macOS appearances, making it a safe default for inspector-style
    /// layouts.
    public static let defaultValue: Material = .regular
}

public extension EnvironmentValues {
    /// The surface material inherited from the surrounding environment.
    var surfaceStyle: Material {
        get { self[SurfaceStyleKey.self] }
        set { self[SurfaceStyleKey.self] = newValue }
    }
}

public extension View {
    /// Assigns a surface material to the current view hierarchy.
    ///
    /// The modifier writes the value to SwiftUI's environment so that any
    /// descendant view can read it via `@Environment(\.surfaceStyle)`.
    ///
    /// - Parameter material: The `Material` to propagate to child views.
    /// - Returns: A view that publishes the provided material to its
    ///   descendants.
    func surfaceStyle(_ material: Material) -> some View {
        environment(\.surfaceStyle, material)
    }
}

#if DEBUG
extension SurfaceStyleKey {
    fileprivate enum PreviewMetrics {
        static let cardPadding: CGFloat = 16
        static let cardCornerRadius: CGFloat = 16
        static let columnSpacing: CGFloat = 12
        static let groupSpacing: CGFloat = 16
    }

    /// A preview card that visualises the inherited material.
    fileprivate struct PreviewCard: View {
        @Environment(\.surfaceStyle) private var inheritedStyle
        let title: String

        var body: some View {
            VStack(spacing: PreviewMetrics.columnSpacing) {
                Text(title)
                    .font(.headline)
                Text(String(describing: inheritedStyle))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(PreviewMetrics.cardPadding)
            .frame(maxWidth: .infinity)
            .background(inheritedStyle)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: PreviewMetrics.cardCornerRadius,
                    style: .continuous
                )
            )
        }
    }

    /// Displays a column of material samples for quick comparison.
    fileprivate struct PalettePreview: View {
        private let materials: [(title: String, material: Material)] = [
            ("Thin", .thin),
            ("Regular", .regular),
            ("Thick", .thick),
            ("Ultra Thin", .ultraThin),
            ("Ultra Thick", .ultraThick)
        ]

        var body: some View {
            VStack(alignment: .leading, spacing: PreviewMetrics.groupSpacing) {
                Text("Surface Style Palette")
                    .font(.title3)
                ForEach(materials, id: \.title) { sample in
                    PreviewCard(title: sample.title)
                        .surfaceStyle(sample.material)
                }
            }
            .padding()
        }
    }

    /// Demonstrates how environment propagation works between parent and child views.
    fileprivate struct PropagationPreview: View {
        var body: some View {
            VStack(spacing: PreviewMetrics.groupSpacing) {
                Text("Environment Propagation")
                    .font(.title3)

                VStack(spacing: PreviewMetrics.groupSpacing) {
                    PreviewCard(title: "Parent (.thick)")
                        .surfaceStyle(.thick)

                    VStack(spacing: PreviewMetrics.columnSpacing) {
                        PreviewCard(title: "Child Inherits (.thick)")
                        PreviewCard(title: "Child Override (.thin)")
                            .surfaceStyle(.thin)
                    }
                }
                .padding(PreviewMetrics.cardPadding)
                .surfaceStyle(.thick)
                .background(.regular)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: PreviewMetrics.cardCornerRadius,
                        style: .continuous
                    )
                )
            }
            .padding()
        }
    }

    /// Highlights the default `.regular` material with explanatory text.
    fileprivate struct DefaultPreview: View {
        var body: some View {
            PreviewCard(title: "Default (.regular)")
                .surfaceStyle(.regular)
                .padding()
        }
    }
}

#Preview("Default Material") {
    SurfaceStyleKey.DefaultPreview()
}

#Preview("Palette") {
    SurfaceStyleKey.PalettePreview()
}

#Preview("Propagation") {
    SurfaceStyleKey.PropagationPreview()
}
#endif

#endif
