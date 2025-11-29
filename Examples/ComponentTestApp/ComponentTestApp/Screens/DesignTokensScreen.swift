/// DesignTokensScreen - Visual Reference for Design Tokens
///
/// Comprehensive visual showcase of all FoundationUI Design System tokens.
/// Provides examples and values for spacing, colors, typography, radius, and animation.
///
/// ## Categories
/// - Spacing: Visual rulers showing s, m, l, xl values
/// - Colors: Color swatches with semantic names and usage
/// - Typography: Font samples showing all text styles
/// - Radius: Corner radius examples on shapes
/// - Animation: Animated examples with timing values

import FoundationUI
import SwiftUI

struct DesignTokensScreen: View {
    @State private var isAnimating = false
    
    /// Whether to override system Dynamic Type with custom setting
    @AppStorage("overrideSystemDynamicType") private var overrideSystemDynamicType: Bool = false
    
    /// Current Dynamic Type size preference (used when override is enabled)
    @AppStorage("dynamicTypeSizePreference") private var dynamicTypeSizePreference:
    DynamicTypeSizePreference = .medium
    
    /// Current system Dynamic Type size (for display purposes)
    @Environment(\.dynamicTypeSize) private var systemDynamicTypeSize
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                
                spacingTokens
                
                Divider()
                
                colorTokens
                
                Divider()
                
                typographyTokens
                
                Divider()
                
                radiusTokens
                
                Divider()
                
                animationTokens
            }
            .padding(DS.Spacing.l)
        }
        .navigationTitle("Design Tokens")
#if os(macOS)
        .frame(minWidth: 600, minHeight: 400)
#endif
    }
}

extension DesignTokensScreen {
    @ViewBuilder
    private var spacingTokens: some View {
        // Spacing Tokens
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text("Spacing")
                .font(DS.Typography.title)
            
            SpacingTokenRow(name: "DS.Spacing.s", value: DS.Spacing.s)
            SpacingTokenRow(name: "DS.Spacing.m", value: DS.Spacing.m)
            SpacingTokenRow(name: "DS.Spacing.l", value: DS.Spacing.l)
            SpacingTokenRow(name: "DS.Spacing.xl", value: DS.Spacing.xl)
        }
    }
}

extension DesignTokensScreen {
    @ViewBuilder
    private var typographyTokens: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text("Typography")
                .font(DS.Typography.title)
            
            // Dynamic Type Controls
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                Text("Dynamic Type Controls")
                    .font(DS.Typography.subheadline)
                    .foregroundStyle(.secondary)
                
                // Override Toggle
                Toggle(isOn: $overrideSystemDynamicType) {
                    HStack {
                        Image(systemName: "textformat.size")
                        Text("Override System Text Size")
                    }
                }
                .padding(DS.Spacing.m)
                .background(DS.Colors.infoBG)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
                
                // Conditional: Show picker or system size
                if overrideSystemDynamicType {
                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        Text("Custom Text Size")
                            .font(DS.Typography.caption)
                            .foregroundStyle(.secondary)
                        
                        Picker("Custom Text Size", selection: $dynamicTypeSizePreference) {
                            Text("XS - Extra Small").tag(DynamicTypeSizePreference.xSmall)
                            Text("S - Small").tag(DynamicTypeSizePreference.small)
                            Text("M - Medium").tag(DynamicTypeSizePreference.medium)
                            Text("L - Large").tag(DynamicTypeSizePreference.large)
                            Text("XL - Extra Large").tag(DynamicTypeSizePreference.xLarge)
                            Text("XXL - Extra Extra Large").tag(
                                DynamicTypeSizePreference.xxLarge)
                            Text("XXXL - Maximum").tag(DynamicTypeSizePreference.xxxLarge)
                            Text("A1 - Accessibility 1").tag(
                                DynamicTypeSizePreference.accessibility1)
                            Text("A2 - Accessibility 2").tag(
                                DynamicTypeSizePreference.accessibility2)
                            Text("A3 - Accessibility 3").tag(
                                DynamicTypeSizePreference.accessibility3)
                            Text("A4 - Accessibility 4").tag(
                                DynamicTypeSizePreference.accessibility4)
                            Text("A5 - Accessibility 5").tag(
                                DynamicTypeSizePreference.accessibility5)
                        }
                        .pickerStyle(.menu)
                    }
                    .padding(DS.Spacing.m)
                    .background(DS.Colors.successBG)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
                } else {
                    HStack {
                        Image(systemName: "gear")
                        Text("Using System Text Size:")
                        Spacer()
                        Text(dynamicTypeSizeLabel(systemDynamicTypeSize))
                            .font(DS.Typography.code)
                            .padding(.horizontal, DS.Spacing.s)
                            .padding(.vertical, DS.Spacing.xxs)
                            .background(DS.Colors.tertiary)
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small))
                    }
                    .padding(DS.Spacing.m)
                    .background(DS.Colors.tertiary)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
                }
            }
            
            Divider()
                .padding(.vertical, DS.Spacing.s)
            
            Text("Typography Samples (affected by controls above)")
                .font(DS.Typography.subheadline)
                .foregroundStyle(.secondary)
            
            // Test: Custom Scalable Text (works on macOS!)
            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                Text("✅ Custom Scaled Text (works on macOS!)")
                    .font(scaledFont(size: 20))
                    .foregroundStyle(.green)
                    .fontWeight(.bold)
                
                Text("This text WILL change size when you change the picker above!")
                    .font(scaledFont(size: 16))
                
                Text(
                    "Current scale: \(String(format: "%.0f%%", fontScaleMultiplier * 100))"
                )
                .font(scaledFont(size: 12))
                .foregroundStyle(.secondary)
            }
            .padding(DS.Spacing.m)
            .background(DS.Colors.successBG)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
            
            TypographyTokenRow(
                name: "DS.Typography.headline", font: DS.Typography.headline,
                sample: "Headline Text")
            TypographyTokenRow(
                name: "DS.Typography.title", font: DS.Typography.title, sample: "Title Text"
            )
            TypographyTokenRow(
                name: "DS.Typography.subheadline", font: DS.Typography.subheadline,
                sample: "Subheadline Text")
            TypographyTokenRow(
                name: "DS.Typography.body", font: DS.Typography.body, sample: "Body Text")
            TypographyTokenRow(
                name: "DS.Typography.caption", font: DS.Typography.caption,
                sample: "Caption Text")
            TypographyTokenRow(
                name: "DS.Typography.label", font: DS.Typography.label, sample: "LABEL TEXT"
            )
            TypographyTokenRow(
                name: "DS.Typography.code", font: DS.Typography.code, sample: "0xDEADBEEF")
        }
    }
}

extension DesignTokensScreen {
    @ViewBuilder
    private var animationTokens: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text("Animation")
                .font(DS.Typography.title)
            
            HStack {
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text("DS.Animation.quick")
                        .font(DS.Typography.code)
                    Text("0.15s snappy")
                        .font(DS.Typography.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button("Animate") {
                    withAnimation(DS.Animation.quick) {
                        isAnimating.toggle()
                    }
                }
            }
            .padding(DS.Spacing.m)
            .background(DS.Colors.tertiary)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small))
            
            AnimationTokenRow(
                name: "DS.Animation.medium", duration: "0.25s",
                animation: DS.Animation.medium, isAnimating: $isAnimating)
            AnimationTokenRow(
                name: "DS.Animation.slow", duration: "0.35s", animation: DS.Animation.slow,
                isAnimating: $isAnimating)
        }
    }
    
    @ViewBuilder
    private var radiusTokens: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text("Corner Radius")
                .font(DS.Typography.title)
            
            RadiusTokenRow(name: "DS.Radius.small", value: DS.Radius.small)
            RadiusTokenRow(name: "DS.Radius.medium", value: DS.Radius.medium)
            RadiusTokenRow(name: "DS.Radius.card", value: DS.Radius.card)
            RadiusTokenRow(name: "DS.Radius.chip", value: DS.Radius.chip)
        }
    }
     
    @ViewBuilder
    private var colorTokens: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Text("Colors")
                .font(DS.Typography.title)
            
            Text("Semantic Backgrounds")
                .font(DS.Typography.subheadline)
                .foregroundStyle(.secondary)
            
            ColorTokenRow(
                name: "DS.Colors.infoBG", color: DS.Colors.infoBG,
                usage: "Neutral information")
            ColorTokenRow(
                name: "DS.Colors.warnBG", color: DS.Colors.warnBG,
                usage: "Warnings, cautions")
            ColorTokenRow(
                name: "DS.Colors.errorBG", color: DS.Colors.errorBG,
                usage: "Errors, failures")
            ColorTokenRow(
                name: "DS.Colors.successBG", color: DS.Colors.successBG,
                usage: "Success, completion")
            
            Text("UI Colors")
                .font(DS.Typography.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, DS.Spacing.m)
            
            ColorTokenRow(
                name: "DS.Colors.accent", color: DS.Colors.accent,
                usage: "Interactive elements")
            ColorTokenRow(
                name: "DS.Colors.secondary", color: DS.Colors.secondary,
                usage: "Supporting elements")
            ColorTokenRow(
                name: "DS.Colors.tertiary", color: DS.Colors.tertiary,
                usage: "Background fills")
        }
    }
}

extension DesignTokensScreen {
    /// Returns human-readable label for Dynamic Type size
    private func dynamicTypeSizeLabel(_ size: DynamicTypeSize) -> String {
        switch size {
        case .xSmall: return "XS"
        case .small: return "S"
        case .medium: return "M"
        case .large: return "L"
        case .xLarge: return "XL"
        case .xxLarge: return "XXL"
        case .xxxLarge: return "XXXL"
        case .accessibility1: return "A1"
        case .accessibility2: return "A2"
        case .accessibility3: return "A3"
        case .accessibility4: return "A4"
        case .accessibility5: return "A5"
        @unknown default: return "M"
        }
    }

    /// Returns font scale multiplier for custom Dynamic Type size
    /// Note: macOS doesn't support .dynamicTypeSize() modifier, so we manually scale
    private var fontScaleMultiplier: CGFloat {
        guard overrideSystemDynamicType else { return 1.0 }

        switch dynamicTypeSizePreference {
        case .xSmall: return 0.7
        case .small: return 0.85
        case .medium: return 1.0
        case .large: return 1.15
        case .xLarge: return 1.3
        case .xxLarge: return 1.5
        case .xxxLarge: return 1.75
        case .accessibility1: return 2.0
        case .accessibility2: return 2.3
        case .accessibility3: return 2.6
        case .accessibility4: return 3.0
        case .accessibility5: return 3.5
        }
    }

    /// Scales a font size based on current Dynamic Type preference
    private func scaledFont(size: CGFloat) -> Font {
        .system(size: size * fontScaleMultiplier)
    }
}

// MARK: - Helper Views

/// Visual representation of a spacing token
struct SpacingTokenRow: View {
    let name: String
    let value: CGFloat

    var body: some View {
        HStack(alignment: .center, spacing: DS.Spacing.m) {
            Text(name)
                .font(DS.Typography.code)
                .frame(width: 140, alignment: .leading)

            Rectangle()
                .fill(DS.Colors.accent)
                .frame(width: value, height: 20)

            Text("\(Int(value))pt")
                .font(DS.Typography.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(DS.Spacing.s)
        .background(DS.Colors.tertiary)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small))
    }
}

/// Visual representation of a color token
struct ColorTokenRow: View {
    let name: String
    let color: Color
    let usage: String

    var body: some View {
        HStack(spacing: DS.Spacing.m) {
            RoundedRectangle(cornerRadius: DS.Radius.small)
                .fill(color)
                .frame(width: 40, height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.small)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                Text(name)
                    .font(DS.Typography.code)
                Text(usage)
                    .font(DS.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(DS.Spacing.s)
        .background(DS.Colors.tertiary)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small))
    }
}

/// Visual representation of a typography token
struct TypographyTokenRow: View {
    let name: String
    let font: Font
    let sample: String

    var body: some View {
        HStack(spacing: DS.Spacing.m) {
            Text(name)
                .font(DS.Typography.code)
                .frame(width: 180, alignment: .leading)

            Text(sample)
                .font(font)

            Spacer()
        }
        .padding(DS.Spacing.s)
        .background(DS.Colors.tertiary)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small))
    }
}

/// Visual representation of a radius token
struct RadiusTokenRow: View {
    let name: String
    let value: CGFloat

    var body: some View {
        HStack(spacing: DS.Spacing.m) {
            Text(name)
                .font(DS.Typography.code)
                .frame(width: 140, alignment: .leading)

            RoundedRectangle(cornerRadius: value)
                .fill(DS.Colors.accent)
                .frame(width: 60, height: 40)

            Text(value == 999 ? "Capsule" : "\(Int(value))pt")
                .font(DS.Typography.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(DS.Spacing.s)
        .background(DS.Colors.tertiary)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small))
    }
}

/// Interactive animation token demonstration
struct AnimationTokenRow: View {
    let name: String
    let duration: String
    let animation: Animation
    @Binding var isAnimating: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                Text(name)
                    .font(DS.Typography.code)
                Text(duration)
                    .font(DS.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Animate") {
                withAnimation(animation) {
                    isAnimating.toggle()
                }
            }
        }
        .padding(DS.Spacing.m)
        .background(DS.Colors.tertiary)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small))
    }
}

// MARK: - Previews

#Preview("Design Tokens Screen") {
    NavigationStack {
        DesignTokensScreen()
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        DesignTokensScreen()
    }
    .preferredColorScheme(.dark)
}
