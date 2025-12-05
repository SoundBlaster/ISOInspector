#if canImport(SwiftUI) && canImport(Combine)
    import Combine
    import SwiftUI
    import NestedA11yIDs
    import ISOInspectorKit
    import FoundationUI

    struct ParseTreeOutlineView: View {
        @ObservedObject var viewModel: ParseTreeOutlineViewModel
        @Binding var selectedNodeID: ParseTreeNode.ID?
        @ObservedObject var annotationSession: AnnotationBookmarkSession
        @FocusState private var focusedRowID: ParseTreeNode.ID?
        let focusTarget: FocusState<InspectorFocusTarget?>.Binding
        let exportSelectionJSONAction: ((ParseTreeNode.ID) -> Void)?
        let exportSelectionIssueSummaryAction: ((ParseTreeNode.ID) -> Void)?

        init(
            viewModel: ParseTreeOutlineViewModel, selectedNodeID: Binding<ParseTreeNode.ID?>,
            annotationSession: AnnotationBookmarkSession,
            focusTarget: FocusState<InspectorFocusTarget?>.Binding,
            exportSelectionJSONAction: ((ParseTreeNode.ID) -> Void)? = nil,
            exportSelectionIssueSummaryAction: ((ParseTreeNode.ID) -> Void)? = nil
        ) {
            self._viewModel = ObservedObject(wrappedValue: viewModel)
            self._selectedNodeID = selectedNodeID
            self._annotationSession = ObservedObject(wrappedValue: annotationSession)
            self.focusTarget = focusTarget
            self.exportSelectionJSONAction = exportSelectionJSONAction
            self.exportSelectionIssueSummaryAction = exportSelectionIssueSummaryAction
        }
        @State private var keyboardSelectionID: ParseTreeNode.ID?

        var body: some View {
            VStack(spacing: DS.Spacing.m) {
                searchBar
                severityFilterBar
                if !viewModel.availableCategories.isEmpty { categoryFilterBar }
                if viewModel.containsStreamingIndicators { streamingToggle }
                outlineList
            }.onAppear {
                keyboardSelectionID = selectedNodeID
                focusedRowID = selectedNodeID
            }.onChangeCompatibility(of: selectedNodeID) { newValue in
                keyboardSelectionID = newValue
                focusedRowID = newValue
            }
        }
    }

    extension ParseTreeOutlineView {

        private var searchBar: some View {
            TextField("Search boxes, names, or summaries", text: $viewModel.searchText)
                .textFieldStyle(.roundedBorder).focused(focusTarget, equals: .outline)
                .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Outline.Filters.searchField)
        }

        private var severityFilterBar: some View {
            ScrollView(.horizontal, showsIndicators: false) {

                HStack(spacing: DS.Spacing.s) {
                    filtersButtons

                    issuesOnlyToggle

                    clearAllFiltersButton
                }
            }
        }

        private var filtersButtons: some View {
            ForEach(ValidationIssue.Severity.allCases, id: \.self) { severity in
                Button {
                    binding(for: severity).wrappedValue.toggle()
                } label: {
                    Badge(level: badgeLevel(for: severity), showIcon: true).opacity(
                        isFilterActive(for: severity) ? 1 : 0.35)
                }.buttonStyle(.plain).nestedAccessibilityIdentifier(
                    ParseTreeAccessibilityID.Outline.Filters.severityToggle(severity))
            }
        }

        private var clearAllFiltersButton: some View {
            Button {
                viewModel.filter = .all
            } label: {
                Image(systemName: "xmark.circle")
            }.nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Outline.Filters.clearButton)
                .disabled(!viewModel.filter.isFocused)
        }

        private var issuesOnlyToggle: some View {
            Button {
                bindingForIssuesOnly.wrappedValue.toggle()
            } label: {
                Badge(text: "Issues only", level: .info, showIcon: true).opacity(
                    isIssuesOnlyActive ? 1 : 0.35)
            }.buttonStyle(.plain).nestedAccessibilityIdentifier(
                ParseTreeAccessibilityID.Outline.Filters.issuesOnlyToggle)
        }

        private var categoryFilterBar: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DS.Spacing.s) {
                    ForEach(viewModel.availableCategories, id: \.self) { category in
                        Button {
                            binding(for: category).wrappedValue.toggle()
                        } label: {
                            Badge(
                                text: category.label, level: badgeLevel(for: category),
                                showIcon: false
                            ).opacity(isFilterActive(for: category) ? 1 : 0.35)
                        }.buttonStyle(.plain).nestedAccessibilityIdentifier(
                            ParseTreeAccessibilityID.Outline.Filters.categoryToggle(category))
                    }

                    Button {
                        viewModel.filter = .all
                    } label: {
                        Image(systemName: "xmark.circle")
                    }.nestedAccessibilityIdentifier(
                        ParseTreeAccessibilityID.Outline.Filters.clearButton
                    ).disabled(!viewModel.filter.isFocused)
                }
            }
        }

        private var streamingToggle: some View {
            Toggle(isOn: bindingForStreamingIndicators) {
                Label("Show streaming markers", systemImage: "dot.radiowaves.left.and.right").font(
                    .caption)
            }.toggleStyle(.switch).nestedAccessibilityIdentifier(
                ParseTreeAccessibilityID.Outline.Filters.streamingToggle)
        }

        @ViewBuilder private var outlineList: some View {
            if viewModel.rows.isEmpty {
                emptyStateView
            } else {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(viewModel.rows) { row in
                        ParseTreeOutlineRowView(
                            row: row, isSelected: selectedNodeID == row.id,
                            isBookmarked: annotationSession.isBookmarked(nodeID: row.id),
                            isBookmarkingEnabled: annotationSession.isEnabled,
                            onSelect: {
                                selectedNodeID = row.id
                                if !row.node.children.isEmpty {
                                    viewModel.toggleExpansion(for: row.id)
                                }
                                keyboardSelectionID = row.id
                            },
                            onToggleBookmark: {
                                selectedNodeID = row.id
                                annotationSession.setSelectedNode(row.id)
                                annotationSession.toggleBookmark()
                            },
                            onExportJSON: exportSelectionJSONAction.map { action in
                                { @MainActor in action(row.id) }
                            },
                            onExportIssueSummary: exportSelectionIssueSummaryAction.map { action in
                                { @MainActor in action(row.id) }
                            }
                        ).id(row.id).focused($focusedRowID, equals: row.id)
                            .nestedAccessibilityIdentifier(
                                ParseTreeAccessibilityID.Outline.List.row(row.id)
                            ).compatibilityFocusable().onTapGesture {
                                focusTarget.wrappedValue = .outline
                                focusedRowID = row.id
                            }
                    }
                }.nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Outline.List.root)
                #if !os(iOS)
                        .onMoveCommand { direction in
                            guard focusTarget.wrappedValue == .outline else { return }
                            guard let nextID = nextRowID(for: direction) else { return }
                            if nextID != selectedNodeID { selectedNodeID = nextID }
                            keyboardSelectionID = nextID
                            focusedRowID = nextID
                        }
                    #endif
            }
        }

        @ViewBuilder private var emptyStateView: some View {
            if #available(iOS 17, macOS 14, *) {
                ContentUnavailableView(
                    "No boxes", systemImage: "tray",
                    description: Text("Run a parse to populate the hierarchy or adjust filters.")
                ).frame(maxWidth: .infinity, maxHeight: .infinity).nestedAccessibilityIdentifier(
                    ParseTreeAccessibilityID.Outline.List.emptyState)
            } else {
                VStack(spacing: DS.Spacing.m) {
                    Image(systemName: "tray").font(.system(size: 44)).foregroundColor(.secondary)
                    Text("No boxes").font(.headline)
                    Text("Run a parse to populate the hierarchy or adjust filters.").font(
                        .subheadline
                    ).foregroundColor(.secondary).multilineTextAlignment(.center)
                }.frame(maxWidth: .infinity, maxHeight: .infinity).nestedAccessibilityIdentifier(
                    ParseTreeAccessibilityID.Outline.List.emptyState)
            }
        }
    }

    extension ParseTreeOutlineView {
        private func binding(for severity: ValidationIssue.Severity) -> Binding<Bool> {
            Binding(
                get: { viewModel.filter.focusedSeverities.contains(severity) },
                set: { viewModel.setSeverity(severity, isEnabled: $0) })
        }

        private func binding(for category: BoxCategory) -> Binding<Bool> {
            Binding(
                get: { viewModel.filter.focusedCategories.contains(category) },
                set: { viewModel.setCategory(category, isEnabled: $0) })
        }

        private var bindingForStreamingIndicators: Binding<Bool> {
            Binding(
                get: { viewModel.filter.showsStreamingIndicators },
                set: { viewModel.setShowsStreamingIndicators($0) })
        }

        private var bindingForIssuesOnly: Binding<Bool> {
            Binding(
                get: { viewModel.filter.showsOnlyIssues },
                set: { newValue in
                    var updated = viewModel.filter
                    updated.showsOnlyIssues = newValue
                    viewModel.filter = updated
                })
        }
    }

    extension ParseTreeOutlineView {
        private func badgeLevel(for severity: ValidationIssue.Severity) -> BadgeLevel {
            switch severity {
            case .info: return .info
            case .warning: return .warning
            case .error: return .error
            }
        }

        private func badgeLevel(for category: BoxCategory) -> BadgeLevel {
            switch category {
            case .metadata: return .success
            case .media: return .warning
            case .index: return .success
            case .container: return .error
            case .other: return .info
            }
        }
    }

    extension ParseTreeOutlineView {
        private func isFilterActive(for severity: ValidationIssue.Severity) -> Bool {
            viewModel.filter.focusedSeverities.contains(severity)
        }

        private func isFilterActive(for category: BoxCategory) -> Bool {
            viewModel.filter.focusedCategories.contains(category)
        }

        private func filterBackground(for severity: ValidationIssue.Severity) -> Color {
            severity.color.opacity(isFilterActive(for: severity) ? 0.25 : 0.08)
        }

        private func filterForeground(for severity: ValidationIssue.Severity) -> Color {
            isFilterActive(for: severity) ? severity.color : .secondary
        }
    }

    extension ParseTreeOutlineView {
        private func categoryBackground(for category: BoxCategory) -> Color {
            category.color.opacity(isFilterActive(for: category) ? 0.25 : 0.08)
        }

        private func categoryForeground(for category: BoxCategory) -> Color {
            isFilterActive(for: category) ? category.color : .secondary
        }
    }

    extension ParseTreeOutlineView {
        private var isIssuesOnlyActive: Bool { viewModel.filter.showsOnlyIssues }

        private var issuesToggleBackground: Color {
            Color.accentColor.opacity(isIssuesOnlyActive ? 0.25 : 0.08)
        }

        private var issuesToggleForeground: Color {
            isIssuesOnlyActive ? Color.accentColor : .secondary
        }

        private var issuesToggleIconName: String {
            viewModel.filter.showsOnlyIssues
                ? "exclamationmark.triangle.fill" : "exclamationmark.triangle"
        }
    }

    #if !os(iOS)
        extension ParseTreeOutlineView {
            private func nextRowID(for direction: MoveCommandDirection) -> ParseTreeNode.ID? {
                let activeID = keyboardSelectionID ?? selectedNodeID
                switch direction {
                case .down: return viewModel.rowID(after: activeID, direction: .down)
                case .up: return viewModel.rowID(after: activeID, direction: .up)
                case .left:
                    guard let activeID else { return nil }
                    if let row = viewModel.rows.first(where: { $0.id == activeID }), row.isExpanded
                    {
                        viewModel.toggleExpansion(for: activeID)
                        return activeID
                    }
                    return viewModel.rowID(after: activeID, direction: .parent) ?? activeID
                case .right:
                    guard let activeID else { return nil }
                    guard let row = viewModel.rows.first(where: { $0.id == activeID }) else {
                        return activeID
                    }
                    if row.node.children.isEmpty { return activeID }
                    if !row.isExpanded { viewModel.toggleExpansion(for: activeID) }
                    return viewModel.rowID(after: activeID, direction: .child) ?? activeID
                default: return activeID
                }
            }
        }
    #endif

    #Preview("Outline View") { ParseTreeOutlinePreview() }

    #Preview("Explorer") { ParseTreeExplorerPreview() }

    private struct ParseTreeOutlinePreview: View {
        @StateObject private var viewModel: ParseTreeOutlineViewModel
        @StateObject private var annotations = AnnotationBookmarkSession(store: nil)
        @State private var selectedNodeID: ParseTreeNode.ID?
        @FocusState private var focusTarget: InspectorFocusTarget?

        init() {
            let model = ParseTreeOutlineViewModel()
            model.apply(snapshot: ParseTreePreviewData.sampleSnapshot)
            _viewModel = StateObject(wrappedValue: model)
            _selectedNodeID = State(
                initialValue: ParseTreePreviewData.sampleSnapshot.nodes.first?.id)
        }

        var body: some View {
            ParseTreeOutlineView(
                viewModel: viewModel, selectedNodeID: $selectedNodeID,
                annotationSession: annotations, focusTarget: $focusTarget
            ).frame(width: 420, height: 480)
        }
    }

    private struct ParseTreeExplorerPreview: View {
        @StateObject private var documentViewModel: DocumentViewModel
        @State private var selectedNodeID: ParseTreeNode.ID?
        @State private var showInspector = false
        @FocusState private var focusTarget: InspectorFocusTarget?

        init() {
            let snapshot = ParseTreePreviewData.sampleSnapshot
            let store = ParseTreeStore(initialSnapshot: snapshot, initialState: .finished)
            let annotations = AnnotationBookmarkSession(store: nil)
            _documentViewModel = StateObject(
                wrappedValue: DocumentViewModel(store: store, annotations: annotations))
            _selectedNodeID = State(initialValue: snapshot.nodes.first?.id)
        }

        var body: some View {
            ParseTreeExplorerView(
                viewModel: documentViewModel, selectedNodeID: $selectedNodeID,
                showInspector: $showInspector, focusTarget: $focusTarget,
                ensureIntegrityViewModel: {}, toggleInspectorVisibility: {},
                exportSelectionJSONAction: nil, exportSelectionIssueSummaryAction: nil
            ).frame(width: 760, height: 520)
        }
    }

#endif
