// swift-tools-version: 6.0
import SwiftUI

/// A metadata model describing the FoundationUI pattern preview catalogue.
///
/// ``PatternPreviewCatalogConfiguration`` exposes structured sections that map
/// each Layer 3 pattern to a set of rich SwiftUI preview scenarios. The model
/// is consumed by ``PatternPreviewCatalog`` to surface platform variations,
/// accessibility demonstrations, and dynamic layout examples without relying on
/// ad-hoc preview declarations across multiple files.
public struct PatternPreviewCatalogConfiguration {

    /// A logical grouping of preview scenarios for a specific pattern.
    public struct Section: Identifiable, Equatable {
        /// Supported pattern identifiers.
        public enum Pattern: String, CaseIterable {
            case inspector
            case sidebar
            case toolbar
            case boxTree

            /// Human readable title used in the UI.
            public var title: String {
                switch self {
                case .inspector:
                    return "InspectorPattern"
                case .sidebar:
                    return "SidebarPattern"
                case .toolbar:
                    return "ToolbarPattern"
                case .boxTree:
                    return "BoxTreePattern"
                }
            }
        }

        public let id: Pattern
        public let pattern: Pattern
        public let summary: String
        public let scenarios: [Scenario]

        public init(pattern: Pattern, summary: String, scenarios: [Scenario]) {
            self.id = pattern
            self.pattern = pattern
            self.summary = summary
            self.scenarios = scenarios
        }
    }

    /// A single preview scenario describing layout intent and traits.
    public struct Scenario: Identifiable, Equatable {
        public let id: ScenarioIdentifier
        public let title: String
        public let details: String
        public let traits: [Trait]

        public init(id: ScenarioIdentifier, title: String, details: String, traits: [Trait]) {
            self.id = id
            self.title = title
            self.details = details
            self.traits = traits
        }
    }

    /// Semantic tags describing the focus of a preview scenario.
    public enum Trait: Hashable {
        /// Platform focus trait.
        public enum Platform: String, CaseIterable {
            case iOS
            case iPadOS
            case macOS
        }

        case lightMode
        case darkMode
        case dynamicType
        case accessibility
        case platform(Platform)

        /// User-visible name rendered in the catalogue.
        var label: String {
            switch self {
            case .lightMode:
                return "Light"
            case .darkMode:
                return "Dark"
            case .dynamicType:
                return "Dynamic Type"
            case .accessibility:
                return "Accessibility"
            case .platform(let platform):
                return platform.rawValue
            }
        }
    }

    /// Stable identifiers used to map scenarios to live preview views.
    public enum ScenarioIdentifier: String {
        case inspectorMetadata
        case inspectorStatus
        case inspectorDynamicType
        case sidebarNavigation
        case sidebarReview
        case toolbarCompact
        case toolbarOverflow
        case boxTreeCollapsed
        case boxTreeExpanded
    }

    public let sections: [Section]

    public init(sections: [Section]) {
        self.sections = sections
    }

    /// Default catalogue covering all FoundationUI patterns.
    public static let `default` = PatternPreviewCatalogConfiguration(sections: Self.makeDefaultSections())

    private static func makeDefaultSections() -> [Section] {
        [
            Section(
                pattern: .inspector,
                summary: "Inspector layouts for metadata dashboards, live status panels, and large text readers.",
                scenarios: [
                    Scenario(
                        id: .inspectorMetadata,
                        title: "Metadata Overview",
                        details: "Fixed header with KeyValueRow metadata for macOS inspectors.",
                        traits: [.platform(.macOS), .lightMode]
                    ),
                    Scenario(
                        id: .inspectorStatus,
                        title: "Status Dashboard",
                        details: "Badge clusters demonstrating Dark Mode contrast and accessibility labelling.",
                        traits: [.platform(.iOS), .darkMode, .accessibility]
                    ),
                    Scenario(
                        id: .inspectorDynamicType,
                        title: "Dynamic Type Notes",
                        details: "Long-form notes with accessibility Dynamic Type sizing on iPadOS.",
                        traits: [.platform(.iPadOS), .dynamicType]
                    )
                ]
            ),
            Section(
                pattern: .sidebar,
                summary: "Navigation split views highlighting keyboard friendly lists and adaptive padding.",
                scenarios: [
                    Scenario(
                        id: .sidebarNavigation,
                        title: "Navigator",
                        details: "Sidebar driven selection showing inspector details on macOS.",
                        traits: [.platform(.macOS), .lightMode]
                    ),
                    Scenario(
                        id: .sidebarReview,
                        title: "Review Workspace",
                        details: "iPadOS review flow with large content and Dynamic Type sizing.",
                        traits: [.platform(.iPadOS), .dynamicType]
                    )
                ]
            ),
            Section(
                pattern: .toolbar,
                summary: "Adaptive toolbars covering compact phone layouts and expanded macOS action bars.",
                scenarios: [
                    Scenario(
                        id: .toolbarCompact,
                        title: "Compact Toolbar",
                        details: "iOS compact actions with icon-only presentation and overflow menu.",
                        traits: [.platform(.iOS), .lightMode]
                    ),
                    Scenario(
                        id: .toolbarOverflow,
                        title: "Expanded Toolbar",
                        details: "macOS toolbar with labelled buttons, keyboard shortcuts, and overflow grouping.",
                        traits: [.platform(.macOS), .darkMode]
                    )
                ]
            ),
            Section(
                pattern: .boxTree,
                summary: "Tree navigation showcasing collapsed and expanded ISO box hierarchies.",
                scenarios: [
                    Scenario(
                        id: .boxTreeCollapsed,
                        title: "Collapsed Tree",
                        details: "iPadOS view showing collapsed nodes with disclosure affordances.",
                        traits: [.platform(.iPadOS), .lightMode]
                    ),
                    Scenario(
                        id: .boxTreeExpanded,
                        title: "Expanded Tree",
                        details: "iOS expanded nodes with badges for flagged validation issues.",
                        traits: [.platform(.iOS), .accessibility]
                    )
                ]
            )
        ]
    }
}

/// A SwiftUI catalogue rendering canonical previews for FoundationUI patterns.
///
/// The catalogue aggregates representative previews across Inspector, Sidebar,
/// Toolbar, and BoxTree patterns to validate Composable Clarity principles and
/// ensure all Layer 3 surfaces respect DS tokens, accessibility goals, and
/// platform adaptations.
public struct PatternPreviewCatalog: View {
    public let configuration: PatternPreviewCatalogConfiguration

    public init(configuration: PatternPreviewCatalogConfiguration = .default) {
        self.configuration = configuration
    }

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DS.Spacing.xl) {
                ForEach(configuration.sections) { section in
                    sectionView(for: section)
                }
            }
            .padding(.vertical, DS.Spacing.xl)
            .padding(.horizontal, DS.Spacing.xl)
        }
        .background(DS.Color.tertiary)
        .navigationTitle("Pattern Preview Catalog")
    }

    @ViewBuilder
    private func sectionView(for section: PatternPreviewCatalogConfiguration.Section) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                Text(section.pattern.title)
                    .font(DS.Typography.title)
                Text(section.summary)
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Color.textSecondary)
            }

            VStack(alignment: .leading, spacing: DS.Spacing.l) {
                ForEach(section.scenarios) { scenario in
                    scenarioCard(for: scenario, pattern: section.pattern)
                }
            }
        }
        .padding(DS.Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .fill(DS.Color.tertiary)
        )
    }

    @ViewBuilder
    private func scenarioCard(
        for scenario: PatternPreviewCatalogConfiguration.Scenario,
        pattern: PatternPreviewCatalogConfiguration.Section.Pattern
    ) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                Text(scenario.title)
                    .font(DS.Typography.subheadline)
                Text(scenario.details)
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Color.textSecondary)
            }

            traitTags(for: scenario)

            scenarioPreview(for: scenario, pattern: pattern)
                .frame(maxWidth: .infinity)
        }
        .padding(DS.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .fill(DS.Color.infoBG)
        )
    }

    @ViewBuilder
    private func traitTags(for scenario: PatternPreviewCatalogConfiguration.Scenario) -> some View {
        HStack(spacing: DS.Spacing.s) {
            ForEach(Array(scenario.traits), id: \.self) { trait in
                Text(trait.label)
                    .font(DS.Typography.caption)
                    .padding(.horizontal, DS.Spacing.s)
                    .padding(.vertical, DS.Spacing.s)
                    .background(
                        Capsule(style: .continuous)
                            .fill(DS.Color.infoBG)
                    )
            }
        }
    }

    @ViewBuilder
    private func scenarioPreview(
        for scenario: PatternPreviewCatalogConfiguration.Scenario,
        pattern: PatternPreviewCatalogConfiguration.Section.Pattern
    ) -> some View {
        switch scenario.id {
        case .inspectorMetadata:
            InspectorMetadataPreview()
        case .inspectorStatus:
            InspectorStatusPreview()
                .environment(\.colorScheme, .dark)
        case .inspectorDynamicType:
            InspectorDynamicTypePreview()
                .environment(\.dynamicTypeSize, .accessibility3)
        case .sidebarNavigation:
            SidebarNavigationPreview()
        case .sidebarReview:
            SidebarReviewPreview()
                .environment(\.dynamicTypeSize, .accessibility3)
        case .toolbarCompact:
            ToolbarCompactPreview()
        case .toolbarOverflow:
            ToolbarOverflowPreview()
                .environment(\.colorScheme, .dark)
        case .boxTreeCollapsed:
            BoxTreePreview(expandedNodes: [], selection: nil)
        case .boxTreeExpanded:
            BoxTreePreview(
                expandedNodes: Set(PreviewData.deepExpandedNodeIDs),
                selection: PreviewData.flaggedNodeID
            )
                .environment(\.accessibilityReduceMotion, false)
        }
    }
}

// MARK: - Inspector Previews

private struct InspectorMetadataPreview: View {
    var body: some View {
        InspectorPattern(title: "File Metadata") {
            SectionHeader(title: "General", showDivider: true)
            KeyValueRow(key: "File Name", value: "wildlife_hd.mov", copyable: true)
            KeyValueRow(key: "Duration", value: "00:12:43")
            KeyValueRow(key: "Size", value: "1.84 GB")
            SectionHeader(title: "Codecs", showDivider: true)
            KeyValueRow(key: "Video", value: "H.265 / HEVC", layout: .vertical)
            KeyValueRow(key: "Audio", value: "Dolby AC-4", layout: .vertical)
        }
        .padding(DS.Spacing.l)
    }
}

private struct InspectorStatusPreview: View {
    var body: some View {
        InspectorPattern(title: "Validation Status") {
            SectionHeader(title: "Overview", showDivider: true)
            HStack(spacing: DS.Spacing.m) {
                Badge(text: "Validated", level: .success, showIcon: true)
                Badge(text: "Warnings", level: .warning, showIcon: true)
                Badge(text: "Errors", level: .error, showIcon: true)
            }
            SectionHeader(title: "Recent Issues", showDivider: true)
            KeyValueRow(key: "Last Check", value: "2 minutes ago")
            KeyValueRow(key: "Flagged Boxes", value: "3", copyable: true)
        }
        .material(.regular)
        .padding(DS.Spacing.l)
    }
}

private struct InspectorDynamicTypePreview: View {
    var body: some View {
        InspectorPattern(title: "QC Notes") {
            SectionHeader(title: "Editors", showDivider: true)
            Text("Dynamic Type preview demonstrating expanded notes on iPadOS.")
                .font(DS.Typography.body)
            SectionHeader(title: "Notes", showDivider: true)
            Text("Audio track exhibits minor clipping between 01:12–01:15. Recommend reviewing original mix before export.")
                .font(DS.Typography.body)
        }
        .padding(DS.Spacing.l)
    }
}

// MARK: - Sidebar Previews

private struct SidebarNavigationPreview: View {
    @State private var selection: UUID? = PreviewData.sidebarSections.first?.items.first?.id

    var body: some View {
        SidebarPattern(
            sections: PreviewData.sidebarSections,
            selection: $selection
        ) { selection in
            SidebarDetailView(selection: selection)
        }
    }
}

private struct SidebarReviewPreview: View {
    @State private var selection: UUID? = PreviewData.sidebarSections.last?.items.last?.id

    var body: some View {
        SidebarPattern(
            sections: PreviewData.sidebarSections,
            selection: $selection
        ) { selection in
            SidebarDetailView(selection: selection)
        }
    }
}

private struct SidebarDetailView: View {
    let selection: UUID?

    var body: some View {
        let detail = PreviewData.detail(for: selection)
        InspectorPattern(title: detail.title) {
            SectionHeader(title: "Highlights", showDivider: true)
            ForEach(detail.highlights, id: \.self) { highlight in
                Text("• \(highlight)")
                    .font(DS.Typography.body)
            }
        }
        .padding(DS.Spacing.l)
    }
}

// MARK: - Toolbar Previews

private struct ToolbarCompactPreview: View {
    var body: some View {
        ToolbarPattern(
            items: PreviewData.toolbarItems,
            layoutOverride: .compact
        )
        .padding(DS.Spacing.l)
    }
}

private struct ToolbarOverflowPreview: View {
    var body: some View {
        ToolbarPattern(
            items: PreviewData.toolbarItems,
            layoutOverride: .expanded
        )
        .padding(DS.Spacing.l)
    }
}

// MARK: - BoxTree Previews

private struct BoxTreePreview: View {
    @State private var expandedNodes: Set<UUID>
    @State private var selection: UUID?

    init(expandedNodes: Set<UUID>, selection: UUID?) {
        _expandedNodes = State(initialValue: expandedNodes)
        _selection = State(initialValue: selection)
    }

    var body: some View {
        BoxTreePattern(
            data: PreviewData.boxTree,
            children: { $0.children },
            expandedNodes: $expandedNodes,
            selection: $selection
        ) { node in
            HStack(spacing: DS.Spacing.m) {
                Text(node.name)
                    .font(DS.Typography.body)
                if node.isFlagged {
                    Badge(text: "Issue", level: .warning)
                }
                Spacer()
                Text(node.size)
                    .font(DS.Typography.code)
                    .foregroundStyle(DS.Color.textSecondary)
            }
        }
        .padding(DS.Spacing.l)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .fill(DS.Color.tertiary)
        )
    }
}

// MARK: - Preview Data

private enum PreviewData {
    struct SidebarDetail {
        let title: String
        let highlights: [String]
    }

    struct TreeNode: Identifiable, Hashable {
        let id: UUID
        let name: String
        let size: String
        let isFlagged: Bool
        var children: [TreeNode]
    }

    static let sidebarSections: [SidebarPattern<UUID, InspectorPattern<SidebarDetailView>>.Section] = {
        let overview = SidebarPattern<UUID, InspectorPattern<SidebarDetailView>>.Item(
            id: UUID(),
            title: "Overview",
            iconSystemName: "doc.richtext"
        )
        let metadata = SidebarPattern<UUID, InspectorPattern<SidebarDetailView>>.Item(
            id: UUID(),
            title: "Metadata",
            iconSystemName: "info.circle"
        )
        let validation = SidebarPattern<UUID, InspectorPattern<SidebarDetailView>>.Item(
            id: UUID(),
            title: "Validation",
            iconSystemName: "checkmark.shield"
        )
        let waveform = SidebarPattern<UUID, InspectorPattern<SidebarDetailView>>.Item(
            id: UUID(),
            title: "Waveform",
            iconSystemName: "waveform"
        )
        let annotations = SidebarPattern<UUID, InspectorPattern<SidebarDetailView>>.Item(
            id: UUID(),
            title: "Annotations",
            iconSystemName: "highlighter"
        )

        sidebarDetailLookup = [
            overview.id: SidebarDetail(title: "Project Overview", highlights: [
                "Timeline assembled with Dolby Vision HDR",
                "Audio conforms to broadcast loudness targets"
            ]),
            metadata.id: SidebarDetail(title: "Metadata", highlights: [
                "Codec: HEVC Main 10", "Color Space: Rec. 2020"
            ]),
            validation.id: SidebarDetail(title: "Validation", highlights: [
                "2 warnings, 0 blocking errors", "Last run completed 3 minutes ago"
            ]),
            waveform.id: SidebarDetail(title: "Waveform", highlights: [
                "True peak at -1.0 dBFS", "Clipping detected at 01:12:04"
            ]),
            annotations.id: SidebarDetail(title: "Annotations", highlights: [
                "Scene markers synced from production notes",
                "3 review tasks outstanding"
            ])
        ]

        return [
            .init(title: "Media", items: [overview, metadata, validation]),
            .init(title: "Analysis", items: [waveform, annotations])
        ]
    }()

    private static var sidebarDetailLookup: [UUID: SidebarDetail] = [:]

    static func detail(for id: UUID?) -> SidebarDetail {
        guard let id, let detail = sidebarDetailLookup[id] else {
            return SidebarDetail(title: "Select an Item", highlights: [
                "Choose an item in the sidebar to review details."
            ])
        }
        return detail
    }

    static let toolbarItems: ToolbarPattern.Items = {
        let primary: [ToolbarPattern.Item] = [
            .init(id: "validate", iconSystemName: "checkmark.circle", title: "Validate", accessibilityHint: "Run validation", role: .primaryAction) {},
            .init(id: "export", iconSystemName: "square.and.arrow.up", title: "Export", accessibilityHint: "Export report", role: .primaryAction) {}
        ]
        let secondary: [ToolbarPattern.Item] = [
            .init(id: "bookmark", iconSystemName: "bookmark", title: "Bookmark", accessibilityHint: "Save bookmark", role: .secondaryAction) {},
            .init(id: "share", iconSystemName: "person.2", title: "Share", accessibilityHint: "Share project", role: .secondaryAction) {}
        ]
        let overflow: [ToolbarPattern.Item] = [
            .init(
                id: "settings",
                iconSystemName: "gear",
                title: "Settings",
                accessibilityHint: "Open settings",
                role: .secondaryAction,
                shortcut: ToolbarPattern.Item.Shortcut(key: ",", modifiers: [.command])
            ) {},
            .init(
                id: "help",
                iconSystemName: "questionmark.circle",
                title: "Help",
                accessibilityHint: "Open help",
                role: .secondaryAction,
                shortcut: ToolbarPattern.Item.Shortcut(key: "?", modifiers: [.command, .shift])
            ) {}
        ]
        return ToolbarPattern.Items(primary: primary, secondary: secondary, overflow: overflow)
    }()

    static let boxTree: [TreeNode] = {
        let audio = TreeNode(
            id: UUID(),
            name: "trak (Audio)",
            size: "128 KB",
            isFlagged: false,
            children: [
                TreeNode(id: UUID(), name: "mdia", size: "32 KB", isFlagged: false, children: []),
                TreeNode(id: UUID(), name: "minf", size: "48 KB", isFlagged: false, children: []),
                TreeNode(id: UUID(), name: "stbl", size: "48 KB", isFlagged: false, children: [])
            ]
        )
        let video = TreeNode(
            id: UUID(),
            name: "trak (Video)",
            size: "512 KB",
            isFlagged: false,
            children: [
                TreeNode(id: UUID(), name: "mdia", size: "128 KB", isFlagged: false, children: []),
                TreeNode(id: UUID(), name: "minf", size: "192 KB", isFlagged: false, children: []),
                TreeNode(id: UUID(), name: "stbl", size: "192 KB", isFlagged: false, children: [])
            ]
        )
        let metadata = TreeNode(
            id: UUID(),
            name: "meta",
            size: "32 KB",
            isFlagged: true,
            children: [
                TreeNode(id: UUID(), name: "ilst", size: "24 KB", isFlagged: true, children: [])
            ]
        )
        let moov = TreeNode(
            id: UUID(),
            name: "moov",
            size: "1.2 MB",
            isFlagged: false,
            children: [video, audio, metadata]
        )
        let mdat = TreeNode(id: UUID(), name: "mdat", size: "2.4 GB", isFlagged: false, children: [])
        rootNodeID = moov.id
        flaggedNodeID = metadata.id
        deepExpandedNodeIDs = [moov.id, video.id, metadata.id]
        return [moov, mdat]
    }()

    static var rootNodeID: UUID = UUID()
    static var flaggedNodeID: UUID = UUID()
    static var deepExpandedNodeIDs: [UUID] = []
}

// MARK: - SwiftUI Previews

#Preview("Pattern Catalog") {
    NavigationStack {
        PatternPreviewCatalog()
    }
    .padding(DS.Spacing.l)
}

#Preview("Pattern Catalog – Dark Mode") {
    NavigationStack {
        PatternPreviewCatalog()
    }
    .padding(DS.Spacing.l)
    .environment(\.colorScheme, .dark)
}
