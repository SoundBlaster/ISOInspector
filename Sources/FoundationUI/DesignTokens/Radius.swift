import Foundation

public extension DS {
    /// Corner radius tokens.
    enum Radius {
        /// Card radius token (10pt).
        public static let card: CGFloat = 10
        /// Chip radius token (999pt) for fully rounded chips.
        public static let chip: CGFloat = 999
        /// Small radius token (6pt) for subtle rounding.
        public static let small: CGFloat = 6
    }
}
