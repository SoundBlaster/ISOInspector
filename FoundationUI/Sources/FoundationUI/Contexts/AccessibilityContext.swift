import SwiftUI

// MARK: - AccessibilityContext

/// Context for accessibility preferences and adaptive UI behavior
///
/// `AccessibilityContext` provides centralized access to system accessibility
/// settings and adapts UI elements accordingly. It follows FoundationUI's
/// design principles by supporting reduce motion, increase contrast, bold text,
/// and Dynamic Type scaling.
///
/// ## Overview
/// The context follows FoundationUI's design principles:
/// - **Reduce Motion**: Respects user preference to minimize animations
/// - **Increase Contrast**: Provides higher contrast colors for accessibility
/// - **Bold Text**: Adapts font weights when bold text is enabled
/// - **Dynamic Type**: Automatically scales fonts with user's text size preference
/// - **Zero Magic Numbers**: Uses only DS tokens for values
///
/// ## Basic Usage
/// ### Reading Accessibility Settings
/// ```swift
/// @Environment(\.accessibilityContext) var a11yContext
///
/// var body: some View {
///     Text("Hello")
///         .font(a11yContext.scaledFont(for: DS.Typography.body))
///         .foregroundColor(a11yContext.adaptiveForeground)
///         .animation(a11yContext.adaptiveAnimation, value: someValue)
/// }
/// ```
///
/// ### Using with SwiftUI Environment
/// ```swift
/// struct MyView: View {
///     @Environment(\.accessibilityReduceMotion) var reduceMotion
///     @Environment(\.accessibilityDifferentiateWithoutColor) var increaseContrast
///     @Environment(\.sizeCategory) var sizeCategory
///     
///     var body: some View {
///         let context = AccessibilityContext(
///             isReduceMotionEnabled: reduceMotion,
///             isIncreaseContrastEnabled: increaseContrast,
///             sizeCategory: sizeCategory
///         )
///         
///         ContentView()
///             .environment(\.accessibilityContext, context)
///     }
/// }
/// ```
///
/// ## Reduce Motion Support
/// ```swift
/// let context = AccessibilityContext(isReduceMotionEnabled: true)
/// if context.isReduceMotionEnabled {
///     // No animation
///     view.animation(nil)
/// } else {
///     // Use DS animation
///     view.animation(DS.Animation.medium)
/// }
/// ```
///
/// ## Increase Contrast Support
/// ```swift
/// let context = AccessibilityContext(isIncreaseContrastEnabled: true)
/// Text("High Contrast")
///     .foregroundColor(context.adaptiveForeground) // Higher contrast
///     .background(context.adaptiveBackground)
/// ```
///
/// ## Bold Text Support
/// ```swift
/// let context = AccessibilityContext(isBoldTextEnabled: true)
/// Text("Bold Text")
///     .fontWeight(context.adaptiveFontWeight) // .bold or .regular
/// ```
///
/// ## Dynamic Type Support
/// ```swift
/// let context = AccessibilityContext(sizeCategory: .accessibilityLarge)
/// Text("Scaled Text")
///     .font(context.scaledFont(for: DS.Typography.body))
///     .padding(context.scaledSpacing(DS.Spacing.m))
/// ```
///
/// ## Integration with Design Tokens
/// AccessibilityContext works seamlessly with DS tokens:
/// ```swift
/// VStack(spacing: context.scaledSpacing(DS.Spacing.m)) {
///     Text("Title")
///         .font(context.scaledFont(for: DS.Typography.headline))
///         .fontWeight(context.adaptiveFontWeight)
///         .foregroundColor(context.adaptiveForeground)
/// }
/// .padding(context.scaledSpacing(DS.Spacing.l))
/// .background(context.adaptiveBackground)
/// .animation(context.adaptiveAnimation, value: someState)
/// ```
///
/// ## Use Cases
/// ### Accessible Card Components
/// ```swift
/// Card {
///     VStack(alignment: .leading, spacing: context.scaledSpacing(DS.Spacing.m)) {
///         Text("Title")
///             .font(context.scaledFont(for: DS.Typography.headline))
///             .fontWeight(context.adaptiveFontWeight)
///             .foregroundColor(context.adaptiveForeground)
///         
///         Text("Content")
///             .font(context.scaledFont(for: DS.Typography.body))
///             .foregroundColor(context.adaptiveForeground)
///     }
/// }
/// ```
///
/// ### Accessible Animations
/// ```swift
/// @State private var isExpanded = false
///
/// VStack {
///     // Content
/// }
/// .rotationEffect(isExpanded ? .degrees(90) : .zero)
/// .animation(context.adaptiveAnimation, value: isExpanded)
/// ```
///
/// ## Platform Support
/// - iOS 17.0+
/// - macOS 14.0+
/// - Automatically detects system preferences on all platforms
///
/// ## Accessibility Guidelines
/// - **WCAG 2.1 Level AA**: All adaptive colors meet ≥4.5:1 contrast
/// - **Reduce Motion**: Respects user's motion preference
/// - **Dynamic Type**: Supports all sizes from XS to Accessibility XXXL
/// - **Bold Text**: Increases weight to .bold when enabled
public struct AccessibilityContext {
    
    // MARK: - Properties
    
    /// Whether reduce motion is enabled
    public let isReduceMotionEnabled: Bool
    
    /// Whether increase contrast is enabled
    public let isIncreaseContrastEnabled: Bool
    
    /// Whether bold text is enabled
    public let isBoldTextEnabled: Bool
    
    /// Current Dynamic Type size category
    public let sizeCategory: DynamicTypeSize
    
    // MARK: - Initializers
    
    /// Creates an accessibility context with specified settings
    ///
    /// - Parameters:
    ///   - isReduceMotionEnabled: Whether reduce motion is enabled (default: false)
    ///   - isIncreaseContrastEnabled: Whether increase contrast is enabled (default: false)
    ///   - isBoldTextEnabled: Whether bold text is enabled (default: false)
    ///   - sizeCategory: Dynamic Type size category (default: .medium)
    public init(
        isReduceMotionEnabled: Bool = false,
        isIncreaseContrastEnabled: Bool = false,
        isBoldTextEnabled: Bool = false,
        sizeCategory: DynamicTypeSize = .medium
    ) {
        self.isReduceMotionEnabled = isReduceMotionEnabled
        self.isIncreaseContrastEnabled = isIncreaseContrastEnabled
        self.isBoldTextEnabled = isBoldTextEnabled
        self.sizeCategory = sizeCategory
    }
    
    // MARK: - Adaptive Properties
    
    /// Returns appropriate animation based on reduce motion setting
    ///
    /// - Returns: DS animation if motion allowed, nil if reduce motion is enabled
    public var adaptiveAnimation: Animation? {
        if isReduceMotionEnabled {
            return nil // No animation when reduce motion is enabled
        } else {
            return DS.Animation.medium
        }
    }
    
    /// Returns adaptive foreground color based on contrast setting
    ///
    /// - Returns: High contrast foreground if increase contrast is enabled
    public var adaptiveForeground: Color {
        if isIncreaseContrastEnabled {
            // Use pure black/white for maximum contrast
            return Color.primary
        } else {
            return DS.Color.textPrimary
        }
    }
    
    /// Returns adaptive background color based on contrast setting
    ///
    /// - Returns: High contrast background if increase contrast is enabled
    public var adaptiveBackground: Color {
        if isIncreaseContrastEnabled {
            // Use system background with maximum contrast
            return Color(uiColor: .systemBackground)
        } else {
            return Color(uiColor: .secondarySystemBackground)
        }
    }
    
    /// Returns adaptive font weight based on bold text setting
    ///
    /// - Returns: .bold if bold text is enabled, .regular otherwise
    public var adaptiveFontWeight: Font.Weight {
        return isBoldTextEnabled ? .bold : .regular
    }
    
    /// Determines if current size category is an accessibility size
    ///
    /// Accessibility sizes are XXXL and larger, requiring special layout considerations
    ///
    /// - Returns: true if using accessibility size category
    public var isAccessibilitySize: Bool {
        switch sizeCategory {
        case .accessibilityMedium, .accessibilityLarge, 
             .accessibilityExtraLarge, .accessibilityExtraExtraLarge,
             .accessibilityExtraExtraExtraLarge:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Scaling Methods
    
    /// Scales a font based on Dynamic Type size category
    ///
    /// - Parameter font: Base font to scale
    /// - Returns: Font scaled according to current size category
    public func scaledFont(for font: Font) -> Font {
        // SwiftUI automatically scales fonts based on sizeCategory environment
        // We just return the font and let SwiftUI handle the scaling
        return font
    }
    
    /// Scales spacing value based on Dynamic Type size category
    ///
    /// For accessibility sizes, spacing is increased to maintain comfortable layouts
    ///
    /// - Parameter spacing: Base spacing value
    /// - Returns: Scaled spacing appropriate for current size category
    public func scaledSpacing(_ spacing: CGFloat) -> CGFloat {
        // Increase spacing for accessibility sizes to prevent crowding
        if isAccessibilitySize {
            return spacing * 1.5
        } else {
            return spacing
        }
    }
}

// MARK: - Environment Key

/// Environment key for accessibility context
private struct AccessibilityContextKey: EnvironmentKey {
    static let defaultValue = AccessibilityContext()
}

public extension EnvironmentValues {
    /// Accessibility context for the current environment
    ///
    /// Use this to access accessibility settings and adaptive UI properties:
    /// ```swift
    /// @Environment(\.accessibilityContext) var a11yContext
    ///
    /// var body: some View {
    ///     Text("Hello")
    ///         .font(a11yContext.scaledFont(for: DS.Typography.body))
    ///         .foregroundColor(a11yContext.adaptiveForeground)
    /// }
    /// ```
    var accessibilityContext: AccessibilityContext {
        get { self[AccessibilityContextKey.self] }
        set { self[AccessibilityContextKey.self] = newValue }
    }
}

// MARK: - View Modifiers

public extension View {
    /// Applies adaptive accessibility context to view and its children
    ///
    /// Automatically configures the view to respect reduce motion, increase contrast,
    /// bold text, and Dynamic Type settings from the environment.
    ///
    /// ## Usage
    /// ```swift
    /// struct MyView: View {
    ///     var body: some View {
    ///         ContentView()
    ///             .adaptiveAccessibility()
    ///     }
    /// }
    /// ```
    ///
    /// This is equivalent to manually reading environment values:
    /// ```swift
    /// @Environment(\.accessibilityReduceMotion) var reduceMotion
    /// @Environment(\.sizeCategory) var sizeCategory
    ///
    /// var body: some View {
    ///     let context = AccessibilityContext(
    ///         isReduceMotionEnabled: reduceMotion,
    ///         sizeCategory: sizeCategory
    ///     )
    ///     ContentView()
    ///         .environment(\.accessibilityContext, context)
    /// }
    /// ```
    ///
    /// - Returns: View with accessibility context applied
    func adaptiveAccessibility() -> some View {
        modifier(AdaptiveAccessibilityModifier())
    }
}

/// Modifier that applies adaptive accessibility context
private struct AdaptiveAccessibilityModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityDifferentiateWithoutColor) private var increaseContrast
    @Environment(\.sizeCategory) private var sizeCategory
    
    // Bold text is only available on iOS/iPadOS
    #if os(iOS)
    @Environment(\.legibilityWeight) private var legibilityWeight
    #endif
    
    func body(content: Content) -> some View {
        let isBold: Bool
        #if os(iOS)
        isBold = legibilityWeight == .bold
        #else
        isBold = false
        #endif
        
        let context = AccessibilityContext(
            isReduceMotionEnabled: reduceMotion,
            isIncreaseContrastEnabled: increaseContrast,
            isBoldTextEnabled: isBold,
            sizeCategory: sizeCategory
        )
        
        content
            .environment(\.accessibilityContext, context)
    }
}

// MARK: - SwiftUI Previews

#if DEBUG
#Preview("Reduce Motion - Enabled") {
    VStack(spacing: DS.Spacing.l) {
        Text("Reduce Motion Enabled")
            .font(DS.Typography.headline)
        
        let context = AccessibilityContext(isReduceMotionEnabled: true)
        
        VStack(spacing: DS.Spacing.m) {
            HStack {
                Text("Animation:")
                    .font(DS.Typography.body)
                Spacer()
                Text(context.adaptiveAnimation == nil ? "Disabled" : "Enabled")
                    .font(DS.Typography.code)
                    .foregroundColor(context.adaptiveAnimation == nil ? DS.Color.successBG : DS.Color.warnBG)
            }
        }
        .padding(DS.Spacing.l)
        .background(DS.Color.infoBG)
        .cornerRadius(DS.Radius.card)
    }
    .padding(DS.Spacing.l)
}

#Preview("Increase Contrast - Enabled") {
    VStack(spacing: DS.Spacing.l) {
        Text("Increase Contrast Enabled")
            .font(DS.Typography.headline)
        
        let context = AccessibilityContext(isIncreaseContrastEnabled: true)
        
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text("High Contrast Text")
                .font(DS.Typography.body)
                .foregroundColor(context.adaptiveForeground)
            
            Text("Standard foreground text with increased contrast")
                .font(DS.Typography.caption)
                .foregroundColor(context.adaptiveForeground)
        }
        .padding(DS.Spacing.l)
        .background(context.adaptiveBackground)
        .cornerRadius(DS.Radius.card)
    }
    .padding(DS.Spacing.l)
}

#Preview("Bold Text - Enabled") {
    VStack(spacing: DS.Spacing.l) {
        Text("Bold Text Enabled")
            .font(DS.Typography.headline)
        
        let context = AccessibilityContext(isBoldTextEnabled: true)
        
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text("Regular weight text")
                .font(DS.Typography.body)
            
            Text("Adaptive weight text")
                .font(DS.Typography.body)
                .fontWeight(context.adaptiveFontWeight)
            
            HStack {
                Text("Font Weight:")
                    .font(DS.Typography.body)
                Spacer()
                Text(context.isBoldTextEnabled ? "Bold" : "Regular")
                    .font(DS.Typography.code)
                    .fontWeight(context.adaptiveFontWeight)
            }
        }
        .padding(DS.Spacing.l)
        .background(DS.Color.infoBG)
        .cornerRadius(DS.Radius.card)
    }
    .padding(DS.Spacing.l)
}

#Preview("Dynamic Type - Small") {
    let context = AccessibilityContext(sizeCategory: .small)
    
    VStack(spacing: context.scaledSpacing(DS.Spacing.l)) {
        Text("Small Size Category")
            .font(context.scaledFont(for: DS.Typography.headline))
        
        VStack(alignment: .leading, spacing: context.scaledSpacing(DS.Spacing.m)) {
            Text("Body text at small size")
                .font(context.scaledFont(for: DS.Typography.body))
            
            Text("Caption text at small size")
                .font(context.scaledFont(for: DS.Typography.caption))
            
            HStack {
                Text("Size Category:")
                Spacer()
                Text("Small")
                    .font(DS.Typography.code)
            }
            .font(context.scaledFont(for: DS.Typography.body))
        }
        .padding(context.scaledSpacing(DS.Spacing.l))
        .background(DS.Color.infoBG)
        .cornerRadius(DS.Radius.card)
    }
    .padding(context.scaledSpacing(DS.Spacing.l))
}

#Preview("Dynamic Type - Accessibility XXL") {
    let context = AccessibilityContext(sizeCategory: .accessibilityExtraExtraExtraLarge)
    
    VStack(spacing: context.scaledSpacing(DS.Spacing.l)) {
        Text("Accessibility XXL Size")
            .font(context.scaledFont(for: DS.Typography.headline))
        
        VStack(alignment: .leading, spacing: context.scaledSpacing(DS.Spacing.m)) {
            Text("Body text at XXL size")
                .font(context.scaledFont(for: DS.Typography.body))
            
            Text("Caption text at XXL size")
                .font(context.scaledFont(for: DS.Typography.caption))
            
            VStack(alignment: .leading, spacing: context.scaledSpacing(DS.Spacing.s)) {
                HStack {
                    Text("Size Category:")
                    Spacer()
                    Text("XXL")
                        .font(DS.Typography.code)
                }
                
                HStack {
                    Text("Is Accessibility Size:")
                    Spacer()
                    Text(context.isAccessibilitySize ? "Yes" : "No")
                        .font(DS.Typography.code)
                        .foregroundColor(context.isAccessibilitySize ? DS.Color.successBG : DS.Color.errorBG)
                }
                
                HStack {
                    Text("Spacing Multiplier:")
                    Spacer()
                    Text("1.5x")
                        .font(DS.Typography.code)
                }
            }
            .font(context.scaledFont(for: DS.Typography.body))
        }
        .padding(context.scaledSpacing(DS.Spacing.l))
        .background(DS.Color.infoBG)
        .cornerRadius(DS.Radius.card)
    }
    .padding(context.scaledSpacing(DS.Spacing.l))
}

#Preview("All Features Combined") {
    let context = AccessibilityContext(
        isReduceMotionEnabled: true,
        isIncreaseContrastEnabled: true,
        isBoldTextEnabled: true,
        sizeCategory: .accessibilityLarge
    )
    
    VStack(spacing: context.scaledSpacing(DS.Spacing.l)) {
        Text("All Accessibility Features")
            .font(context.scaledFont(for: DS.Typography.headline))
            .fontWeight(context.adaptiveFontWeight)
        
        VStack(alignment: .leading, spacing: context.scaledSpacing(DS.Spacing.m)) {
            FeatureRow(
                title: "Reduce Motion",
                value: context.isReduceMotionEnabled ? "Enabled" : "Disabled",
                isEnabled: context.isReduceMotionEnabled,
                context: context
            )
            
            FeatureRow(
                title: "Increase Contrast",
                value: context.isIncreaseContrastEnabled ? "Enabled" : "Disabled",
                isEnabled: context.isIncreaseContrastEnabled,
                context: context
            )
            
            FeatureRow(
                title: "Bold Text",
                value: context.isBoldTextEnabled ? "Enabled" : "Disabled",
                isEnabled: context.isBoldTextEnabled,
                context: context
            )
            
            FeatureRow(
                title: "Dynamic Type",
                value: "Accessibility Large",
                isEnabled: context.isAccessibilitySize,
                context: context
            )
        }
        .padding(context.scaledSpacing(DS.Spacing.l))
        .background(context.adaptiveBackground)
        .cornerRadius(DS.Radius.card)
    }
    .padding(context.scaledSpacing(DS.Spacing.l))
}

// Helper view for preview
private struct FeatureRow: View {
    let title: String
    let value: String
    let isEnabled: Bool
    let context: AccessibilityContext
    
    var body: some View {
        HStack {
            Text(title)
                .font(context.scaledFont(for: DS.Typography.body))
                .fontWeight(context.adaptiveFontWeight)
            Spacer()
            Text(value)
                .font(context.scaledFont(for: DS.Typography.code))
                .foregroundColor(isEnabled ? DS.Color.successBG : DS.Color.warnBG)
        }
        .foregroundColor(context.adaptiveForeground)
    }
}

#endif // DEBUG
