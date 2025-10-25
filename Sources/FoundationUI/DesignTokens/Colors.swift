#if canImport(SwiftUI)
import SwiftUI
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#endif
#if os(macOS)
import AppKit
#endif

public extension DS {
    /// Semantic color tokens for FoundationUI components.
    enum Colors {
        /// Informational background color token with adaptive variants.
        public static let infoBackground: Color = adaptive(
            light: Color(red: 0.91, green: 0.97, blue: 1.0),
            dark: Color(red: 0.14, green: 0.22, blue: 0.30)
        )
        /// Warning background color token with adaptive variants.
        public static let warningBackground: Color = adaptive(
            light: Color(red: 1.0, green: 0.95, blue: 0.88),
            dark: Color(red: 0.38, green: 0.24, blue: 0.04)
        )
        /// Error background color token with adaptive variants.
        public static let errorBackground: Color = adaptive(
            light: Color(red: 1.0, green: 0.93, blue: 0.93),
            dark: Color(red: 0.32, green: 0.10, blue: 0.12)
        )
        /// Success background color token with adaptive variants.
        public static let successBackground: Color = adaptive(
            light: Color(red: 0.91, green: 0.97, blue: 0.92),
            dark: Color(red: 0.10, green: 0.23, blue: 0.12)
        )
        /// Primary text color token that adapts to system appearance.
        public static let primaryText: Color = adaptive(
            light: Color(red: 0.09, green: 0.09, blue: 0.11),
            dark: Color(red: 0.93, green: 0.95, blue: 0.97)
        )
        /// Surface background color for tree containers.
        public static let surfaceBackground: Color = adaptive(
            light: Color(red: 0.98, green: 0.99, blue: 1.0),
            dark: Color(red: 0.11, green: 0.13, blue: 0.17)
        )
        /// Selection highlight background color.
        public static let selectionBackground: Color = adaptive(
            light: Color(red: 0.80, green: 0.93, blue: 0.85),
            dark: Color(red: 0.16, green: 0.36, blue: 0.23)
        )

        private static func adaptive(light: Color, dark: Color) -> Color {
            #if os(iOS) || os(tvOS) || os(watchOS)
            return Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(dark)
                    : UIColor(light)
            })
            #elseif os(macOS)
            return Color(NSColor(name: nil) { appearance in
                appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                    ? NSColor(dark)
                    : NSColor(light)
            } ?? NSColor(light))
            #else
            return light
            #endif
        }
    }
}
#endif
