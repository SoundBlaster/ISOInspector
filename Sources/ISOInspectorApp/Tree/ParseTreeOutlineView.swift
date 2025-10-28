#if canImport(SwiftUI) && canImport(Combine)
import Combine
import SwiftUI
import NestedA11yIDs
import ISOInspectorKit

struct ParseTreeExplorerView: View {
    enum Tab {
        case explorer
        case integrity
    }

    @ObservedObject var viewModel: DocumentViewModel
    @ObservedObject private var outlineViewModel: ParseTreeOutlineViewModel
    @ObservedObject private var detailViewModel: ParseTreeDetailViewModel
    @ObservedObject private var annotations: AnnotationBookmarkSession
    @ObservedObject private var parseTreeStore: ParseTreeStore
    @State private var selectedTab: Tab = .explorer
    @State private var integrityViewModel: IntegritySummaryViewModel?
    @FocusState private var focusTarget: InspectorFocusTarget?
    let exportSelectionJSONAction: ((ParseTreeNode.ID) -> Void)?
    let exportSelectionIssueSummaryAction: ((ParseTreeNode.ID) -> Void)?
    let exportDocumentJSONAction: (() -> Void)?
    let exportDocumentIssueSummaryAction: (() -> Void)?
    private let focusCatalog = InspectorFocusShortcutCatalog.default

    init(
        viewModel: DocumentViewModel,
        exportSelectionJSONAction: ((ParseTreeNode.ID) -> Void)? = nil,
        exportSelectionIssueSummaryAction: ((ParseTreeNode.ID) -> Void)? = nil,
        exportDocumentJSONAction: (() -> Void)? = nil,
        exportDocumentIssueSummaryAction: (() -> Void)? = nil
    ) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self._outlineViewModel = ObservedObject(wrappedValue: viewModel.outlineViewModel)
        self._detailViewModel = ObservedObject(wrappedValue: viewModel.detailViewModel)
        self._annotations = ObservedObject(wrappedValue: viewModel.annotations)
        self._parseTreeStore = ObservedObject(wrappedValue: viewModel.store)
        self.exportSelectionJSONAction = exportSelectionJSONAction
        self.exportSelectionIssueSummaryAction = exportSelectionIssueSummaryAction
        self.exportDocumentJSONAction = exportDocumentJSONAction
        self.exportDocumentIssueSummaryAction = exportDocumentIssueSummaryAction
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            TabView(selection: $selectedTab) {
                explorerTab
                    .tabItem {
                        Label("Explorer", systemImage: "square.stack.3d.up")
                    }
                    .tag(Tab.explorer)

                integrityTab
                    .tabItem {
                        Label("Integrity", systemImage: "checkmark.shield")
                    }
                    .tag(Tab.integrity)
            }
        }
        .padding()
        .onAppear {
            focusTarget = .outline
            if integrityViewModel == nil {
                integrityViewModel = IntegritySummaryViewModel(issueStore: parseTreeStore.issueStore)
            }
        }
        .background(focusCommands)
        .focusedSceneValue(\.inspectorFocusTarget, focusBinding)
    }

    private var explorerTab: some View {
        HStack(alignment: .top, spacing: 16) {
            ParseTreeOutlineView(
                viewModel: outlineViewModel,
                selectedNodeID: selectionBinding,
                annotationSession: annotations,
                focusTarget: $focusTarget,
                exportSelectionJSONAction: exportSelectionJSONAction,
                exportSelectionIssueSummaryAction: exportSelectionIssueSummaryAction
            )
            .frame(minWidth: 320)
            .focused($focusTarget, equals: .outline)
            .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Outline.root)

            ParseTreeDetailView(
                viewModel: detailViewModel,
                annotationSession: annotations,
                selectedNodeID: selectionBinding,
                focusTarget: $focusTarget
            )
                .frame(minWidth: 360)
                .focused($focusTarget, equals: .detail)
                .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Detail.root)
        }
    }

    private var integrityTab: some View {
        Group {
            if let integrityViewModel {
                IntegritySummaryView(
                    viewModel: integrityViewModel,
                    onIssueSelected: handleIssueSelected,
                    onExportJSON: exportDocumentJSONAction,
                    onExportIssueSummary: exportDocumentIssueSummaryAction
                )
            } else {
                Text("Loading integrity summary...")
                    .foregroundColor(.secondary)
            }
        }
    }

    private func handleIssueSelected(_ issue: ParseIssue) {
        // @todo #T36-003 Navigate to affected node when issue is selected
        if let nodeID = issue.affectedNodeIDs.first {
            viewModel.nodeViewModel.select(nodeID: nodeID)
            selectedTab = .explorer
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(headerTitle)
                    .font(.title2)
                    .bold()
                    .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Header.title)
                Text(headerSubtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Header.subtitle)
            }
            Spacer()
            ParseStateBadge(state: viewModel.parseState)
                .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Header.parseState)
        }
        .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Header.root)
    }

    private var headerTitle: String {
        switch selectedTab {
        case .explorer:
            return "Box Hierarchy"
        case .integrity:
            return "Integrity Report"
        }
    }

    private var headerSubtitle: String {
        switch selectedTab {
        case .explorer:
            return "Search, filter, and expand ISO BMFF boxes"
        case .integrity:
            return "Review and triage parsing issues"
        }
    }

    private var focusCommands: some View {
        Group {
            ForEach(focusCatalog.shortcuts) { descriptor in
                HiddenKeyboardShortcutButton(
                    title: LocalizedStringKey(descriptor.title),
                    key: keyEquivalent(for: descriptor),
                    modifiers: [.command, .option]
                ) {
                    focusTarget = descriptor.target
                }
            }
        }
    }

    private var focusBinding: Binding<InspectorFocusTarget?> {
        Binding(
            get: { focusTarget },
            set: { focusTarget = $0 }
        )
    }

    private func keyEquivalent(for descriptor: InspectorFocusShortcutDescriptor) -> KeyEquivalent {
        KeyEquivalent(descriptor.key.first ?? " ")
    }

    private var selectionBinding: Binding<ParseTreeNode.ID?> {
        Binding(
            get: { viewModel.nodeViewModel.selectedNodeID },
            set: { newValue in viewModel.nodeViewModel.select(nodeID: newValue) }
        )
    }
}

struct ParseTreeOutlineView: View {
    @ObservedObject var viewModel: ParseTreeOutlineViewModel
    @Binding var selectedNodeID: ParseTreeNode.ID?
    @ObservedObject var annotationSession: AnnotationBookmarkSession
    @FocusState private var focusedRowID: ParseTreeNode.ID?
    let focusTarget: FocusState<InspectorFocusTarget?>.Binding
    let exportSelectionJSONAction: ((ParseTreeNode.ID) -> Void)?
    let exportSelectionIssueSummaryAction: ((ParseTreeNode.ID) -> Void)?

    init(
        viewModel: ParseTreeOutlineViewModel,
        selectedNodeID: Binding<ParseTreeNode.ID?>,
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
        VStack(spacing: 12) {
            searchBar
            severityFilterBar
            if !viewModel.availableCategories.isEmpty {
                categoryFilterBar
            }
            if viewModel.containsStreamingIndicators {
                streamingToggle
            }
            outlineList
        }
        .onAppear {
            keyboardSelectionID = selectedNodeID
            focusedRowID = selectedNodeID
        }
        .onChangeCompatibility(of: selectedNodeID) { newValue in
            keyboardSelectionID = newValue
            focusedRowID = newValue
        }
    }

    private var searchBar: some View {
        TextField("Search boxes, names, or summaries", text: $viewModel.searchText)
            .textFieldStyle(.roundedBorder)
            .focused(focusTarget, equals: .outline)
            .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Outline.Filters.searchField)
    }

    private var severityFilterBar: some View {
        HStack(spacing: 8) {
            ForEach(ValidationIssue.Severity.allCases, id: \.self) { severity in
                Toggle(isOn: binding(for: severity)) {
                    Text(severity.label)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(filterBackground(for: severity))
                        .foregroundColor(filterForeground(for: severity))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .toggleStyle(.button)
                .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Outline.Filters.severityToggle(severity))
            }
            Spacer()
            if viewModel.filter.isFocused {
                Button("Clear filters") {
                    viewModel.filter = .all
                }
                .font(.caption)
                .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Outline.Filters.clearButton)
            }
        }
    }

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.availableCategories, id: \.self) { category in
                    Toggle(isOn: binding(for: category)) {
                        Text(category.label)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(categoryBackground(for: category))
                            .foregroundColor(categoryForeground(for: category))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .toggleStyle(.button)
                    .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Outline.Filters.categoryToggle(category))
                }
            }
        }
    }

    private var streamingToggle: some View {
        Toggle(isOn: bindingForStreamingIndicators) {
            Label("Show streaming markers", systemImage: "dot.radiowaves.left.and.right")
                .font(.caption)
        }
        .toggleStyle(.switch)
        .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Outline.Filters.streamingToggle)
    }

    @ViewBuilder
    private var outlineList: some View {
        if viewModel.rows.isEmpty {
            emptyStateView
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(viewModel.rows) { row in
                        ParseTreeOutlineRowView(
                            row: row,
                            isSelected: selectedNodeID == row.id,
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
                            onExportJSON: exportSelectionJSONAction.map { action in {
                                action(row.id)
                            } },
                            onExportIssueSummary: exportSelectionIssueSummaryAction.map { action in {
                                action(row.id)
                            } }
                        )
                        .id(row.id)
                        .focused($focusedRowID, equals: row.id)
                        .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Outline.List.row(row.id))
                        .compatibilityFocusable()
                        .onTapGesture {
                            focusTarget.wrappedValue = .outline
                            focusedRowID = row.id
                        }
                    }
                }
            }
            .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Outline.List.root)
#if !os(iOS)
            .onMoveCommand { direction in
                guard focusTarget.wrappedValue == .outline else { return }
                guard let nextID = nextRowID(for: direction) else { return }
                if nextID != selectedNodeID {
                    selectedNodeID = nextID
                }
                keyboardSelectionID = nextID
                focusedRowID = nextID
            }
#endif
        }
    }

    @ViewBuilder
    private var emptyStateView: some View {
        if #available(iOS 17, macOS 14, *) {
            ContentUnavailableView(
                "No boxes",
                systemImage: "tray",
                description: Text("Run a parse to populate the hierarchy or adjust filters.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Outline.List.emptyState)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "tray")
                    .font(.system(size: 44))
                    .foregroundColor(.secondary)
                Text("No boxes")
                    .font(.headline)
                Text("Run a parse to populate the hierarchy or adjust filters.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Outline.List.emptyState)
        }
    }

    private func binding(for severity: ValidationIssue.Severity) -> Binding<Bool> {
        Binding(
            get: { viewModel.filter.focusedSeverities.contains(severity) },
            set: { viewModel.setSeverity(severity, isEnabled: $0) }
        )
    }

    private func binding(for category: BoxCategory) -> Binding<Bool> {
        Binding(
            get: { viewModel.filter.focusedCategories.contains(category) },
            set: { viewModel.setCategory(category, isEnabled: $0) }
        )
    }

    private var bindingForStreamingIndicators: Binding<Bool> {
        Binding(
            get: { viewModel.filter.showsStreamingIndicators },
            set: { viewModel.setShowsStreamingIndicators($0) }
        )
    }

    private func filterBackground(for severity: ValidationIssue.Severity) -> Color {
        let isActive = viewModel.filter.focusedSeverities.contains(severity)
        return severity.color.opacity(isActive ? 0.25 : 0.08)
    }

    private func filterForeground(for severity: ValidationIssue.Severity) -> Color {
        let isActive = viewModel.filter.focusedSeverities.contains(severity)
        return isActive ? severity.color : .secondary
    }

    private func categoryBackground(for category: BoxCategory) -> Color {
        let isActive = viewModel.filter.focusedCategories.contains(category)
        return category.color.opacity(isActive ? 0.25 : 0.08)
    }

    private func categoryForeground(for category: BoxCategory) -> Color {
        let isActive = viewModel.filter.focusedCategories.contains(category)
        return isActive ? category.color : .secondary
    }

#if !os(iOS)
    private func nextRowID(for direction: MoveCommandDirection) -> ParseTreeNode.ID? {
        let activeID = keyboardSelectionID ?? selectedNodeID
        switch direction {
        case .down:
            return viewModel.rowID(after: activeID, direction: .down)
        case .up:
            return viewModel.rowID(after: activeID, direction: .up)
        case .left:
            guard let activeID else { return nil }
            if let row = viewModel.rows.first(where: { $0.id == activeID }), row.isExpanded {
                viewModel.toggleExpansion(for: activeID)
                return activeID
            }
            return viewModel.rowID(after: activeID, direction: .parent) ?? activeID
        case .right:
            guard let activeID else { return nil }
            guard let row = viewModel.rows.first(where: { $0.id == activeID }) else {
                return activeID
            }
            if row.node.children.isEmpty {
                return activeID
            }
            if !row.isExpanded {
                viewModel.toggleExpansion(for: activeID)
            }
            return viewModel.rowID(after: activeID, direction: .child) ?? activeID
        default:
            return activeID
        }
    }
#endif
}

private struct ParseTreeOutlineRowView: View {
    let row: ParseTreeOutlineRow
    let isSelected: Bool
    let isBookmarked: Bool
    let isBookmarkingEnabled: Bool
    let onSelect: () -> Void
    let onToggleBookmark: () -> Void
    let onExportJSON: (() -> Void)?
    let onExportIssueSummary: (() -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            icon
            VStack(alignment: .leading, spacing: 2) {
                Text(row.displayName)
                    .font(.body)
                    .fontWeight(row.isSearchMatch ? .semibold : .regular)
                    .foregroundColor(row.isSearchMatch ? Color.accentColor : Color.primary)
                Text(row.typeDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let summary = row.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer()
            if let statusDescriptor = row.statusDescriptor {
                ParseTreeStatusBadge(descriptor: statusDescriptor)
            }
            if let corruption = row.corruptionSummary {
                CorruptionBadge(summary: corruption)
            } else if let severity = row.dominantSeverity {
                SeverityBadge(severity: severity)
            } else if row.hasValidationIssues {
                SeverityBadge(severity: .info)
            }
            bookmarkButton
        }
        .padding(.vertical, 6)
        .padding(.leading, CGFloat(row.depth) * 16 + 4)
        .padding(.trailing, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescriptor.label)
        .accessibilityValue(optional: accessibilityDescriptor.value)
        .accessibilityHint(optional: accessibilityDescriptor.hint)
        .contextMenu {
            if let onExportJSON {
                Button {
                    onExportJSON()
                } label: {
                    Label("Export JSON…", systemImage: "square.and.arrow.down")
                }
            }
            if let onExportIssueSummary {
                Button {
                    onExportIssueSummary()
                } label: {
                    Label("Export Issue Summary…", systemImage: "doc.text")
                }
            }
        }
    }

    private var icon: some View {
        Group {
            if row.node.children.isEmpty {
                Image(systemName: "square")
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: row.isExpanded ? "chevron.down" : "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 12)
    }

    private var bookmarkButton: some View {
        Button(action: onToggleBookmark) {
            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                .foregroundColor(isBookmarked ? Color.accentColor : Color.secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isBookmarked ? "Remove bookmark" : "Add bookmark")
        .disabled(!isBookmarkingEnabled)
        .opacity(isBookmarkingEnabled ? 1 : 0.35)
        .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Outline.List.rowBookmark(row.id))
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(backgroundColor)
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.18)
        }
        if row.isSearchMatch {
            return Color.accentColor.opacity(0.12)
        }
        return Color.clear
    }

    private var accessibilityDescriptor: AccessibilityDescriptor {
        row.accessibilityDescriptor(isBookmarked: isBookmarked)
    }
}

private struct CorruptionBadge: View {
    let summary: ParseTreeOutlineRow.CorruptionSummary

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: summary.dominantSeverity.iconName)
                .font(.caption2.weight(.bold))
                .accessibilityHidden(true)
            Text(summary.badgeText)
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .foregroundColor(summary.dominantSeverity.color)
        .background(summary.dominantSeverity.color.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .contentShape(Rectangle())
        .help(summary.tooltipText ?? summary.badgeText)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(summary.accessibilityLabel)
        .accessibilityHint(optional: summary.accessibilityHint)
#if os(macOS)
        .focusable(true)
#endif
    }
}

private struct SeverityBadge: View {
    let severity: ValidationIssue.Severity

    var body: some View {
        Text(severity.label.uppercased())
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(severity.color.opacity(0.2))
            .foregroundColor(severity.color)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

private struct ParseStateBadge: View {
    let state: ParseTreeStoreState

    var body: some View {
        Text(stateDescription)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(stateColor.opacity(0.15))
            .foregroundColor(stateColor)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var stateDescription: String {
        switch state {
        case .idle: return "Idle"
        case .parsing: return "Parsing"
        case .finished: return "Finished"
        case let .failed(message): return "Failed: \(message)"
        }
    }

    private var stateColor: Color {
        switch state {
        case .idle: return .secondary
        case .parsing: return .blue
        case .finished: return .green
        case .failed: return .red
        }
    }
}

private extension ParseIssue.Severity {
    var label: String {
        switch self {
        case .info: return "Info"
        case .warning: return "Warning"
        case .error: return "Error"
        }
    }

    var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }

    var iconName: String {
        switch self {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        }
    }
}

private extension ValidationIssue.Severity {
    var label: String {
        switch self {
        case .info: return "Info"
        case .warning: return "Warning"
        case .error: return "Error"
        }
    }

    var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
}

private extension BoxCategory {
    var label: String {
        switch self {
        case .metadata: return "Metadata"
        case .media: return "Media"
        case .index: return "Index"
        case .container: return "Container"
        case .other: return "Other"
        }
    }

    var color: Color {
        switch self {
        case .metadata: return .purple
        case .media: return .green
        case .index: return .blue
        case .container: return .teal
        case .other: return .gray
        }
    }
}

#Preview("Outline View") {
    ParseTreeOutlinePreview()
}

#Preview("Explorer") {
    ParseTreeExplorerPreview()
}

private struct ParseTreeOutlinePreview: View {
    @StateObject private var viewModel: ParseTreeOutlineViewModel
    @StateObject private var annotations = AnnotationBookmarkSession(store: nil)
    @State private var selectedNodeID: ParseTreeNode.ID?
    @FocusState private var focusTarget: InspectorFocusTarget?

    init() {
        let model = ParseTreeOutlineViewModel()
        model.apply(snapshot: ParseTreePreviewData.sampleSnapshot)
        _viewModel = StateObject(wrappedValue: model)
        _selectedNodeID = State(initialValue: ParseTreePreviewData.sampleSnapshot.nodes.first?.id)
    }

    var body: some View {
        ParseTreeOutlineView(
            viewModel: viewModel,
            selectedNodeID: $selectedNodeID,
            annotationSession: annotations,
            focusTarget: $focusTarget
        )
        .frame(width: 420, height: 480)
    }
}

private struct ParseTreeExplorerPreview: View {
    @StateObject private var documentViewModel: DocumentViewModel

    init() {
        let snapshot = ParseTreePreviewData.sampleSnapshot
        let store = ParseTreeStore(initialSnapshot: snapshot, initialState: .finished)
        let annotations = AnnotationBookmarkSession(store: nil)
        _documentViewModel = StateObject(wrappedValue: DocumentViewModel(store: store, annotations: annotations))
    }

    var body: some View {
        ParseTreeExplorerView(
            viewModel: documentViewModel
        )
        .frame(width: 520, height: 520)
    }
}

private extension View {
    @ViewBuilder
    func accessibilityValue(optional value: String?) -> some View {
        if let value {
            accessibilityValue(value)
        } else {
            self
        }
    }

    @ViewBuilder
    func accessibilityHint(optional hint: String?) -> some View {
        if let hint {
            accessibilityHint(hint)
        } else {
            self
        }
    }

    @ViewBuilder
    func compatibilityFocusable() -> some View {
#if os(iOS)
        if #available(iOS 17, *) {
            focusable(true)
        } else {
            self
        }
#else
        focusable(true)
#endif
    }

    @ViewBuilder
    func onChangeCompatibility<Value: Equatable>(
        of value: Value,
        initial: Bool = false,
        perform: @escaping (Value) -> Void
    ) -> some View {
        if #available(iOS 17, macOS 14, *) {
            onChange(of: value, initial: initial) { _, newValue in
                perform(newValue)
            }
        } else {
            onChange(of: value, perform: perform)
        }
    }
}

private struct HiddenKeyboardShortcutButton: View {
    let title: LocalizedStringKey
    let key: KeyEquivalent
    let modifiers: EventModifiers
    let action: () -> Void

    var body: some View {
        Button(title) { action() }
            .keyboardShortcut(key, modifiers: modifiers)
            .buttonStyle(.plain)
            .frame(width: 0, height: 0)
            .opacity(0.001)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
#endif
