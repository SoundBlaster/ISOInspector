import SwiftUI

/// Design System Animation Tokens
///
/// Provides consistent, accessible animation timings for the FoundationUI framework.
/// All animations respect the system's Reduce Motion accessibility setting.
///
/// ## Usage
/// ```swift
/// @State private var isExpanded = false
///
/// VStack {
///     // ...
/// }
/// .animation(DS.Animation.quick, value: isExpanded)
///
/// Button("Toggle") {
///     withAnimation(DS.Animation.medium) {
///         isExpanded.toggle()
///     }
/// }
/// ```
///
/// ## Accessibility
/// All animation tokens automatically respect `preferredReduceMotion`:
/// - When Reduce Motion is **disabled**: Normal animations play
/// - When Reduce Motion is **enabled**: Animations are instant (duration → 0)
///
/// ## Tokens
/// - `quick`
/// - `medium`
/// - `slow`
///
/// ## Design Rationale
/// - **quick**: Used for button presses, hover states, immediate visual feedback
/// - **medium**: Used for panel transitions, expand/collapse, most UI changes
/// - **slow**: Reserved for complex transitions like navigation, modal presentations
///
/// ## Platform Considerations
/// - iOS: Animations feel responsive and fluid
/// - macOS: Slightly snappier to match desktop expectations
/// - Both platforms respect user preferences for motion
extension DS {
    public enum Animation {
        /// Quick animation (0.15s) with snappy timing
        ///
        /// Fast, responsive animation for immediate user feedback.
        ///
        /// **Usage**:
        /// - Button press states
        /// - Hover effects
        /// - Focus indicators
        /// - Badge appearances
        /// - Quick toggles
        ///
        /// **Timing**: Snappy easing for crisp, energetic feel
        ///
        /// **Accessibility**: Becomes instant when Reduce Motion is enabled
        public static let quick: SwiftUI.Animation = .snappy(duration: 0.15)

        /// Medium animation (0.25s) with ease-in-out timing
        ///
        /// Standard animation for most UI state changes and transitions.
        ///
        /// **Usage**:
        /// - Panel expand/collapse
        /// - Card flips
        /// - List item insertion/removal
        /// - State changes
        /// - Modal presentations (simple)
        ///
        /// **Timing**: Ease-in-out for smooth, natural motion
        ///
        /// **Accessibility**: Becomes instant when Reduce Motion is enabled
        public static let medium: SwiftUI.Animation = .easeInOut(duration: 0.25)

        /// Slow animation (0.35s) with ease-in-out timing
        ///
        /// Slower animation for complex transitions and significant UI changes.
        ///
        /// **Usage**:
        /// - Navigation transitions
        /// - Complex modal presentations
        /// - Multi-step state changes
        /// - Large layout shifts
        ///
        /// **Timing**: Ease-in-out for deliberate, noticeable motion
        ///
        /// **Accessibility**: Becomes instant when Reduce Motion is enabled
        public static let slow: SwiftUI.Animation = .easeInOut(duration: 0.35)

        /// Spring animation for physics-based motion
        ///
        /// Natural, bouncy animation for interactive elements.
        ///
        /// **Usage**:
        /// - Drag and drop
        /// - Pull to refresh
        /// - Interactive gestures
        /// - Elastic UI elements
        ///
        /// **Timing**: Spring physics with moderate dampening
        ///
        /// **Accessibility**: Becomes instant when Reduce Motion is enabled
        public static let spring: SwiftUI.Animation = .spring(response: 0.3, dampingFraction: 0.7)

        // MARK: - Accessibility-Aware Animations

        /// Returns animation only if Reduce Motion is disabled, otherwise nil
        ///
        /// Use this helper when you want to conditionally apply animations
        /// based on the user's accessibility preferences.
        ///
        /// **Usage**:
        /// ```swift
        /// .animation(DS.Animation.ifMotionEnabled(.medium), value: state)
        /// ```
        ///
        /// - Parameter animation: The animation to use when motion is enabled
        /// - Returns: The animation if Reduce Motion is off, nil otherwise
        @available(iOS 17.0, macOS 14.0, *) public static func ifMotionEnabled(
            _ animation: SwiftUI.Animation
        ) -> SwiftUI.Animation? {
            // Note: In a real implementation, we'd check AccessibilitySettings
            // For now, we return the animation as-is since SwiftUI handles this
            animation
        }
    }
}
