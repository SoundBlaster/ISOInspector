import SwiftUI

#if os(iOS)
    import UIKit
#endif

// MARK: - Platform Comparison Previews

// Platform comparison previews showcasing FoundationUI's cross-platform adaptation
//
// These previews demonstrate how FoundationUI components automatically adapt
// across macOS, iOS, and iPadOS platforms, highlighting:
// - **Platform detection** via `PlatformAdapter`
// - **Adaptive spacing** (macOS: 12pt, iOS: 16pt, iPad: size class-based)
// - **Platform-specific interactions** (keyboard shortcuts, gestures, hover effects)
// - **Color scheme adaptation** (automatic Dark Mode support)
// - **Component adaptation** (touch targets, spacing, visual hierarchy)
// - **DS token usage** (zero magic numbers, semantic naming)
//
// ## Purpose
// These previews serve multiple purposes:
// - **Developer reference**: Understanding platform-specific behavior
// - **Visual test**: Verifying adaptive features work correctly
// - **Documentation**: Showcasing FoundationUI's capabilities
// - **Design validation**: Ensuring consistent experience across platforms
//
// ## Platform-Specific Features
//
// ### macOS (Desktop)
// - **Spacing**: `DS.Spacing.m` (12pt) for denser UI
// - **Keyboard shortcuts**: ⌘C, ⌘V, ⌘X, ⌘A
// - **Hover effects**: Pointer-based interactions
// - **Visual density**: Optimized for desktop screens
//
// ### iOS (iPhone)
// - **Spacing**: `DS.Spacing.l` (16pt) for touch-friendly UI
// - **Touch targets**: Minimum 44×44pt per Apple HIG
// - **Gestures**: Tap, double tap, long press, swipe
// - **Safe areas**: Respects notch and home indicator
//
// ### iPadOS (iPad)
// - **Spacing**: Adaptive based on size class
//   - Compact: `DS.Spacing.m` (12pt)
//   - Regular: `DS.Spacing.l` (16pt)
// - **Pointer interactions**: Hover effects with runtime detection
// - **Split view**: Multi-column layouts
// - **Hybrid input**: Supports both touch and keyboard/pointer
//
// ## Design System Integration
// All previews use DS tokens exclusively:
// - **Spacing**: `DS.Spacing.s/m/l/xl`
// - **Colors**: `DS.Colors.*` (not shown, but available)
// - **Radius**: `DS.Radius.small/card/chip`
// - **Animation**: `DS.Animation.quick/medium/slow`
// - **Typography**: `DS.Typography.*`
//
// ## SwiftUI Previews
// Each preview is designed to run in Xcode's Canvas, allowing developers to:
// - Compare platforms side-by-side
// - Test different device sizes
// - Verify Dark Mode adaptation
// - Validate accessibility features
//
// ## See Also
// - ``PlatformAdapter``
// - ``PlatformExtensions``
// - ``ColorSchemeAdapter``
// - ``DS``

// MARK: - Preview: Platform Detection

#if DEBUG

    #Preview("Platform Detection") {
        VStack(spacing: DS.Spacing.l) {
            Text("Platform Detection").font(DS.Typography.title)

            Card {
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    // Current platform
                    HStack {
                        Text("Current Platform:").font(DS.Typography.label)
                        Spacer()
                        Text(PlatformAdapter.isMacOS ? "macOS" : "iOS/iPadOS").font(
                            DS.Typography.code
                        ).foregroundColor(.blue)
                    }

                    // Platform-specific indicator
                    HStack {
                        Text("Platform Type:").font(DS.Typography.label)
                        Spacer()
                        #if os(macOS)
                            Text("🖥️ Desktop").font(DS.Typography.body)
                        #elseif os(iOS)
                            if UIDevice.current.userInterfaceIdiom == .pad {
                                Text("📱 iPad").font(DS.Typography.body)
                            } else {
                                Text("📱 iPhone").font(DS.Typography.body)
                            }
                        #else
                            Text("❓ Unknown").font(DS.Typography.body)
                        #endif
                    }

                    Divider()

                    // Compile-time detection
                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        Text("Compile-Time Detection").font(DS.Typography.caption).foregroundColor(
                            .secondary)

                        HStack {
                            Text("PlatformAdapter.isMacOS:")
                            Text("\(PlatformAdapter.isMacOS ? "true" : "false")").font(
                                DS.Typography.code
                            ).foregroundColor(PlatformAdapter.isMacOS ? .green : .red)
                        }.font(DS.Typography.body)

                        HStack {
                            Text("PlatformAdapter.isIOS:")
                            Text("\(PlatformAdapter.isIOS ? "true" : "false")").font(
                                DS.Typography.code
                            ).foregroundColor(PlatformAdapter.isIOS ? .green : .red)
                        }.font(DS.Typography.body)
                    }
                }
            }

            Text("ℹ️ Platform detection uses conditional compilation").font(DS.Typography.caption)
                .foregroundColor(.secondary)
        }.padding(DS.Spacing.xl)
    }

    // MARK: - Preview: Spacing Adaptation

    #Preview("Spacing Adaptation Side-by-Side") {
        VStack(spacing: DS.Spacing.l) {
            Text("Platform Spacing Comparison").font(DS.Typography.title)

            HStack(alignment: .top, spacing: DS.Spacing.l) {
                // macOS spacing (12pt)
                VStack(spacing: DS.Spacing.s) {
                    Text("macOS").font(DS.Typography.headline)

                    VStack {
                        Text("12pt spacing").font(DS.Typography.caption)
                        Text("(DS.Spacing.m)").font(DS.Typography.code)
                    }.padding(DS.Spacing.m).background(Color.blue.opacity(0.1)).cornerRadius(
                        DS.Radius.card
                    ).overlay(
                        Text("\(Int(DS.Spacing.m))pt").font(DS.Typography.caption).foregroundColor(
                            .blue
                        ).padding(DS.Spacing.s), alignment: .topTrailing)
                }

                // iOS spacing (16pt)
                VStack(spacing: DS.Spacing.s) {
                    Text("iOS/iPadOS").font(DS.Typography.headline)

                    VStack {
                        Text("16pt spacing").font(DS.Typography.caption)
                        Text("(DS.Spacing.l)").font(DS.Typography.code)
                    }.padding(DS.Spacing.l).background(Color.green.opacity(0.1)).cornerRadius(
                        DS.Radius.card
                    ).overlay(
                        Text("\(Int(DS.Spacing.l))pt").font(DS.Typography.caption).foregroundColor(
                            .green
                        ).padding(DS.Spacing.s), alignment: .topTrailing)
                }
            }

            Card {
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Current Default Spacing").font(DS.Typography.headline)

                    HStack {
                        Text("Platform Default:")
                        Text("\(Int(PlatformAdapter.defaultSpacing))pt").font(DS.Typography.code)
                            .foregroundColor(.blue)
                    }

                    HStack {
                        Text("Compact Size Class:")
                        Text("\(Int(PlatformAdapter.spacing(for: .compact)))pt").font(
                            DS.Typography.code
                        ).foregroundColor(.orange)
                    }

                    HStack {
                        Text("Regular Size Class:")
                        Text("\(Int(PlatformAdapter.spacing(for: .regular)))pt").font(
                            DS.Typography.code
                        ).foregroundColor(.purple)
                    }
                }
            }

            Text("ℹ️ Spacing adapts automatically per platform").font(DS.Typography.caption)
                .foregroundColor(.secondary)
        }.padding(DS.Spacing.xl)
    }

    // MARK: - Preview: macOS Keyboard Shortcuts

    #Preview("macOS Keyboard Shortcuts") {
        #if os(macOS)
            VStack(spacing: DS.Spacing.l) {
                Text("macOS Keyboard Shortcuts").font(DS.Typography.title)

                Text("⌘ Command key shortcuts for common actions").font(DS.Typography.body)
                    .foregroundColor(.secondary)

                VStack(spacing: DS.Spacing.m) {
                    // Copy shortcut
                    HStack {
                        Text("⌘C").font(DS.Typography.code).padding(DS.Spacing.s).background(
                            Color.blue.opacity(0.1)
                        ).cornerRadius(DS.Radius.small)

                        Button("Copy") { print("Copy action") }.platformKeyboardShortcut(.copy)

                        Spacer()
                    }

                    // Paste shortcut
                    HStack {
                        Text("⌘V").font(DS.Typography.code).padding(DS.Spacing.s).background(
                            Color.green.opacity(0.1)
                        ).cornerRadius(DS.Radius.small)

                        Button("Paste") { print("Paste action") }.platformKeyboardShortcut(.paste)

                        Spacer()
                    }

                    // Cut shortcut
                    HStack {
                        Text("⌘X").font(DS.Typography.code).padding(DS.Spacing.s).background(
                            Color.orange.opacity(0.1)
                        ).cornerRadius(DS.Radius.small)

                        Button("Cut") { print("Cut action") }.platformKeyboardShortcut(.cut)

                        Spacer()
                    }

                    // Select All shortcut
                    HStack {
                        Text("⌘A").font(DS.Typography.code).padding(DS.Spacing.s).background(
                            Color.purple.opacity(0.1)
                        ).cornerRadius(DS.Radius.small)

                        Button("Select All") { print("Select all action") }
                            .platformKeyboardShortcut(.selectAll)

                        Spacer()
                    }
                }.cardStyle(elevation: .low)

                Text("ℹ️ Keyboard shortcuts only available on macOS").font(DS.Typography.caption)
                    .foregroundColor(.secondary)
            }.padding(DS.Spacing.xl)
        #else
            VStack(spacing: DS.Spacing.l) {
                Text("macOS Keyboard Shortcuts").font(DS.Typography.title)

                Text("⚠️ Not available on this platform").font(DS.Typography.body).foregroundColor(
                    .orange)

                Text(
                    "Keyboard shortcuts are macOS-specific and use conditional compilation (#if os(macOS))"
                ).font(DS.Typography.caption).foregroundColor(.secondary).multilineTextAlignment(
                    .center)
            }.padding(DS.Spacing.xl)
        #endif
    }

    // MARK: - Preview: iOS Gestures

    #Preview("iOS Gestures") {
        #if os(iOS)
            VStack(spacing: DS.Spacing.l) {
                Text("iOS Touch Gestures").font(DS.Typography.title)

                Text("Touch-based interactions for iPhone and iPad").font(DS.Typography.body)
                    .foregroundColor(.secondary)

                VStack(spacing: DS.Spacing.m) {
                    // Tap gesture
                    VStack {
                        Text("👆 Tap").font(DS.Typography.caption)
                        Text("Tap Me").font(DS.Typography.body)
                    }.frame(maxWidth: .infinity).padding(DS.Spacing.l).background(
                        Color.blue.opacity(0.1)
                    ).cornerRadius(DS.Radius.card).platformTapGesture { print("Tapped!") }

                    // Double tap gesture
                    VStack {
                        Text("👆👆 Double Tap").font(DS.Typography.caption)
                        Text("Double Tap Me").font(DS.Typography.body)
                    }.frame(maxWidth: .infinity).padding(DS.Spacing.l).background(
                        Color.green.opacity(0.1)
                    ).cornerRadius(DS.Radius.card).platformTapGesture(count: 2) {
                        print("Double tapped!")
                    }

                    // Long press gesture
                    VStack {
                        Text("👆⏱️ Long Press").font(DS.Typography.caption)
                        Text("Hold Me").font(DS.Typography.body)
                    }.frame(maxWidth: .infinity).padding(DS.Spacing.l).background(
                        Color.orange.opacity(0.1)
                    ).cornerRadius(DS.Radius.card).platformLongPressGesture {
                        print("Long pressed!")
                    }

                    // Swipe gesture
                    VStack {
                        Text("👈 Swipe Left").font(DS.Typography.caption)
                        Text("Swipe Left on Me").font(DS.Typography.body)
                    }.frame(maxWidth: .infinity).padding(DS.Spacing.l).background(
                        Color.purple.opacity(0.1)
                    ).cornerRadius(DS.Radius.card).platformSwipeGesture(direction: .left) {
                        print("Swiped left!")
                    }
                }

                #if os(iOS)
                    Card {
                        HStack {
                            Text("Min Touch Target:").font(DS.Typography.label)
                            Spacer()
                            Text("\(Int(PlatformAdapter.minimumTouchTarget))pt").font(
                                DS.Typography.code
                            ).foregroundColor(.blue)
                        }
                    }
                #endif

                Text("ℹ️ All gestures respect 44×44pt minimum touch target").font(
                    DS.Typography.caption
                ).foregroundColor(.secondary)
            }.padding(DS.Spacing.xl)
        #else
            VStack(spacing: DS.Spacing.l) {
                Text("iOS Touch Gestures").font(DS.Typography.title)

                Text("⚠️ Not available on this platform").font(DS.Typography.body).foregroundColor(
                    .orange)

                Text(
                    "Touch gestures are iOS/iPadOS-specific and use conditional compilation (#if os(iOS))"
                ).font(DS.Typography.caption).foregroundColor(.secondary).multilineTextAlignment(
                    .center)
            }.padding(DS.Spacing.xl)
        #endif
    }

#endif
