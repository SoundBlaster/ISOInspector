import FoundationUI
import SwiftUI

struct IndicatorScreen: View {
    @State private var selectedLevel: BadgeLevel = .info
    @State private var selectedSize: Indicator.Size = .small
    @State private var includeReason = true
    @State private var includeTooltip = true
    @State private var tooltipStyle: Indicator.TooltipStyle = .automatic

    private var sampleReason: String? {
        includeReason ? "\(selectedLevel.accessibilityLabel) condition" : nil
    }

    private var sampleTooltip: Indicator.Tooltip? {
        guard includeTooltip else { return nil }
        return .badge(text: "\(selectedLevel.accessibilityLabel) detected", level: selectedLevel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Indicator Component").font(DS.Typography.title)
                    Text(
                        "Semantic, tooltip-enabled status dots that mirror Badge levels for compact surfaces such as inspectors and tables."
                    ).font(DS.Typography.body).foregroundStyle(.secondary)
                }

                Divider()

                controlsSection

                Divider()

                showcaseSection

                Divider()

                accessibilitySection

                Divider()

                apiSection
            }.padding(DS.Spacing.l).indicatorTooltipStyle(tooltipStyle)
        }.navigationTitle("Indicator Component")#if os(macOS)
            .frame(minWidth: 600, minHeight: 500)
            #endif
    }

    private var controlsSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text("Controls").font(DS.Typography.subheadline)

            Picker("Level", selection: $selectedLevel) {
                Text("Info").tag(BadgeLevel.info)
                Text("Warning").tag(BadgeLevel.warning)
                Text("Error").tag(BadgeLevel.error)
                Text("Success").tag(BadgeLevel.success)
            }.pickerStyle(.segmented)

            Picker("Size", selection: $selectedSize) {
                Text("Mini").tag(Indicator.Size.mini)
                Text("Small").tag(Indicator.Size.small)
                Text("Medium").tag(Indicator.Size.medium)
            }.pickerStyle(.segmented)

            Toggle("Include Reason (VoiceOver hint)", isOn: $includeReason)
            Toggle("Include Tooltip", isOn: $includeTooltip)

            Picker("Tooltip Style", selection: $tooltipStyle) {
                Text("Automatic").tag(Indicator.TooltipStyle.automatic)
                Text("Text").tag(Indicator.TooltipStyle.text)
                Text("Badge").tag(Indicator.TooltipStyle.badge)
                Text("Disabled").tag(Indicator.TooltipStyle.none)
            }.pickerStyle(.segmented).disabled(!includeTooltip)
        }
    }

    private var showcaseSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.l) {
            Text("Live Preview").font(DS.Typography.subheadline)

            HStack(spacing: DS.Spacing.l) {
                Indicator(
                    level: selectedLevel, size: selectedSize, reason: sampleReason,
                    tooltip: sampleTooltip)
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text("Level: \(levelLabel(selectedLevel))")
                    Text("Size: \(sizeLabel(selectedSize))")
                    Text("Reason: \(sampleReason ?? "None")")
                    Text("Tooltip: \(includeTooltip ? "Enabled" : "None")")
                }.font(DS.Typography.caption)
            }

            Text("All Variants").font(DS.Typography.subheadline)

            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                ForEach(Indicator.Size.allCases, id: \.self) { size in
                    HStack(spacing: DS.Spacing.l) {
                        Text(sizeLabel(size)).font(DS.Typography.body).frame(
                            width: 80, alignment: .leading)
                        HStack(spacing: DS.Spacing.m) {
                            Indicator(
                                level: .info, size: size, reason: "Healthy",
                                tooltip: .text("All checks passed"))
                            Indicator(
                                level: .warning, size: size, reason: "Warning found",
                                tooltip: .text("Needs review"))
                            Indicator(
                                level: .error, size: size, reason: "Blocking issue",
                                tooltip: .badge(text: "Failed validation", level: .error))
                            Indicator(
                                level: .success, size: size, reason: "Complete",
                                tooltip: .badge(text: "Tests passed", level: .success))
                        }
                    }
                }
            }

            CodeSnippetView(
                code: """
                    Indicator(
                        level: .\(levelLabel(selectedLevel, lowercase: true)),
                        size: .\(sizeLabel(selectedSize, lowercase: true)),
                        reason: \(reasonSnippet),
                        tooltip: \(tooltipSnippet)
                    )
                    """)
        }
    }

    private var accessibilitySection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text("Accessibility & Guidance").font(DS.Typography.subheadline)

            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                Text("• Touch targets expand to meet HIG guidance (44×44pt on touch platforms).")
                Text("• VoiceOver label combines level with optional reason text.")
                Text("• Tooltip content becomes the accessibility hint when no reason is supplied.")
                Text("• Animations respect Reduce Motion preferences.")
            }.font(DS.Typography.caption).foregroundStyle(.secondary)
        }
    }

    private var apiSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text("Component API").font(DS.Typography.subheadline)

            CodeSnippetView(
                code: """
                    Indicator(
                        level: BadgeLevel,
                        size: Indicator.Size = .small,
                        reason: String? = nil,
                        tooltip: Indicator.Tooltip? = nil
                    )
                    """)
        }
    }

    private func levelLabel(_ level: BadgeLevel, lowercase: Bool = false) -> String {
        let label: String
        switch level {
        case .info: label = "Info"
        case .warning: label = "Warning"
        case .error: label = "Error"
        case .success: label = "Success"
        }
        return lowercase ? label.lowercased() : label
    }

    private func sizeLabel(_ size: Indicator.Size, lowercase: Bool = false) -> String {
        let label: String
        switch size {
        case .mini: label = "Mini"
        case .small: label = "Small"
        case .medium: label = "Medium"
        }
        return lowercase ? label.lowercased() : label
    }

    private var reasonSnippet: String { sampleReason.map { "\"\($0)\"" } ?? "nil" }

    private var tooltipSnippet: String {
        guard includeTooltip else { return "nil" }
        let level = levelLabel(selectedLevel, lowercase: true)
        return """
            Indicator.Tooltip.badge(
                text: "\(selectedLevel.accessibilityLabel) detected",
                level: .\(level)
            )
            """
    }
}

#Preview { NavigationStack { IndicatorScreen() } }
