// @todo #235 Fix AccessibilityHelpers closure parameter positions in previews
// swiftlint:disable closure_parameter_position

import SwiftUI

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

// MARK: - AccessibilityHelpers

/// A collection of utilities for enhancing accessibility in FoundationUI components
///
/// `AccessibilityHelpers` provides tools for:
/// - **Contrast ratio validation** (WCAG 2.1 compliance)
/// - **VoiceOver hint builders** (clear, concise guidance)
/// - **Common accessibility modifiers** (button, toggle, heading, value)
/// - **Accessibility audit tools** (touch targets, labels, comprehensive audits)
/// - **Focus management** (keyboard navigation)
/// - **Dynamic Type support** (scaling helpers)
///
/// ## Overview
///
/// All helpers follow the Composable Clarity design system principles:
/// - Zero magic numbers (uses DS tokens exclusively)
/// - Platform-adaptive behavior (macOS, iOS, iPadOS)
/// - Full accessibility support (VoiceOver, keyboard, Dynamic Type)
/// - WCAG 2.1 Level AA compliance (≥4.5:1 contrast ratio)
///
/// ## Usage
///
/// ### Contrast Ratio Validation
/// ```swift
/// let ratio = AccessibilityHelpers.contrastRatio(
///     foreground: .black,
///     background: .white
/// )
/// // ratio ≈ 21.0
///
/// let meetsAA = AccessibilityHelpers.meetsWCAG_AA(
///     foreground: .black,
///     background: DS.Colors.infoBG
/// )
/// // true if contrast ≥ 4.5:1
/// ```
///
/// ### VoiceOver Hint Builders
/// ```swift
/// let hint = AccessibilityHelpers.voiceOverHint(
///     action: "copy",
///     target: "value"
/// )
/// // "Double tap to copy value"
/// ```
///
/// ### Accessibility Modifiers
/// ```swift
/// Text("Action")
///     .accessibleButton(
///         label: "Copy Value",
///         hint: "Copies the value to clipboard"
///     )
/// ```
///
/// ### Accessibility Audit
/// ```swift
/// let audit = AccessibilityHelpers.auditView(
///     hasLabel: true,
///     hasHint: true,
///     touchTargetSize: CGSize(width: 44, height: 44),
///     contrastRatio: 7.0
/// )
/// if !audit.passes {
///     print("Issues: \(audit.issues)")
/// }
/// ```
///
/// ## Platform Compatibility
///
/// - iOS 17.0+
/// - iPadOS 17.0+
/// - macOS 14.0+
///
/// ## See Also
///
/// - ``AccessibilityContext``
/// - ``DS``
public enum AccessibilityHelpers {
    // MARK: - Contrast Ratio Validation

    /// Calculates the WCAG 2.1 contrast ratio between two colors
    ///
    /// The contrast ratio is calculated using the formula:
    /// ```
    /// (L1 + 0.05) / (L2 + 0.05)
    /// ```
    /// where L1 is the relative luminance of the lighter color
    /// and L2 is the relative luminance of the darker color.
    ///
    /// - Parameters:
    ///   - foreground: The foreground color (typically text)
    ///   - background: The background color
    /// - Returns: The contrast ratio (1.0 to 21.0)
    ///
    /// ## Example
    /// ```swift
    /// let ratio = AccessibilityHelpers.contrastRatio(
    ///     foreground: .black,
    ///     background: .white
    /// )
    /// // ratio ≈ 21.0 (maximum contrast)
    /// ```
    public static func contrastRatio(foreground: Color, background: Color) -> CGFloat {
        let fgLuminance = relativeLuminance(of: foreground)
        let bgLuminance = relativeLuminance(of: background)

        let lighter = max(fgLuminance, bgLuminance)
        let darker = min(fgLuminance, bgLuminance)

        return (lighter + 0.05) / (darker + 0.05)
    }

    /// Checks if colors meet WCAG 2.1 Level AA requirements (≥4.5:1)
    ///
    /// - Parameters:
    ///   - foreground: The foreground color (typically text)
    ///   - background: The background color
    /// - Returns: `true` if contrast ratio is ≥4.5:1
    ///
    /// ## Example
    /// ```swift
    /// let meetsAA = AccessibilityHelpers.meetsWCAG_AA(
    ///     foreground: .black,
    ///     background: DS.Colors.infoBG
    /// )
    /// ```
    public static func meetsWCAG_AA(foreground: Color, background: Color) -> Bool {
        contrastRatio(foreground: foreground, background: background) >= 4.5
    }

    /// Checks if colors meet WCAG 2.1 Level AAA requirements (≥7:1)
    ///
    /// - Parameters:
    ///   - foreground: The foreground color (typically text)
    ///   - background: The background color
    /// - Returns: `true` if contrast ratio is ≥7:1
    ///
    /// ## Example
    /// ```swift
    /// let meetsAAA = AccessibilityHelpers.meetsWCAG_AAA(
    ///     foreground: .black,
    ///     background: .white
    /// )
    /// // true (21:1 exceeds 7:1 requirement)
    /// ```
    public static func meetsWCAG_AAA(foreground: Color, background: Color) -> Bool {
        contrastRatio(foreground: foreground, background: background) >= 7.0
    }

    // MARK: - VoiceOver Hint Builders

    /// Builds a VoiceOver hint for an action
    ///
    /// - Parameters:
    ///   - action: The action verb (e.g., "copy", "expand", "activate")
    ///   - target: The target of the action (e.g., "value", "section", "button")
    /// - Returns: A formatted VoiceOver hint string
    ///
    /// ## Example
    /// ```swift
    /// let hint = AccessibilityHelpers.voiceOverHint(
    ///     action: "copy",
    ///     target: "value"
    /// )
    /// // "Double tap to copy value"
    /// ```
    public static func voiceOverHint(action: String, target: String) -> String {
        "Double tap to \(action) \(target)"
    }

    /// Builds a VoiceOver hint using a result builder
    ///
    /// - Parameter builder: A closure that builds the hint text
    /// - Returns: The combined hint string
    ///
    /// ## Example
    /// ```swift
    /// let hint = AccessibilityHelpers.buildVoiceOverHint {
    ///     "Double tap to "
    ///     "activate"
    /// }
    /// ```
    public static func buildVoiceOverHint(@StringBuilder _ builder: () -> String) -> String {
        builder()
    }

    // MARK: - Touch Target Validation

    /// Validates touch target size against iOS HIG requirements (≥44×44 pt)
    ///
    /// - Parameter size: The size of the touch target
    /// - Returns: `true` if both width and height are ≥44 pt
    ///
    /// ## Example
    /// ```swift
    /// let isValid = AccessibilityHelpers.isValidTouchTarget(
    ///     size: CGSize(width: 44, height: 44)
    /// )
    /// // true
    /// ```
    public static func isValidTouchTarget(size: CGSize) -> Bool {
        let minimumSize: CGFloat = 44.0
        return size.width >= minimumSize && size.height >= minimumSize
    }

    // MARK: - Accessibility Label Validation

    /// Validates accessibility label quality
    ///
    /// - Parameter label: The accessibility label to validate
    /// - Returns: `true` if label is non-empty and meaningful (≥2 characters)
    ///
    /// ## Example
    /// ```swift
    /// let isValid = AccessibilityHelpers.isValidAccessibilityLabel("Copy Value")
    /// // true
    ///
    /// let isInvalid = AccessibilityHelpers.isValidAccessibilityLabel("X")
    /// // false (too short)
    /// ```
    public static func isValidAccessibilityLabel(_ label: String) -> Bool {
        !label.isEmpty && label.count >= 2
    }

    // MARK: - Accessibility Audit

    /// Result of an accessibility audit
    public struct AuditResult {
        /// Whether the view passes all accessibility criteria
        public let passes: Bool

        /// List of specific accessibility issues found
        public let issues: [String]

        /// Creates a new audit result
        public init(passes: Bool, issues: [String]) {
            self.passes = passes
            self.issues = issues
        }
    }

    /// Performs a comprehensive accessibility audit
    ///
    /// - Parameters:
    ///   - hasLabel: Whether the view has an accessibility label
    ///   - hasHint: Whether the view has an accessibility hint
    ///   - touchTargetSize: The size of the touch target
    ///   - contrastRatio: The contrast ratio of foreground/background
    /// - Returns: An audit result with pass/fail status and issues
    ///
    /// ## Example
    /// ```swift
    /// let audit = AccessibilityHelpers.auditView(
    ///     hasLabel: true,
    ///     hasHint: true,
    ///     touchTargetSize: CGSize(width: 44, height: 44),
    ///     contrastRatio: 7.0
    /// )
    /// if !audit.passes {
    ///     print("Issues: \(audit.issues)")
    /// }
    /// ```
    public static func auditView(
        hasLabel: Bool, hasHint: Bool, touchTargetSize: CGSize, contrastRatio: CGFloat
    ) -> AuditResult {
        var issues: [String] = []

        if !hasLabel { issues.append("Missing accessibility label") }

        if !hasHint { issues.append("Missing accessibility hint") }

        if !isValidTouchTarget(size: touchTargetSize) {
            issues.append("Touch target too small (minimum 44×44 pt)")
        }

        if contrastRatio < 4.5 {
            issues.append("Insufficient contrast ratio (minimum 4.5:1 for WCAG AA)")
        }

        return AuditResult(passes: issues.isEmpty, issues: issues)
    }

    // MARK: - Focus Management

    /// Represents a focusable element with order
    public struct FocusElement: Identifiable, Equatable {
        /// Unique identifier
        public let id: String

        /// Focus order (1-indexed)
        public let order: Int

        /// Accessibility label
        public let label: String

        /// Creates a new focus element
        public init(id: String, order: Int, label: String) {
            self.id = id
            self.order = order
            self.label = label
        }
    }

    /// Validates focus order for keyboard navigation
    ///
    /// - Parameter elements: Array of focusable elements
    /// - Returns: `true` if focus order is sequential without gaps
    ///
    /// ## Example
    /// ```swift
    /// let elements = [
    ///     AccessibilityHelpers.FocusElement(id: "1", order: 1, label: "First"),
    ///     AccessibilityHelpers.FocusElement(id: "2", order: 2, label: "Second")
    /// ]
    /// let isValid = AccessibilityHelpers.isValidFocusOrder(elements)
    /// // true
    /// ```
    public static func isValidFocusOrder(_ elements: [FocusElement]) -> Bool {
        guard !elements.isEmpty else { return true }

        let sorted = elements.sorted { $0.order < $1.order }

        // Check for sequential ordering starting from 1
        for (index, element) in sorted.enumerated() where element.order != index + 1 {
            return false
        }

        return true
    }

    // MARK: - Dynamic Type Support

    /// Scales a value based on Dynamic Type size
    ///
    /// - Parameters:
    ///   - baseValue: The base value at .large size
    ///   - size: The Dynamic Type size
    /// - Returns: The scaled value
    ///
    /// ## Example
    /// ```swift
    /// let scaled = AccessibilityHelpers.scaledValue(16.0, for: .extraExtraLarge)
    /// // Returns value larger than 16.0
    /// ```
    public static func scaledValue(_ baseValue: CGFloat, for size: DynamicTypeSize) -> CGFloat {
        let scaleFactor = scaleFactor(for: size)
        return baseValue * scaleFactor
    }

    /// Checks if a Dynamic Type size is an accessibility size
    ///
    /// - Parameter size: The Dynamic Type size to check
    /// - Returns: `true` if size is accessibility category (≥ .accessibilityMedium)
    ///
    /// ## Example
    /// ```swift
    /// AccessibilityHelpers.isAccessibilitySize(.accessibilityMedium) // true
    /// AccessibilityHelpers.isAccessibilitySize(.large) // false
    /// ```
    public static func isAccessibilitySize(_ size: DynamicTypeSize) -> Bool {
        size >= .accessibilityMedium
    }

    // MARK: - AccessibilityContext Integration

    /// Checks if animations should be performed in the given context
    ///
    /// - Parameter context: The accessibility context
    /// - Returns: `true` if animations are allowed (reduced motion is off)
    ///
    /// ## Example
    /// ```swift
    /// let context = AccessibilityContext(prefersReducedMotion: true)
    /// let shouldAnimate = AccessibilityHelpers.shouldAnimate(in: context)
    /// // false
    /// ```
    public static func shouldAnimate(in context: AccessibilityContext) -> Bool {
        !context.prefersReducedMotion
    }

    /// Returns preferred spacing for the given context
    ///
    /// - Parameter context: The accessibility context
    /// - Returns: Increased spacing if high contrast is preferred
    ///
    /// ## Example
    /// ```swift
    /// let context = AccessibilityContext(prefersIncreasedContrast: true)
    /// let spacing = AccessibilityHelpers.preferredSpacing(in: context)
    /// // Returns DS.Spacing.l instead of DS.Spacing.m
    /// ```
    public static func preferredSpacing(in context: AccessibilityContext) -> CGFloat {
        context.prefersIncreasedContrast ? DS.Spacing.l : DS.Spacing.m
    }

    // MARK: - Private Helpers

    /// Calculates relative luminance of a color (WCAG 2.1 formula)
    private static func relativeLuminance(of color: Color) -> CGFloat {
        #if canImport(UIKit)
            guard let components = UIColor(color).cgColor.components else { return 0 }
        #elseif canImport(AppKit)
            guard let components = NSColor(color).usingColorSpace(.deviceRGB)?.cgColor.components
            else { return 0 }
        #else
            return 0
        #endif

        let r = !components.isEmpty ? gammaCorrect(components[0]) : 0
        let g = components.count > 1 ? gammaCorrect(components[1]) : 0
        let b = components.count > 2 ? gammaCorrect(components[2]) : 0

        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    /// Applies gamma correction to a color component
    private static func gammaCorrect(_ component: CGFloat) -> CGFloat {
        if component <= 0.03928 {
            return component / 12.92
        } else {
            return pow((component + 0.055) / 1.055, 2.4)
        }
    }

    /// Returns scale factor for Dynamic Type size
    ///
    /// @todo #230 Refactor to reduce cyclomatic complexity (currently 18, target: ≤15)
    // swiftlint:disable:next cyclomatic_complexity
    private static func scaleFactor(for size: DynamicTypeSize) -> CGFloat {
        switch size {
        case .xSmall: return 0.8
        case .small: return 0.9
        case .medium: return 0.95
        case .large: return 1.0
        case .xLarge: return 1.1
        case .xxLarge: return 1.2
        case .xxxLarge: return 1.3
        case .accessibilityMedium: return 1.5
        case .accessibilityLarge: return 1.8
        case .accessibilityXLarge: return 2.0
        case .accessibilityXxLarge: return 2.3
        case .accessibilityXxxLarge: return 2.5
        case .accessibility1: return 1.5
        case .accessibility2: return 1.8
        case .accessibility3: return 2.0
        case .accessibility4: return 2.3
        case .accessibility5: return 2.5
        @unknown default: return 1.0
        }
    }
}

// MARK: - Result Builder

/// Result builder for constructing VoiceOver hints
@resultBuilder public struct StringBuilder {
    public static func buildBlock(_ components: String...) -> String { components.joined() }
}

// MARK: - View Extensions

extension View {
    /// Applies accessible button modifiers
    ///
    /// - Parameters:
    ///   - label: The accessibility label
    ///   - hint: The accessibility hint
    /// - Returns: A view with accessibility modifiers applied
    ///
    /// ## Example
    /// ```swift
    /// Text("Copy")
    ///     .accessibleButton(
    ///         label: "Copy Value",
    ///         hint: "Copies the value to clipboard"
    ///     )
    /// ```
    public func accessibleButton(label: String, hint: String) -> some View {
        accessibilityLabel(label).accessibilityHint(hint).accessibilityAddTraits(.isButton)
    }

    /// Applies accessible toggle modifiers
    ///
    /// - Parameters:
    ///   - label: The accessibility label
    ///   - isOn: Whether the toggle is on
    /// - Returns: A view with accessibility modifiers applied
    ///
    /// ## Example
    /// ```swift
    /// Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
    ///     .accessibleToggle(label: "Section", isOn: isExpanded)
    /// ```
    public func accessibleToggle(label: String, isOn: Bool) -> some View {
        accessibilityLabel(label).accessibilityValue(isOn ? "On" : "Off").accessibilityAddTraits(
            .isButton)
    }

    /// Applies accessible heading modifiers
    ///
    /// - Parameter level: The heading level (1-6)
    /// - Returns: A view with heading accessibility trait
    ///
    /// ## Example
    /// ```swift
    /// Text("Title")
    ///     .accessibleHeading(level: 1)
    /// ```
    public func accessibleHeading(level _: Int) -> some View { accessibilityAddTraits(.isHeader) }

    /// Applies accessible value modifiers for key-value pairs
    ///
    /// - Parameters:
    ///   - label: The accessibility label (key)
    ///   - value: The accessibility value
    /// - Returns: A view with accessibility modifiers applied
    ///
    /// ## Example
    /// ```swift
    /// Text("12345")
    ///     .accessibleValue(label: "Count", value: "12345")
    /// ```
    public func accessibleValue(label: String, value: String) -> some View {
        accessibilityLabel(label).accessibilityValue(value)
    }

    /// Applies focus priority for keyboard navigation
    ///
    /// Uses SwiftUI's `accessibilitySortPriority` to influence the order in which
    /// VoiceOver and other assistive technologies navigate through elements.
    ///
    /// - Parameter priority: The focus priority (low: -1, medium: 0, high: 1)
    /// - Returns: A view with accessibility sort priority applied
    ///
    /// ## Example
    /// ```swift
    /// TextField("Search", text: $query)
    ///     .accessibleFocus(priority: .high)
    /// // This field will be focused before lower-priority elements
    /// ```
    ///
    /// ## Priority Mapping
    /// - `.high`
    /// - `.medium`
    /// - `.low`
    public func accessibleFocus(priority: AccessibilityFocusPriority) -> some View {
        accessibilitySortPriority(priority.rawValue)
    }

    // MARK: - Platform-Specific Extensions

    #if os(macOS)
        /// Enables macOS keyboard navigation
        ///
        /// - Returns: A view with macOS keyboard navigation enabled
        public func macOSKeyboardNavigable() -> some View { focusable() }
    #endif

    #if os(iOS)
        /// Adds entry to iOS VoiceOver rotor
        ///
        /// VoiceOver rotor allows users to quickly navigate between specific elements
        /// (like headings, links, buttons) by rotating two fingers on the screen.
        ///
        /// - Parameter entry: The rotor entry name describing the element type
        /// - Returns: A view with VoiceOver rotor entry
        ///
        /// ## Example
        /// ```swift
        /// Text("Section Title")
        ///     .font(.headline)
        ///     .voiceOverRotor(entry: "Heading")
        /// ```
        public func voiceOverRotor(entry: String) -> some View {
            accessibilityAddTraits(.isHeader).accessibilityLabel(entry)
        }
    #endif
}

// MARK: - Accessibility Focus Priority

/// Priority for accessibility focus in navigation order
///
/// Determines the order in which VoiceOver and other assistive technologies
/// navigate through UI elements. Higher priority elements are focused first.
///
/// ## Priority Values
/// - `.high`
/// - `.medium`
/// - `.low`
///
/// ## Usage
/// ```swift
/// VStack {
///     TextField("Search", text: $query)
///         .accessibleFocus(priority: .high)  // Focused first
///
///     Button("Submit") {}
///         .accessibleFocus(priority: .medium)  // Default order
///
///     Text("Help text")
///         .accessibleFocus(priority: .low)  // Focused last
/// }
/// ```
public enum AccessibilityFocusPriority {
    case low
    case medium
    case high

    /// Maps priority to SwiftUI's accessibilitySortPriority value
    var rawValue: Double {
        switch self {
        case .low: return -1.0
        case .medium: return 0.0
        case .high: return 1.0
        }
    }
}

// MARK: - SwiftUI Previews

#if DEBUG && canImport(SwiftUI)
    import SwiftUI

    #Preview("Accessibility Helpers Demo") {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.l) {
                // Contrast Ratio Demo
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text("Contrast Ratio Validation").font(DS.Typography.headline)
                        .accessibleHeading(level: 1)

                    HStack {
                        Text("Black on White")
                        Spacer()
                        Text(
                            "\(AccessibilityHelpers.contrastRatio(foreground: .black, background: .white), specifier: "%.1f"):1"
                        ).foregroundColor(DS.Colors.accent)
                    }

                    HStack {
                        Text("DS.Colors.infoBG")
                        Spacer()
                        Text(
                            AccessibilityHelpers.meetsWCAG_AA(
                                foreground: .black, background: DS.Colors.infoBG)
                                ? "✓ AA" : "✗ Fail"
                        ).foregroundColor(
                            AccessibilityHelpers.meetsWCAG_AA(
                                foreground: .black, background: DS.Colors.infoBG) ? .green : .red)
                    }
                }.padding(DS.Spacing.m).background(Color.gray.opacity(0.1)).cornerRadius(
                    DS.Radius.medium)

                // VoiceOver Hints Demo
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text("VoiceOver Hints").font(DS.Typography.headline).accessibleHeading(level: 1)

                    Button("Copy Value") {}.accessibleButton(
                        label: "Copy Value",
                        hint: AccessibilityHelpers.voiceOverHint(action: "copy", target: "value")
                    ).padding(DS.Spacing.s).background(DS.Colors.infoBG).cornerRadius(
                        DS.Radius.small)

                    Button("Expand Section") {}.accessibleToggle(label: "Section", isOn: false)
                        .padding(DS.Spacing.s).background(DS.Colors.warnBG).cornerRadius(
                            DS.Radius.small)
                }.padding(DS.Spacing.m).background(Color.gray.opacity(0.1)).cornerRadius(
                    DS.Radius.medium)

                // Touch Target Validation Demo
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text("Touch Target Validation").font(DS.Typography.headline).accessibleHeading(
                        level: 1)

                    HStack {
                        Text("44×44 pt")
                        Spacer()
                        Text(
                            AccessibilityHelpers.isValidTouchTarget(
                                size: CGSize(width: 44, height: 44)) ? "✓ Valid" : "✗ Invalid"
                        ).foregroundColor(.green)
                    }

                    HStack {
                        Text("30×30 pt")
                        Spacer()
                        Text(
                            AccessibilityHelpers.isValidTouchTarget(
                                size: CGSize(width: 30, height: 30)) ? "✓ Valid" : "✗ Invalid"
                        ).foregroundColor(.red)
                    }
                }.padding(DS.Spacing.m).background(Color.gray.opacity(0.1)).cornerRadius(
                    DS.Radius.medium)

                // Accessibility Audit Demo
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text("Accessibility Audit").font(DS.Typography.headline).accessibleHeading(
                        level: 1)

                    let goodAudit = AccessibilityHelpers.auditView(
                        hasLabel: true, hasHint: true,
                        touchTargetSize: CGSize(width: 44, height: 44), contrastRatio: 7.0)

                    HStack {
                        Text("Good View")
                        Spacer()
                        Text(goodAudit.passes ? "✓ Passes" : "✗ Fails").foregroundColor(.green)
                    }

                    let badAudit = AccessibilityHelpers.auditView(
                        hasLabel: false, hasHint: false,
                        touchTargetSize: CGSize(width: 20, height: 20), contrastRatio: 2.0)

                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        HStack {
                            Text("Bad View")
                            Spacer()
                            Text(badAudit.passes ? "✓ Passes" : "✗ Fails").foregroundColor(.red)
                        }

                        ForEach(badAudit.issues, id: \.self) { issue in
                            Text("• \(issue)").font(DS.Typography.caption).foregroundColor(.red)
                        }
                    }
                }.padding(DS.Spacing.m).background(Color.gray.opacity(0.1)).cornerRadius(
                    DS.Radius.medium)
            }.padding(DS.Spacing.l)
        }
    }

    #Preview("Dynamic Type Scaling") {
        VStack(spacing: DS.Spacing.l) {
            ForEach([DynamicTypeSize.large, .xLarge, .xxLarge, .accessibilityMedium], id: \.self) {
                size in
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text("\(String(describing: size))").font(DS.Typography.headline)

                    Text(
                        "Base: 16.0 → Scaled: \(AccessibilityHelpers.scaledValue(16.0, for: size), specifier: "%.1f")"
                    ).font(DS.Typography.body)

                    Text(
                        AccessibilityHelpers.isAccessibilitySize(size)
                            ? "Accessibility Size" : "Normal Size"
                    ).font(DS.Typography.caption).foregroundColor(
                        AccessibilityHelpers.isAccessibilitySize(size) ? .orange : .gray)
                }.padding(DS.Spacing.m).background(Color.gray.opacity(0.1)).cornerRadius(
                    DS.Radius.medium)
            }
        }.padding(DS.Spacing.l)
    }

    #Preview("AccessibilityContext Integration") {
        let reducedMotionContext = AccessibilityContext(
            prefersReducedMotion: true, prefersIncreasedContrast: false)

        let highContrastContext = AccessibilityContext(
            prefersReducedMotion: false, prefersIncreasedContrast: true)

        VStack(spacing: DS.Spacing.l) {
            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                Text("Reduced Motion Context").font(DS.Typography.headline)

                Text(
                    "Should Animate: \(AccessibilityHelpers.shouldAnimate(in: reducedMotionContext) ? "Yes" : "No")"
                )
                Text(
                    "Preferred Spacing: \(AccessibilityHelpers.preferredSpacing(in: reducedMotionContext), specifier: "%.0f") pt"
                )
            }.padding(DS.Spacing.m).background(Color.blue.opacity(0.1)).cornerRadius(
                DS.Radius.medium)

            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                Text("High Contrast Context").font(DS.Typography.headline)

                Text(
                    "Should Animate: \(AccessibilityHelpers.shouldAnimate(in: highContrastContext) ? "Yes" : "No")"
                )
                Text(
                    "Preferred Spacing: \(AccessibilityHelpers.preferredSpacing(in: highContrastContext), specifier: "%.0f") pt"
                )
            }.padding(DS.Spacing.m).background(Color.orange.opacity(0.1)).cornerRadius(
                DS.Radius.medium)
        }.padding(DS.Spacing.l)
    }
#endif
