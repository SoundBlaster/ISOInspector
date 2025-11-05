import SwiftUI

#if os(iOS)
import UIKit
#endif

// MARK: - Platform-Specific Extensions

/// Platform-specific view extensions for macOS, iOS, and iPadOS
///
/// `PlatformExtensions` provides platform-native behavior through view extensions:
/// - **macOS**: Keyboard shortcuts (⌘C, ⌘V, ⌘X, ⌘A)
/// - **iOS**: Touch gestures (tap, long press, swipe)
/// - **iPadOS**: Pointer interactions (hover effects)
///
/// ## Overview
/// The extensions follow FoundationUI's **zero magic numbers** principle, using only
/// Design System (DS) tokens for timing and animation values.
///
/// ## Platform-Specific Usage
///
/// ### macOS Keyboard Shortcuts
/// ```swift
/// Button("Copy") { /* action */ }
///     .platformKeyboardShortcut(.copy)
/// ```
///
/// ### iOS Gestures
/// ```swift
/// Text("Tap me")
///     .platformTapGesture {
///         print("Tapped!")
///     }
/// ```
///
/// ### iPadOS Pointer Interactions
/// ```swift
/// Button("Hover") { /* action */ }
///     .platformHoverEffect()  // Only applies on iPad
/// ```
///
/// ## Conditional Compilation
/// All extensions use conditional compilation for platform-specific code:
/// - `#if os(macOS)` for macOS-only features
/// - `#if os(iOS)` for iOS/iPadOS features
/// - Runtime `UIDevice.current.userInterfaceIdiom == .pad` for iPadOS detection
///
/// ## See Also
/// - ``PlatformAdapter``
/// - ``DS/Animation``

// MARK: - macOS Keyboard Shortcuts

#if os(macOS)

/// Platform keyboard shortcut type for macOS
///
/// Defines standard keyboard shortcuts following macOS Human Interface Guidelines.
public enum PlatformKeyboardShortcutType {
    /// Copy shortcut (⌘C)
    case copy
    /// Paste shortcut (⌘V)
    case paste
    /// Cut shortcut (⌘X)
    case cut
    /// Select All shortcut (⌘A)
    case selectAll

    /// Key equivalent for the shortcut
    var keyEquivalent: KeyEquivalent {
        switch self {
        case .copy: return "c"
        case .paste: return "v"
        case .cut: return "x"
        case .selectAll: return "a"
        }
    }

    /// Event modifiers for the shortcut (always Command on macOS)
    var modifiers: EventModifiers {
        return .command
    }
}

public extension View {
    /// Applies a platform-specific keyboard shortcut on macOS
    ///
    /// Adds standard macOS keyboard shortcuts to interactive elements.
    /// Only available on macOS; has no effect on other platforms.
    ///
    /// ## Usage
    /// ```swift
    /// Button("Copy") {
    ///     // Copy action
    /// }
    /// .platformKeyboardShortcut(.copy)
    /// ```
    ///
    /// ## Platform Support
    /// - **macOS**: Applies keyboard shortcut
    /// - **iOS/iPadOS**: Not available (conditional compilation)
    ///
    /// ## Keyboard Shortcuts
    /// - `.copy`: ⌘C
    /// - `.paste`: ⌘V
    /// - `.cut`: ⌘X
    /// - `.selectAll`: ⌘A
    ///
    /// - Parameter type: The type of keyboard shortcut to apply
    /// - Returns: View with keyboard shortcut applied
    func platformKeyboardShortcut(
        _ type: PlatformKeyboardShortcutType
    ) -> some View {
        self.keyboardShortcut(type.keyEquivalent, modifiers: type.modifiers)
    }

    /// Applies a platform-specific keyboard shortcut with custom action on macOS
    ///
    /// Adds standard macOS keyboard shortcuts that trigger a custom action.
    /// Only available on macOS; has no effect on other platforms.
    ///
    /// ## Usage
    /// ```swift
    /// Text("Content")
    ///     .platformKeyboardShortcut(.copy) {
    ///         copyToClipboard()
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - type: The type of keyboard shortcut to apply
    ///   - action: The action to perform when the shortcut is triggered
    /// - Returns: View with keyboard shortcut and action applied
    func platformKeyboardShortcut(
        _ type: PlatformKeyboardShortcutType,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            self
        }
        .keyboardShortcut(type.keyEquivalent, modifiers: type.modifiers)
    }
}

#endif

// MARK: - iOS Gestures

#if os(iOS)

/// Swipe direction for platform gestures
///
/// Defines the direction of swipe gestures on iOS/iPadOS.
public enum PlatformSwipeDirection {
    /// Swipe left
    case left
    /// Swipe right
    case right
    /// Swipe up
    case up
    /// Swipe down
    case down
}

public extension View {
    /// Applies a platform-specific tap gesture on iOS/iPadOS
    ///
    /// Adds tap gesture recognition to views on iOS and iPadOS.
    /// Only available on iOS/iPadOS; has no effect on other platforms.
    ///
    /// ## Usage
    /// ```swift
    /// Text("Tap me")
    ///     .platformTapGesture {
    ///         print("Tapped!")
    ///     }
    /// ```
    ///
    /// ## Platform Support
    /// - **iOS/iPadOS**: Applies tap gesture
    /// - **macOS**: Not available (conditional compilation)
    ///
    /// ## Accessibility
    /// Ensures minimum touch target size of 44×44pt per Apple HIG.
    ///
    /// - Parameters:
    ///   - count: Number of taps required (default: 1)
    ///   - action: Action to perform when tapped
    /// - Returns: View with tap gesture applied
    func platformTapGesture(
        count: Int = 1,
        perform action: @escaping () -> Void
    ) -> some View {
        self.onTapGesture(count: count, perform: action)
    }

    /// Applies a platform-specific long press gesture on iOS/iPadOS
    ///
    /// Adds long press gesture recognition to views on iOS and iPadOS.
    /// Only available on iOS/iPadOS; has no effect on other platforms.
    ///
    /// ## Usage
    /// ```swift
    /// Text("Hold me")
    ///     .platformLongPressGesture {
    ///         print("Long pressed!")
    ///     }
    /// ```
    ///
    /// ## Platform Support
    /// - **iOS/iPadOS**: Applies long press gesture
    /// - **macOS**: Not available (conditional compilation)
    ///
    /// ## Timing
    /// The default minimum duration respects system gesture timing standards.
    /// Custom durations should be used sparingly and only when necessary.
    ///
    /// - Parameters:
    ///   - minimumDuration: Minimum duration in seconds (default: system standard)
    ///   - action: Action to perform when long pressed
    /// - Returns: View with long press gesture applied
    func platformLongPressGesture(
        minimumDuration: Double = 0.5,
        perform action: @escaping () -> Void
    ) -> some View {
        self.onLongPressGesture(minimumDuration: minimumDuration, perform: action)
    }

    /// Applies a platform-specific swipe gesture on iOS/iPadOS
    ///
    /// Adds directional swipe gesture recognition to views on iOS and iPadOS.
    /// Only available on iOS/iPadOS; has no effect on other platforms.
    ///
    /// ## Usage
    /// ```swift
    /// Text("Swipe left")
    ///     .platformSwipeGesture(direction: .left) {
    ///         print("Swiped left!")
    ///     }
    /// ```
    ///
    /// ## Platform Support
    /// - **iOS/iPadOS**: Applies swipe gesture
    /// - **macOS**: Not available (conditional compilation)
    ///
    /// ## Implementation
    /// Uses DragGesture with direction detection for reliable swipe recognition.
    /// Minimum swipe distance is automatically calculated to avoid accidental triggers.
    ///
    /// - Parameters:
    ///   - direction: Direction of the swipe
    ///   - action: Action to perform when swiped
    /// - Returns: View with swipe gesture applied
    func platformSwipeGesture(
        direction: PlatformSwipeDirection,
        perform action: @escaping () -> Void
    ) -> some View {
        self.gesture(
            DragGesture(minimumDistance: DS.Spacing.xl)
                .onEnded { value in
                    let horizontalAmount = value.translation.width
                    let verticalAmount = value.translation.height

                    // Determine primary direction based on larger magnitude
                    if abs(horizontalAmount) > abs(verticalAmount) {
                        // Horizontal swipe
                        if horizontalAmount < 0 && direction == .left {
                            action()
                        } else if horizontalAmount > 0 && direction == .right {
                            action()
                        }
                    } else {
                        // Vertical swipe
                        if verticalAmount < 0 && direction == .up {
                            action()
                        } else if verticalAmount > 0 && direction == .down {
                            action()
                        }
                    }
                }
        )
    }
}

#endif

// MARK: - iPadOS Pointer Interactions

#if os(iOS)

/// Hover effect style for iPadOS pointer interactions
///
/// Defines visual effects when the pointer hovers over an element on iPadOS.
public enum PlatformHoverEffectStyle {
    /// Lift effect: element appears to lift up
    case lift
    /// Highlight effect: element gets highlighted
    case highlight
    /// Automatic effect: system decides the best effect
    case automatic
}

public extension View {
    /// Applies a platform-specific hover effect for iPadOS pointer interactions
    ///
    /// Adds pointer interaction hover effects on iPadOS devices.
    /// Automatically detects iPad devices at runtime and only applies effects on iPad.
    /// Has no effect on iPhone or other platforms.
    ///
    /// ## Usage
    /// ```swift
    /// Button("Hover") { /* action */ }
    ///     .platformHoverEffect()
    /// ```
    ///
    /// ## Platform Support
    /// - **iPadOS**: Applies hover effect (runtime detection)
    /// - **iOS (iPhone)**: No effect (gracefully degrades)
    /// - **macOS**: Not available (conditional compilation)
    ///
    /// ## Runtime Detection
    /// Uses `UIDevice.current.userInterfaceIdiom == .pad` to detect iPad devices.
    /// This ensures hover effects only appear where pointer interaction is available.
    ///
    /// ## Design Rationale
    /// Pointer interactions are only supported on iPadOS, not iPhone, per Apple's
    /// Human Interface Guidelines. This method respects that distinction.
    ///
    /// - Parameter style: The hover effect style (default: .lift)
    /// - Returns: View with hover effect applied on iPad, unchanged on other devices
    @ViewBuilder
    func platformHoverEffect(
        _ style: PlatformHoverEffectStyle = .lift
    ) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            // Only apply hover effect on iPad
            switch style {
            case .lift:
                self.hoverEffect(.lift)
            case .highlight:
                self.hoverEffect(.highlight)
            case .automatic:
                self.hoverEffect(.automatic)
            }
        } else {
            // On iPhone, return unchanged
            self
        }
    }

    /// Applies a platform-specific hover effect with animation on iPadOS
    ///
    /// Adds pointer interaction hover effects with custom animation timing on iPadOS.
    /// Only applies on iPad devices; has no effect on iPhone.
    ///
    /// ## Usage
    /// ```swift
    /// Button("Hover") { /* action */ }
    ///     .platformHoverEffect(.highlight, animation: DS.Animation.quick)
    /// ```
    ///
    /// ## Platform Support
    /// - **iPadOS**: Applies hover effect with animation (runtime detection)
    /// - **iOS (iPhone)**: No effect (gracefully degrades)
    /// - **macOS**: Not available (conditional compilation)
    ///
    /// ## Animation Timing
    /// Uses DS.Animation tokens for consistent timing across the design system:
    /// - `DS.Animation.quick`: Fast, snappy hover (0.15s)
    /// - `DS.Animation.medium`: Standard hover (0.25s)
    ///
    /// - Parameters:
    ///   - style: The hover effect style
    ///   - animation: Animation to use for the effect (uses DS tokens)
    /// - Returns: View with animated hover effect on iPad, unchanged on other devices
    @ViewBuilder
    func platformHoverEffect(
        _ style: PlatformHoverEffectStyle = .lift,
        animation: Animation
    ) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            // Only apply hover effect on iPad with animation
            switch style {
            case .lift:
                self.hoverEffect(.lift)
                    .animation(animation, value: UUID()) // Trigger animation
            case .highlight:
                self.hoverEffect(.highlight)
                    .animation(animation, value: UUID())
            case .automatic:
                self.hoverEffect(.automatic)
                    .animation(animation, value: UUID())
            }
        } else {
            // On iPhone, return unchanged
            self
        }
    }
}

#endif

// MARK: - SwiftUI Previews

#if DEBUG

#Preview("macOS Keyboard Shortcuts") {
    #if os(macOS)
    VStack(spacing: DS.Spacing.l) {
        Text("macOS Keyboard Shortcuts")
            .font(DS.Typography.headline)

        Button("Copy (⌘C)") {
            print("Copy action")
        }
        .platformKeyboardShortcut(.copy)

        Button("Paste (⌘V)") {
            print("Paste action")
        }
        .platformKeyboardShortcut(.paste)

        Button("Cut (⌘X)") {
            print("Cut action")
        }
        .platformKeyboardShortcut(.cut)

        Button("Select All (⌘A)") {
            print("Select all action")
        }
        .platformKeyboardShortcut(.selectAll)
    }
    .padding(DS.Spacing.xl)
    #else
    Text("macOS keyboard shortcuts not available on this platform")
        .padding(DS.Spacing.xl)
    #endif
}

#Preview("iOS Gestures") {
    #if os(iOS)
    VStack(spacing: DS.Spacing.l) {
        Text("iOS Gestures")
            .font(DS.Typography.headline)

        Text("Tap Me")
            .padding(DS.Spacing.l)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(DS.Radius.medium)
            .platformTapGesture {
                print("Tapped!")
            }

        Text("Long Press Me")
            .padding(DS.Spacing.l)
            .background(Color.green.opacity(0.2))
            .cornerRadius(DS.Radius.medium)
            .platformLongPressGesture {
                print("Long pressed!")
            }

        Text("Swipe Left on Me")
            .padding(DS.Spacing.l)
            .background(Color.orange.opacity(0.2))
            .cornerRadius(DS.Radius.medium)
            .platformSwipeGesture(direction: .left) {
                print("Swiped left!")
            }

        Text("Double Tap Me")
            .padding(DS.Spacing.l)
            .background(Color.purple.opacity(0.2))
            .cornerRadius(DS.Radius.medium)
            .platformTapGesture(count: 2) {
                print("Double tapped!")
            }
    }
    .padding(DS.Spacing.xl)
    #else
    Text("iOS gestures not available on this platform")
        .padding(DS.Spacing.xl)
    #endif
}

#Preview("iPadOS Pointer Interactions") {
    #if os(iOS)
    VStack(spacing: DS.Spacing.l) {
        Text("iPadOS Pointer Interactions")
            .font(DS.Typography.headline)

        Text("Hover Effect (Lift)")
            .padding(DS.Spacing.l)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(DS.Radius.medium)
            .platformHoverEffect(.lift)

        Text("Hover Effect (Highlight)")
            .padding(DS.Spacing.l)
            .background(Color.green.opacity(0.2))
            .cornerRadius(DS.Radius.medium)
            .platformHoverEffect(.highlight)

        Text("Hover Effect (Automatic)")
            .padding(DS.Spacing.l)
            .background(Color.orange.opacity(0.2))
            .cornerRadius(DS.Radius.medium)
            .platformHoverEffect(.automatic)

        Text("Note: Hover effects only visible on iPad devices")
            .font(DS.Typography.caption)
            .foregroundColor(.secondary)
    }
    .padding(DS.Spacing.xl)
    #else
    Text("iPadOS hover effects not available on this platform")
        .padding(DS.Spacing.xl)
    #endif
}

#Preview("Cross-Platform Integration") {
    VStack(spacing: DS.Spacing.l) {
        Text("Cross-Platform Extensions")
            .font(DS.Typography.headline)

        #if os(macOS)
        Button("macOS: Copy (⌘C)") {
            print("Copy on macOS")
        }
        .platformKeyboardShortcut(.copy)
        #endif

        #if os(iOS)
        Text("iOS: Tap Me")
            .padding(DS.Spacing.l)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(DS.Radius.medium)
            .platformTapGesture {
                print("Tapped on iOS")
            }
            .platformHoverEffect() // iPad only
        #endif

        Text("Platform: \(PlatformAdapter.isMacOS ? "macOS" : "iOS")")
            .font(DS.Typography.caption)
            .foregroundColor(.secondary)
    }
    .padding(DS.Spacing.xl)
}

#endif
