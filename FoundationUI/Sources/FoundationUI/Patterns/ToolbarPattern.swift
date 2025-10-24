// swift-tools-version: 6.0
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// A platform-adaptive toolbar pattern that arranges primary, secondary, and overflow
/// actions according to Composable Clarity design principles.
///
/// The toolbar composes FoundationUI layers by consuming design system tokens,
/// exposing semantic metadata for accessibility, and adapting layout behaviour
/// across platforms and size classes.
public struct ToolbarPattern: View {
    public let items: Items
    public let layoutOverride: Layout?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Creates a new toolbar pattern instance.
    /// - Parameters:
    ///   - items: Grouped toolbar items separated into primary, secondary, and overflow collections.
    ///   - layoutOverride: Optional explicit layout override used primarily for testing and previews.
    public init(items: Items, layoutOverride: Layout? = nil) {
        self.items = items
        self.layoutOverride = layoutOverride
    }

    public var body: some View {
        let resolvedLayout = layout

        return HStack(spacing: DS.Spacing.m) {
            primarySection(layout: resolvedLayout)

            if !items.secondary.isEmpty {
                Divider()
                    .frame(height: DS.Spacing.xl)
                    .padding(.vertical, DS.Spacing.s)
                secondarySection(layout: resolvedLayout)
            }

            if !items.overflow.isEmpty {
                overflowSection()
            }
        }
        .padding(.horizontal, DS.Spacing.m)
        .padding(.vertical, DS.Spacing.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous)
                .fill(DS.Color.tertiary)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Toolbar"))
    }

    private var layout: Layout {
        if let override = layoutOverride {
            return override
        }

        let traits = Traits(
            horizontalSizeClass: horizontalSizeClass,
            platform: platform,
            prefersLargeContent: prefersLargeContent
        )

        return LayoutResolver.layout(for: traits)
    }

    private var platform: Platform {
        #if os(macOS)
        return .macOS
        #elseif os(iOS)
        #if canImport(UIKit)
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return .iPadOS
        default:
            return .iOS
        }
        #else
        return .iOS
        #endif
        #else
        return .iOS
        #endif
    }

    private var prefersLargeContent: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    @ViewBuilder
    private func primarySection(layout: Layout) -> some View {
        HStack(spacing: DS.Spacing.s) {
            ForEach(items.primary) { item in
                toolbarButton(for: item, layout: layout)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Primary Actions"))
    }

    @ViewBuilder
    private func secondarySection(layout: Layout) -> some View {
        HStack(spacing: DS.Spacing.s) {
            ForEach(items.secondary) { item in
                toolbarButton(for: item, layout: layout)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Secondary Actions"))
    }

    @ViewBuilder
    private func overflowSection() -> some View {
        Menu {
            ForEach(items.overflow) { item in
                Button(item.menuTitle) {
                    item.action()
                }
                .keyboardShortcut(item.shortcut)
                .accessibilityLabel(Text(item.accessibilityLabel))
                .accessibilityHint(Text(item.accessibilityHint ?? ""))
            }
        } label: {
            Label("More", systemImage: "ellipsis.circle")
                .labelStyle(.iconOnly)
                .frame(minWidth: DS.Spacing.xl, minHeight: DS.Spacing.xl)
                .accessibilityLabel(Text("More Actions"))
        }
    }

    @ViewBuilder
    private func toolbarButton(for item: Item, layout: Layout) -> some View {
        Button(action: item.action) {
            Group {
                switch layout {
                case .compact:
                    Image(systemName: item.iconSystemName)
                        .frame(width: DS.Spacing.xl, height: DS.Spacing.xl)
                case .expanded:
                    if let title = item.title {
                        Label(title, systemImage: item.iconSystemName)
                    } else {
                        Image(systemName: item.iconSystemName)
                            .frame(width: DS.Spacing.xl, height: DS.Spacing.xl)
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.s)
            .padding(.vertical, DS.Spacing.s)
            .frame(minHeight: DS.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous)
                    .fill(item.role.backgroundColor)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(item.accessibilityLabel))
        .accessibilityHint(Text(item.accessibilityHint ?? ""))
        .keyboardShortcut(item.shortcut)
    }
}

// MARK: - Public Types

public extension ToolbarPattern {
    /// Represents grouped toolbar items.
    struct Items {
        public var primary: [Item]
        public var secondary: [Item]
        public var overflow: [Item]

        public init(primary: [Item] = [], secondary: [Item] = [], overflow: [Item] = []) {
            self.primary = primary
            self.secondary = secondary
            self.overflow = overflow
        }
    }

    /// Describes a single toolbar action item.
    struct Item: Identifiable {
        public let id: String
        public let iconSystemName: String
        public let title: String?
        public let accessibilityHint: String?
        public let role: Role
        public let shortcut: Shortcut?
        public let action: () -> Void

        public init(
            id: String,
            iconSystemName: String,
            title: String? = nil,
            accessibilityHint: String? = nil,
            role: Role = .primaryAction,
            shortcut: Shortcut? = nil,
            action: @escaping () -> Void = {}
        ) {
            self.id = id
            self.iconSystemName = iconSystemName
            self.title = title
            self.accessibilityHint = accessibilityHint
            self.role = role
            self.shortcut = shortcut
            self.action = action
        }

        public var accessibilityLabel: String {
            var components: [String] = []
            if let title {
                components.append(title)
            } else {
                components.append(menuTitle)
            }
            if let shortcutDescription = shortcut?.glyphRepresentation {
                components.append(shortcutDescription)
            }
            return components.joined(separator: ", ")
        }

        fileprivate var menuTitle: String {
            title ?? iconSystemName.replacingOccurrences(of: ".", with: " ")
        }
    }

    /// Keyboard shortcut metadata attached to toolbar items.
    struct Shortcut: Hashable {
        public enum Modifier: Hashable {
            case command
            case option
            case shift
            case control
        }

        public let key: String
        public let modifiers: [Modifier]
        public let description: String?

        public init(key: String, modifiers: [Modifier] = [], description: String? = nil) {
            self.key = key
            self.modifiers = modifiers
            self.description = description
        }

        fileprivate var glyphRepresentation: String {
            let glyphs = modifiers.map { $0.glyph }.joined()
            return glyphs + key.uppercased()
        }
    }

    /// Semantic role classification for toolbar items.
    enum Role {
        case primaryAction
        case destructive
        case neutral

        fileprivate var backgroundColor: Color {
            switch self {
            case .primaryAction:
                return DS.Color.tertiary
            case .destructive:
                return DS.Color.errorBG
            case .neutral:
                return DS.Color.infoBG
            }
        }
    }

    /// Layout modes supported by the toolbar.
    enum Layout: Equatable {
        case compact
        case expanded
    }

    /// Supported platform contexts for layout resolution.
    enum Platform: Equatable {
        case iOS
        case iPadOS
        case macOS
    }

    /// Encapsulates runtime traits used for resolving layout.
    struct Traits: Equatable {
        public let horizontalSizeClass: UserInterfaceSizeClass?
        public let platform: Platform
        public let prefersLargeContent: Bool

        public init(
            horizontalSizeClass: UserInterfaceSizeClass?,
            platform: Platform,
            prefersLargeContent: Bool
        ) {
            self.horizontalSizeClass = horizontalSizeClass
            self.platform = platform
            self.prefersLargeContent = prefersLargeContent
        }
    }

    enum LayoutResolver {
        public static func layout(for traits: Traits) -> Layout {
            if traits.prefersLargeContent {
                return .expanded
            }

            switch traits.platform {
            case .macOS:
                return .expanded
            case .iPadOS:
                return .expanded
            case .iOS:
                if traits.horizontalSizeClass == .compact {
                    return .compact
                } else {
                    return .expanded
                }
            }
        }
    }
}

private extension ToolbarPattern.Shortcut.Modifier {
    var glyph: String {
        switch self {
        case .command:
            return "⌘"
        case .option:
            return "⌥"
        case .shift:
            return "⇧"
        case .control:
            return "⌃"
        }
    }
}

#if canImport(SwiftUI)
private extension View {
    @ViewBuilder
    func keyboardShortcut(_ shortcut: ToolbarPattern.Shortcut?) -> some View {
        if let shortcut {
            #if os(macOS) || os(iOS)
            let modifiers = shortcut.modifiers.reduce(into: SwiftUI.EventModifiers()) { result, modifier in
                switch modifier {
                case .command:
                    result.insert(.command)
                case .option:
                    result.insert(.option)
                case .shift:
                    result.insert(.shift)
                case .control:
                    result.insert(.control)
                }
            }
            if let firstCharacter = shortcut.key.lowercased().first {
                self.keyboardShortcut(
                    KeyEquivalent(firstCharacter),
                    modifiers: modifiers
                )
            } else {
                self
            }
            #else
            self
            #endif
        } else {
            self
        }
    }
}
#endif

// MARK: - Preview Catalogue

#Preview("Compact Toolbar") {
    ToolbarPattern(
        items: .init(
            primary: [
                .init(id: "inspect", iconSystemName: "magnifyingglass", title: "Inspect"),
                .init(id: "share", iconSystemName: "square.and.arrow.up", title: "Share")
            ],
            secondary: [
                .init(id: "flag", iconSystemName: "flag", title: "Flag", role: .neutral)
            ],
            overflow: [
                .init(
                    id: "archive",
                    iconSystemName: "archivebox",
                    title: "Archive",
                    shortcut: .init(key: "a", modifiers: [.command])
                )
            ]
        ),
        layoutOverride: .compact
    )
    .padding(DS.Spacing.l)
}

#Preview("Expanded Toolbar") {
    ToolbarPattern(
        items: .init(
            primary: [
                .init(id: "validate", iconSystemName: "checkmark.seal", title: "Validate"),
                .init(id: "export", iconSystemName: "square.and.arrow.up", title: "Export")
            ],
            secondary: [
                .init(id: "flag", iconSystemName: "flag", title: "Flag", role: .neutral)
            ]
        ),
        layoutOverride: .expanded
    )
    .padding(DS.Spacing.l)
}
