import SwiftUI

// MARK: - Platform Detection

/// Platform adapter utility providing platform-specific behavior and spacing
///
/// `PlatformAdapter` provides compile-time platform detection and runtime adaptation
/// for spacing, layout, and behavior across iOS/iPadOS/macOS platforms.
///
/// ## Overview
/// The adapter follows FoundationUI's **zero magic numbers** principle, using only
/// Design System (DS) tokens for all spacing and size values.
///
/// ## Platform Detection
/// Platform detection uses conditional compilation for optimal performance:
/// ```swift
/// if PlatformAdapter.isMacOS {
///     // macOS-specific code
/// }
/// ```
///
/// ## Spacing Adaptation
/// Spacing automatically adapts to platform conventions:
/// - **macOS**: Uses `DS.Spacing.m` (12pt) for denser desktop UI
/// - **iOS/iPadOS**: Uses `DS.Spacing.l` (16pt) for touch-optimized spacing
///
/// ```swift
/// VStack(spacing: PlatformAdapter.defaultSpacing) {
///     Text("Title")
///     Text("Content")
/// }
/// ```
///
/// ## Size Class Adaptation
/// The adapter supports size class-based spacing on iOS/iPadOS:
/// ```swift
/// let spacing = PlatformAdapter.spacing(for: horizontalSizeClass)
/// ```
///
/// ## See Also
/// - ``PlatformAdaptiveModifier``
/// - ``DS/Spacing``
public enum PlatformAdapter {
    // MARK: - Platform Detection

    /// Indicates if the current platform is macOS
    ///
    /// Uses conditional compilation for compile-time platform detection.
    /// This value is known at compile time and has zero runtime overhead.
    ///
    /// - Returns: `true` if running on macOS, `false` otherwise
    public static let isMacOS: Bool = {
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }()

    /// Indicates if the current platform is iOS or iPadOS
    ///
    /// Uses conditional compilation for compile-time platform detection.
    /// This value is known at compile time and has zero runtime overhead.
    ///
    /// - Returns: `true` if running on iOS/iPadOS, `false` otherwise
    public static let isIOS: Bool = {
        #if os(iOS)
        return true
        #else
        return false
        #endif
    }()

    // MARK: - Spacing Adaptation

    /// Default platform-adaptive spacing
    ///
    /// Returns the appropriate default spacing for the current platform,
    /// following Apple Human Interface Guidelines:
    /// - **macOS**: `DS.Spacing.m` (12pt) for denser desktop UI
    /// - **iOS/iPadOS**: `DS.Spacing.l` (16pt) for touch-optimized spacing
    ///
    /// ## Usage
    /// ```swift
    /// VStack(spacing: PlatformAdapter.defaultSpacing) {
    ///     Text("Title")
    ///     Text("Content")
    /// }
    /// ```
    ///
    /// - Returns: Platform-appropriate spacing value from DS tokens
    public static var defaultSpacing: CGFloat {
        #if os(macOS)
        return DS.Spacing.m
        #else
        return DS.Spacing.l
        #endif
    }

    /// Returns spacing adapted for the given size class
    ///
    /// Provides size class-aware spacing for responsive layouts on iOS/iPadOS:
    /// - **Compact**: `DS.Spacing.m` (12pt) for smaller screens
    /// - **Regular**: `DS.Spacing.l` (16pt) for larger screens
    /// - **nil**: Falls back to `defaultSpacing`
    ///
    /// ## Usage
    /// ```swift
    /// @Environment(\.horizontalSizeClass) var sizeClass
    ///
    /// var body: some View {
    ///     VStack(spacing: PlatformAdapter.spacing(for: sizeClass)) {
    ///         // Content adapts to size class
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter sizeClass: The current size class (horizontal or vertical)
    /// - Returns: Spacing value from DS tokens appropriate for the size class
    public static func spacing(for sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        guard let sizeClass else {
            return defaultSpacing
        }

        switch sizeClass {
        case .compact:
            return DS.Spacing.m
        case .regular:
            return DS.Spacing.l
        @unknown default:
            return defaultSpacing
        }
    }

    // MARK: - Touch Target Sizes

    #if os(iOS)
    /// Minimum touch target size for iOS (44×44 pt per Apple HIG)
    ///
    /// Per Apple Human Interface Guidelines, interactive elements on iOS
    /// should have a minimum touch target size of 44×44 points for accessibility.
    ///
    /// ## Usage
    /// ```swift
    /// Button("Tap Me") { }
    ///     .frame(minWidth: PlatformAdapter.minimumTouchTarget,
    ///            minHeight: PlatformAdapter.minimumTouchTarget)
    /// ```
    ///
    /// - Returns: 44.0 points (Apple HIG requirement)
    ///
    /// ## See Also
    /// - [Apple HIG - iOS Touch Targets](https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/adaptivity-and-layout/)
    public static let minimumTouchTarget: CGFloat = 44.0
    #endif
}

/// Alias exposed for documentation consistency so ``PlatformAdaptation``
/// resolves to the same utilities as ``PlatformAdapter``.
public typealias PlatformAdaptation = PlatformAdapter

// MARK: - Platform Adaptive Modifier

/// A view modifier that applies platform-adaptive spacing and layout
///
/// `PlatformAdaptiveModifier` automatically adjusts spacing, padding, and layout
/// based on the current platform (iOS/iPadOS/macOS) and size class, ensuring
/// consistent user experiences while respecting platform conventions.
///
/// ## Overview
/// The modifier uses DS tokens exclusively (zero magic numbers) and adapts to:
/// - Platform differences (macOS vs iOS/iPadOS)
/// - Size classes (compact vs regular)
/// - Custom spacing overrides
///
/// ## Usage
/// Apply via the `.platformAdaptive()` view extension:
/// ```swift
/// Text("Title")
///     .platformAdaptive()
/// ```
///
/// Or with custom spacing:
/// ```swift
/// VStack {
///     Text("Content")
/// }
/// .platformAdaptive(spacing: DS.Spacing.xl)
/// ```
///
/// ## See Also
/// - ``PlatformAdapter``
/// - `View.platformAdaptive()` modifier
/// - `View.platformAdaptive(spacing:)` modifier
public struct PlatformAdaptiveModifier: ViewModifier {
    /// Custom spacing override (optional)
    ///
    /// If provided, uses this spacing instead of platform default.
    /// If `nil`, automatically selects spacing via `PlatformAdapter.defaultSpacing`.
    private let customSpacing: CGFloat?

    /// Size class for adaptive layout (optional)
    ///
    /// If provided, adapts spacing to the given size class.
    /// If `nil`, uses platform default spacing.
    private let sizeClass: UserInterfaceSizeClass?

    /// Creates a platform-adaptive modifier
    ///
    /// - Parameters:
    ///   - spacing: Custom spacing override (defaults to platform default)
    ///   - sizeClass: Size class for adaptation (defaults to nil)
    public init(spacing: CGFloat? = nil, sizeClass: UserInterfaceSizeClass? = nil) {
        customSpacing = spacing
        self.sizeClass = sizeClass
    }

    /// Applies platform-adaptive spacing and padding
    ///
    /// Calculates appropriate spacing based on:
    /// 1. Custom spacing (if provided)
    /// 2. Size class (if provided)
    /// 3. Platform default (fallback)
    ///
    /// - Parameter content: The view to modify
    /// - Returns: Modified view with platform-adaptive spacing
    public func body(content: Content) -> some View {
        let spacing = resolveSpacing()

        content
            .padding(spacing)
    }

    /// Resolves the appropriate spacing value
    ///
    /// Priority order:
    /// 1. Custom spacing (if provided)
    /// 2. Size class-based spacing (if size class provided)
    /// 3. Platform default spacing (fallback)
    ///
    /// - Returns: Resolved spacing value from DS tokens
    private func resolveSpacing() -> CGFloat {
        if let customSpacing {
            return customSpacing
        }

        if let sizeClass {
            return PlatformAdapter.spacing(for: sizeClass)
        }

        return PlatformAdapter.defaultSpacing
    }
}

// MARK: - View Extensions

public extension View {
    /// Applies platform-adaptive spacing and layout
    ///
    /// Automatically adjusts spacing based on the current platform:
    /// - **macOS**: Uses `DS.Spacing.m` (12pt)
    /// - **iOS/iPadOS**: Uses `DS.Spacing.l` (16pt)
    ///
    /// ## Usage
    /// ```swift
    /// VStack {
    ///     Text("Title")
    ///     Text("Content")
    /// }
    /// .platformAdaptive()
    /// ```
    ///
    /// - Returns: A view with platform-adaptive spacing applied
    ///
    /// ## See Also
    /// - ``platformAdaptive(spacing:)``
    /// - ``platformAdaptive(sizeClass:)``
    func platformAdaptive() -> some View {
        modifier(PlatformAdaptiveModifier())
    }

    /// Applies platform-adaptive spacing with a custom value
    ///
    /// Uses the provided spacing value instead of the platform default.
    /// All spacing values should use DS tokens (zero magic numbers).
    ///
    /// ## Usage
    /// ```swift
    /// Card {
    ///     Text("Content")
    /// }
    /// .platformAdaptive(spacing: DS.Spacing.xl)
    /// ```
    ///
    /// - Parameter spacing: Custom spacing value (should be a DS token)
    /// - Returns: A view with custom platform-adaptive spacing applied
    func platformAdaptive(spacing: CGFloat) -> some View {
        modifier(PlatformAdaptiveModifier(spacing: spacing))
    }

    /// Applies platform-adaptive spacing for a specific size class
    ///
    /// Adapts spacing based on the provided size class:
    /// - **Compact**: `DS.Spacing.m` (12pt)
    /// - **Regular**: `DS.Spacing.l` (16pt)
    ///
    /// ## Usage
    /// ```swift
    /// @Environment(\.horizontalSizeClass) var sizeClass
    ///
    /// var body: some View {
    ///     VStack {
    ///         Text("Content")
    ///     }
    ///     .platformAdaptive(sizeClass: sizeClass)
    /// }
    /// ```
    ///
    /// - Parameter sizeClass: The size class to adapt to
    /// - Returns: A view with size class-adaptive spacing applied
    func platformAdaptive(sizeClass: UserInterfaceSizeClass?) -> some View {
        modifier(PlatformAdaptiveModifier(sizeClass: sizeClass))
    }

    /// Applies platform-specific spacing to the view
    ///
    /// Uses platform default spacing if no value is provided:
    /// - **macOS**: `DS.Spacing.m` (12pt)
    /// - **iOS/iPadOS**: `DS.Spacing.l` (16pt)
    ///
    /// ## Usage
    /// ```swift
    /// Text("Title")
    ///     .platformSpacing()
    /// ```
    ///
    /// - Parameter value: Custom spacing value (defaults to platform default)
    /// - Returns: A view with platform spacing applied via padding
    func platformSpacing(_ value: CGFloat = PlatformAdapter.defaultSpacing) -> some View {
        padding(value)
    }

    /// Applies platform-specific padding to specific edges
    ///
    /// Uses platform default spacing for the specified edges:
    /// - **macOS**: `DS.Spacing.m` (12pt)
    /// - **iOS/iPadOS**: `DS.Spacing.l` (16pt)
    ///
    /// ## Usage
    /// ```swift
    /// Text("Title")
    ///     .platformPadding(.horizontal)
    /// ```
    ///
    /// - Parameter edges: The edges to apply padding to (defaults to all edges)
    /// - Returns: A view with platform-specific padding applied
    func platformPadding(_ edges: Edge.Set = .all) -> some View {
        padding(edges, PlatformAdapter.defaultSpacing)
    }
}

// MARK: - Previews

#Preview("Platform Adaptive - Default") {
    VStack(spacing: DS.Spacing.m) {
        Text("Platform Adaptive Modifier")
            .font(DS.Typography.title)

        VStack {
            Text("This content uses platform-adaptive spacing")
                .font(DS.Typography.body)
        }
        .platformAdaptive()
        .cardStyle(elevation: .low)

        HStack {
            Text("Platform:")
            Text(PlatformAdapter.isMacOS ? "macOS" : "iOS")
                .font(DS.Typography.code)
        }

        HStack {
            Text("Default Spacing:")
            Text("\(Int(PlatformAdapter.defaultSpacing))pt")
                .font(DS.Typography.code)
        }
    }
    .padding(DS.Spacing.xl)
}

#Preview("Platform Adaptive - Custom Spacing") {
    VStack(spacing: DS.Spacing.m) {
        Text("Custom Spacing Examples")
            .font(DS.Typography.title)

        VStack {
            Text("Small spacing (DS.Spacing.s)")
                .font(DS.Typography.caption)
        }
        .platformAdaptive(spacing: DS.Spacing.s)
        .cardStyle(elevation: .low)

        VStack {
            Text("Medium spacing (DS.Spacing.m)")
                .font(DS.Typography.caption)
        }
        .platformAdaptive(spacing: DS.Spacing.m)
        .cardStyle(elevation: .low)

        VStack {
            Text("Large spacing (DS.Spacing.l)")
                .font(DS.Typography.caption)
        }
        .platformAdaptive(spacing: DS.Spacing.l)
        .cardStyle(elevation: .low)

        VStack {
            Text("Extra large spacing (DS.Spacing.xl)")
                .font(DS.Typography.caption)
        }
        .platformAdaptive(spacing: DS.Spacing.xl)
        .cardStyle(elevation: .low)
    }
    .padding(DS.Spacing.xl)
}

#Preview("Platform Adaptive - Size Classes") {
    VStack(spacing: DS.Spacing.m) {
        Text("Size Class Adaptation")
            .font(DS.Typography.title)

        VStack {
            Text("Compact Size Class")
                .font(DS.Typography.body)
            Text("Spacing: \(Int(PlatformAdapter.spacing(for: .compact)))pt")
                .font(DS.Typography.code)
        }
        .platformAdaptive(sizeClass: .compact)
        .cardStyle(elevation: .low)

        VStack {
            Text("Regular Size Class")
                .font(DS.Typography.body)
            Text("Spacing: \(Int(PlatformAdapter.spacing(for: .regular)))pt")
                .font(DS.Typography.code)
        }
        .platformAdaptive(sizeClass: .regular)
        .cardStyle(elevation: .low)
    }
    .padding(DS.Spacing.xl)
}

#Preview("Platform Spacing Extension") {
    VStack(spacing: DS.Spacing.m) {
        Text("Platform Spacing Extensions")
            .font(DS.Typography.title)

        Text("Default platform spacing")
            .platformSpacing()
            .background(Color.blue.opacity(0.1))

        Text("Custom spacing (DS.Spacing.xl)")
            .platformSpacing(DS.Spacing.xl)
            .background(Color.green.opacity(0.1))

        Text("Horizontal padding only")
            .platformPadding(.horizontal)
            .background(Color.purple.opacity(0.1))

        Text("Vertical padding only")
            .platformPadding(.vertical)
            .background(Color.orange.opacity(0.1))
    }
    .padding(DS.Spacing.xl)
}

#Preview("Platform Comparison") {
    VStack(spacing: DS.Spacing.l) {
        Text("Platform Information")
            .font(DS.Typography.title)

        Card {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                HStack {
                    Text("Current Platform:")
                        .font(DS.Typography.label)
                    Spacer()
                    Text(PlatformAdapter.isMacOS ? "macOS" : "iOS/iPadOS")
                        .font(DS.Typography.code)
                }

                HStack {
                    Text("Default Spacing:")
                        .font(DS.Typography.label)
                    Spacer()
                    Text("\(Int(PlatformAdapter.defaultSpacing))pt")
                        .font(DS.Typography.code)
                }

                HStack {
                    Text("Compact Spacing:")
                        .font(DS.Typography.label)
                    Spacer()
                    Text("\(Int(PlatformAdapter.spacing(for: .compact)))pt")
                        .font(DS.Typography.code)
                }

                HStack {
                    Text("Regular Spacing:")
                        .font(DS.Typography.label)
                    Spacer()
                    Text("\(Int(PlatformAdapter.spacing(for: .regular)))pt")
                        .font(DS.Typography.code)
                }

                #if os(iOS)
                HStack {
                    Text("Min Touch Target:")
                        .font(DS.Typography.label)
                    Spacer()
                    Text("\(Int(PlatformAdapter.minimumTouchTarget))pt")
                        .font(DS.Typography.code)
                }
                #endif
            }
        }
    }
    .padding(DS.Spacing.xl)
}

#Preview("Dark Mode") {
    VStack(spacing: DS.Spacing.m) {
        Text("Platform Adaptive (Dark Mode)")
            .font(DS.Typography.title)

        VStack {
            Text("Adapts to platform and color scheme")
                .font(DS.Typography.body)
        }
        .platformAdaptive()
        .cardStyle(elevation: .medium)
    }
    .padding(DS.Spacing.xl)
    .preferredColorScheme(.dark)
}
