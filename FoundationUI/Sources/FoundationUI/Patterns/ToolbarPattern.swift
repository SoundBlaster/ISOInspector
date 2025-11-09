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
                .fill(DS.Colors.tertiary)
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
                return DS.Colors.tertiary
            case .destructive:
                return DS.Colors.errorBG
            case .neutral:
                return DS.Colors.infoBG
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

#Preview("Dark Mode") {
    VStack(spacing: DS.Spacing.l) {
        ToolbarPattern(
            items: .init(
                primary: [
                    .init(id: "inspect", iconSystemName: "magnifyingglass", title: "Inspect"),
                    .init(id: "validate", iconSystemName: "checkmark.seal", title: "Validate")
                ],
                secondary: [
                    .init(id: "share", iconSystemName: "square.and.arrow.up", title: "Share"),
                    .init(id: "flag", iconSystemName: "flag", title: "Flag", role: .neutral)
                ],
                overflow: [
                    .init(id: "settings", iconSystemName: "gearshape", title: "Settings")
                ]
            ),
            layoutOverride: .expanded
        )

        Text("Dark mode enhances toolbar visibility")
            .font(DS.Typography.caption)
            .foregroundStyle(.secondary)
    }
    .padding(DS.Spacing.l)
    .preferredColorScheme(.dark)
}

#Preview("Role Variants") {
    VStack(spacing: DS.Spacing.l) {
        Text("Primary Action Role")
            .font(DS.Typography.caption)
            .foregroundStyle(.secondary)

        ToolbarPattern(
            items: .init(
                primary: [
                    .init(id: "save", iconSystemName: "square.and.arrow.down", title: "Save", role: .primaryAction),
                    .init(id: "open", iconSystemName: "folder", title: "Open", role: .primaryAction)
                ]
            ),
            layoutOverride: .expanded
        )

        Text("Destructive Role")
            .font(DS.Typography.caption)
            .foregroundStyle(.secondary)

        ToolbarPattern(
            items: .init(
                primary: [
                    .init(id: "delete", iconSystemName: "trash", title: "Delete", role: .destructive),
                    .init(id: "clear", iconSystemName: "xmark.circle", title: "Clear", role: .destructive)
                ]
            ),
            layoutOverride: .expanded
        )

        Text("Neutral Role")
            .font(DS.Typography.caption)
            .foregroundStyle(.secondary)

        ToolbarPattern(
            items: .init(
                primary: [
                    .init(id: "info", iconSystemName: "info.circle", title: "Info", role: .neutral),
                    .init(id: "help", iconSystemName: "questionmark.circle", title: "Help", role: .neutral)
                ]
            ),
            layoutOverride: .expanded
        )
    }
    .padding(DS.Spacing.l)
}

#Preview("Keyboard Shortcuts") {
    VStack(spacing: DS.Spacing.l) {
        Text("Toolbar with keyboard shortcuts")
            .font(DS.Typography.caption)
            .foregroundStyle(.secondary)

        ToolbarPattern(
            items: .init(
                primary: [
                    .init(
                        id: "save",
                        iconSystemName: "square.and.arrow.down",
                        title: "Save",
                        shortcut: .init(key: "s", modifiers: [.command])
                    ),
                    .init(
                        id: "open",
                        iconSystemName: "folder",
                        title: "Open",
                        shortcut: .init(key: "o", modifiers: [.command])
                    )
                ],
                secondary: [
                    .init(
                        id: "find",
                        iconSystemName: "magnifyingglass",
                        title: "Find",
                        shortcut: .init(key: "f", modifiers: [.command])
                    )
                ]
            ),
            layoutOverride: .expanded
        )

        Text("Shortcuts: ⌘S, ⌘O, ⌘F")
            .font(DS.Typography.caption)
            .foregroundStyle(.secondary)
    }
    .padding(DS.Spacing.l)
}

#Preview("Overflow Menu") {
    VStack(spacing: DS.Spacing.l) {
        Text("Toolbar with overflow menu")
            .font(DS.Typography.caption)
            .foregroundStyle(.secondary)

        ToolbarPattern(
            items: .init(
                primary: [
                    .init(id: "validate", iconSystemName: "checkmark.seal", title: "Validate"),
                    .init(id: "export", iconSystemName: "square.and.arrow.up", title: "Export")
                ],
                secondary: [],
                overflow: [
                    .init(
                        id: "archive",
                        iconSystemName: "archivebox",
                        title: "Archive",
                        shortcut: .init(key: "a", modifiers: [.command])
                    ),
                    .init(
                        id: "duplicate",
                        iconSystemName: "doc.on.doc",
                        title: "Duplicate",
                        shortcut: .init(key: "d", modifiers: [.command])
                    ),
                    .init(
                        id: "settings",
                        iconSystemName: "gearshape",
                        title: "Settings",
                        shortcut: .init(key: ",", modifiers: [.command])
                    )
                ]
            ),
            layoutOverride: .expanded
        )

        Text("Additional actions available in overflow menu")
            .font(DS.Typography.caption)
            .foregroundStyle(.secondary)
    }
    .padding(DS.Spacing.l)
}

#Preview("Platform-Specific Layout") {
    VStack(spacing: DS.Spacing.l) {
        #if os(macOS)
        Text("macOS: Expanded layout with labels")
            .font(DS.Typography.caption)
            .foregroundStyle(.secondary)
        #else
        Text("iOS: Compact layout, icon-only")
            .font(DS.Typography.caption)
            .foregroundStyle(.secondary)
        #endif

        ToolbarPattern(
            items: .init(
                primary: [
                    .init(id: "inspect", iconSystemName: "magnifyingglass", title: "Inspect"),
                    .init(id: "validate", iconSystemName: "checkmark.seal", title: "Validate")
                ],
                secondary: [
                    .init(id: "share", iconSystemName: "square.and.arrow.up", title: "Share")
                ]
            )
        )

        #if os(macOS)
        KeyValueRow(key: "Layout", value: "Expanded")
        #else
        KeyValueRow(key: "Layout", value: "Compact")
        #endif
    }
    .padding(DS.Spacing.l)
}

#Preview("Dynamic Type - Small") {
    ToolbarPattern(
        items: .init(
            primary: [
                .init(id: "save", iconSystemName: "square.and.arrow.down", title: "Save"),
                .init(id: "open", iconSystemName: "folder", title: "Open")
            ],
            secondary: [
                .init(id: "share", iconSystemName: "square.and.arrow.up", title: "Share")
            ]
        ),
        layoutOverride: .expanded
    )
    .padding(DS.Spacing.l)
    .environment(\.dynamicTypeSize, .xSmall)
}

#Preview("Dynamic Type - Large") {
    ToolbarPattern(
        items: .init(
            primary: [
                .init(id: "save", iconSystemName: "square.and.arrow.down", title: "Save"),
                .init(id: "open", iconSystemName: "folder", title: "Open")
            ],
            secondary: [
                .init(id: "share", iconSystemName: "square.and.arrow.up", title: "Share")
            ]
        ),
        layoutOverride: .expanded
    )
    .padding(DS.Spacing.l)
    .environment(\.dynamicTypeSize, .xxxLarge)
}

#Preview("ISO Inspector Toolbar") {
    VStack(spacing: DS.Spacing.m) {
        Text("ISO File Inspector Toolbar")
            .font(DS.Typography.title)
            .frame(maxWidth: .infinity, alignment: .leading)

        ToolbarPattern(
            items: .init(
                primary: [
                    .init(
                        id: "validate",
                        iconSystemName: "checkmark.seal.fill",
                        title: "Validate",
                        accessibilityHint: "Validate ISO file structure",
                        shortcut: .init(key: "v", modifiers: [.command])
                    ),
                    .init(
                        id: "inspect",
                        iconSystemName: "magnifyingglass",
                        title: "Inspect",
                        accessibilityHint: "Open box inspector",
                        shortcut: .init(key: "i", modifiers: [.command])
                    )
                ],
                secondary: [
                    .init(
                        id: "export",
                        iconSystemName: "square.and.arrow.up",
                        title: "Export",
                        accessibilityHint: "Export metadata to file",
                        role: .primaryAction,
                        shortcut: .init(key: "e", modifiers: [.command, .shift])
                    ),
                    .init(
                        id: "flag",
                        iconSystemName: "flag",
                        title: "Flag Issues",
                        accessibilityHint: "Show validation warnings",
                        role: .neutral
                    )
                ],
                overflow: [
                    .init(
                        id: "hex",
                        iconSystemName: "number",
                        title: "Hex View",
                        accessibilityHint: "Open hex viewer",
                        shortcut: .init(key: "h", modifiers: [.command, .option])
                    ),
                    .init(
                        id: "compare",
                        iconSystemName: "arrow.left.arrow.right",
                        title: "Compare Files",
                        accessibilityHint: "Compare with another ISO file"
                    ),
                    .init(
                        id: "settings",
                        iconSystemName: "gearshape",
                        title: "Settings",
                        shortcut: .init(key: ",", modifiers: [.command])
                    )
                ]
            ),
            layoutOverride: .expanded
        )

        InspectorPattern(title: "File Details") {
            SectionHeader(title: "Loaded File")
            KeyValueRow(key: "File", value: "sample_video.mp4")
            KeyValueRow(key: "Size", value: "125.4 MB")
        }
        .material(.regular)
    }
    .padding(DS.Spacing.l)
}

#Preview("Empty Toolbar") {
    VStack(spacing: DS.Spacing.l) {
        Text("Toolbar with no items")
            .font(DS.Typography.caption)
            .foregroundStyle(.secondary)

        ToolbarPattern(
            items: .init(
                primary: [],
                secondary: [],
                overflow: []
            ),
            layoutOverride: .expanded
        )

        Text("Empty toolbar still maintains structure")
            .font(DS.Typography.caption)
            .foregroundStyle(.secondary)
    }
    .padding(DS.Spacing.l)
}

#Preview("Accessibility Hints") {
    ToolbarPattern(
        items: .init(
            primary: [
                .init(
                    id: "save",
                    iconSystemName: "square.and.arrow.down",
                    title: "Save",
                    accessibilityHint: "Save current document to disk"
                ),
                .init(
                    id: "delete",
                    iconSystemName: "trash",
                    title: "Delete",
                    accessibilityHint: "Permanently delete this item",
                    role: .destructive
                )
            ],
            secondary: [
                .init(
                    id: "info",
                    iconSystemName: "info.circle",
                    title: "Info",
                    accessibilityHint: "Show detailed information about this file",
                    role: .neutral
                )
            ]
        ),
        layoutOverride: .expanded
    )
    .padding(DS.Spacing.l)
}

// MARK: - AgentDescribable Conformance

@available(iOS 17.0, macOS 14.0, *)
@MainActor
extension ToolbarPattern: AgentDescribable {
    public var componentType: String {
        "ToolbarPattern"
    }

    public var properties: [String: Any] {
        [
            "items": [
                "primary": items.primary.count,
                "secondary": items.secondary.count,
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
