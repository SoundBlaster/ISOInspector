#if canImport(SwiftUI)
import SwiftUI
import ISOInspectorKit

struct ISOInspectorAppThemeModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .tint(ISOInspectorAppTheme.accentColor(for: colorScheme))
            .background(ISOInspectorAppTheme.surfaceBackground(for: colorScheme))
    }
}

enum ISOInspectorAppTheme {
    static let palette = ISOInspectorBrandPalette.production

    static func accentColor(for scheme: ColorScheme) -> Color {
        Color("AccentColor", bundle: .module)
    }

    static func surfaceBackground(for scheme: ColorScheme) -> Color {
        Color("SurfaceBackground", bundle: .module)
    }

    // @todo PDD:45m Generate production app icon raster assets from the brand vector source and populate AppIcon.appiconset filenames.
    // Ensure the automation runs during distribution packaging so notarized builds include real icon art.
}

extension View {
    func isoInspectorAppTheme() -> some View {
        modifier(ISOInspectorAppThemeModifier())
    }
}
#endif
