// swift-tools-version: 6.0
import SwiftUI

#if os(iOS)
import UIKit
#endif

// MARK: - Platform Comparison Previews

/// Platform comparison previews showcasing FoundationUI's cross-platform adaptation
///
/// These previews demonstrate how FoundationUI components automatically adapt
/// across macOS, iOS, and iPadOS platforms, highlighting:
/// - **Platform detection** via `PlatformAdapter`
/// - **Adaptive spacing** (macOS: 12pt, iOS: 16pt, iPad: size class-based)
/// - **Platform-specific interactions** (keyboard shortcuts, gestures, hover effects)
/// - **Color scheme adaptation** (automatic Dark Mode support)
/// - **Component adaptation** (touch targets, spacing, visual hierarchy)
/// - **DS token usage** (zero magic numbers, semantic naming)
///
/// ## Purpose
/// These previews serve multiple purposes:
/// - **Developer reference**: Understanding platform-specific behavior
/// - **Visual test**: Verifying adaptive features work correctly
/// - **Documentation**: Showcasing FoundationUI's capabilities
/// - **Design validation**: Ensuring consistent experience across platforms
///
/// ## Platform-Specific Features
///
/// ### macOS (Desktop)
/// - **Spacing**: `DS.Spacing.m` (12pt) for denser UI
/// - **Keyboard shortcuts**: ⌘C, ⌘V, ⌘X, ⌘A
/// - **Hover effects**: Pointer-based interactions
/// - **Visual density**: Optimized for desktop screens
///
/// ### iOS (iPhone)
/// - **Spacing**: `DS.Spacing.l` (16pt) for touch-friendly UI
/// - **Touch targets**: Minimum 44×44pt per Apple HIG
/// - **Gestures**: Tap, double tap, long press, swipe
/// - **Safe areas**: Respects notch and home indicator
///
/// ### iPadOS (iPad)
/// - **Spacing**: Adaptive based on size class
///   - Compact: `DS.Spacing.m` (12pt)
///   - Regular: `DS.Spacing.l` (16pt)
/// - **Pointer interactions**: Hover effects with runtime detection
/// - **Split view**: Multi-column layouts
/// - **Hybrid input**: Supports both touch and keyboard/pointer
///
/// ## Design System Integration
/// All previews use DS tokens exclusively:
/// - **Spacing**: `DS.Spacing.s/m/l/xl`
/// - **Colors**: `DS.Colors.*` (not shown, but available)
/// - **Radius**: `DS.Radius.small/card/chip`
/// - **Animation**: `DS.Animation.quick/medium/slow`
/// - **Typography**: `DS.Typography.*`
///
/// ## SwiftUI Previews
/// Each preview is designed to run in Xcode's Canvas, allowing developers to:
/// - Compare platforms side-by-side
/// - Test different device sizes
/// - Verify Dark Mode adaptation
/// - Validate accessibility features
///
/// ## See Also
/// - ``PlatformAdapter``
/// - ``PlatformExtensions``
/// - ``ColorSchemeAdapter``
/// - ``DS``

// MARK: - Preview: Platform Detection

#if DEBUG

#Preview("Platform Detection") {
    VStack(spacing: DS.Spacing.l) {
        Text("Platform Detection")
            .font(DS.Typography.title)

        Card {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                // Current platform
                HStack {
                    Text("Current Platform:")
                        .font(DS.Typography.label)
                    Spacer()
                    Text(PlatformAdapter.isMacOS ? "macOS" : "iOS/iPadOS")
                        .font(DS.Typography.code)
                        .foregroundColor(.blue)
                }

                // Platform-specific indicator
                HStack {
                    Text("Platform Type:")
                        .font(DS.Typography.label)
                    Spacer()
                    #if os(macOS)
                    Text("🖥️ Desktop")
                        .font(DS.Typography.body)
                    #elseif os(iOS)
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        Text("📱 iPad")
                            .font(DS.Typography.body)
                    } else {
                        Text("📱 iPhone")
                            .font(DS.Typography.body)
                    }
                    #else
                    Text("❓ Unknown")
                        .font(DS.Typography.body)
                    #endif
                }

                Divider()

                // Compile-time detection
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text("Compile-Time Detection")
                        .font(DS.Typography.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        Text("PlatformAdapter.isMacOS:")
                        Text("\(PlatformAdapter.isMacOS ? "true" : "false")")
                            .font(DS.Typography.code)
                            .foregroundColor(PlatformAdapter.isMacOS ? .green : .red)
                    }
                    .font(DS.Typography.body)

                    HStack {
                        Text("PlatformAdapter.isIOS:")
                        Text("\(PlatformAdapter.isIOS ? "true" : "false")")
                            .font(DS.Typography.code)
                            .foregroundColor(PlatformAdapter.isIOS ? .green : .red)
                    }
                    .font(DS.Typography.body)
                }
            }
        }

        Text("ℹ️ Platform detection uses conditional compilation")
            .font(DS.Typography.caption)
            .foregroundColor(.secondary)
    }
    .padding(DS.Spacing.xl)
}

// MARK: - Preview: Spacing Adaptation

#Preview("Spacing Adaptation Side-by-Side") {
    VStack(spacing: DS.Spacing.l) {
        Text("Platform Spacing Comparison")
            .font(DS.Typography.title)

        HStack(alignment: .top, spacing: DS.Spacing.l) {
            // macOS spacing (12pt)
            VStack(spacing: DS.Spacing.s) {
                Text("macOS")
                    .font(DS.Typography.headline)

                VStack {
                    Text("12pt spacing")
                        .font(DS.Typography.caption)
                    Text("(DS.Spacing.m)")
                        .font(DS.Typography.code)
                }
                .padding(DS.Spacing.m)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(DS.Radius.card)
                .overlay(
                    Text("\(Int(DS.Spacing.m))pt")
                        .font(DS.Typography.caption)
                        .foregroundColor(.blue)
                        .padding(DS.Spacing.s)
                    , alignment: .topTrailing
                )
            }

            // iOS spacing (16pt)
            VStack(spacing: DS.Spacing.s) {
                Text("iOS/iPadOS")
                    .font(DS.Typography.headline)

                VStack {
                    Text("16pt spacing")
                        .font(DS.Typography.caption)
                    Text("(DS.Spacing.l)")
                        .font(DS.Typography.code)
                }
                .padding(DS.Spacing.l)
                .background(Color.green.opacity(0.1))
                .cornerRadius(DS.Radius.card)
                .overlay(
                    Text("\(Int(DS.Spacing.l))pt")
                        .font(DS.Typography.caption)
                        .foregroundColor(.green)
                        .padding(DS.Spacing.s)
                    , alignment: .topTrailing
                )
            }
        }

        Card {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                Text("Current Default Spacing")
                    .font(DS.Typography.headline)

                HStack {
                    Text("Platform Default:")
                    Text("\(Int(PlatformAdapter.defaultSpacing))pt")
                        .font(DS.Typography.code)
                        .foregroundColor(.blue)
                }

                HStack {
                    Text("Compact Size Class:")
                    Text("\(Int(PlatformAdapter.spacing(for: .compact)))pt")
                        .font(DS.Typography.code)
                        .foregroundColor(.orange)
                }

                HStack {
                    Text("Regular Size Class:")
                    Text("\(Int(PlatformAdapter.spacing(for: .regular)))pt")
                        .font(DS.Typography.code)
                        .foregroundColor(.purple)
                }
            }
        }

        Text("ℹ️ Spacing adapts automatically per platform")
            .font(DS.Typography.caption)
            .foregroundColor(.secondary)
    }
    .padding(DS.Spacing.xl)
}

// MARK: - Preview: macOS Keyboard Shortcuts

#Preview("macOS Keyboard Shortcuts") {
    #if os(macOS)
    VStack(spacing: DS.Spacing.l) {
        Text("macOS Keyboard Shortcuts")
            .font(DS.Typography.title)

        Text("⌘ Command key shortcuts for common actions")
            .font(DS.Typography.body)
            .foregroundColor(.secondary)

        VStack(spacing: DS.Spacing.m) {
            // Copy shortcut
            HStack {
                Text("⌘C")
                    .font(DS.Typography.code)
                    .padding(DS.Spacing.s)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(DS.Radius.small)

                Button("Copy") {
                    print("Copy action")
                }
                .platformKeyboardShortcut(.copy)

                Spacer()
            }

            // Paste shortcut
            HStack {
                Text("⌘V")
                    .font(DS.Typography.code)
                    .padding(DS.Spacing.s)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(DS.Radius.small)

                Button("Paste") {
                    print("Paste action")
                }
                .platformKeyboardShortcut(.paste)

                Spacer()
            }

            // Cut shortcut
            HStack {
                Text("⌘X")
                    .font(DS.Typography.code)
                    .padding(DS.Spacing.s)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(DS.Radius.small)

                Button("Cut") {
                    print("Cut action")
                }
                .platformKeyboardShortcut(.cut)

                Spacer()
            }

            // Select All shortcut
            HStack {
                Text("⌘A")
                    .font(DS.Typography.code)
                    .padding(DS.Spacing.s)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(DS.Radius.small)

                Button("Select All") {
                    print("Select all action")
                }
                .platformKeyboardShortcut(.selectAll)

                Spacer()
            }
        }
        .cardStyle(elevation: .low)

        Text("ℹ️ Keyboard shortcuts only available on macOS")
            .font(DS.Typography.caption)
            .foregroundColor(.secondary)
    }
    .padding(DS.Spacing.xl)
    #else
    VStack(spacing: DS.Spacing.l) {
        Text("macOS Keyboard Shortcuts")
            .font(DS.Typography.title)

        Text("⚠️ Not available on this platform")
            .font(DS.Typography.body)
            .foregroundColor(.orange)

        Text("Keyboard shortcuts are macOS-specific and use conditional compilation (#if os(macOS))")
            .font(DS.Typography.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
    }
    .padding(DS.Spacing.xl)
    #endif
}

// MARK: - Preview: iOS Gestures

#Preview("iOS Gestures") {
    #if os(iOS)
    VStack(spacing: DS.Spacing.l) {
        Text("iOS Touch Gestures")
            .font(DS.Typography.title)

        Text("Touch-based interactions for iPhone and iPad")
            .font(DS.Typography.body)
            .foregroundColor(.secondary)

        VStack(spacing: DS.Spacing.m) {
            // Tap gesture
            VStack {
                Text("👆 Tap")
                    .font(DS.Typography.caption)
                Text("Tap Me")
                    .font(DS.Typography.body)
            }
            .frame(maxWidth: .infinity)
            .padding(DS.Spacing.l)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(DS.Radius.card)
            .platformTapGesture {
                print("Tapped!")
            }

            // Double tap gesture
            VStack {
                Text("👆👆 Double Tap")
                    .font(DS.Typography.caption)
                Text("Double Tap Me")
                    .font(DS.Typography.body)
            }
            .frame(maxWidth: .infinity)
            .padding(DS.Spacing.l)
            .background(Color.green.opacity(0.1))
            .cornerRadius(DS.Radius.card)
            .platformTapGesture(count: 2) {
                print("Double tapped!")
            }

            // Long press gesture
            VStack {
                Text("👆⏱️ Long Press")
                    .font(DS.Typography.caption)
                Text("Hold Me")
                    .font(DS.Typography.body)
            }
            .frame(maxWidth: .infinity)
            .padding(DS.Spacing.l)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(DS.Radius.card)
            .platformLongPressGesture {
                print("Long pressed!")
            }

            // Swipe gesture
            VStack {
                Text("👈 Swipe Left")
                    .font(DS.Typography.caption)
                Text("Swipe Left on Me")
                    .font(DS.Typography.body)
            }
            .frame(maxWidth: .infinity)
            .padding(DS.Spacing.l)
            .background(Color.purple.opacity(0.1))
            .cornerRadius(DS.Radius.card)
            .platformSwipeGesture(direction: .left) {
                print("Swiped left!")
            }
        }

        #if os(iOS)
        Card {
            HStack {
                Text("Min Touch Target:")
                    .font(DS.Typography.label)
                Spacer()
                Text("\(Int(PlatformAdapter.minimumTouchTarget))pt")
                    .font(DS.Typography.code)
                    .foregroundColor(.blue)
            }
        }
        #endif

        Text("ℹ️ All gestures respect 44×44pt minimum touch target")
            .font(DS.Typography.caption)
            .foregroundColor(.secondary)
    }
    .padding(DS.Spacing.xl)
    #else
    VStack(spacing: DS.Spacing.l) {
        Text("iOS Touch Gestures")
            .font(DS.Typography.title)

        Text("⚠️ Not available on this platform")
            .font(DS.Typography.body)
            .foregroundColor(.orange)

        Text("Touch gestures are iOS/iPadOS-specific and use conditional compilation (#if os(iOS))")
            .font(DS.Typography.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
    }
    .padding(DS.Spacing.xl)
    #endif
}

// MARK: - Preview: iPadOS Pointer Interactions

#Preview("iPadOS Pointer Interactions") {
    #if os(iOS)
    VStack(spacing: DS.Spacing.l) {
        Text("iPadOS Pointer Interactions")
            .font(DS.Typography.title)

        Text("Hover effects with runtime iPad detection")
            .font(DS.Typography.body)
            .foregroundColor(.secondary)

        if UIDevice.current.userInterfaceIdiom == .pad {
            Text("✅ iPad detected - Hover effects active")
                .font(DS.Typography.caption)
                .foregroundColor(.green)
        } else {
            Text("ℹ️ iPhone detected - Hover effects inactive")
                .font(DS.Typography.caption)
                .foregroundColor(.orange)
        }

        VStack(spacing: DS.Spacing.m) {
            // Lift hover effect
            VStack {
                Text("⬆️ Lift Effect")
                    .font(DS.Typography.caption)
                Text("Hover to Lift")
                    .font(DS.Typography.body)
            }
            .frame(maxWidth: .infinity)
            .padding(DS.Spacing.l)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(DS.Radius.card)
            .platformHoverEffect(.lift)

            // Highlight hover effect
            VStack {
                Text("✨ Highlight Effect")
                    .font(DS.Typography.caption)
                Text("Hover to Highlight")
                    .font(DS.Typography.body)
            }
            .frame(maxWidth: .infinity)
            .padding(DS.Spacing.l)
            .background(Color.green.opacity(0.1))
            .cornerRadius(DS.Radius.card)
            .platformHoverEffect(.highlight)

            // Automatic hover effect
            VStack {
                Text("🤖 Automatic Effect")
                    .font(DS.Typography.caption)
                Text("Hover for System Effect")
                    .font(DS.Typography.body)
            }
            .frame(maxWidth: .infinity)
            .padding(DS.Spacing.l)
            .background(Color.purple.opacity(0.1))
            .cornerRadius(DS.Radius.card)
            .platformHoverEffect(.automatic)
        }

        Text("ℹ️ Hover effects only activate on iPad devices")
            .font(DS.Typography.caption)
            .foregroundColor(.secondary)
    }
    .padding(DS.Spacing.xl)
    #else
    VStack(spacing: DS.Spacing.l) {
        Text("iPadOS Pointer Interactions")
            .font(DS.Typography.title)

        Text("⚠️ Not available on this platform")
            .font(DS.Typography.body)
            .foregroundColor(.orange)

        Text("Pointer interactions are iPadOS-specific with runtime device detection (UIDevice.current.userInterfaceIdiom == .pad)")
            .font(DS.Typography.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
    }
    .padding(DS.Spacing.xl)
    #endif
}

// MARK: - Preview: Color Scheme Adaptation

#Preview("Color Scheme - Light Mode") {
    struct LightModeComparison: View {
        var body: some View {
            let adapter = ColorSchemeAdapter(colorScheme: .light)

            return VStack(spacing: DS.Spacing.l) {
                Text("Light Mode Adaptation")
                    .font(DS.Typography.title)
                    .foregroundColor(adapter.adaptiveTextColor)

                VStack(spacing: DS.Spacing.m) {
                    // Background demonstration
                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        Text("Background Colors")
                            .font(DS.Typography.headline)
                            .foregroundColor(adapter.adaptiveTextColor)

                        HStack(spacing: DS.Spacing.s) {
                            VStack {
                                Text("Primary")
                                    .font(DS.Typography.caption)
                            }
                            .frame(width: 80, height: 60)
                            .background(adapter.adaptiveBackground)
                            .cornerRadius(DS.Radius.small)
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.Radius.small)
                                    .stroke(adapter.adaptiveBorderColor, lineWidth: 1)
                            )

                            VStack {
                                Text("Secondary")
                                    .font(DS.Typography.caption)
                            }
                            .frame(width: 80, height: 60)
                            .background(adapter.adaptiveSecondaryBackground)
                            .cornerRadius(DS.Radius.small)

                            VStack {
                                Text("Elevated")
                                    .font(DS.Typography.caption)
                            }
                            .frame(width: 80, height: 60)
                            .background(adapter.adaptiveElevatedSurface)
                            .cornerRadius(DS.Radius.small)
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.Radius.small)
                                    .stroke(adapter.adaptiveBorderColor, lineWidth: 1)
                            )
                        }
                    }

                    // Text color demonstration
                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        Text("Text Colors")
                            .font(DS.Typography.headline)
                            .foregroundColor(adapter.adaptiveTextColor)

                        VStack(alignment: .leading, spacing: DS.Spacing.s) {
                            Text("Primary text color")
                                .foregroundColor(adapter.adaptiveTextColor)
                            Text("Secondary text color")
                                .foregroundColor(adapter.adaptiveSecondaryTextColor)
                        }
                        .padding(DS.Spacing.m)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(adapter.adaptiveBackground)
                        .cornerRadius(DS.Radius.card)
                    }
                }
                .cardStyle(elevation: .low)

                Text("ℹ️ All colors adapt automatically via ColorSchemeAdapter")
                    .font(DS.Typography.caption)
                    .foregroundColor(.secondary)
            }
            .padding(DS.Spacing.xl)
            .background(adapter.adaptiveBackground)
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
                Text("Dark Mode Adaptation")
                    .font(DS.Typography.title)
                    .foregroundColor(adapter.adaptiveTextColor)

                VStack(spacing: DS.Spacing.m) {
                    // Background demonstration
                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        Text("Background Colors")
                            .font(DS.Typography.headline)
                            .foregroundColor(adapter.adaptiveTextColor)

                        HStack(spacing: DS.Spacing.s) {
                            VStack {
                                Text("Primary")
                                    .font(DS.Typography.caption)
                            }
                            .frame(width: 80, height: 60)
                            .background(adapter.adaptiveBackground)
                            .cornerRadius(DS.Radius.small)
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.Radius.small)
                                    .stroke(adapter.adaptiveBorderColor, lineWidth: 1)
                            )

                            VStack {
                                Text("Secondary")
                                    .font(DS.Typography.caption)
                            }
                            .frame(width: 80, height: 60)
                            .background(adapter.adaptiveSecondaryBackground)
                            .cornerRadius(DS.Radius.small)

                            VStack {
                                Text("Elevated")
                                    .font(DS.Typography.caption)
                            }
                            .frame(width: 80, height: 60)
                            .background(adapter.adaptiveElevatedSurface)
                            .cornerRadius(DS.Radius.small)
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.Radius.small)
                                    .stroke(adapter.adaptiveBorderColor, lineWidth: 1)
                            )
                        }
                    }

                    // Text color demonstration
                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        Text("Text Colors")
                            .font(DS.Typography.headline)
                            .foregroundColor(adapter.adaptiveTextColor)

                        VStack(alignment: .leading, spacing: DS.Spacing.s) {
                            Text("Primary text color")
                                .foregroundColor(adapter.adaptiveTextColor)
                            Text("Secondary text color")
                                .foregroundColor(adapter.adaptiveSecondaryTextColor)
                        }
                        .padding(DS.Spacing.m)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(adapter.adaptiveBackground)
                        .cornerRadius(DS.Radius.card)
                    }
                }
                .cardStyle(elevation: .low)

                Text("ℹ️ Colors automatically invert for optimal contrast in dark mode")
                    .font(DS.Typography.caption)
                    .foregroundColor(.secondary)
            }
            .padding(DS.Spacing.xl)
            .background(adapter.adaptiveBackground)
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
            Text("FoundationUI Component Adaptation")
                .font(DS.Typography.title)

            Text("Components automatically adapt to platform conventions")
                .font(DS.Typography.body)
                .foregroundColor(.secondary)

            // Platform info card
            Card {
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    HStack {
                        Text("Platform:")
                            .font(DS.Typography.label)
                        Spacer()
                        Text(PlatformAdapter.isMacOS ? "macOS" : "iOS/iPadOS")
                            .font(DS.Typography.code)
                            .foregroundColor(.blue)
                    }

                    HStack {
                        Text("Default Spacing:")
                            .font(DS.Typography.label)
                        Spacer()
                        Text("\(Int(PlatformAdapter.defaultSpacing))pt")
                            .font(DS.Typography.code)
                            .foregroundColor(.green)
                    }

                    HStack {
                        Text("Color Scheme:")
                            .font(DS.Typography.label)
                        Spacer()
                        Text(colorScheme == .dark ? "Dark" : "Light")
                            .font(DS.Typography.code)
                            .foregroundColor(.purple)
                    }

                    #if os(iOS)
                    HStack {
                        Text("Touch Target:")
                            .font(DS.Typography.label)
                        Spacer()
                        Text("\(Int(PlatformAdapter.minimumTouchTarget))pt")
                            .font(DS.Typography.code)
                            .foregroundColor(.orange)
                    }
                    #endif
                }
            }

            // DS Token showcase
            VStack(spacing: DS.Spacing.m) {
                Text("Design System Tokens")
                    .font(DS.Typography.headline)

                HStack(spacing: DS.Spacing.m) {
                    VStack {
                        Text("S")
                            .font(DS.Typography.caption)
                        Text("\(Int(DS.Spacing.s))pt")
                            .font(DS.Typography.code)
                    }
                    .padding(DS.Spacing.s)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(DS.Radius.small)

                    VStack {
                        Text("M")
                            .font(DS.Typography.caption)
                        Text("\(Int(DS.Spacing.m))pt")
                            .font(DS.Typography.code)
                    }
                    .padding(DS.Spacing.m)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(DS.Radius.small)

                    VStack {
                        Text("L")
                            .font(DS.Typography.caption)
                        Text("\(Int(DS.Spacing.l))pt")
                            .font(DS.Typography.code)
                    }
                    .padding(DS.Spacing.l)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(DS.Radius.small)
                }
            }
            .cardStyle(elevation: .low)

            Text("ℹ️ Zero magic numbers - all values use DS tokens")
                .font(DS.Typography.caption)
                .foregroundColor(.secondary)
        }
        .padding(DS.Spacing.xl)
        .platformAdaptive()
    }
}
#endif

#Preview("Component Adaptation Showcase") {
    ComponentAdaptationShowcaseView()
}

// MARK: - Preview: Cross-Platform Integration

#Preview("Cross-Platform Integration") {
    VStack(spacing: DS.Spacing.l) {
        Text("Cross-Platform Integration")
            .font(DS.Typography.title)

        Text("Unified API across all platforms")
            .font(DS.Typography.body)
            .foregroundColor(.secondary)

        // Platform-specific features
        VStack(spacing: DS.Spacing.m) {
            #if os(macOS)
            // macOS-specific features
            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                Text("macOS Features")
                    .font(DS.Typography.headline)

                Button("Copy (⌘C)") {
                    print("Copy action")
                }
                .platformKeyboardShortcut(.copy)

                Text("✓ Keyboard shortcuts")
                    .font(DS.Typography.caption)
                    .foregroundColor(.green)
                Text("✓ 12pt spacing (denser UI)")
                    .font(DS.Typography.caption)
                    .foregroundColor(.green)
            }
            .cardStyle(elevation: .low)
            #endif

            #if os(iOS)
            // iOS/iPadOS-specific features
            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                Text(UIDevice.current.userInterfaceIdiom == .pad ? "iPadOS Features" : "iOS Features")
                    .font(DS.Typography.headline)

                Text("Tap Me")
                    .frame(maxWidth: .infinity)
                    .padding(DS.Spacing.m)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(DS.Radius.card)
                    .platformTapGesture {
                        print("Tapped!")
                    }
                    .platformHoverEffect(.lift)

                Text("✓ Touch gestures")
                    .font(DS.Typography.caption)
                    .foregroundColor(.green)
                Text("✓ 16pt spacing (touch-friendly)")
                    .font(DS.Typography.caption)
                    .foregroundColor(.green)
                Text("✓ 44pt min touch target")
                    .font(DS.Typography.caption)
                    .foregroundColor(.green)

                if UIDevice.current.userInterfaceIdiom == .pad {
                    Text("✓ Pointer hover effects (iPad)")
                        .font(DS.Typography.caption)
                        .foregroundColor(.green)
                }
            }
            .cardStyle(elevation: .low)
            #endif

            // Shared features
            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                Text("Shared Features")
                    .font(DS.Typography.headline)

                Text("✓ Automatic Dark Mode")
                    .font(DS.Typography.caption)
                    .foregroundColor(.green)
                Text("✓ DS token system")
                    .font(DS.Typography.caption)
                    .foregroundColor(.green)
                Text("✓ Platform detection")
                    .font(DS.Typography.caption)
                    .foregroundColor(.green)
                Text("✓ Adaptive spacing")
                    .font(DS.Typography.caption)
                    .foregroundColor(.green)
            }
            .cardStyle(elevation: .low)
        }

        Text("ℹ️ FoundationUI provides a consistent API with platform-specific optimizations")
            .font(DS.Typography.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
    }
    .padding(DS.Spacing.xl)
    .platformAdaptive()
}

#endif
