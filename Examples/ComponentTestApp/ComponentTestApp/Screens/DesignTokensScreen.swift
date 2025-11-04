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

import SwiftUI
import FoundationUI

struct DesignTokensScreen: View {
    @State private var isAnimating = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                // Spacing Tokens
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Spacing")
                        .font(DS.Typography.title)

                    SpacingTokenRow(name: "DS.Spacing.s", value: DS.Spacing.s)
                    SpacingTokenRow(name: "DS.Spacing.m", value: DS.Spacing.m)
                    SpacingTokenRow(name: "DS.Spacing.l", value: DS.Spacing.l)
                    SpacingTokenRow(name: "DS.Spacing.xl", value: DS.Spacing.xl)
                }

                Divider()

                // Color Tokens
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Colors")
                        .font(DS.Typography.title)

                    Text("Semantic Backgrounds")
                        .font(DS.Typography.subheadline)
                        .foregroundStyle(.secondary)

                    ColorTokenRow(name: "DS.Colors.infoBG", color: DS.Colors.infoBG, usage: "Neutral information")
                    ColorTokenRow(name: "DS.Colors.warnBG", color: DS.Colors.warnBG, usage: "Warnings, cautions")
                    ColorTokenRow(name: "DS.Colors.errorBG", color: DS.Colors.errorBG, usage: "Errors, failures")
                    ColorTokenRow(name: "DS.Colors.successBG", color: DS.Colors.successBG, usage: "Success, completion")

                    Text("UI Colors")
                        .font(DS.Typography.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, DS.Spacing.m)

                    ColorTokenRow(name: "DS.Colors.accent", color: DS.Colors.accent, usage: "Interactive elements")
                    ColorTokenRow(name: "DS.Colors.secondary", color: DS.Colors.secondary, usage: "Supporting elements")
                    ColorTokenRow(name: "DS.Colors.tertiary", color: DS.Colors.tertiary, usage: "Background fills")
                }

                Divider()

                // Typography Tokens
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Typography")
                        .font(DS.Typography.title)

                    TypographyTokenRow(name: "DS.Typography.headline", font: DS.Typography.headline, sample: "Headline Text")
                    TypographyTokenRow(name: "DS.Typography.title", font: DS.Typography.title, sample: "Title Text")
                    TypographyTokenRow(name: "DS.Typography.subheadline", font: DS.Typography.subheadline, sample: "Subheadline Text")
                    TypographyTokenRow(name: "DS.Typography.body", font: DS.Typography.body, sample: "Body Text")
                    TypographyTokenRow(name: "DS.Typography.caption", font: DS.Typography.caption, sample: "Caption Text")
                    TypographyTokenRow(name: "DS.Typography.label", font: DS.Typography.label, sample: "LABEL TEXT")
                    TypographyTokenRow(name: "DS.Typography.code", font: DS.Typography.code, sample: "0xDEADBEEF")
                }

                Divider()

                // Radius Tokens
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Corner Radius")
                        .font(DS.Typography.title)

                    RadiusTokenRow(name: "DS.Radius.small", value: DS.Radius.small)
                    RadiusTokenRow(name: "DS.Radius.medium", value: DS.Radius.medium)
                    RadiusTokenRow(name: "DS.Radius.card", value: DS.Radius.card)
                    RadiusTokenRow(name: "DS.Radius.chip", value: DS.Radius.chip)
                }

                Divider()

                // Animation Tokens
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

                    AnimationTokenRow(name: "DS.Animation.medium", duration: "0.25s", animation: DS.Animation.medium, isAnimating: $isAnimating)
                    AnimationTokenRow(name: "DS.Animation.slow", duration: "0.35s", animation: DS.Animation.slow, isAnimating: $isAnimating)
                }
            }
            .padding(DS.Spacing.l)
        }
        .navigationTitle("Design Tokens")
        #if os(macOS)
        .frame(minWidth: 600, minHeight: 400)
        #endif
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
