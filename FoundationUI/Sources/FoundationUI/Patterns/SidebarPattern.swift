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
    ///
    /// ## NavigationSplitScaffold Integration
    ///
    /// When used inside ``NavigationSplitScaffold``, this pattern automatically adapts
    /// to provide only the sidebar content, allowing the scaffold to manage the
    /// three-column layout. When used standalone, it provides its own two-column
    /// NavigationSplitView.
    ///
    /// ```swift
    /// // Standalone usage (provides own NavigationSplitView)
    /// SidebarPattern(sections: sections, selection: $selection) { item in
    ///     DetailView(item: item)
    /// }
    ///
    /// // Inside scaffold (adapts to scaffold's layout)
    /// NavigationSplitScaffold {
    ///     SidebarPattern(sections: sections, selection: $selection) { _ in
    ///         EmptyView()
    ///     }
    /// } content: {
    ///     ContentView()
    /// } detail: {
    ///     InspectorPattern(title: "Details") { /* ... */ }
    /// }
    /// ```
    @available(iOS 17.0, macOS 14.0, *)
    public struct SidebarPattern<Selection: Hashable, Detail: View>: View {
        @Environment(\.navigationModel) private var navigationModel
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
                id: Selection, title: String, iconSystemName: String? = nil,
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
            sections: [Section], selection: Binding<Selection?>,
            @ViewBuilder detail: @escaping (Selection?) -> Detail
        ) {
            self.sections = sections
            _selection = selection
            detailBuilder = detail
        }

        public var body: some View {
            if navigationModel != nil {
                // Inside NavigationSplitScaffold: Only render sidebar content
                sidebarContent.accessibilityIdentifier("FoundationUI.SidebarPattern.sidebar")
                    .accessibilityLabel(Text("File Browser in Navigation"))
            } else {
                // Standalone mode: Provide own NavigationSplitView
                NavigationSplitView {
                    sidebarContent.accessibilityIdentifier("FoundationUI.SidebarPattern.sidebar")
                } detail: {
                    detailContent.accessibilityIdentifier("FoundationUI.SidebarPattern.detail")
                }.navigationSplitViewStyle(.balanced)#if os(macOS)
                    .navigationSplitViewColumnWidth(
                        min: Layout.sidebarMinimumWidth, ideal: Layout.sidebarIdealWidth)
                    #endif
            }
        }

        /// Returns true if this pattern is being used inside a NavigationSplitScaffold.
        private var isInScaffold: Bool { navigationModel != nil }

        @ViewBuilder private var sidebarContent: some View {
            List(selection: $selection) {
                ForEach(sections) { section in
                    SwiftUI.Section(header: sectionHeader(for: section)) {
                        ForEach(section.items) { item in sidebarRow(for: item) }
                    }
                }
            }.listStyle(.sidebar).accessibilityLabel(Text("Navigation"))
        }

        @ViewBuilder private func sectionHeader(for section: Section) -> some View {
            Text(section.title).font(DS.Typography.caption).textCase(.uppercase).foregroundStyle(
                .secondary
            ).padding(.horizontal, DS.Spacing.l).padding(.top, DS.Spacing.m).padding(
                .bottom, DS.Spacing.s
            ).accessibilityAddTraits(.isHeader)
        }

        @ViewBuilder private func sidebarRow(for item: Item) -> some View {
            Label {
                Text(item.title).font(DS.Typography.body).foregroundStyle(DS.Colors.textPrimary)
            } icon: {
                if let iconSystemName = item.iconSystemName {
                    Image(systemName: iconSystemName).font(DS.Typography.body).foregroundStyle(
                        DS.Colors.textSecondary)
                }
            }.tag(item.id).padding(.vertical, DS.Spacing.s).padding(.horizontal, DS.Spacing.l)
                .listRowInsets(
                    EdgeInsets(
                        top: DS.Spacing.s, leading: DS.Spacing.l, bottom: DS.Spacing.s,
                        trailing: DS.Spacing.m)
                ).contentShape(Rectangle()).accessibilityLabel(Text(item.accessibilityLabel))
        }

        @ViewBuilder private var detailContent: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.l) { detailBuilder(selection) }
                    .frame(maxWidth: .infinity, alignment: .leading).padding(detailPadding)
            }.background(DS.Colors.tertiary)
        }

        private var detailPadding: EdgeInsets {
            #if os(macOS)
                return EdgeInsets(
                    top: DS.Spacing.xl, leading: DS.Spacing.xl, bottom: DS.Spacing.xl,
                    trailing: DS.Spacing.xl)
            #else
                return EdgeInsets(
                    top: DS.Spacing.l, leading: DS.Spacing.l, bottom: DS.Spacing.l,
                    trailing: DS.Spacing.l)
            #endif
        }
    }

    private enum Layout {
        static let sidebarMinimumWidth = DS.Spacing.l * CGFloat(10) + DS.Spacing.xl * CGFloat(2)
        static let sidebarIdealWidth = DS.Spacing.l * CGFloat(12) + DS.Spacing.xl * CGFloat(2)
    }

    @available(iOS 17.0, macOS 14.0, *) @MainActor extension SidebarPattern: AgentDescribable {
        public var componentType: String { "SidebarPattern" }

        public var properties: [String: Any] {
            [
                "sections": sections.map { ["title": $0.title, "itemCount": $0.items.count] },
                "selection": selection.map { String(describing: $0) } ?? "none"
            ]
        }

        public var semantics: String {
            """
            A navigation sidebar pattern with \(sections.count) section(s). \
            Provides hierarchical navigation with selection-driven detail content.
            """
        }
    }

#endif
