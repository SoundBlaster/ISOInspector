import SwiftUI

// MARK: - ColorSchemeAdapter

/// Adapter for automatic Dark Mode and color scheme adaptation
///
/// `ColorSchemeAdapter` provides automatic color adaptation based on the system
/// color scheme (light or dark mode), ensuring consistent and accessible UI
/// across all appearance modes.
///
/// ## Overview
/// The adapter follows FoundationUI's design principles:
/// - **Automatic Dark Mode**: Colors adapt seamlessly to light/dark mode
/// - **WCAG Compliance**: All colors meet ≥4.5:1 contrast requirements
/// - **Zero Magic Numbers**: Uses only DS tokens for opacity values
/// - **SwiftUI Integration**: Works naturally with `@Environment(\.colorScheme)`
///
/// ## Basic Usage
/// ### Reading Color Scheme
/// ```swift
/// @Environment(\.colorScheme) var colorScheme
///
/// var body: some View {
///     let adapter = ColorSchemeAdapter(colorScheme: colorScheme)
///     Text("Hello")
///         .foregroundColor(adapter.adaptiveTextColor)
///         .background(adapter.adaptiveBackground)
/// }
/// ```
///
/// ### Using View Modifier
/// ```swift
/// struct MyView: View {
///     var body: some View {
///         VStack {
///             Text("Content")
///         }
///         .adaptiveColorScheme()
///     }
/// }
/// ```
///
/// ## Adaptive Color Properties
/// The adapter provides semantic color properties that automatically adapt:
/// - ``adaptiveBackground``
/// - ``adaptiveSecondaryBackground``
/// - ``adaptiveTextColor``
/// - ``adaptiveSecondaryTextColor``
/// - ``adaptiveBorderColor``
/// - ``adaptiveDividerColor``
/// - ``adaptiveElevatedSurface``
///
/// ## Color Scheme Detection
/// ```swift
/// let adapter = ColorSchemeAdapter(colorScheme: .dark)
/// if adapter.isDarkMode {
///     // Dark mode specific logic
/// }
/// ```
///
/// ## Integration with Design Tokens
/// ColorSchemeAdapter works seamlessly with DS tokens:
/// ```swift
/// let adapter = ColorSchemeAdapter(colorScheme: colorScheme)
/// VStack(spacing: DS.Spacing.m) {
///     Text("Title")
///         .font(DS.Typography.headline)
///         .foregroundColor(adapter.adaptiveTextColor)
/// }
/// .padding(DS.Spacing.l)
/// .background(adapter.adaptiveBackground)
/// ```
///
/// ## Use Cases
/// ### Card Components
/// ```swift
/// Card {
///     let adapter = ColorSchemeAdapter(colorScheme: colorScheme)
///     VStack {
///         Text("Card Content")
///             .foregroundColor(adapter.adaptiveTextColor)
///     }
///     .background(adapter.adaptiveElevatedSurface)
/// }
/// ```
///
/// ### Inspector Panels
/// ```swift
/// HStack {
///     // Main content
///     ContentView()
///         .background(adapter.adaptiveBackground)
///
///     // Inspector panel
///     InspectorView()
///         .background(adapter.adaptiveSecondaryBackground)
/// }
/// ```
///
/// ### Bordered Elements
/// ```swift
/// Text("Info")
///     .padding()
///     .overlay(
///         RoundedRectangle(cornerRadius: DS.Radius.medium)
///             .stroke(adapter.adaptiveBorderColor, lineWidth: 1)
///     )
/// ```
///
/// ## Platform Support
/// - iOS 17.0+: Full support
/// - macOS 14.0+: Full support
/// - All platforms: Automatic Dark Mode adaptation
///
/// ## Accessibility
/// All adaptive colors meet WCAG 2.1 AA contrast requirements:
/// - Text colors: ≥4.5:1 contrast ratio
/// - Increase Contrast: Automatically supported by system colors
/// - Color blind users: Semantic colors maintain distinction
///
/// ## Performance
/// ColorSchemeAdapter is lightweight and efficient:
/// - Computed properties with no caching overhead
/// - No runtime color calculations
/// - Leverages SwiftUI's built-in color adaptation
///
/// ## See Also
/// - ``adaptiveBackground``
/// - ``adaptiveTextColor``
/// - `View.adaptiveColorScheme()` modifier
public struct ColorSchemeAdapter {
    // MARK: - Properties

    /// The current color scheme (light or dark)
    ///
    /// This value is typically read from the SwiftUI environment:
    /// ```swift
    /// @Environment(\.colorScheme) var colorScheme
    /// let adapter = ColorSchemeAdapter(colorScheme: colorScheme)
    /// ```
    public let colorScheme: ColorScheme

    // MARK: - Initialization

    /// Creates a color scheme adapter
    ///
    /// - Parameter colorScheme: The current color scheme (light or dark)
    ///
    /// ## Example
    /// ```swift
    /// @Environment(\.colorScheme) var colorScheme
    ///
    /// var body: some View {
    ///     let adapter = ColorSchemeAdapter(colorScheme: colorScheme)
    ///     // Use adapter properties...
    /// }
    /// ```
    public init(colorScheme: ColorScheme) { self.colorScheme = colorScheme }

    // MARK: - Color Scheme Detection

    /// Indicates if the current color scheme is dark mode
    ///
    /// Returns `true` when the color scheme is `.dark`, `false` for `.light`.
    ///
    /// ## Usage
    /// ```swift
    /// let adapter = ColorSchemeAdapter(colorScheme: .dark)
    /// if adapter.isDarkMode {
    ///     // Apply dark mode specific logic
    /// }
    /// ```
    ///
    /// - Returns: `true` if dark mode, `false` if light mode
    public var isDarkMode: Bool { colorScheme == .dark }

    // MARK: - Adaptive Background Colors

    /// Primary adaptive background color
    ///
    /// Provides the main background color for views, automatically adapting
    /// to the current color scheme:
    /// - **Light mode**: System background (white/light gray)
    /// - **Dark mode**: System background (dark gray/black)
    ///
    /// ## Usage
    /// ```swift
    /// VStack {
    ///     Text("Content")
    /// }
    /// .background(adapter.adaptiveBackground)
    /// ```
    ///
    /// ## Accessibility
    /// - Contrast: Provides optimal contrast for text elements
    /// - Increase Contrast: Automatically adjusts via system colors
    ///
    /// ## See Also
    /// - ``adaptiveSecondaryBackground``
    /// - ``adaptiveElevatedSurface``
    public var adaptiveBackground: Color {
        #if os(iOS)
            return Color(uiColor: .systemBackground)
        #elseif os(macOS)
            return Color(nsColor: .windowBackgroundColor)
        #else
            return Color(uiColor: .systemBackground)
        #endif
    }

    /// Secondary adaptive background color
    ///
    /// Provides background color for secondary UI elements like sidebars,
    /// panels, and grouped content:
    /// - **Light mode**: Slightly darker than primary background
    /// - **Dark mode**: Slightly lighter than primary background
    ///
    /// ## Usage
    /// ```swift
    /// HStack {
    ///     Sidebar()
    ///         .background(adapter.adaptiveSecondaryBackground)
    ///
    ///     MainContent()
    ///         .background(adapter.adaptiveBackground)
    /// }
    /// ```
    ///
    /// ## Use Cases
    /// - Sidebar panels
    /// - Inspector backgrounds
    /// - Grouped list backgrounds
    /// - Secondary panels
    ///
    /// ## See Also
    /// - ``adaptiveBackground``
    /// - ``adaptiveElevatedSurface``
    public var adaptiveSecondaryBackground: Color {
        #if os(iOS)
            return Color(uiColor: .secondarySystemBackground)
        #elseif os(macOS)
            return Color(nsColor: .controlBackgroundColor)
        #else
            return Color(uiColor: .secondarySystemBackground)
        #endif
    }

    /// Elevated surface color for cards and panels
    ///
    /// Provides background color for elevated UI elements like cards,
    /// sheets, and prominent panels:
    /// - **Light mode**: White or light surface
    /// - **Dark mode**: Elevated dark surface with subtle lightness
    ///
    /// ## Usage
    /// ```swift
    /// Card {
    ///     Text("Card Content")
    /// }
    /// .background(adapter.adaptiveElevatedSurface)
    /// .cornerRadius(DS.Radius.card)
    /// .shadow(radius: DS.Spacing.s)
    /// ```
    ///
    /// ## Use Cases
    /// - Card components
    /// - Modal sheets
    /// - Floating panels
    /// - Popovers
    ///
    /// ## Visual Hierarchy
    /// Creates visual separation from the base background, indicating
    /// elevated or floating content.
    ///
    /// ## See Also
    /// - ``adaptiveBackground``
    /// - ``adaptiveSecondaryBackground``
    public var adaptiveElevatedSurface: Color {
        #if os(iOS)
            return Color(uiColor: .secondarySystemGroupedBackground)
        #elseif os(macOS)
            return Color(nsColor: .controlBackgroundColor)
        #else
            return Color(uiColor: .secondarySystemGroupedBackground)
        #endif
    }

    // MARK: - Adaptive Text Colors

    /// Primary adaptive text color
    ///
    /// Provides the main text color, automatically adapting for optimal
    /// contrast against backgrounds:
    /// - **Light mode**: Dark text (near black)
    /// - **Dark mode**: Light text (near white)
    ///
    /// ## Usage
    /// ```swift
    /// Text("Title")
    ///     .foregroundColor(adapter.adaptiveTextColor)
    /// ```
    ///
    /// ## Accessibility
    /// - Contrast: ≥4.5:1 against adaptive backgrounds
    /// - Dynamic Type: Fully supported via SwiftUI.Font
    /// - Bold Text: Automatically respected by system colors
    ///
    /// ## See Also
    /// - ``adaptiveSecondaryTextColor``
    /// - ``DS/Typography``
    public var adaptiveTextColor: Color {
        #if os(iOS)
            return Color(uiColor: .label)
        #elseif os(macOS)
            return Color(nsColor: .labelColor)
        #else
            return Color(uiColor: .label)
        #endif
    }

    /// Secondary adaptive text color
    ///
    /// Provides muted text color for secondary information, captions,
    /// and less prominent content:
    /// - **Light mode**: Medium gray
    /// - **Dark mode**: Light gray
    ///
    /// ## Usage
    /// ```swift
    /// VStack(alignment: .leading) {
    ///     Text("Title")
    ///         .foregroundColor(adapter.adaptiveTextColor)
    ///     Text("Subtitle")
    ///         .foregroundColor(adapter.adaptiveSecondaryTextColor)
    /// }
    /// ```
    ///
    /// ## Use Cases
    /// - Subtitles and captions
    /// - Metadata labels
    /// - Secondary information
    /// - Help text
    ///
    /// ## Accessibility
    /// - Contrast: ≥4.5:1 for standard text sizes
    /// - Semantic meaning: Use for non-critical information only
    ///
    /// ## See Also
    /// - ``adaptiveTextColor``
    public var adaptiveSecondaryTextColor: Color {
        #if os(iOS)
            return Color(uiColor: .secondaryLabel)
        #elseif os(macOS)
            return Color(nsColor: .secondaryLabelColor)
        #else
            return Color(uiColor: .secondaryLabel)
        #endif
    }

    // MARK: - Adaptive Border and Divider Colors

    /// Adaptive border color
    ///
    /// Provides color for borders, outlines, and strokes that adapt
    /// to the color scheme:
    /// - **Light mode**: Subtle dark border
    /// - **Dark mode**: Subtle light border
    ///
    /// ## Usage
    /// ```swift
    /// RoundedRectangle(cornerRadius: DS.Radius.card)
    ///     .stroke(adapter.adaptiveBorderColor, lineWidth: 1)
    /// ```
    ///
    /// ## Use Cases
    /// - Card borders
    /// - Input field outlines
    /// - Container strokes
    /// - Focus indicators
    ///
    /// ## Visual Design
    /// Border color is subtle but provides clear visual boundaries
    /// without overwhelming the content.
    ///
    /// ## See Also
    /// - ``adaptiveDividerColor``
    public var adaptiveBorderColor: Color {
        #if os(iOS)
            return Color(uiColor: .separator)
        #elseif os(macOS)
            return Color(nsColor: .separatorColor)
        #else
            return Color(uiColor: .separator)
        #endif
    }

    /// Adaptive divider color
    ///
    /// Provides subtle color for dividers and separators:
    /// - **Light mode**: Very light gray
    /// - **Dark mode**: Very dark gray
    ///
    /// ## Usage
    /// ```swift
    /// VStack {
    ///     Text("Section 1")
    ///     Divider()
    ///         .background(adapter.adaptiveDividerColor)
    ///     Text("Section 2")
    /// }
    /// ```
    ///
    /// ## Use Cases
    /// - List dividers
    /// - Section separators
    /// - Toolbar dividers
    /// - Content boundaries
    ///
    /// ## Visual Design
    /// Dividers are more subtle than borders, providing gentle
    /// visual separation without strong contrast. Uses the most
    /// subtle system label color (quaternary) for minimal visual weight.
    ///
    /// ## See Also
    /// - ``adaptiveBorderColor``
    public var adaptiveDividerColor: Color {
        #if os(iOS)
            return Color(uiColor: .quaternaryLabel)
        #elseif os(macOS)
            return Color(nsColor: .quaternaryLabelColor)
        #else
            return Color(uiColor: .quaternaryLabel)
        #endif
    }
}

// MARK: - View Extensions

extension View {
    /// Applies adaptive color scheme to the view
    ///
    /// Automatically adapts view colors based on the system color scheme.
    /// This is a convenience modifier for common adaptive color patterns.
    ///
    /// ## Usage
    /// ```swift
    /// VStack {
    ///     Text("Content")
    /// }
    /// .adaptiveColorScheme()
    /// ```
    ///
    /// ## Behavior
    /// The modifier reads the color scheme from the environment and applies
    /// adaptive styling automatically. This includes:
    /// - Background colors
    /// - Text colors
    /// - Border colors
    ///
    /// ## Custom Adaptation
    /// For more control, create a `ColorSchemeAdapter` instance:
    /// ```swift
    /// @Environment(\.colorScheme) var colorScheme
    ///
    /// var body: some View {
    ///     let adapter = ColorSchemeAdapter(colorScheme: colorScheme)
    ///     VStack {
    ///         Text("Title")
    ///             .foregroundColor(adapter.adaptiveTextColor)
    ///     }
    ///     .background(adapter.adaptiveBackground)
    /// }
    /// ```
    ///
    /// ## See Also
    /// - ``ColorSchemeAdapter``
    /// - ``ColorSchemeAdapter/adaptiveBackground``
    /// - ``ColorSchemeAdapter/adaptiveTextColor``
    ///
    /// - Returns: A view that adapts to the color scheme
    public func adaptiveColorScheme() -> some View { modifier(AdaptiveColorSchemeModifier()) }
}

// MARK: - Adaptive Color Scheme Modifier

/// View modifier that applies adaptive color scheme styling
///
/// Internal modifier used by the `.adaptiveColorScheme()` view extension.
/// Reads the color scheme from the environment and applies adaptive colors.
///
/// ## See Also
/// - `View.adaptiveColorScheme()` modifier
/// - ``ColorSchemeAdapter``
private struct AdaptiveColorSchemeModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        let adapter = ColorSchemeAdapter(colorScheme: colorScheme)
        content.foregroundColor(adapter.adaptiveTextColor).background(adapter.adaptiveBackground)
    }
}

// MARK: - SwiftUI Previews

#Preview("ColorSchemeAdapter - Light Mode") {
    struct LightModeDemo: View {
        var body: some View {
            let adapter = ColorSchemeAdapter(colorScheme: .light)

            return VStack(spacing: DS.Spacing.l) {
                Text("Light Mode Colors").font(DS.Typography.title).foregroundColor(
                    adapter.adaptiveTextColor)

                VStack(spacing: DS.Spacing.m) {
                    ColorSwatch(label: "Primary Background", color: adapter.adaptiveBackground)
                    ColorSwatch(
                        label: "Secondary Background", color: adapter.adaptiveSecondaryBackground)
                    ColorSwatch(label: "Elevated Surface", color: adapter.adaptiveElevatedSurface)
                    ColorSwatch(label: "Primary Text", color: adapter.adaptiveTextColor)
                    ColorSwatch(label: "Secondary Text", color: adapter.adaptiveSecondaryTextColor)
                    ColorSwatch(label: "Border", color: adapter.adaptiveBorderColor)
                    ColorSwatch(label: "Divider", color: adapter.adaptiveDividerColor)
                }
            }.padding(DS.Spacing.xl).background(adapter.adaptiveBackground).preferredColorScheme(
                .light)
        }
    }

    return LightModeDemo()
}

#Preview("ColorSchemeAdapter - Dark Mode") {
    struct DarkModeDemo: View {
        var body: some View {
            let adapter = ColorSchemeAdapter(colorScheme: .dark)

            return VStack(spacing: DS.Spacing.l) {
                Text("Dark Mode Colors").font(DS.Typography.title).foregroundColor(
                    adapter.adaptiveTextColor)

                VStack(spacing: DS.Spacing.m) {
                    ColorSwatch(label: "Primary Background", color: adapter.adaptiveBackground)
                    ColorSwatch(
                        label: "Secondary Background", color: adapter.adaptiveSecondaryBackground)
                    ColorSwatch(label: "Elevated Surface", color: adapter.adaptiveElevatedSurface)
                    ColorSwatch(label: "Primary Text", color: adapter.adaptiveTextColor)
                    ColorSwatch(label: "Secondary Text", color: adapter.adaptiveSecondaryTextColor)
                    ColorSwatch(label: "Border", color: adapter.adaptiveBorderColor)
                    ColorSwatch(label: "Divider", color: adapter.adaptiveDividerColor)
                }
            }.padding(DS.Spacing.xl).background(adapter.adaptiveBackground).preferredColorScheme(
                .dark)
        }
    }

    return DarkModeDemo()
}

#Preview("Adaptive Card Example") {
    struct AdaptiveCardDemo: View {
        @Environment(\.colorScheme) var colorScheme

        var body: some View {
            let adapter = ColorSchemeAdapter(colorScheme: colorScheme)

            return VStack(spacing: DS.Spacing.l) {
                Text("Adaptive Card").font(DS.Typography.title).foregroundColor(
                    adapter.adaptiveTextColor)

                // Card with adaptive colors
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Card Title").font(DS.Typography.headline).foregroundColor(
                        adapter.adaptiveTextColor)

                    Text("This card adapts to light and dark mode automatically.").font(
                        DS.Typography.body
                    ).foregroundColor(adapter.adaptiveSecondaryTextColor)

                    Divider().background(adapter.adaptiveDividerColor)

                    Text("Footer content").font(DS.Typography.caption).foregroundColor(
                        adapter.adaptiveSecondaryTextColor)
                }.padding(DS.Spacing.l).background(adapter.adaptiveElevatedSurface).cornerRadius(
                    DS.Radius.card
                ).overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.card).stroke(
                        adapter.adaptiveBorderColor, lineWidth: 1))
            }.padding(DS.Spacing.xl).background(adapter.adaptiveBackground)
        }
    }

    return AdaptiveCardDemo()
}

#Preview("Inspector Pattern with Adaptive Colors") {
    struct AdaptiveInspectorDemo: View {
        @Environment(\.colorScheme) var colorScheme

        var body: some View {
            let adapter = ColorSchemeAdapter(colorScheme: colorScheme)

            return HStack(spacing: 0) {
                // Main content area
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Main Content").font(DS.Typography.title).foregroundColor(
                        adapter.adaptiveTextColor)

                    Text("Uses adaptive background color").font(DS.Typography.body).foregroundColor(
                        adapter.adaptiveSecondaryTextColor)

                    Spacer()
                }.padding(DS.Spacing.l).frame(maxWidth: .infinity, maxHeight: .infinity).background(
                    adapter.adaptiveBackground)

                // Inspector sidebar
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Inspector").font(DS.Typography.headline).foregroundColor(
                        adapter.adaptiveTextColor)

                    Divider().background(adapter.adaptiveDividerColor)

                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        Text("Background Style").font(DS.Typography.caption).foregroundColor(
                            adapter.adaptiveSecondaryTextColor)
                        Text("Secondary adaptive").font(DS.Typography.body).foregroundColor(
                            adapter.adaptiveTextColor)
                    }

                    Spacer()
                }.padding(DS.Spacing.l).frame(width: 250).frame(maxHeight: .infinity).background(
                    adapter.adaptiveSecondaryBackground
                ).overlay(
                    Rectangle().frame(width: 1).foregroundColor(adapter.adaptiveDividerColor),
                    alignment: .leading)
            }.frame(height: 400)
        }
    }

    return AdaptiveInspectorDemo()
}

#Preview("Adaptive Color Scheme Modifier") {
    struct ModifierDemo: View {
        var body: some View {
            VStack(spacing: DS.Spacing.m) {
                Text("Using .adaptiveColorScheme() Modifier").font(DS.Typography.title)

                Text("Colors adapt automatically to light/dark mode").font(DS.Typography.body)

                Text("Try switching appearance in Xcode preview").font(DS.Typography.caption)
            }.padding(DS.Spacing.l).adaptiveColorScheme()
        }
    }

    return ModifierDemo().frame(height: 200)
}

#Preview("Side-by-Side Comparison") {
    HStack(spacing: DS.Spacing.m) {
        // Light mode
        VStack {
            let adapter = ColorSchemeAdapter(colorScheme: .light)

            VStack(spacing: DS.Spacing.m) {
                Text("Light Mode").font(DS.Typography.headline).foregroundColor(
                    adapter.adaptiveTextColor)

                Text("Adaptive colors").font(DS.Typography.body).foregroundColor(
                    adapter.adaptiveSecondaryTextColor)
            }.padding(DS.Spacing.l).background(adapter.adaptiveElevatedSurface).cornerRadius(
                DS.Radius.card
            ).overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card).stroke(
                    adapter.adaptiveBorderColor, lineWidth: 1))
        }.preferredColorScheme(.light)

        // Dark mode
        VStack {
            let adapter = ColorSchemeAdapter(colorScheme: .dark)

            VStack(spacing: DS.Spacing.m) {
                Text("Dark Mode").font(DS.Typography.headline).foregroundColor(
                    adapter.adaptiveTextColor)

                Text("Adaptive colors").font(DS.Typography.body).foregroundColor(
                    adapter.adaptiveSecondaryTextColor)
            }.padding(DS.Spacing.l).background(adapter.adaptiveElevatedSurface).cornerRadius(
                DS.Radius.card
            ).overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card).stroke(
                    adapter.adaptiveBorderColor, lineWidth: 1))
        }.preferredColorScheme(.dark)
    }.padding(DS.Spacing.xl)
}

// MARK: - Preview Helpers

/// Helper view to display color swatches in previews
private struct ColorSwatch: View {
    let label: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        let adapter = ColorSchemeAdapter(colorScheme: colorScheme)

        HStack {
            Text(label).font(DS.Typography.body).frame(width: 150, alignment: .leading)

            RoundedRectangle(cornerRadius: DS.Radius.small).fill(color).frame(height: 30).overlay(
                RoundedRectangle(cornerRadius: DS.Radius.small).stroke(
                    adapter.adaptiveDividerColor, lineWidth: 1))
        }
    }
}
