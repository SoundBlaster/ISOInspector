#if canImport(SwiftUI)
    import SwiftUI

    // MARK: - SidebarPattern Previews

    #Preview("Sidebar Navigation") {
        struct SidebarPatternPreviewContainer: View {
            @State private var selection: UUID?

            var body: some View {
                SidebarPattern(
                    sections: [
                        .init(
                            title: "Media",
                            items: [
                                .init(
                                    id: UUID(), title: "Overview", iconSystemName: "doc.richtext"),
                                .init(id: UUID(), title: "Metadata", iconSystemName: "info.circle")
                            ]),
                        .init(
                            title: "Quality",
                            items: [
                                .init(id: UUID(), title: "Waveform", iconSystemName: "waveform")
                            ])
                    ], selection: $selection
                ) { selection in
                    VStack(alignment: .leading, spacing: DS.Spacing.m) {
                        if let selection {
                            SectionHeader(title: "Selected Item", showDivider: true)
                            Text(selection.uuidString).font(DS.Typography.body)
                        } else {
                            SectionHeader(title: "No Selection", showDivider: true)
                            Text("Choose an item from the sidebar to see details.").font(
                                DS.Typography.body
                            ).foregroundStyle(DS.Colors.textSecondary)
                        }
                    }
                }
            }
        }

        return SidebarPatternPreviewContainer()
    }

    #Preview("Dark Mode") {
        struct PreviewContainer: View {
            @State private var selection: UUID? = UUID()

            // Note: Explicit AnyView type annotation is required for previews with multiple
            // detail view types. This allows type-erased detail builder for demonstration purposes.
            private let sections: [SidebarPattern<UUID, AnyView>.Section] = {
                let overviewId = UUID()
                return [
                    .init(
                        title: "Analysis",
                        items: [
                            .init(id: overviewId, title: "Overview", iconSystemName: "doc.text"),
                            .init(
                                id: UUID(), title: "Structure", iconSystemName: "square.grid.3x3"),
                            .init(
                                id: UUID(), title: "Validation", iconSystemName: "checkmark.seal")
                        ]),
                    .init(
                        title: "Media",
                        items: [
                            .init(id: UUID(), title: "Video Tracks", iconSystemName: "video"),
                            .init(id: UUID(), title: "Audio Tracks", iconSystemName: "waveform"),
                            .init(id: UUID(), title: "Subtitles", iconSystemName: "text.bubble")
                        ])
                ]
            }()

            var body: some View {
                SidebarPattern(sections: sections, selection: $selection) { _ in
                    AnyView(
                        InspectorPattern(title: "Track Details") {
                            SectionHeader(title: "Codec Info")
                            KeyValueRow(key: "Codec", value: "H.264")
                            KeyValueRow(key: "Bitrate", value: "5 Mbps")
                        }.material(.regular))
                }.preferredColorScheme(.dark)
            }
        }

        return PreviewContainer()
    }

    #Preview("ISO Inspector Workflow") {
        struct PreviewContainer: View {
            @State private var selection: String? = "overview"

            // Note: Explicit AnyView type annotation is required for previews with multiple
            // detail view types. The switch statement returns different view types per case.
            private let sections: [SidebarPattern<String, AnyView>.Section] = [
                .init(
                    title: "File Analysis",
                    items: [
                        .init(id: "overview", title: "Overview", iconSystemName: "doc.text"),
                        .init(
                            id: "structure", title: "Box Structure",
                            iconSystemName: "square.stack.3d.up"),
                        .init(
                            id: "validation", title: "Validation", iconSystemName: "checkmark.seal")
                    ]),
                .init(
                    title: "Media Tracks",
                    items: [
                        .init(id: "video", title: "Video Tracks", iconSystemName: "video"),
                        .init(id: "audio", title: "Audio Tracks", iconSystemName: "waveform"),
                        .init(id: "text", title: "Text Tracks", iconSystemName: "text.bubble")
                    ]),
                .init(
                    title: "Advanced",
                    items: [
                        .init(id: "hex", title: "Hex Viewer", iconSystemName: "number"),
                        .init(
                            id: "export", title: "Export Data",
                            iconSystemName: "square.and.arrow.up")
                    ])
            ]

            var body: some View {
                SidebarPattern(sections: sections, selection: $selection) { currentSelection in
                    AnyView(
                        Group {
                            switch currentSelection {
                            case "overview":
                                InspectorPattern(title: "File Overview") {
                                    SectionHeader(title: "General Information", showDivider: true)
                                    KeyValueRow(key: "File Name", value: "sample_video.mp4")
                                    KeyValueRow(key: "Size", value: "125.4 MB")
                                    KeyValueRow(key: "Format", value: "ISO Base Media File")

                                    SectionHeader(title: "Status", showDivider: true)
                                    HStack(spacing: DS.Spacing.s) {
                                        Badge(text: "Valid", level: .success)
                                        Badge(text: "ISO 14496-12", level: .info)
                                    }
                                }.material(.regular)

                            case "structure":
                                InspectorPattern(title: "Box Structure") {
                                    SectionHeader(title: "Root Boxes", showDivider: true)
                                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                                        HStack {
                                            Text("ftyp").font(DS.Typography.code)
                                            Spacer()
                                            Badge(text: "File Type", level: .info)
                                        }
                                        HStack {
                                            Text("moov").font(DS.Typography.code)
                                            Spacer()
                                            Badge(text: "Movie", level: .info)
                                        }
                                        HStack {
                                            Text("mdat").font(DS.Typography.code)
                                            Spacer()
                                            Badge(text: "Media Data", level: .info)
                                        }
                                    }
                                }.material(.regular)

                            case "video":
                                InspectorPattern(title: "Video Track") {
                                    SectionHeader(title: "Codec Information", showDivider: true)
                                    KeyValueRow(key: "Codec", value: "H.264/AVC")
                                    KeyValueRow(key: "Resolution", value: "1920x1080")
                                    KeyValueRow(key: "Frame Rate", value: "29.97 fps")
                                    KeyValueRow(key: "Bitrate", value: "5 Mbps")

                                    SectionHeader(title: "Quality", showDivider: true)
                                    HStack(spacing: DS.Spacing.s) {
                                        Badge(text: "HD", level: .success)
                                        Badge(text: "1080p", level: .info)
                                    }
                                }.material(.regular)

                            default:
                                VStack(alignment: .center, spacing: DS.Spacing.l) {
                                    Image(systemName: "doc.questionmark").font(
                                        .system(size: DS.Spacing.xl * 2)
                                    ).foregroundStyle(.secondary)
                                    Text("Select a category from the sidebar").font(
                                        DS.Typography.body
                                    ).foregroundStyle(.secondary)
                                }.frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        })
                }
            }
        }

        return PreviewContainer().frame(minWidth: 800, minHeight: 600)
    }

    #Preview("Multiple Sections") {
        struct PreviewContainer: View {
            @State private var selection: Int? = 1

            // Note: Explicit AnyView type annotation is required for previews with multiple
            // detail view types. The if-else statement returns different view types per branch.
            private let sections: [SidebarPattern<Int, AnyView>.Section] = [
                .init(
                    title: "Containers",
                    items: [
                        .init(
                            id: 1, title: "ftyp", iconSystemName: "doc",
                            accessibilityLabel: "File Type Box"),
                        .init(
                            id: 2, title: "moov", iconSystemName: "film",
                            accessibilityLabel: "Movie Box"),
                        .init(
                            id: 3, title: "mdat", iconSystemName: "cube",
                            accessibilityLabel: "Media Data Box")
                    ]),
                .init(
                    title: "Metadata",
                    items: [
                        .init(
                            id: 4, title: "mvhd", iconSystemName: "info.circle",
                            accessibilityLabel: "Movie Header"),
                        .init(
                            id: 5, title: "iods", iconSystemName: "gearshape",
                            accessibilityLabel: "Object Descriptor")
                    ]),
                .init(
                    title: "Tracks",
                    items: [
                        .init(id: 6, title: "trak (Video)", iconSystemName: "video"),
                        .init(id: 7, title: "trak (Audio)", iconSystemName: "speaker.wave.2"),
                        .init(id: 8, title: "trak (Subtitle)", iconSystemName: "text.bubble")
                    ])
            ]

            var body: some View {
                SidebarPattern(sections: sections, selection: $selection) { currentSelection in
                    AnyView(
                        Group {
                            if let selected = currentSelection {
                                InspectorPattern(title: "Box Details") {
                                    KeyValueRow(key: "Box ID", value: "\(selected)")
                                    KeyValueRow(key: "Type", value: "ISO Box")
                                }.material(.regular)
                            } else {
                                Text("No selection").font(DS.Typography.body).foregroundStyle(
                                    .secondary)
                            }
                        })
                }
            }
        }

        return PreviewContainer().frame(minWidth: 700, minHeight: 500)
    }
#endif
