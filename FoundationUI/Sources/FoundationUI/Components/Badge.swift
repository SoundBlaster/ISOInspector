import SwiftUI

/// A semantic badge component for displaying status, categories, or metadata
///
/// The Badge component provides a simple, reusable UI element that displays
/// text with semantic color coding (info, warning, error, success). It uses
/// the BadgeChipStyle modifier internally to ensure consistent styling across
/// the application.
///
/// ## Design System Integration
/// Badge uses the following Design System tokens:
/// - **Colors**: `DS.Colors.infoBG`, `DS.Colors.warnBG`, `DS.Colors.errorBG`, `DS.Colors.successBG`
/// - **Spacing**: `DS.Spacing.s`, `DS.Spacing.m` (via BadgeChipStyle)
/// - **Radius**: `DS.Radius.chip` (via BadgeChipStyle)
/// - **Typography**: `.caption.weight(.medium)` (via BadgeChipStyle)
///
/// ## Usage
/// ```swift
/// // Basic usage with different levels
/// Badge(text: "NEW", level: .info)
/// Badge(text: "WARNING", level: .warning)
/// Badge(text: "ERROR", level: .error)
/// Badge(text: "SUCCESS", level: .success)
///
/// // In a layout
/// HStack {
///     Text("File Type:")
///     Badge(text: "VALID", level: .success)
/// }
///
/// // With icon
/// Badge(text: "Alert", level: .warning, showIcon: true)
/// ```
///
/// ## Accessibility
/// Each badge level provides:
/// - Semantic VoiceOver labels ("Information", "Warning", "Error", "Success")
/// - WCAG 2.1 AA compliant contrast ratios (≥4.5:1)
/// - Automatic color adaptation for Light and Dark mode
/// - Support for Dynamic Type text scaling
///
/// ## Platform Support
/// - iOS 17.0+
/// - iPadOS 17.0+
/// - macOS 14.0+
///
/// ## See Also
/// - ``BadgeLevel``
/// - ``BadgeChipStyle``
/// - ``DS/Colors``
public struct Badge: View {
    // MARK: - Properties

    /// The text content displayed in the badge
    public let text: String?

    /// The semantic level of the badge (info, warning, error, success)
    public let level: BadgeLevel

    /// Whether to show an icon alongside the text
    public let showIcon: Bool

    // MARK: - Initialization

    /// Creates a new Badge component
    ///
    /// ## Example
    /// ```swift
    /// Badge(text: "NEW", level: .info)
    /// Badge(text: "ERROR", level: .error, showIcon: true)
    /// ```
    ///
    /// ## Parameters
    /// - text: The text content to display in the badge
    /// - level: The semantic level that determines the badge's color and accessibility label
    /// - showIcon: Whether to display an SF Symbol icon (default: false)
    ///
    /// ## Accessibility
    /// The badge will automatically receive an accessibility label based on the level:
    /// - `.info` → "Information: {text}"
    /// - `.warning` → "Warning: {text}"
    /// - `.error` → "Error: {text}"
    /// - `.success` → "Success: {text}"
    ///
    /// Passing `nil` or an empty string for `text` renders an icon-only badge while
    /// keeping accessibility labels intact.
    public init(text: String?, level: BadgeLevel, showIcon: Bool = false) {
        self.text = text
        self.level = level
        self.showIcon = showIcon
    }

    /// Creates an icon-only Badge component
    ///
    /// ## Example
    /// ```swift
    /// Badge(level: .warning, showIcon: true)
    /// ```
    ///
    /// - Parameters
    ///   - level: The semantic level that determines the badge's color and accessibility label
    ///   - showIcon: Whether to display an SF Symbol icon (default: false)
    public init(level: BadgeLevel, showIcon: Bool = false) {
        self.init(text: nil, level: level, showIcon: showIcon)
    }

    // MARK: - Body

    public var body: some View {
        Text(displayText)
            .badgeChipStyle(level: level, showIcon: showIcon, hasText: hasText)
            .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Helpers

    private var hasText: Bool {
        !displayText.isEmpty
    }

    private var semanticsTextDescription: String {
        if hasText {
            return "'\(displayText)'"
        }
        return "(icon only)"
    }

    private var displayText: String {
        text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private var accessibilityLabel: String {
        if hasText {
            return "\(level.accessibilityLabel): \(displayText)"
        }
        return level.accessibilityLabel
    }
}

// MARK: - SwiftUI Previews

#Preview("Badge - All Levels") {
    VStack(spacing: DS.Spacing.l) {
        Badge(text: "INFO", level: .info)
        Badge(text: "WARNING", level: .warning)
        Badge(text: "ERROR", level: .error)
        Badge(text: "SUCCESS", level: .success)
    }
    .padding()
}

#Preview("Badge - With Icons") {
    VStack(spacing: DS.Spacing.l) {
        Badge(text: "Information", level: .info, showIcon: true)
        Badge(text: "Warning", level: .warning, showIcon: true)
        Badge(text: "Error", level: .error, showIcon: true)
        Badge(text: "Success", level: .success, showIcon: true)
    }
    .padding()
}

#Preview("Badge - Dark Mode") {
    VStack(spacing: DS.Spacing.l) {
        Badge(text: "INFO", level: .info)
        Badge(text: "WARNING", level: .warning)
        Badge(text: "ERROR", level: .error)
        Badge(text: "SUCCESS", level: .success)
    }
    .padding()
    .preferredColorScheme(.dark)
}

#Preview("Badge - Various Lengths") {
    VStack(alignment: .leading, spacing: DS.Spacing.m) {
        Badge(text: "OK", level: .success)
        Badge(text: "PENDING", level: .info)
        Badge(text: "ATTENTION REQUIRED", level: .warning)
        Badge(text: "CRITICAL FAILURE", level: .error)
    }
    .padding()
}

#Preview("Badge - Real World Usage") {
    VStack(alignment: .leading, spacing: DS.Spacing.l) {
        // File type indicators
        HStack {
            Text("File Type:")
                .font(.body)
            Badge(text: "VALID", level: .success, showIcon: true)
        }

        // Status indicators
        HStack {
            Text("Status:")
                .font(.body)
            Badge(text: "PROCESSING", level: .info)
        }

        // Validation results
        HStack {
            Text("Validation:")
                .font(.body)
            Badge(text: "FAILED", level: .error, showIcon: true)
        }

        // Warnings
        HStack {
            Text("Check:")
                .font(.body)
            Badge(text: "NEEDS REVIEW", level: .warning, showIcon: true)
        }
    }
    .padding()
}

// MARK: - AgentDescribable Conformance

@available(iOS 17.0, macOS 14.0, *)
@MainActor
extension Badge: AgentDescribable {
    public var componentType: String {
        "Badge"
    }

    public var properties: [String: Any] {
        [
            "text": displayText,
            "level": level.stringValue,
            "showIcon": showIcon,
            "hasText": hasText
        ]
    }

    public var semantics: String {
        """
        A colored badge component displaying \(semanticsTextDescription) at level '\(level.stringValue)'. \
        Shows icon: \(showIcon). \
        Accessibility: '\(level.accessibilityLabel)'.
        """
    }
}

#Preview("Badge - Platform Comparison") {
    VStack(spacing: DS.Spacing.xl) {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            Text("iOS/iPadOS Style")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: DS.Spacing.m) {
                Badge(text: "NEW", level: .info)
                Badge(text: "ALERT", level: .warning, showIcon: true)
            }
        }

        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            Text("macOS Style")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: DS.Spacing.m) {
                Badge(text: "NEW", level: .info)
                Badge(text: "ALERT", level: .warning, showIcon: true)
            }
        }
    }
    .padding()
}

@available(iOS 17.0, macOS 14.0, *)
#Preview("Badge - Agent Integration") {
    VStack(alignment: .leading, spacing: DS.Spacing.l) {
        Text("AgentDescribable Protocol Demo")
            .font(.headline)

        let infoBadge = Badge(text: "INFO", level: .info, showIcon: true)
        infoBadge

        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            Text("Component Type: \(infoBadge.componentType)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Properties: \(String(describing: infoBadge.properties))")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Semantics: \(infoBadge.semantics)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(DS.Radius.small)
    }
    .padding()
}
