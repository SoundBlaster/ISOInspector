// @todo #239 Fix SwiftFormat/SwiftLint indentation conflict for multi-line if conditions
// swiftlint:disable indentation_width

import SwiftUI

/// A semantic status indicator that visualizes ``BadgeLevel`` without text.
///
/// The indicator renders a circular dot that reuses the badge color system,
/// supports platform-aware tooltips, and maintains minimum touch target sizes.
/// It is designed for dashboards, inspectors, and compact metadata displays
/// where textual badges would be too heavy.
public struct Indicator: View, Sendable {
    /// The semantic level conveyed by the indicator.
    public let level: BadgeLevel

    /// Size preset that determines the rendered diameter.
    public let size: Size

    /// Optional textual reason surfaced in accessibility metadata.
    public let reason: String?

    /// Optional tooltip content presented on hover/long-press.
    public let tooltip: Tooltip?

    @Environment(\.indicatorTooltipStyle) private var tooltipStyle
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Creates a new status indicator.
    ///
    /// - Parameters:
    ///   - level: Semantic level (info, warning, error, success).
    ///   - size: Indicator size preset. Defaults to ``Indicator/Size/small``.
    ///   - reason: Optional description exposed to assistive technologies.
    ///   - tooltip: Optional tooltip describing the status.
    public init(
        level: BadgeLevel, size: Size = .small, reason: String? = nil, tooltip: Tooltip? = nil
    ) {
        self.level = level
        self.size = size
        self.reason = reason
        self.tooltip = tooltip
    }

    public var body: some View {
        let accessibilityConfiguration = AccessibilityConfiguration.make(
            level: level, reason: reason, tooltip: tooltip)

        return Circle().fill(level.foregroundColor).frame(
            width: size.diameter, height: size.diameter
        ).overlay(Circle().stroke(level.backgroundColor, lineWidth: size.haloThickness)).padding(
            size.hitPadding
        ).frame(minWidth: size.minimumHitTarget.width, minHeight: size.minimumHitTarget.height)
            .contentShape(Circle()).modifier(
                IndicatorTooltipModifier(
                    style: tooltipStyle, tooltip: tooltip, fallbackLevel: level)
            ).animation(reduceMotion ? nil : DS.Animation.quick, value: level).accessibilityElement(
                children: .ignore
            ).accessibilityLabel(accessibilityConfiguration.label).modifier(
                OptionalAccessibilityHintModifier(hint: accessibilityConfiguration.hint)
            ).accessibilityAddTraits(.isImage)
    }
}

// MARK: - Size

extension Indicator {
    /// Indicator size presets.
    public enum Size: CaseIterable, Equatable, Sendable {
        /// Compact indicator sized with ``DS/Spacing/s``.
        case mini
        /// Default indicator sized with ``DS/Spacing/m``.
        case small
        /// Prominent indicator sized with ``DS/Spacing/l``.
        case medium

        /// Rendered diameter derived from design tokens.
        public var diameter: CGFloat {
            switch self {
            case .mini: DS.Spacing.s
            case .small: DS.Spacing.m
            case .medium: DS.Spacing.l
            }
        }

        /// Halo thickness for the outline stroke.
        var haloThickness: CGFloat { DS.Spacing.s / 2 }

        /// Minimum hit target size for accessibility compliance.
        var minimumHitTarget: CGSize {
            #if os(iOS) || os(tvOS)
                let minimum = PlatformAdapter.minimumTouchTarget
                return CGSize(width: minimum, height: minimum)
            #else
                let length = DS.Spacing.xl + DS.Spacing.m + DS.Spacing.s
                return CGSize(width: length, height: length)
            #endif
        }

        /// Padding applied to reach the minimum touch target.
        var hitPadding: CGFloat {
            let targetWidth = minimumHitTarget.width
            let padding = (targetWidth - diameter) / 2
            return max(padding, 0)
        }

        /// Agent-friendly string identifier.
        var stringValue: String {
            switch self {
            case .mini: "mini"
            case .small: "small"
            case .medium: "medium"
            }
        }
    }
}

// MARK: - Tooltip

extension Indicator {
    /// Tooltip payload describing an indicator state.
    public struct Tooltip: Equatable, Sendable {
        /// Tooltip content variants.
        public enum Content: Equatable, Sendable {
            /// Plain textual tooltip.
            case text(String)
            /// Badge-styled tooltip content.
            case badge(text: String, level: BadgeLevel)
        }

        /// Underlying tooltip content.
        public let content: Content

        private init(content: Content) { self.content = content }

        /// Creates a textual tooltip.
        public static func text(_ value: String) -> Tooltip { Tooltip(content: .text(value)) }

        /// Creates a badge tooltip with semantic styling.
        public static func badge(text: String, level: BadgeLevel) -> Tooltip {
            Tooltip(content: .badge(text: text, level: level))
        }

        /// Preferred content for the given style.
        ///
        /// - Parameters:
        ///   - style: Tooltip style preference.
        ///   - fallbackLevel: Level used when converting badge content.
        /// - Returns: Resolved tooltip content.
        func preferredContent(style: Indicator.TooltipStyle, fallbackLevel: BadgeLevel) -> Content {
            switch style {
            case .automatic: content
            case .text:
                switch content {
                case .badge(let text, _): .text(text)
                case .text: content
                }
            case .badge:
                switch content {
                case .badge: content
                case .text(let text): .badge(text: text, level: fallbackLevel)
                }
            case .none: .text("")
            }
        }

        /// Accessibility-friendly text description.
        var accessibilityHint: String? {
            switch content {
            case .text(let value): value
            case .badge(let text, _): text
            }
        }

        /// Agent metadata describing the tooltip.
        var agentPayload: [String: Any] {
            switch content {
            case .text(let value): ["kind": "text", "value": value]
            case .badge(let text, let level):
                ["kind": "badge", "text": text, "level": level.stringValue]
            }
        }
    }

    /// Tooltip presentation style environment value.
    public enum TooltipStyle: Equatable, Sendable {
        /// Automatically uses the provided tooltip content.
        case automatic
        /// Forces textual presentation.
        case text
        /// Prefers badge presentation when available.
        case badge
        /// Disables tooltips.
        case none
    }
}

// MARK: - Accessibility

extension Indicator {
    /// Accessibility metadata describing the indicator.
    public struct AccessibilityConfiguration: Equatable, Sendable {
        /// VoiceOver label for the indicator.
        public let label: String
        /// Optional VoiceOver hint.
        public let hint: String?

        /// Builds accessibility metadata from the provided inputs.
        ///
        /// - Parameters:
        ///   - level: Badge level associated with the indicator.
        ///   - reason: Optional human-readable reason.
        ///   - tooltip: Optional tooltip providing additional context.
        /// - Returns: Accessibility configuration containing label and hint.
        public static func make(level: BadgeLevel, reason: String?, tooltip: Tooltip?)
            -> AccessibilityConfiguration {
            let sanitizedReason = reason?.trimmingCharacters(in: .whitespacesAndNewlines)
            let baseLabel = "\(level.accessibilityLabel) indicator"
            let label: String =
                if let sanitizedReason, !sanitizedReason.isEmpty {
                    "\(baseLabel) — \(sanitizedReason)"
                } else { baseLabel }

            if let sanitizedReason, !sanitizedReason.isEmpty {
                return AccessibilityConfiguration(label: label, hint: sanitizedReason)
            }

            if let tooltipHint = tooltip?.accessibilityHint?.trimmingCharacters(
                in: .whitespacesAndNewlines), !tooltipHint.isEmpty {
                return AccessibilityConfiguration(label: label, hint: tooltipHint)
            }

            return AccessibilityConfiguration(label: label, hint: nil)
        }
    }
}

// MARK: - Environment

private struct IndicatorTooltipStyleKey: EnvironmentKey {
    static let defaultValue: Indicator.TooltipStyle = .automatic
}

extension EnvironmentValues {
    /// Controls how indicator tooltips are rendered.
    public var indicatorTooltipStyle: Indicator.TooltipStyle {
        get { self[IndicatorTooltipStyleKey.self] }
        set { self[IndicatorTooltipStyleKey.self] = newValue }
    }
}

extension View {
    /// Overrides the tooltip style for nested indicators.
    public func indicatorTooltipStyle(_ style: Indicator.TooltipStyle) -> some View {
        environment(\.indicatorTooltipStyle, style)
    }
}

// MARK: - View Modifiers

private struct IndicatorTooltipModifier: ViewModifier {
    let style: Indicator.TooltipStyle
    let tooltip: Indicator.Tooltip?
    let fallbackLevel: BadgeLevel

    @ViewBuilder func body(content: Content) -> some View {
        if let tooltip {
            let resolvedContent = tooltip.preferredContent(
                style: style, fallbackLevel: fallbackLevel)
            switch resolvedContent {
            case .text(let value): applyTextTooltip(value: value, to: content)
            case .badge(let text, let level):
                applyBadgeTooltip(text: text, level: level, to: content)
            }
        } else {
            content
        }
    }

    @ViewBuilder private func applyTextTooltip(value: String, to content: Content) -> some View {
        switch style {
        case .none: content
        default:
            #if os(macOS)
                content.help(value)
            #elseif os(iOS) || os(tvOS)
                content.contextMenu { Text(value) }
            #else
                content
            #endif
        }
    }

    @ViewBuilder private func applyBadgeTooltip(
        text: String, level: BadgeLevel, to content: Content
    ) -> some View {
        switch style {
        case .none: content
        default:
            #if os(macOS)
                content.help(text)
            #elseif os(iOS) || os(tvOS)
                content.contextMenu { Badge(text: text, level: level) }
            #else
                content
            #endif
        }
    }
}

private struct OptionalAccessibilityHintModifier: ViewModifier {
    let hint: String?

    func body(content: Content) -> some View {
        if let hint { content.accessibilityHint(hint) } else { content }
    }
}

// @todo: Add macOS hover effect previews once CI can build SwiftUI previews.

#if canImport(SwiftUI)
    @available(iOS 17.0, macOS 14.0, *) @MainActor extension Indicator: AgentDescribable {
        public var componentType: String { "Indicator" }

        public var properties: [String: Any] {
            var values: [String: Any] = ["level": level.stringValue, "size": size.stringValue]

            if let reason, !reason.isEmpty { values["reason"] = reason }

            if let tooltip { values["tooltip"] = tooltip.agentPayload }

            return values
        }

        public var semantics: String {
            if let reason, !reason.isEmpty {
                return "\(level.accessibilityLabel) indicator — \(reason)"
            }
            return "\(level.accessibilityLabel) indicator"
        }
    }
#endif

#Preview("Indicator Levels") {
    VStack(spacing: DS.Spacing.m) {
        ForEach(BadgeLevel.allCases, id: \.self) { level in
            Indicator(level: level, size: .small, reason: level.accessibilityLabel)
        }
    }.padding(DS.Spacing.l)
}

#Preview("Indicator Sizes") {
    HStack(spacing: DS.Spacing.m) {
        Indicator(level: .info, size: .mini, reason: "Idle")
        Indicator(level: .warning, size: .small, reason: "Processing")
        Indicator(
            level: .error, size: .medium, reason: "Failure",
            tooltip: .badge(text: "Integrity failure", level: .error))
    }.padding(DS.Spacing.l).indicatorTooltipStyle(.badge)
}
