#if canImport(SwiftUI)
    import SwiftUI
    import ISOInspectorKit

    struct ISOInspectorAppThemeModifier: ViewModifier {
        @Environment(\.colorScheme) private var colorScheme

        func body(content: Content) -> some View {
            content.tint(ISOInspectorAppTheme.accentColor(for: colorScheme)).background(
                ISOInspectorAppTheme.surfaceBackground(for: colorScheme))
        }
    }

    enum ISOInspectorAppTheme {
        static let palette = ISOInspectorBrandPalette.production

        static func accentColor(for scheme: ColorScheme) -> Color {
            let brandColor = scheme == .light ? palette.lightModeAccent : palette.darkModeAccent
            return Color(red: brandColor.red, green: brandColor.green, blue: brandColor.blue)
        }

        static func surfaceBackground(for scheme: ColorScheme) -> Color {
            let brandColor = scheme == .light ? palette.lightBackground : palette.darkBackground
            return Color(red: brandColor.red, green: brandColor.green, blue: brandColor.blue)
        }

    }

    extension View {
        func isoInspectorAppTheme() -> some View { modifier(ISOInspectorAppThemeModifier()) }
    }
#endif
