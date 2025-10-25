import Foundation

public extension DS {
    /// Spacing tokens used throughout FoundationUI components.
    enum Spacing {
        /// Extra small spacing (4pt) suitable for tight layouts.
        public static let xs: CGFloat = 4
        /// Small spacing (8pt) for compact padding.
        public static let s: CGFloat = 8
        /// Medium spacing (12pt) for standard padding.
        public static let m: CGFloat = 12
        /// Large spacing (16pt) for comfortable separation.
        public static let l: CGFloat = 16
        /// Extra large spacing (24pt) for major grouping.
        public static let xl: CGFloat = 24
        /// Indentation applied per hierarchy level in tree patterns.
        public static let levelIndentation: CGFloat = l

        /// Returns the default platform spacing baseline.
        public static var platformDefault: CGFloat {
            #if os(macOS)
            return m
            #else
            return l
            #endif
        }

        /// Computes indentation for a hierarchical depth.
        /// - Parameter depth: The depth in the hierarchy (root starts at zero).
        /// - Returns: The cumulative indentation using ``levelIndentation``.
        public static func indentation(forDepth depth: Int) -> CGFloat {
            levelIndentation * CGFloat(depth)
        }
    }
}
