// swift-tools-version: 6.0
#if canImport(SwiftUI)
import SwiftUI

/// A pattern that renders a navigable sidebar with support for grouped sections
/// and selection-driven detail content.
///
/// `SidebarPattern` provides the canonical navigation experience used throughout
/// ISO Inspector on macOS and iPadOS. The pattern composes existing design system
/// tokens, typography, and accessibility behaviours to ensure a consistent
/// experience across platforms.
///
/// The sidebar uses ``DS/Spacing`` tokens for padding, relies on semantic
/// typography from ``DS/Typography`` and exposes semantic accessibility labels
/// for VoiceOver users. The detail content is provided through a `@ViewBuilder`
/// closure and adapts its padding based on the target platform.
public struct SidebarPattern<Selection: Hashable, Detail: View>: View {
    /// A semantic item rendered inside a sidebar section.
    public struct Item: Identifiable, Hashable {
        /// The unique identifier representing the selection.
        public let id: Selection
        
        /// The visible title for the row.
        public let title: String
        
        /// Optional SF Symbol identifier displayed alongside the title.
        public let iconSystemName: String?
        
        /// Accessibility label used by VoiceOver. Defaults to the visible title.
        public let accessibilityLabel: String
        
        /// Creates a sidebar item.
        /// - Parameters:
        ///   - id: Unique identifier for the sidebar item.
        ///   - title: Visible title shown within the sidebar row.
        ///   - iconSystemName: Optional SF Symbol name for supplementary context.
        ///   - accessibilityLabel: Optional override for VoiceOver description.
        public init(
            id: Selection,
            title: String,
            iconSystemName: String? = nil,
            accessibilityLabel: String? = nil
        ) {
            self.id = id
            self.title = title
            self.iconSystemName = iconSystemName
            self.accessibilityLabel = accessibilityLabel ?? title
        }
    }
    
    /// A logical section grouping multiple sidebar items.
    public struct Section: Identifiable, Hashable {
        /// Stable identifier for diffing and accessibility grouping.
        public let id: String
        
        /// Visible section title.
        public let title: String
        
        /// Items contained within the section.
        public let items: [Item]
        
        /// Creates a sidebar section.
        /// - Parameters:
        ///   - id: Optional explicit identifier. Defaults to the provided title.
        ///   - title: Visible title describing the section.
        ///   - items: Items displayed in the section.
        public init(id: String? = nil, title: String, items: [Item]) {
            self.id = id ?? title
            self.title = title
            self.items = items
        }
    }
    
    /// Sections rendered within the sidebar.
    public let sections: [Section]
    
    /// Binding to the currently selected item identifier.
    @Binding public var selection: Selection?
    
    /// Builder used to render the corresponding detail view.
    public let detailBuilder: (Selection?) -> Detail
    
    /// Creates a new sidebar pattern instance.
    /// - Parameters:
    ///   - sections: Sections rendered inside the sidebar list.
    ///   - selection: Binding to the currently selected item.
    ///   - detail: View builder producing the detail content for the active selection.
    public init(
        sections: [Section],
        selection: Binding<Selection?>,
        @ViewBuilder detail: @escaping (Selection?) -> Detail
    ) {
        self.sections = sections
        self._selection = selection
        self.detailBuilder = detail
    }
    
    public var body: some View {
        NavigationSplitView {
            sidebarContent
                .accessibilityIdentifier("FoundationUI.SidebarPattern.sidebar")
        } detail: {
            detailContent
                .accessibilityIdentifier("FoundationUI.SidebarPattern.detail")
        }
        .navigationSplitViewStyle(.balanced)
#if os(macOS)
        .navigationSplitViewColumnWidth(
            min: Layout.sidebarMinimumWidth, ideal: Layout.sidebarIdealWidth)
#endif
    }
    
    @ViewBuilder
    private var sidebarContent: some View {
        List(selection: $selection) {
            ForEach(sections) { section in
                SwiftUI.Section(header: sectionHeader(for: section)) {
                    ForEach(section.items) { item in
                        sidebarRow(for: item)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .accessibilityLabel(Text("Navigation"))
    }
    
    @ViewBuilder
    private func sectionHeader(for section: Section) -> some View {
        Text(section.title)
            .font(DS.Typography.caption)
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
            .padding(.horizontal, DS.Spacing.l)
            .padding(.top, DS.Spacing.m)
            .padding(.bottom, DS.Spacing.s)
            .accessibilityAddTraits(.isHeader)
    }
    
    @ViewBuilder
    private func sidebarRow(for item: Item) -> some View {
        Label {
            Text(item.title)
                .font(DS.Typography.body)
                .foregroundStyle(DS.Colors.textPrimary)
        } icon: {
            if let iconSystemName = item.iconSystemName {
                Image(systemName: iconSystemName)
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Colors.textSecondary)
            }
        }
        .tag(item.id)
        .padding(.vertical, DS.Spacing.s)
        .padding(.horizontal, DS.Spacing.l)
        .listRowInsets(
            EdgeInsets(
                top: DS.Spacing.s,
                leading: DS.Spacing.l,
                bottom: DS.Spacing.s,
                trailing: DS.Spacing.m
            )
        )
        .contentShape(Rectangle())
        .accessibilityLabel(Text(item.accessibilityLabel))
    }
    
    @ViewBuilder
    private var detailContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.l) {
                detailBuilder(selection)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(detailPadding)
        }
        .background(DS.Colors.tertiary)
    }
    
    private var detailPadding: EdgeInsets {
#if os(macOS)
        return EdgeInsets(
            top: DS.Spacing.xl,
            leading: DS.Spacing.xl,
            bottom: DS.Spacing.xl,
            trailing: DS.Spacing.xl
        )
#else
        return EdgeInsets(
            top: DS.Spacing.l,
            leading: DS.Spacing.l,
            bottom: DS.Spacing.l,
            trailing: DS.Spacing.l
        )
#endif
    }
}

private enum Layout {
    static let sidebarMinimumWidth = DS.Spacing.l * CGFloat(10) + DS.Spacing.xl * CGFloat(2)
    static let sidebarIdealWidth = DS.Spacing.l * CGFloat(12) + DS.Spacing.xl * CGFloat(2)
}

// MARK: - SwiftUI Previews

#Preview("Sidebar Navigation") {
    struct SidebarPatternPreviewContainer: View {
        @State private var selection: UUID? = nil
        
        var body: some View {
            SidebarPattern(
                sections: [
                    .init(
                        title: "Media",
                        items: [
                            .init(
                                id: UUID(), title: "Overview", iconSystemName: "doc.richtext"),
                            .init(id: UUID(), title: "Metadata", iconSystemName: "info.circle"),
                        ]
                    ),
                    .init(
                        title: "Quality",
                        items: [
                            .init(id: UUID(), title: "Waveform", iconSystemName: "waveform")
                        ]
                    ),
                ],
                selection: $selection
            ) { selection in
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    if let selection {
                        SectionHeader(title: "Selected Item", showDivider: true)
                        Text(selection.uuidString)
                            .font(DS.Typography.body)
                    } else {
                        SectionHeader(title: "No Selection", showDivider: true)
                        Text("Choose an item from the sidebar to see details.")
                            .font(DS.Typography.body)
                            .foregroundStyle(DS.Colors.textSecondary)
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
                            id: UUID(), title: "Validation", iconSystemName: "checkmark.seal"),
                    ]
                ),
                .init(
                    title: "Media",
                    items: [
                        .init(id: UUID(), title: "Video Tracks", iconSystemName: "video"),
                        .init(id: UUID(), title: "Audio Tracks", iconSystemName: "waveform"),
                        .init(id: UUID(), title: "Subtitles", iconSystemName: "text.bubble"),
                    ]
                ),
            ]
        }()
        
        var body: some View {
            SidebarPattern(
                sections: sections,
                selection: $selection
            ) { _ in
                AnyView(
                    InspectorPattern(title: "Track Details") {
                        SectionHeader(title: "Codec Info")
                        KeyValueRow(key: "Codec", value: "H.264")
                        KeyValueRow(key: "Bitrate", value: "5 Mbps")
                    }
                        .material(.regular)
                )
            }
            .preferredColorScheme(.dark)
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
                        id: "validation", title: "Validation", iconSystemName: "checkmark.seal"),
                ]
            ),
            .init(
                title: "Media Tracks",
                items: [
                    .init(id: "video", title: "Video Tracks", iconSystemName: "video"),
                    .init(id: "audio", title: "Audio Tracks", iconSystemName: "waveform"),
                    .init(id: "text", title: "Text Tracks", iconSystemName: "text.bubble"),
                ]
            ),
            .init(
                title: "Advanced",
                items: [
                    .init(id: "hex", title: "Hex Viewer", iconSystemName: "number"),
                    .init(
                        id: "export", title: "Export Data",
                        iconSystemName: "square.and.arrow.up"),
                ]
            ),
        ]
        
        var body: some View {
            SidebarPattern(
                sections: sections,
                selection: $selection
            ) { currentSelection in
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
                            }
                            .material(.regular)
                            
                        case "structure":
                            InspectorPattern(title: "Box Structure") {
                                SectionHeader(title: "Root Boxes", showDivider: true)
                                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                                    HStack {
                                        Text("ftyp")
                                            .font(DS.Typography.code)
                                        Spacer()
                                        Badge(text: "File Type", level: .info)
                                    }
                                    HStack {
                                        Text("moov")
                                            .font(DS.Typography.code)
                                        Spacer()
                                        Badge(text: "Movie", level: .info)
                                    }
                                    HStack {
                                        Text("mdat")
                                            .font(DS.Typography.code)
                                        Spacer()
                                        Badge(text: "Media Data", level: .info)
                                    }
                                }
                            }
                            .material(.regular)
                            
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
                            }
                            .material(.regular)
                            
                        default:
                            VStack(alignment: .center, spacing: DS.Spacing.l) {
                                Image(systemName: "doc.questionmark")
                                    .font(.system(size: DS.Spacing.xl * 2))
                                    .foregroundStyle(.secondary)
                                Text("Select a category from the sidebar")
                                    .font(DS.Typography.body)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                )
            }
        }
    }
    
    return PreviewContainer()
        .frame(minWidth: 800, minHeight: 600)
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
                        accessibilityLabel: "Media Data Box"),
                ]
            ),
            .init(
                title: "Metadata",
                items: [
                    .init(
                        id: 4, title: "mvhd", iconSystemName: "info.circle",
                        accessibilityLabel: "Movie Header"),
                    .init(
                        id: 5, title: "iods", iconSystemName: "gearshape",
                        accessibilityLabel: "Object Descriptor"),
                ]
            ),
            .init(
                title: "Tracks",
                items: [
                    .init(id: 6, title: "trak (Video)", iconSystemName: "video"),
                    .init(id: 7, title: "trak (Audio)", iconSystemName: "speaker.wave.2"),
                    .init(id: 8, title: "trak (Subtitle)", iconSystemName: "text.bubble"),
                ]
            ),
        ]
        
        var body: some View {
            SidebarPattern(
                sections: sections,
                selection: $selection
            ) { currentSelection in
                AnyView(
                    Group {
                        if let selected = currentSelection {
                            InspectorPattern(title: "Box Details") {
                                KeyValueRow(key: "Box ID", value: "\(selected)")
                                KeyValueRow(key: "Type", value: "ISO Box")
                            }
                            .material(.regular)
                        } else {
                            Text("No selection")
                                .font(DS.Typography.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                )
            }
        }
    }
    
    return PreviewContainer()
        .frame(minWidth: 700, minHeight: 500)
}

#Preview("Dynamic Type - Small") {
    struct PreviewContainer: View {
        @State private var selection: UUID? = nil
        
        var body: some View {
            SidebarPattern(
                sections: [
                    .init(
                        title: "Analysis",
                        items: [
                            .init(id: UUID(), title: "Overview", iconSystemName: "doc.text"),
                            .init(id: UUID(), title: "Details", iconSystemName: "info.circle"),
                        ]
                    )
                ],
                selection: $selection
            ) { _ in
                Text("Detail content")
                    .font(DS.Typography.body)
            }
            .environment(\.dynamicTypeSize, .xSmall)
        }
    }
    
    return PreviewContainer()
        .frame(minWidth: 600, minHeight: 400)
}

#Preview("Dynamic Type - Large") {
    struct PreviewContainer: View {
        @State private var selection: UUID? = nil
        
        var body: some View {
            SidebarPattern(
                sections: [
                    .init(
                        title: "Analysis",
                        items: [
                            .init(id: UUID(), title: "Overview", iconSystemName: "doc.text"),
                            .init(id: UUID(), title: "Details", iconSystemName: "info.circle"),
                        ]
                    )
                ],
                selection: $selection
            ) { _ in
                Text("Detail content with large type")
                    .font(DS.Typography.body)
            }
            .environment(\.dynamicTypeSize, .xxxLarge)
        }
    }
    
    return PreviewContainer()
        .frame(minWidth: 700, minHeight: 500)
}

#Preview("Empty State") {
    struct PreviewContainer: View {
        @State private var selection: UUID? = nil
        
        var body: some View {
            SidebarPattern(
                sections: [
                    .init(
                        title: "Empty Section",
                        items: []
                    )
                ],
                selection: $selection
            ) { _ in
                VStack(spacing: DS.Spacing.l) {
                    Image(systemName: "tray")
                        .font(.system(size: DS.Spacing.xl * 2))
                        .foregroundStyle(.secondary)
                    Text("No items available")
                        .font(DS.Typography.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    return PreviewContainer()
        .frame(minWidth: 600, minHeight: 400)
}

#Preview("Platform-Specific Width") {
    struct PreviewContainer: View {
        @State private var selection: UUID? = nil
        
        var body: some View {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
#if os(macOS)
                Text("macOS: Sidebar width calculated with DS tokens")
                    .font(DS.Typography.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, DS.Spacing.l)
#else
                Text("iOS/iPadOS: Adaptive sidebar layout")
                    .font(DS.Typography.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, DS.Spacing.l)
#endif
                
                SidebarPattern(
                    sections: [
                        .init(
                            title: "Platform Info",
                            items: [
                                .init(
                                    id: UUID(), title: "Current Platform",
                                    iconSystemName: "display")
                            ]
                        )
                    ],
                    selection: $selection
                ) { _ in
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
                    }
                    .material(.regular)
                }
            }
        }
    }
    
    return PreviewContainer()
        .frame(minWidth: 700, minHeight: 500)
}
#endif
