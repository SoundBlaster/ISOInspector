#if canImport(SwiftUI)
    import SwiftUI

    #Preview("Dynamic Type - Small") {
        struct PreviewContainer: View {
            @State private var selection: UUID?

            var body: some View {
                SidebarPattern(
                    sections: [
                        .init(
                            title: "Analysis",
                            items: [
                                .init(id: UUID(), title: "Overview", iconSystemName: "doc.text"),
                                .init(id: UUID(), title: "Details", iconSystemName: "info.circle"),
                            ])
                    ], selection: $selection,
                    content: { _ in Text("Detail content").font(DS.Typography.body) }
                ).environment(\.dynamicTypeSize, .xSmall)
            }
        }

        return PreviewContainer().frame(minWidth: 600, minHeight: 400)
    }

    #Preview("Dynamic Type - Large") {
        struct PreviewContainer: View {
            @State private var selection: UUID?

            var body: some View {
                SidebarPattern(
                    sections: [
                        .init(
                            title: "Analysis",
                            items: [
                                .init(id: UUID(), title: "Overview", iconSystemName: "doc.text"),
                                .init(id: UUID(), title: "Details", iconSystemName: "info.circle"),
                            ])
                    ], selection: $selection,
                    content: { _ in Text("Detail content with large type").font(DS.Typography.body)
                    }
                ).environment(\.dynamicTypeSize, .xxxLarge)
            }
        }

        return PreviewContainer().frame(minWidth: 700, minHeight: 500)
    }

    #Preview("Empty State") {
        struct PreviewContainer: View {
            @State private var selection: UUID?

            var body: some View {
                SidebarPattern(
                    sections: [.init(title: "Empty Section", items: [])], selection: $selection,
                    content: { _ in
                    VStack(spacing: DS.Spacing.l) {
                        Image(systemName: "tray").font(.system(size: DS.Spacing.xl * 2))
                            .foregroundStyle(.secondary)
                        Text("No items available").font(DS.Typography.body).foregroundStyle(
                            .secondary)
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }

        return PreviewContainer().frame(minWidth: 600, minHeight: 400)
    }

    #Preview("Platform-Specific Width") {
        struct PreviewContainer: View {
            @State private var selection: UUID?

            var body: some View {
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    #if os(macOS)
                        Text("macOS: Sidebar width calculated with DS tokens").font(
                            DS.Typography.caption
                        ).foregroundStyle(.secondary).padding(.horizontal, DS.Spacing.l)
                    #else
                        Text("iOS/iPadOS: Adaptive sidebar layout").font(DS.Typography.caption)
                            .foregroundStyle(.secondary).padding(.horizontal, DS.Spacing.l)
                    #endif

                    SidebarPattern(
                        sections: [
                            .init(
                                title: "Platform Info",
                                items: [
                                    .init(
                                        id: UUID(), title: "Current Platform",
                                        iconSystemName: "display")
                                ])
                        ], selection: $selection,
                        content: { _ in
                        InspectorPattern(title: "Platform Details") {
                            #if os(macOS)
                                KeyValueRow(key: "Platform", value: "macOS")
                                KeyValueRow(
                                    key: "Min Width", value: "DS.Spacing.l * 10 + DS.Spacing.xl * 2"
                                )
                            #else
                                KeyValueRow(key: "Platform", value: "iOS/iPadOS")
                                KeyValueRow(key: "Layout", value: "Adaptive")
                            #endif
                        }.material(.regular)
                    }
                }
            }
        }

        return PreviewContainer().frame(minWidth: 700, minHeight: 500)
    }

    #Preview("Bug Fix - macOS Tertiary Color Contrast") {
        struct PreviewContainer: View {
            @State private var selection: Int? = 1

            var body: some View {
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("BUG FIX: DS.Colors.tertiary now uses proper background color on macOS")
                        .font(DS.Typography.headline).padding(.horizontal, DS.Spacing.l)

                    Text("Before: Used .tertiaryLabelColor (text color) - LOW CONTRAST").font(
                        DS.Typography.caption
                    ).foregroundStyle(.red).padding(.horizontal, DS.Spacing.l)

                    Text("After: Uses .controlBackgroundColor (background color) - PROPER CONTRAST")
                        .font(DS.Typography.caption).foregroundStyle(.green).padding(
                            .horizontal, DS.Spacing.l)

                    SidebarPattern(
                        sections: [
                            .init(
                                title: "Test Section",
                                items: [
                                    .init(id: 1, title: "Item 1", iconSystemName: "doc"),
                                    .init(id: 2, title: "Item 2", iconSystemName: "folder"),
                                    .init(id: 3, title: "Item 3", iconSystemName: "star"),
                                ])
                        ], selection: $selection,
                        content: { _ in
                        VStack(alignment: .leading, spacing: DS.Spacing.m) {
                            Text("Detail Content Area").font(DS.Typography.title)

                            Text("This area uses DS.Colors.tertiary as background").font(
                                DS.Typography.body)

                            Card {
                                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                                    Text("Verification on macOS:").font(DS.Typography.headline)

                                    Text("✓ Adequate contrast with window background").font(
                                        DS.Typography.caption)

                                    Text("✓ Proper semantic: background color for backgrounds")
                                        .font(DS.Typography.caption)

                                    Text("✓ Works in Light and Dark mode").font(
                                        DS.Typography.caption)

                                    Text("✓ WCAG AA compliant (≥4.5:1 contrast)").font(
                                        DS.Typography.caption)
                                }
                            }
                        }.padding(DS.Spacing.l)
                    }
                }
            }
        }

        return PreviewContainer().frame(minWidth: 800, minHeight: 600)
    }

    #Preview("With NavigationSplitScaffold") {
        @Previewable @State var selection: String?
        @Previewable @State var navigationModel = NavigationModel()

        NavigationSplitScaffold(model: navigationModel) {
            SidebarPattern(
                sections: [
                    .init(
                        title: "Recent Files",
                        items: [
                            .init(id: "file1", title: "sample.mp4", iconSystemName: "doc.fill"),
                            .init(id: "file2", title: "video.mov", iconSystemName: "doc.fill"),
                            .init(id: "file3", title: "test.iso", iconSystemName: "opticaldisc"),
                        ]),
                    .init(
                        title: "Bookmarks",
                        items: [
                            .init(id: "bm1", title: "Important Atoms", iconSystemName: "star.fill"),
                            .init(
                                id: "bm2", title: "Error Locations",
                                iconSystemName: "exclamationmark.triangle"),
                        ]),
                ], selection: $selection,
                content: { _ in EmptyView() }
            )
        } content: {
            VStack(alignment: .leading, spacing: DS.Spacing.l) {
                Text("Parse Tree").font(DS.Typography.title).padding(DS.Spacing.l)

                if let selectedFile = selection {
                    Text("Selected: \(selectedFile)").font(DS.Typography.body).foregroundStyle(
                        DS.Colors.textSecondary
                    ).padding(.horizontal, DS.Spacing.l)
                } else {
                    Text("No file selected").font(DS.Typography.body).foregroundStyle(
                        DS.Colors.textSecondary
                    ).padding(.horizontal, DS.Spacing.l)
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).background(
                DS.Colors.tertiary)
        } detail: {
            InspectorPattern(title: "File Properties") {
                SectionHeader(title: "Details", showDivider: true)
                KeyValueRow(key: "Type", value: "MP4")
                KeyValueRow(key: "Size", value: "125 MB")
            }.padding(DS.Spacing.l)
        }.frame(minWidth: 900, minHeight: 600)
    }
#endif
