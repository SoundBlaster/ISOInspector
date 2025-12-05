import SwiftUI

#if DEBUG
    // MARK: - ToolbarPattern Previews

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
                        id: "archive", iconSystemName: "archivebox", title: "Archive",
                        shortcut: .init(key: "a", modifiers: [.command]))
                ]), layoutOverride: .compact
        ).padding(DS.Spacing.l)
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
                ]), layoutOverride: .expanded
        ).padding(DS.Spacing.l)
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
                    ]), layoutOverride: .expanded)

            Text("Dark mode enhances toolbar visibility").font(DS.Typography.caption)
                .foregroundStyle(.secondary)
        }.padding(DS.Spacing.l).preferredColorScheme(.dark)
    }

    #Preview("Role Variants") {
        VStack(spacing: DS.Spacing.l) {
            Text("Primary Action Role").font(DS.Typography.caption).foregroundStyle(.secondary)

            ToolbarPattern(
                items: .init(primary: [
                    .init(
                        id: "save", iconSystemName: "square.and.arrow.down", title: "Save",
                        role: .primaryAction),
                    .init(
                        id: "open", iconSystemName: "folder", title: "Open", role: .primaryAction)
                ]), layoutOverride: .expanded)

            Text("Destructive Role").font(DS.Typography.caption).foregroundStyle(.secondary)

            ToolbarPattern(
                items: .init(primary: [
                    .init(
                        id: "delete", iconSystemName: "trash", title: "Delete", role: .destructive),
                    .init(
                        id: "clear", iconSystemName: "xmark.circle", title: "Clear",
                        role: .destructive)
                ]), layoutOverride: .expanded)

            Text("Neutral Role").font(DS.Typography.caption).foregroundStyle(.secondary)

            ToolbarPattern(
                items: .init(primary: [
                    .init(id: "info", iconSystemName: "info.circle", title: "Info", role: .neutral),
                    .init(
                        id: "help", iconSystemName: "questionmark.circle", title: "Help",
                        role: .neutral)
                ]), layoutOverride: .expanded)
        }.padding(DS.Spacing.l)
    }

    #Preview("Keyboard Shortcuts") {
        VStack(spacing: DS.Spacing.l) {
            Text("Toolbar with keyboard shortcuts").font(DS.Typography.caption).foregroundStyle(
                .secondary)

            ToolbarPattern(
                items: .init(
                    primary: [
                        .init(
                            id: "save", iconSystemName: "square.and.arrow.down", title: "Save",
                            shortcut: .init(key: "s", modifiers: [.command])),
                        .init(
                            id: "open", iconSystemName: "folder", title: "Open",
                            shortcut: .init(key: "o", modifiers: [.command]))
                    ],
                    secondary: [
                        .init(
                            id: "find", iconSystemName: "magnifyingglass", title: "Find",
                            shortcut: .init(key: "f", modifiers: [.command]))
                    ]), layoutOverride: .expanded)

            Text("Shortcuts: ⌘S, ⌘O, ⌘F").font(DS.Typography.caption).foregroundStyle(.secondary)
        }.padding(DS.Spacing.l)
    }

    #Preview("Overflow Menu") {
        VStack(spacing: DS.Spacing.l) {
            Text("Toolbar with overflow menu").font(DS.Typography.caption).foregroundStyle(
                .secondary)

            ToolbarPattern(
                items: .init(
                    primary: [
                        .init(id: "validate", iconSystemName: "checkmark.seal", title: "Validate"),
                        .init(id: "export", iconSystemName: "square.and.arrow.up", title: "Export")
                    ], secondary: [],
                    overflow: [
                        .init(
                            id: "archive", iconSystemName: "archivebox", title: "Archive",
                            shortcut: .init(key: "a", modifiers: [.command])),
                        .init(
                            id: "duplicate", iconSystemName: "doc.on.doc", title: "Duplicate",
                            shortcut: .init(key: "d", modifiers: [.command])),
                        .init(
                            id: "settings", iconSystemName: "gearshape", title: "Settings",
                            shortcut: .init(key: ",", modifiers: [.command]))
                    ]), layoutOverride: .expanded)

            Text("Additional actions available in overflow menu").font(DS.Typography.caption)
                .foregroundStyle(.secondary)
        }.padding(DS.Spacing.l)
    }

    #Preview("Platform-Specific Layout") {
        VStack(spacing: DS.Spacing.l) {
            #if os(macOS)
                Text("macOS: Expanded layout with labels").font(DS.Typography.caption)
                    .foregroundStyle(.secondary)
            #else
                Text("iOS: Compact layout, icon-only").font(DS.Typography.caption).foregroundStyle(
                    .secondary)
            #endif

            ToolbarPattern(
                items: .init(
                    primary: [
                        .init(id: "inspect", iconSystemName: "magnifyingglass", title: "Inspect"),
                        .init(id: "validate", iconSystemName: "checkmark.seal", title: "Validate")
                    ],
                    secondary: [
                        .init(id: "share", iconSystemName: "square.and.arrow.up", title: "Share")
                    ]))

            #if os(macOS)
                KeyValueRow(key: "Layout", value: "Expanded")
            #else
                KeyValueRow(key: "Layout", value: "Compact")
            #endif
        }.padding(DS.Spacing.l)
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
                ]), layoutOverride: .expanded
        ).padding(DS.Spacing.l).environment(\.dynamicTypeSize, .xSmall)
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
                ]), layoutOverride: .expanded
        ).padding(DS.Spacing.l).environment(\.dynamicTypeSize, .xxxLarge)
    }

    #Preview("ISO Inspector Toolbar") {
        VStack(spacing: DS.Spacing.m) {
            Text("ISO File Inspector Toolbar").font(DS.Typography.title).frame(
                maxWidth: .infinity, alignment: .leading)

            ToolbarPattern(
                items: .init(
                    primary: [
                        .init(
                            id: "validate", iconSystemName: "checkmark.seal.fill",
                            title: "Validate", accessibilityHint: "Validate ISO file structure",
                            shortcut: .init(key: "v", modifiers: [.command])),
                        .init(
                            id: "inspect", iconSystemName: "magnifyingglass", title: "Inspect",
                            accessibilityHint: "Open box inspector",
                            shortcut: .init(key: "i", modifiers: [.command]))
                    ],
                    secondary: [
                        .init(
                            id: "export", iconSystemName: "square.and.arrow.up", title: "Export",
                            accessibilityHint: "Export metadata to file", role: .primaryAction,
                            shortcut: .init(key: "e", modifiers: [.command, .shift])),
                        .init(
                            id: "flag", iconSystemName: "flag", title: "Flag Issues",
                            accessibilityHint: "Show validation warnings", role: .neutral)
                    ],
                    overflow: [
                        .init(
                            id: "hex", iconSystemName: "number", title: "Hex View",
                            accessibilityHint: "Open hex viewer",
                            shortcut: .init(key: "h", modifiers: [.command, .option])),
                        .init(
                            id: "compare", iconSystemName: "arrow.left.arrow.right",
                            title: "Compare Files",
                            accessibilityHint: "Compare with another ISO file"),
                        .init(
                            id: "settings", iconSystemName: "gearshape", title: "Settings",
                            shortcut: .init(key: ",", modifiers: [.command]))
                    ]), layoutOverride: .expanded)

            InspectorPattern(title: "File Details") {
                SectionHeader(title: "Loaded File")
                KeyValueRow(key: "File", value: "sample_video.mp4")
                KeyValueRow(key: "Size", value: "125.4 MB")
            }.material(.regular)
        }.padding(DS.Spacing.l)
    }

    #Preview("Empty Toolbar") {
        VStack(spacing: DS.Spacing.l) {
            Text("Toolbar with no items").font(DS.Typography.caption).foregroundStyle(.secondary)

            ToolbarPattern(
                items: .init(primary: [], secondary: [], overflow: []), layoutOverride: .expanded)

            Text("Empty toolbar still maintains structure").font(DS.Typography.caption)
                .foregroundStyle(.secondary)
        }.padding(DS.Spacing.l)
    }

    #Preview("Accessibility Hints") {
        ToolbarPattern(
            items: .init(
                primary: [
                    .init(
                        id: "save", iconSystemName: "square.and.arrow.down", title: "Save",
                        accessibilityHint: "Save current document to disk"),
                    .init(
                        id: "delete", iconSystemName: "trash", title: "Delete",
                        accessibilityHint: "Permanently delete this item", role: .destructive)
                ],
                secondary: [
                    .init(
                        id: "info", iconSystemName: "info.circle", title: "Info",
                        accessibilityHint: "Show detailed information about this file",
                        role: .neutral)
                ]), layoutOverride: .expanded
        ).padding(DS.Spacing.l)
    }

    #Preview("With NavigationSplitScaffold") {
        @Previewable @State var selection: String? = "file1"
        @Previewable @State var navigationModel = NavigationModel()

        NavigationSplitScaffold(model: navigationModel) {
            List {
                Section("Files") {
                    ForEach(["file1", "file2", "file3"], id: \.self) { file in
                        Label(file, systemImage: "doc.fill").tag(file)
                    }
                }
            }.listStyle(.sidebar)
        } content: {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                // Toolbar with navigation controls (automatically adds sidebar/inspector toggles)
                ToolbarPattern(
                    items: .init(
                        primary: [
                            .init(
                                id: "validate", iconSystemName: "checkmark.seal.fill",
                                title: "Validate", accessibilityHint: "Validate file structure",
                                shortcut: .init(key: "v", modifiers: [.command])),
                            .init(
                                id: "inspect", iconSystemName: "magnifyingglass", title: "Inspect",
                                accessibilityHint: "Open inspector",
                                shortcut: .init(key: "i", modifiers: [.command]))
                        ],
                        secondary: [
                            .init(
                                id: "export", iconSystemName: "square.and.arrow.up",
                                title: "Export", role: .primaryAction)
                        ]), layoutOverride: .expanded)

                Divider()

                VStack(alignment: .leading, spacing: DS.Spacing.l) {
                    Text("Content Area").font(DS.Typography.title).padding(
                        .horizontal, DS.Spacing.l)

                    if let selectedFile = selection {
                        Text("Viewing: \(selectedFile)").font(DS.Typography.body).foregroundStyle(
                            DS.Colors.textSecondary
                        ).padding(.horizontal, DS.Spacing.l)
                    }

                    Text(
                        "Notice the Sidebar and Inspector toggle buttons automatically added to the toolbar"
                    ).font(DS.Typography.caption).foregroundStyle(DS.Colors.textSecondary).padding(
                        .horizontal, DS.Spacing.l)

                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        Text("• ⌘⌃S: Toggle Sidebar")
                        Text("• ⌘⌥I: Toggle Inspector")
                    }.font(DS.Typography.caption).foregroundStyle(DS.Colors.textSecondary).padding(
                        .horizontal, DS.Spacing.l)
                }.frame(maxWidth: .infinity, alignment: .topLeading)
            }.background(DS.Colors.tertiary)
        } detail: {
            InspectorPattern(title: "Properties") {
                SectionHeader(title: "File Information", showDivider: true)
                KeyValueRow(key: "Name", value: selection ?? "None")
                KeyValueRow(key: "Type", value: "MP4")
                KeyValueRow(key: "Size", value: "125 MB")

                SectionHeader(title: "Navigation", showDivider: true)
                Text("Use toolbar buttons or keyboard shortcuts to toggle columns").font(
                    DS.Typography.caption
                ).foregroundStyle(DS.Colors.textSecondary)
            }.padding(DS.Spacing.l)
        }.frame(minWidth: 900, minHeight: 600)
    }
#endif
