import SwiftUI

/// A flexible card component with configurable elevation, corner radius, and material backgrounds
///
/// The Card component provides a reusable container that wraps any SwiftUI content
/// with visual depth through elevation (shadows) and configurable corner radius.
/// It uses the CardStyle modifier internally to ensure consistent styling across
/// the application.
///
/// ## Design System Integration
/// Card uses the following Design System tokens:
/// - **Radius**: `DS.Radius.card` (default), `DS.Radius.small`, `DS.Radius.medium`
/// - **Elevation**: CardElevation enum (none, low, medium, high) for shadow depth
/// - **Materials**: Optional SwiftUI Material backgrounds (.thin, .regular, .thick)
///
/// ## Usage
/// ```swift
/// // Simple card with default settings
/// Card {
///     Text("Hello, World!")
///         .padding()
/// }
///
/// // Card with custom elevation
/// Card(elevation: .high) {
///     VStack {
///         Text("Title")
///             .font(.headline)
///         Text("Content")
///             .font(.body)
///     }
///     .padding()
/// }
///
/// // Card with material background
/// Card(material: .thin) {
///     Text("Translucent Card")
///         .padding()
/// }
///
/// // Card with custom corner radius
/// Card(cornerRadius: DS.Radius.small) {
///     Text("Sharp Corners")
///         .padding()
/// }
///
/// // Nested cards
/// Card(elevation: .high) {
///     VStack {
///         Text("Outer Card")
///         Card(elevation: .low) {
///             Text("Inner Card")
///                 .padding()
///         }
///     }
///     .padding()
/// }
/// ```
///
/// ## Accessibility
/// - Maintains semantic structure for assistive technologies
/// - Content accessibility is preserved (VoiceOver, Dynamic Type)
/// - Shadow effects are supplementary, not required for comprehension
/// - Supports all Dynamic Type sizes
///
/// ## Platform Support
/// - iOS 16.0+
/// - iPadOS 16.0+
/// - macOS 14.0+
///
/// ## See Also
/// - ``CardElevation``: Semantic elevation level enumeration
/// - ``CardStyle``: View modifier for card styling
/// - ``DS/Radius``: Design System radius tokens
public struct Card<Content: View>: View {
    // MARK: - Properties

    /// The elevation level determining shadow depth
    public let elevation: CardElevation

    /// The corner radius for the card shape
    public let cornerRadius: CGFloat

    /// Optional material background for translucency effects
    public let material: Material?

    /// The content displayed inside the card
    private let content: Content

    // MARK: - Initialization

    /// Creates a new Card component with configurable styling
    ///
    /// ## Example
    /// ```swift
    /// Card(elevation: .medium, cornerRadius: DS.Radius.card) {
    ///     VStack {
    ///         Text("Title")
    ///         Text("Content")
    ///     }
    ///     .padding()
    /// }
    /// ```
    ///
    /// ## Parameters
    /// - elevation: Visual depth level (none, low, medium, high). Default: `.medium`
    /// - cornerRadius: Corner rounding using DS.Radius tokens. Default: `DS.Radius.card`
    /// - material: Optional material background for translucency. Default: `nil`
    /// - content: The SwiftUI view content to display inside the card
    ///
    /// ## Design Tokens Used
    /// - `DS.Radius.card`: Standard card corner radius (10pt) - Default
    /// - `DS.Radius.small`: Subtle corner radius (6pt)
    /// - `DS.Radius.medium`: Balanced corner radius (8pt)
    ///
    /// ## Platform Adaptation
    /// - macOS: Stronger shadows for desktop UI aesthetics
    /// - iOS/iPadOS: Lighter shadows optimized for touch interfaces
    /// - Material backgrounds adapt automatically to light/dark mode
    ///
    /// ## Accessibility
    /// - Maintains semantic structure from content
    /// - Shadow is purely visual, not semantic
    /// - Supports Dynamic Type scaling
    /// - Content accessibility labels are preserved
    public init(
        elevation: CardElevation = .medium,
        cornerRadius: CGFloat = DS.Radius.card,
        material: Material? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.elevation = elevation
        self.cornerRadius = cornerRadius
        self.material = material
        self.content = content()
    }

    // MARK: - Body

    public var body: some View {
        Group {
            if let material = material {
                // Card with material background
                content
                    .background(material)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .shadow(
                        color: elevation.hasShadow ? Color.black.opacity(elevation.shadowOpacity) : .clear,
                        radius: elevation.shadowRadius,
                        x: 0,
                        y: elevation.shadowYOffset
                    )
            } else {
                // Card with CardStyle modifier (includes background)
                content
                    .cardStyle(
                        elevation: elevation,
                        cornerRadius: cornerRadius,
                        useMaterial: false
                    )
            }
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - SwiftUI Previews

#Preview("Card - Elevation Levels") {
    ScrollView {
        VStack(spacing: DS.Spacing.xl) {
            Card(elevation: .none) {
                VStack {
                    Text("No Elevation")
                        .font(.headline)
                    Text("Flat appearance with no shadow")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }

            Card(elevation: .low) {
                VStack {
                    Text("Low Elevation")
                        .font(.headline)
                    Text("Subtle shadow for slight depth")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }

            Card(elevation: .medium) {
                VStack {
                    Text("Medium Elevation")
                        .font(.headline)
                    Text("Standard shadow for typical cards")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }

            Card(elevation: .high) {
                VStack {
                    Text("High Elevation")
                        .font(.headline)
                    Text("Prominent shadow for emphasized content")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
        }
        .padding()
    }
}

#Preview("Card - Corner Radius Variants") {
    VStack(spacing: DS.Spacing.l) {
        Card(cornerRadius: DS.Radius.small) {
            VStack {
                Text("Small Radius")
                    .font(.headline)
                Text("6pt corners - compact elements")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }

        Card(cornerRadius: DS.Radius.medium) {
            VStack {
                Text("Medium Radius")
                    .font(.headline)
                Text("8pt corners - balanced rounding")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }

        Card(cornerRadius: DS.Radius.card) {
            VStack {
                Text("Card Radius (Default)")
                    .font(.headline)
                Text("10pt corners - standard cards")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
    .padding()
}

#Preview("Card - Material Backgrounds") {
    ZStack {
        // Background gradient to show translucency
        LinearGradient(
            colors: [.blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: DS.Spacing.l) {
            Card(material: .ultraThin) {
                VStack {
                    Text("Ultra Thin Material")
                        .font(.headline)
                    Text("Maximum translucency")
                        .font(.caption)
                }
                .padding()
            }

            Card(material: .thin) {
                VStack {
                    Text("Thin Material")
                        .font(.headline)
                    Text("High translucency")
                        .font(.caption)
                }
                .padding()
            }

            Card(material: .regular) {
                VStack {
                    Text("Regular Material")
                        .font(.headline)
                    Text("Balanced translucency")
                        .font(.caption)
                }
                .padding()
            }

            Card(material: .thick) {
                VStack {
                    Text("Thick Material")
                        .font(.headline)
                    Text("Low translucency")
                        .font(.caption)
                }
                .padding()
            }
        }
        .padding()
    }
}

#Preview("Card - Dark Mode") {
    VStack(spacing: DS.Spacing.l) {
        Card(elevation: .low) {
            VStack {
                Text("Low Elevation")
                    .font(.headline)
                Text("Dark mode shadow rendering")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }

        Card(elevation: .medium) {
            VStack {
                Text("Medium Elevation")
                    .font(.headline)
                Text("Standard dark mode appearance")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }

        Card(elevation: .high) {
            VStack {
                Text("High Elevation")
                    .font(.headline)
                Text("Prominent dark mode depth")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
    .padding()
    .preferredColorScheme(.dark)
}

#Preview("Card - Content Examples") {
    ScrollView {
        VStack(spacing: DS.Spacing.l) {
            // Simple text card
            Card {
                Text("Simple Card")
                    .font(.headline)
                    .padding()
            }

            // Card with complex content
            Card(elevation: .medium) {
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
            }

            // Card with image
            Card(elevation: .low) {
                VStack(spacing: DS.Spacing.m) {
                    Image(systemName: "photo.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.blue)
                    Text("Image Card")
                        .font(.headline)
                    Text("Cards can contain any SwiftUI content")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }

            // Card with badge integration
            Card(elevation: .medium) {
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    HStack {
                        Text("Status Card")
                            .font(.headline)
                        Spacer()
                        Text("ACTIVE")
                            .badgeChipStyle(level: .success)
                    }
                    Text("Integration with other FoundationUI components")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
        }
        .padding()
    }
}

#Preview("Card - Nested Cards") {
    Card(elevation: .high) {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text("Outer Card")
                .font(.title2)
                .fontWeight(.bold)

            Text("Cards can be nested for hierarchical layouts")
                .font(.body)
                .foregroundStyle(.secondary)

            Card(elevation: .low) {
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text("Inner Card")
                        .font(.headline)
                    Text("This card is nested inside another card")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }

            Card(elevation: .low) {
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text("Another Inner Card")
                        .font(.headline)
                    Text("Multiple cards can be nested")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
        }
        .padding()
    }
    .padding()
}

#Preview("Card - Platform Comparison") {
    VStack(spacing: DS.Spacing.l) {
        Card(elevation: .medium) {
            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                #if os(macOS)
                Text("macOS Card")
                    .font(.headline)
                Text("Desktop-optimized shadows and spacing")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                #elseif os(iOS)
                Text("iOS Card")
                    .font(.headline)
                Text("Touch-optimized shadows and spacing")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                #else
                Text("Platform Card")
                    .font(.headline)
                Text("Platform-adaptive styling")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                #endif
            }
            .padding()
        }

        Card(elevation: .high, material: .regular) {
            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                Text("Material + Elevation")
                    .font(.headline)
                Text("Combining material backgrounds with elevation")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
    .padding()
}

// MARK: - AgentDescribable Conformance

@available(iOS 17.0, macOS 14.0, *)
@MainActor
extension Card: AgentDescribable {
    public var componentType: String {
        "Card"
    }

    public var properties: [String: Any] {
        var props: [String: Any] = [
            "elevation": elevation.stringValue,
            "cornerRadius": cornerRadius
        ]

        if let material = material {
            props["material"] = String(describing: material)
        }

        return props
    }

    public var semantics: String {
        let materialDesc = material != nil ? "with material background" : "with solid background"
        return """
        A container component with '\(elevation.stringValue)' elevation \(materialDesc). \
        Corner radius: \(cornerRadius)pt. \
        Provides visual hierarchy and content grouping.
        """
    }
}

@available(iOS 17.0, macOS 14.0, *)
#Preview("Card - Agent Integration") {
    VStack(alignment: .leading, spacing: DS.Spacing.l) {
        Text("AgentDescribable Protocol Demo")
            .font(.headline)

        let card = Card(elevation: .high, cornerRadius: DS.Radius.card, material: .regular) {
            Text("Card Content")
                .padding()
        }
        card

        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            Text("Component Type: \(card.componentType)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Elevation: \(card.properties["elevation"] as? String ?? "unknown")")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Corner Radius: \(card.properties["cornerRadius"] as? CGFloat ?? 0)pt")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Semantics: \(card.semantics)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(DS.Radius.small)
    }
    .padding()
}
