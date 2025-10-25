#if canImport(SwiftUI)
import SwiftUI

public extension DS {
    /// Typography tokens describing semantic text styles.
    enum Typography {
        /// Style for supplemental labels.
        public static let label: Font = .system(.callout, design: .rounded)
        /// Style for primary body content.
        public static let body: Font = .system(.body, design: .default)
        /// Style for primary titles.
        public static let title: Font = .system(.title3, design: .default)
        /// Style for caption and metadata labels.
        public static let caption: Font = .system(.caption, design: .rounded)
        /// Style used for icon glyphs within interactive controls.
        public static let icon: Font = .system(.caption2, design: .default)

        /// Preferred typography for platform default text styling.
        public static var platformDefault: Font {
            #if os(macOS)
            return .system(.body, design: .default)
            #else
            return .system(.body, design: .rounded)
            #endif
        }
    }
}
#endif
