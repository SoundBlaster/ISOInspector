import SwiftUI

#if os(iOS)
    import UIKit
#endif

#if DEBUG
    // MARK: - Preview: iPadOS Pointer Interactions

    #Preview("iPadOS Pointer Interactions") {
        #if os(iOS)
            VStack(spacing: DS.Spacing.l) {
                Text("iPadOS Pointer Interactions").font(DS.Typography.title)

                Text("Hover effects with runtime iPad detection").font(DS.Typography.body)
                    .foregroundColor(.secondary)

                if UIDevice.current.userInterfaceIdiom == .pad {
                    Text("✅ iPad detected - Hover effects active").font(DS.Typography.caption)
                        .foregroundColor(.green)
                } else {
                    Text("ℹ️ iPhone detected - Hover effects inactive").font(DS.Typography.caption)
                        .foregroundColor(.orange)
                }

                VStack(spacing: DS.Spacing.m) {
                    // Lift hover effect
                    VStack {
                        Text("⬆️ Lift Effect").font(DS.Typography.caption)
                        Text("Hover to Lift").font(DS.Typography.body)
                    }.frame(maxWidth: .infinity).padding(DS.Spacing.l).background(
                        Color.blue.opacity(0.1)
                    ).cornerRadius(DS.Radius.card).platformHoverEffect(.lift)

                    // Highlight hover effect
                    VStack {
                        Text("✨ Highlight Effect").font(DS.Typography.caption)
                        Text("Hover to Highlight").font(DS.Typography.body)
                    }.frame(maxWidth: .infinity).padding(DS.Spacing.l).background(
                        Color.green.opacity(0.1)
                    ).cornerRadius(DS.Radius.card).platformHoverEffect(.highlight)

                    // Automatic hover effect
                    VStack {
                        Text("🤖 Automatic Effect").font(DS.Typography.caption)
                        Text("Hover for System Effect").font(DS.Typography.body)
                    }.frame(maxWidth: .infinity).padding(DS.Spacing.l).background(
                        Color.purple.opacity(0.1)
                    ).cornerRadius(DS.Radius.card).platformHoverEffect(.automatic)
                }

                Text("ℹ️ Hover effects only activate on iPad devices").font(DS.Typography.caption)
                    .foregroundColor(.secondary)
            }.padding(DS.Spacing.xl)
        #else
            VStack(spacing: DS.Spacing.l) {
                Text("iPadOS Pointer Interactions").font(DS.Typography.title)

                Text("⚠️ Not available on this platform").font(DS.Typography.body).foregroundColor(
                    .orange)

                Text(
                    "Pointer interactions are iPadOS-specific with runtime device detection (UIDevice.current.userInterfaceIdiom == .pad)"
                ).font(DS.Typography.caption).foregroundColor(.secondary).multilineTextAlignment(
                    .center)
            }.padding(DS.Spacing.xl)
        #endif
    }

    // MARK: - Preview: Color Scheme Adaptation

    #Preview("Color Scheme - Light Mode") {
        struct LightModeComparison: View {
            var body: some View {
                let adapter = ColorSchemeAdapter(colorScheme: .light)

                return VStack(spacing: DS.Spacing.l) {
                    Text("Light Mode Adaptation").font(DS.Typography.title).foregroundColor(
                        adapter.adaptiveTextColor)

                    VStack(spacing: DS.Spacing.m) {
                        // Background demonstration
                        VStack(alignment: .leading, spacing: DS.Spacing.s) {
                            Text("Background Colors").font(DS.Typography.headline).foregroundColor(
                                adapter.adaptiveTextColor)

                            HStack(spacing: DS.Spacing.s) {
                                VStack { Text("Primary").font(DS.Typography.caption) }.frame(
                                    width: 80, height: 60
                                ).background(adapter.adaptiveBackground).cornerRadius(
                                    DS.Radius.small
                                ).overlay(
                                    RoundedRectangle(cornerRadius: DS.Radius.small).stroke(
                                        adapter.adaptiveBorderColor, lineWidth: 1))

                                VStack { Text("Secondary").font(DS.Typography.caption) }.frame(
                                    width: 80, height: 60
                                ).background(adapter.adaptiveSecondaryBackground).cornerRadius(
                                    DS.Radius.small)

                                VStack { Text("Elevated").font(DS.Typography.caption) }.frame(
                                    width: 80, height: 60
                                ).background(adapter.adaptiveElevatedSurface).cornerRadius(
                                    DS.Radius.small
                                ).overlay(
                                    RoundedRectangle(cornerRadius: DS.Radius.small).stroke(
                                        adapter.adaptiveBorderColor, lineWidth: 1))
                            }
                        }

                        // Text color demonstration
                        VStack(alignment: .leading, spacing: DS.Spacing.s) {
                            Text("Text Colors").font(DS.Typography.headline).foregroundColor(
                                adapter.adaptiveTextColor)

                            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                                Text("Primary text color").foregroundColor(
                                    adapter.adaptiveTextColor)
                                Text("Secondary text color").foregroundColor(
                                    adapter.adaptiveSecondaryTextColor)
                            }.padding(DS.Spacing.m).frame(maxWidth: .infinity, alignment: .leading)
                                .background(adapter.adaptiveBackground).cornerRadius(DS.Radius.card)
                        }
                    }.cardStyle(elevation: .low)

                    Text("ℹ️ All colors adapt automatically via ColorSchemeAdapter").font(
                        DS.Typography.caption
                    ).foregroundColor(.secondary)
                }.padding(DS.Spacing.xl).background(adapter.adaptiveBackground)
                    .preferredColorScheme(.light)
            }
        }

        return LightModeComparison()
    }

    #Preview("Color Scheme - Dark Mode") {
        struct DarkModeComparison: View {
            var body: some View {
                let adapter = ColorSchemeAdapter(colorScheme: .dark)

                return VStack(spacing: DS.Spacing.l) {
                    Text("Dark Mode Adaptation").font(DS.Typography.title).foregroundColor(
                        adapter.adaptiveTextColor)

                    VStack(spacing: DS.Spacing.m) {
                        // Background demonstration
                        VStack(alignment: .leading, spacing: DS.Spacing.s) {
                            Text("Background Colors").font(DS.Typography.headline).foregroundColor(
                                adapter.adaptiveTextColor)

                            HStack(spacing: DS.Spacing.s) {
                                VStack { Text("Primary").font(DS.Typography.caption) }.frame(
                                    width: 80, height: 60
                                ).background(adapter.adaptiveBackground).cornerRadius(
                                    DS.Radius.small
                                ).overlay(
                                    RoundedRectangle(cornerRadius: DS.Radius.small).stroke(
                                        adapter.adaptiveBorderColor, lineWidth: 1))

                                VStack { Text("Secondary").font(DS.Typography.caption) }.frame(
                                    width: 80, height: 60
                                ).background(adapter.adaptiveSecondaryBackground).cornerRadius(
                                    DS.Radius.small)

                                VStack { Text("Elevated").font(DS.Typography.caption) }.frame(
                                    width: 80, height: 60
                                ).background(adapter.adaptiveElevatedSurface).cornerRadius(
                                    DS.Radius.small
                                ).overlay(
                                    RoundedRectangle(cornerRadius: DS.Radius.small).stroke(
                                        adapter.adaptiveBorderColor, lineWidth: 1))
                            }
                        }

                        // Text color demonstration
                        VStack(alignment: .leading, spacing: DS.Spacing.s) {
                            Text("Text Colors").font(DS.Typography.headline).foregroundColor(
                                adapter.adaptiveTextColor)

                            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                                Text("Primary text color").foregroundColor(
                                    adapter.adaptiveTextColor)
                                Text("Secondary text color").foregroundColor(
                                    adapter.adaptiveSecondaryTextColor)
                            }.padding(DS.Spacing.m).frame(maxWidth: .infinity, alignment: .leading)
                                .background(adapter.adaptiveBackground).cornerRadius(DS.Radius.card)
                        }
                    }.cardStyle(elevation: .low)

                    Text("ℹ️ Colors automatically invert for optimal contrast in dark mode").font(
                        DS.Typography.caption
                    ).foregroundColor(.secondary)
                }.padding(DS.Spacing.xl).background(adapter.adaptiveBackground)
                    .preferredColorScheme(.dark)
            }
        }

        return DarkModeComparison()
    }

    // MARK: - Preview: Component Adaptation

    #if DEBUG
        private struct ComponentAdaptationShowcaseView: View {
            @Environment(\.colorScheme) var colorScheme

            var body: some View {
                VStack(spacing: DS.Spacing.l) {
                    Text("FoundationUI Component Adaptation").font(DS.Typography.title)

                    Text("Components automatically adapt to platform conventions").font(
                        DS.Typography.body
                    ).foregroundColor(.secondary)

                    // Platform info card
                    Card {
                        VStack(alignment: .leading, spacing: DS.Spacing.m) {
                            HStack {
                                Text("Platform:").font(DS.Typography.label)
                                Spacer()
                                Text(PlatformAdapter.isMacOS ? "macOS" : "iOS/iPadOS").font(
                                    DS.Typography.code
                                ).foregroundColor(.blue)
                            }

                            HStack {
                                Text("Default Spacing:").font(DS.Typography.label)
                                Spacer()
                                Text("\(Int(PlatformAdapter.defaultSpacing))pt").font(
                                    DS.Typography.code
                                ).foregroundColor(.green)
                            }

                            HStack {
                                Text("Color Scheme:").font(DS.Typography.label)
                                Spacer()
                                Text(colorScheme == .dark ? "Dark" : "Light").font(
                                    DS.Typography.code
                                ).foregroundColor(.purple)
                            }

                            #if os(iOS)
                                HStack {
                                    Text("Touch Target:").font(DS.Typography.label)
                                    Spacer()
                                    Text("\(Int(PlatformAdapter.minimumTouchTarget))pt").font(
                                        DS.Typography.code
                                    ).foregroundColor(.orange)
                                }
                            #endif
                        }
                    }

                    // DS Token showcase
                    VStack(spacing: DS.Spacing.m) {
                        Text("Design System Tokens").font(DS.Typography.headline)

                        HStack(spacing: DS.Spacing.m) {
                            VStack {
                                Text("S").font(DS.Typography.caption)
                                Text("\(Int(DS.Spacing.s))pt").font(DS.Typography.code)
                            }.padding(DS.Spacing.s).background(Color.blue.opacity(0.1))
                                .cornerRadius(DS.Radius.small)

                            VStack {
                                Text("M").font(DS.Typography.caption)
                                Text("\(Int(DS.Spacing.m))pt").font(DS.Typography.code)
                            }.padding(DS.Spacing.m).background(Color.green.opacity(0.1))
                                .cornerRadius(DS.Radius.small)

                            VStack {
                                Text("L").font(DS.Typography.caption)
                                Text("\(Int(DS.Spacing.l))pt").font(DS.Typography.code)
                            }.padding(DS.Spacing.l).background(Color.orange.opacity(0.1))
                                .cornerRadius(DS.Radius.small)
                        }
                    }.cardStyle(elevation: .low)

                    Text("ℹ️ Zero magic numbers - all values use DS tokens").font(
                        DS.Typography.caption
                    ).foregroundColor(.secondary)
                }.padding(DS.Spacing.xl).platformAdaptive()
            }
        }
    #endif

    #Preview("Component Adaptation Showcase") { ComponentAdaptationShowcaseView() }

    // MARK: - Preview: Cross-Platform Integration

    #Preview("Cross-Platform Integration") {
        VStack(spacing: DS.Spacing.l) {
            Text("Cross-Platform Integration").font(DS.Typography.title)

            Text("Unified API across all platforms").font(DS.Typography.body).foregroundColor(
                .secondary)

            // Platform-specific features
            VStack(spacing: DS.Spacing.m) {
                #if os(macOS)
                    // macOS-specific features
                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        Text("macOS Features").font(DS.Typography.headline)

                        Button("Copy (⌘C)") { print("Copy action") }.platformKeyboardShortcut(.copy)

                        Text("✓ Keyboard shortcuts").font(DS.Typography.caption).foregroundColor(
                            .green)
                        Text("✓ 12pt spacing (denser UI)").font(DS.Typography.caption)
                            .foregroundColor(.green)
                    }.cardStyle(elevation: .low)
                #endif

                #if os(iOS)
                    // iOS/iPadOS-specific features
                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        Text(
                            UIDevice.current.userInterfaceIdiom == .pad
                                ? "iPadOS Features" : "iOS Features"
                        ).font(DS.Typography.headline)

                        Text("Tap Me").frame(maxWidth: .infinity).padding(DS.Spacing.m).background(
                            Color.blue.opacity(0.1)
                        ).cornerRadius(DS.Radius.card).platformTapGesture { print("Tapped!") }
                            .platformHoverEffect(.lift)

                        Text("✓ Touch gestures").font(DS.Typography.caption).foregroundColor(.green)
                        Text("✓ 16pt spacing (touch-friendly)").font(DS.Typography.caption)
                            .foregroundColor(.green)
                        Text("✓ 44pt min touch target").font(DS.Typography.caption).foregroundColor(
                            .green)

                        if UIDevice.current.userInterfaceIdiom == .pad {
                            Text("✓ Pointer hover effects (iPad)").font(DS.Typography.caption)
                                .foregroundColor(.green)
                        }
                    }.cardStyle(elevation: .low)
                #endif

                // Shared features
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text("Shared Features").font(DS.Typography.headline)

                    Text("✓ Automatic Dark Mode").font(DS.Typography.caption).foregroundColor(
                        .green)
                    Text("✓ DS token system").font(DS.Typography.caption).foregroundColor(.green)
                    Text("✓ Platform detection").font(DS.Typography.caption).foregroundColor(.green)
                    Text("✓ Adaptive spacing").font(DS.Typography.caption).foregroundColor(.green)
                }.cardStyle(elevation: .low)
            }

            Text("ℹ️ FoundationUI provides a consistent API with platform-specific optimizations")
                .font(DS.Typography.caption).foregroundColor(.secondary).multilineTextAlignment(
                    .center)
        }.padding(DS.Spacing.xl).platformAdaptive()
    }
#endif
