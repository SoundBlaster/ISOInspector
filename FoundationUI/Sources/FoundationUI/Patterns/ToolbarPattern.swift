// @todo #234 Fix ToolbarPattern closure parameter positions
// swiftlint:disable closure_parameter_position

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
///
/// ## NavigationSplitScaffold Integration
///
/// When used inside ``NavigationSplitScaffold``, this pattern automatically adds
/// navigation column toggle buttons with keyboard shortcuts:
/// - ⌘⌃S: Toggle sidebar column
/// - ⌘⌥I: Toggle inspector column
///
/// ```swift
/// // Standalone usage
/// ToolbarPattern(items: .init(primary: [/* ... */]))
///
/// // Inside scaffold (automatically adds navigation controls)
/// NavigationSplitScaffold {
///     SidebarPattern(...)
/// } content: {
///     VStack {
///         ToolbarPattern(items: .init(primary: [/* ... */]))
///         ContentView()
///     }
/// } detail: {
///     InspectorPattern(...)
/// }
/// ```
@available(iOS 17.0, macOS 14.0, *) public struct ToolbarPattern: View {
    public let items: Items
    public let layoutOverride: Layout?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.navigationModel) private var navigationModel

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
            // Navigation controls (when inside scaffold)
            if isInScaffold {
                navigationControls(layout: resolvedLayout)
                if !items.primary.isEmpty || !items.secondary.isEmpty {
                    Divider().frame(height: DS.Spacing.xl).padding(.vertical, DS.Spacing.s)
                }
            }

            primarySection(layout: resolvedLayout)

            if !items.secondary.isEmpty {
                Divider().frame(height: DS.Spacing.xl).padding(.vertical, DS.Spacing.s)
                secondarySection(layout: resolvedLayout)
            }

            if !items.overflow.isEmpty { overflowSection() }
        }.padding(.horizontal, DS.Spacing.m).padding(.vertical, DS.Spacing.s).frame(
            maxWidth: .infinity, alignment: .leading
        ).background(
            RoundedRectangle(cornerRadius: DS.Radius.medium, style: .continuous).fill(
                DS.Colors.tertiary)
        ).accessibilityElement(children: .contain).accessibilityLabel(
            Text(isInScaffold ? "Navigation Toolbar" : "Toolbar"))
    }

    /// Returns true if this pattern is being used inside a NavigationSplitScaffold.
    private var isInScaffold: Bool { navigationModel != nil }

    private var layout: Layout {
        if let override = layoutOverride { return override }

        let traits = Traits(
            horizontalSizeClass: horizontalSizeClass, platform: platform,
            prefersLargeContent: prefersLargeContent)

        return LayoutResolver.layout(for: traits)
    }

    private var platform: Platform {
        #if os(macOS)
            return .macOS
        #elseif os(iOS)
            #if canImport(UIKit)
                switch UIDevice.current.userInterfaceIdiom {
                case .pad: return .iPadOS
                default: return .iOS
                }
            #else
                return .iOS
            #endif
        #else
            return .iOS
        #endif
    }

    private var prefersLargeContent: Bool { dynamicTypeSize.isAccessibilitySize }

    @ViewBuilder private func navigationControls(layout: Layout) -> some View {
        HStack(spacing: DS.Spacing.s) {
            // Toggle Sidebar button
            Button(action: toggleSidebar) {
                Group {
                    switch layout {
                    case .compact:
                        Image(systemName: "sidebar.left").frame(
                            width: DS.Spacing.xl, height: DS.Spacing.xl)
                    case .expanded: Label("Sidebar", systemImage: "sidebar.left")
                    }
                }.padding(.horizontal, DS.Spacing.s).padding(.vertical, DS.Spacing.s).frame(
                    minHeight: DS.Spacing.xl
                ).background(
                    RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous).fill(
                        DS.Colors.tertiary))
            }.buttonStyle(.plain).accessibilityLabel(Text("Toggle Sidebar")).accessibilityHint(
                Text("Show or hide the sidebar column")
            ).keyboardShortcut("s", modifiers: [.command, .control])

            // Toggle Inspector button
            Button(action: toggleInspector) {
                Group {
                    switch layout {
                    case .compact:
                        Image(systemName: "sidebar.right").frame(
                            width: DS.Spacing.xl, height: DS.Spacing.xl)
                    case .expanded: Label("Inspector", systemImage: "sidebar.right")
                    }
                }.padding(.horizontal, DS.Spacing.s).padding(.vertical, DS.Spacing.s).frame(
                    minHeight: DS.Spacing.xl
                ).background(
                    RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous).fill(
                        DS.Colors.tertiary))
            }.buttonStyle(.plain).accessibilityLabel(Text("Toggle Inspector")).accessibilityHint(
                Text("Show or hide the inspector column")
            ).keyboardShortcut("i", modifiers: [.command, .option])
        }.accessibilityElement(children: .contain).accessibilityLabel(Text("Navigation Controls"))
    }

    /// Toggles sidebar visibility. Switches between .all and .doubleColumn modes.
    private func toggleSidebar() {
        guard let model = navigationModel else { return }
        withAnimation(DS.Animation.medium) {
            if model.columnVisibility == .all {
                model.columnVisibility = .doubleColumn
            } else {
                model.columnVisibility = .all
            }
        }
    }

    /// Toggles inspector visibility. Switches between .all and .detailOnly modes.
    private func toggleInspector() {
        guard let model = navigationModel else { return }
        withAnimation(DS.Animation.medium) {
            if model.columnVisibility == .all {
                model.columnVisibility = .detailOnly
            } else if model.columnVisibility == .detailOnly
                || model.columnVisibility == .doubleColumn {
                model.columnVisibility = .all
            } else {
                // From .automatic, go to .all
                model.columnVisibility = .all
            }
        }
    }

    @ViewBuilder private func primarySection(layout: Layout) -> some View {
        HStack(spacing: DS.Spacing.s) {
            ForEach(items.primary) { item in toolbarButton(for: item, layout: layout) }
        }.accessibilityElement(children: .contain).accessibilityLabel(Text("Primary Actions"))
    }

    @ViewBuilder private func secondarySection(layout: Layout) -> some View {
        HStack(spacing: DS.Spacing.s) {
            ForEach(items.secondary) { item in toolbarButton(for: item, layout: layout) }
        }.accessibilityElement(children: .contain).accessibilityLabel(Text("Secondary Actions"))
    }

    @ViewBuilder private func overflowSection() -> some View {
        Menu {
            ForEach(items.overflow) { item in
                Button(item.menuTitle) { item.action() }.keyboardShortcut(item.shortcut)
                    .accessibilityLabel(Text(item.accessibilityLabel)).accessibilityHint(
                        Text(item.accessibilityHint ?? ""))
            }
        } label: {
            Label("More", systemImage: "ellipsis.circle").labelStyle(.iconOnly).frame(
                minWidth: DS.Spacing.xl, minHeight: DS.Spacing.xl
            ).accessibilityLabel(Text("More Actions"))
        }
    }

    @ViewBuilder private func toolbarButton(for item: Item, layout: Layout) -> some View {
        Button(action: item.action) {
            Group {
                switch layout {
                case .compact:
                    Image(systemName: item.iconSystemName).frame(
                        width: DS.Spacing.xl, height: DS.Spacing.xl)
                case .expanded:
                    if let title = item.title {
                        Label(title, systemImage: item.iconSystemName)
                    } else {
                        Image(systemName: item.iconSystemName).frame(
                            width: DS.Spacing.xl, height: DS.Spacing.xl)
                    }
                }
            }.padding(.horizontal, DS.Spacing.s).padding(.vertical, DS.Spacing.s).frame(
                minHeight: DS.Spacing.xl
            ).background(
                RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous).fill(
                    item.role.backgroundColor))
        }.buttonStyle(.plain).accessibilityLabel(Text(item.accessibilityLabel)).accessibilityHint(
            Text(item.accessibilityHint ?? "")
        ).keyboardShortcut(item.shortcut)
    }
}

// MARK: - Public Types

extension ToolbarPattern {
    /// Represents grouped toolbar items.
    public struct Items {
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
    public struct Item: Identifiable {
        public let id: String
        public let iconSystemName: String
        public let title: String?
        public let accessibilityHint: String?
        public let role: Role
        public let shortcut: Shortcut?
        public let action: () -> Void

        public init(
            id: String, iconSystemName: String, title: String? = nil,
            accessibilityHint: String? = nil, role: Role = .primaryAction,
            shortcut: Shortcut? = nil, action: @escaping () -> Void = {}
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
            if let title { components.append(title) } else { components.append(menuTitle) }
            if let shortcutDescription = shortcut?.glyphRepresentation {
                components.append(shortcutDescription)
            }
            return components.joined(separator: ", ")
        }

        var menuTitle: String { title ?? iconSystemName.replacingOccurrences(of: ".", with: " ") }
    }

    /// Keyboard shortcut metadata attached to toolbar items.
    public struct Shortcut: Hashable {
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

        var glyphRepresentation: String {
            let glyphs = modifiers.map(\.glyph).joined()
            return glyphs + key.uppercased()
        }
    }

    /// Semantic role classification for toolbar items.
    public enum Role {
        case primaryAction
        case destructive
        case neutral

        var backgroundColor: Color {
            switch self {
            case .primaryAction: DS.Colors.tertiary
            case .destructive: DS.Colors.errorBG
            case .neutral: DS.Colors.infoBG
            }
        }
    }

    /// Layout modes supported by the toolbar.
    public enum Layout: Equatable {
        case compact
        case expanded
    }

    /// Supported platform contexts for layout resolution.
    public enum Platform: Equatable {
        case iOS
        case iPadOS
        case macOS
    }

    /// Encapsulates runtime traits used for resolving layout.
    public struct Traits: Equatable {
        public let horizontalSizeClass: UserInterfaceSizeClass?
        public let platform: Platform
        public let prefersLargeContent: Bool

        public init(
            horizontalSizeClass: UserInterfaceSizeClass?, platform: Platform,
            prefersLargeContent: Bool
        ) {
            self.horizontalSizeClass = horizontalSizeClass
            self.platform = platform
            self.prefersLargeContent = prefersLargeContent
        }
    }

    public enum LayoutResolver {
        public static func layout(for traits: Traits) -> Layout {
            if traits.prefersLargeContent { return .expanded }

            switch traits.platform {
            case .macOS: return .expanded
            case .iPadOS, .iOS:
                // iPadOS and iOS use compact layout when horizontal size class is compact
                // This happens in Split View on iPad or on smaller iPhones
                if traits.horizontalSizeClass == .compact {
                    return .compact
                } else {
                    return .expanded
                }
            }
        }
    }
}

extension ToolbarPattern.Shortcut.Modifier {
    var glyph: String {
        switch self {
        case .command: "⌘"
        case .option: "⌥"
        case .shift: "⇧"
        case .control: "⌃"
        }
    }
}

#if canImport(SwiftUI)
    extension View {
        @ViewBuilder func keyboardShortcut(_ shortcut: ToolbarPattern.Shortcut?) -> some View {
            if let shortcut {
                #if os(macOS) || os(iOS)
                    let modifiers = shortcut.modifiers.reduce(into: SwiftUI.EventModifiers()) {
                        result, modifier in
                        switch modifier {
                        case .command: result.insert(.command)
                        case .option: result.insert(.option)
                        case .shift: result.insert(.shift)
                        case .control: result.insert(.control)
                        }
                    }
                    if let firstCharacter = shortcut.key.lowercased().first {
                        keyboardShortcut(KeyEquivalent(firstCharacter), modifiers: modifiers)
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

@available(iOS 17.0, macOS 14.0, *) @MainActor extension ToolbarPattern: AgentDescribable {
    public var componentType: String { "ToolbarPattern" }

    public var properties: [String: Any] {
        [
            "items": [
                "primary": items.primary.count, "secondary": items.secondary.count,
                "overflow": items.overflow.count
            ]
        ]
    }

    public var semantics: String {
        """
        A platform-adaptive toolbar with \(items.primary.count + items.secondary.count + items.overflow.count) action(s). \
        Primary: \(items.primary.count), Secondary: \(items.secondary.count), Overflow: \(items.overflow.count).
        """
    }
}
