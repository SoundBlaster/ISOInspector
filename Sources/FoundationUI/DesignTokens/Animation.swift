#if canImport(SwiftUI)
import SwiftUI

public extension DS {
    /// Animation tokens.
    enum Animation {
        /// Quick easeInOut animation lasting 0.15 seconds.
        public static let quick: SwiftUI.Animation = .easeInOut(duration: 0.15)
        /// Medium easeInOut animation lasting 0.25 seconds.
        public static let medium: SwiftUI.Animation = .easeInOut(duration: 0.25)

        /// Resolved animation respecting reduce motion settings.
        /// - Parameter prefersReducedMotion: A Boolean indicating whether the user requested reduced motion.
        /// - Returns: An animation to apply or `nil` if motion should be avoided.
        public static func resolvedQuick(prefersReducedMotion: Bool) -> SwiftUI.Animation? {
            prefersReducedMotion ? nil : quick
        }
    }
}
#endif
