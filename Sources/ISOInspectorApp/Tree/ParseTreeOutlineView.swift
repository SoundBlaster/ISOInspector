#if canImport(SwiftUI) && canImport(Combine)
import Combine
import SwiftUI
import ISOInspectorKit

struct ParseTreeExplorerView: View {
    @ObservedObject var store: ParseTreeStore
    @ObservedObject var annotations: AnnotationBookmarkSession
    @StateObject private var outlineViewModel = ParseTreeOutlineViewModel()
    @StateObject private var detailViewModel = ParseTreeDetailViewModel(hexSliceProvider: nil, annotationProvider: nil)
    @State private var selectedNodeID: ParseTreeNode.ID?
    @FocusState private var focusTarget: InspectorFocusTarget?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            HStack(alignment: .top, spacing: 16) {
                ParseTreeOutlineView(
                    viewModel: outlineViewModel,
                    selectedNodeID: $selectedNodeID,
                    annotationSession: annotations,
                    focusTarget: $focusTarget
                )
                .frame(minWidth: 320)
                .focused($focusTarget, equals: .outline)

                ParseTreeDetailView(
                    viewModel: detailViewModel,
                    annotationSession: annotations,
                    selectedNodeID: $selectedNodeID,
                    focusTarget: $focusTarget
                )
                    .frame(minWidth: 360)
                    .focused($focusTarget, equals: .detail)
            }
        }
        .padding()
        .onAppear {
            outlineViewModel.bind(to: store.$snapshot.eraseToAnyPublisher())
            detailViewModel.bind(to: store.$snapshot.eraseToAnyPublisher())
            detailViewModel.update(
                hexSliceProvider: store.makeHexSliceProvider(),
                annotationProvider: store.makePayloadAnnotationProvider()
            )
            annotations.setFileURL(store.fileURL)
            annotations.setSelectedNode(selectedNodeID)
        }
        .onChange(of: selectedNodeID) { _, newValue in
            detailViewModel.select(nodeID: newValue)
            annotations.setSelectedNode(newValue)
        }
        .onChange(of: store.state) { _, _ in
            detailViewModel.update(
                hexSliceProvider: store.makeHexSliceProvider(),
                annotationProvider: store.makePayloadAnnotationProvider()
            )
        }
        .onChange(of: store.fileURL) { _, newValue in
            annotations.setFileURL(newValue)
        }
        .onAppear {
            focusTarget = .outline
        }
        .background(focusCommands)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Box Hierarchy")
                    .font(.title2)
                    .bold()
                Text("Search, filter, and expand ISO BMFF boxes")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            ParseStateBadge(state: store.state)
        }
    }

    private var focusCommands: some View {
        HStack(spacing: 0) {
            Button("Focus outline") { focusTarget = .outline }
                .keyboardShortcut("1", modifiers: [.command, .option])
            Button("Focus detail") { focusTarget = .detail }
                .keyboardShortcut("2", modifiers: [.command, .option])
            Button("Focus notes") { focusTarget = .notes }
                .keyboardShortcut("3", modifiers: [.command, .option])
            Button("Focus hex") { focusTarget = .hex }
                .keyboardShortcut("4", modifiers: [.command, .option])
        }
        .frame(width: 0, height: 0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct ParseTreeOutlineView: View {
    @ObservedObject var viewModel: ParseTreeOutlineViewModel
    @Binding var selectedNodeID: ParseTreeNode.ID?
    @ObservedObject var annotationSession: AnnotationBookmarkSession
    @FocusState private var focusedRowID: ParseTreeNode.ID?
    let focusTarget: FocusState<InspectorFocusTarget?>.Binding
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
        .onChange(of: selectedNodeID) { _, newValue in
            keyboardSelectionID = newValue
            focusedRowID = newValue
        }
    }

    private var searchBar: some View {
        TextField("Search boxes, names, or summaries", text: $viewModel.searchText)
            .textFieldStyle(.roundedBorder)
            .focused(focusTarget, equals: .outline)
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
                        .foregroundStyle(filterForeground(for: severity))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .toggleStyle(.button)
            }
            Spacer()
            if viewModel.filter.isFocused {
                Button("Clear filters") {
                    viewModel.filter = .all
                }
                .font(.caption)
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
                            .foregroundStyle(categoryForeground(for: category))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .toggleStyle(.button)
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
    }

    @ViewBuilder
    private var outlineList: some View {
        if viewModel.rows.isEmpty {
            ContentUnavailableView(
                "No boxes",
                systemImage: "tray",
                description: Text("Run a parse to populate the hierarchy or adjust filters.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                            }
                        )
                        .id(row.id)
                        .focused($focusedRowID, equals: row.id)
                        .focusable(true)
                        .onTapGesture {
                            focusTarget.wrappedValue = .outline
                            focusedRowID = row.id
                        }
                    }
                }
            }
            .onMoveCommand { direction in
                guard focusTarget.wrappedValue == .outline else { return }
                guard let nextID = nextRowID(for: direction) else { return }
                if nextID != selectedNodeID {
                    selectedNodeID = nextID
                }
                keyboardSelectionID = nextID
                focusedRowID = nextID
            }
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
}

private struct ParseTreeOutlineRowView: View {
    let row: ParseTreeOutlineRow
    let isSelected: Bool
    let isBookmarked: Bool
    let isBookmarkingEnabled: Bool
    let onSelect: () -> Void
    let onToggleBookmark: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            icon
            VStack(alignment: .leading, spacing: 2) {
                Text(row.displayName)
                    .font(.body)
                    .fontWeight(row.isSearchMatch ? .semibold : .regular)
                    .foregroundStyle(row.isSearchMatch ? Color.accentColor : Color.primary)
                Text(row.typeDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let summary = row.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer()
            if let severity = row.dominantSeverity {
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
        .accessibilityValue(accessibilityDescriptor.value)
        .accessibilityHint(accessibilityDescriptor.hint)
    }

    private var icon: some View {
        Group {
            if row.node.children.isEmpty {
                Image(systemName: "square")
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: row.isExpanded ? "chevron.down" : "chevron.right")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 12)
    }

    private var bookmarkButton: some View {
        Button(action: onToggleBookmark) {
            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                .foregroundStyle(isBookmarked ? Color.accentColor : Color.secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isBookmarked ? "Remove bookmark" : "Add bookmark")
        .disabled(!isBookmarkingEnabled)
        .opacity(isBookmarkingEnabled ? 1 : 0.35)
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

private struct SeverityBadge: View {
    let severity: ValidationIssue.Severity

    var body: some View {
        Text(severity.label.uppercased())
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(severity.color.opacity(0.2))
            .foregroundStyle(severity.color)
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
            .foregroundStyle(stateColor)
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
    ParseTreeOutlineView(viewModel: {
        let model = ParseTreeOutlineViewModel()
        model.apply(snapshot: ParseTreePreviewData.sampleSnapshot)
        return model
    }(),
    selectedNodeID: .constant(ParseTreePreviewData.sampleSnapshot.nodes.first?.id),
    annotationSession: AnnotationBookmarkSession(store: nil),
    focusTarget: .constant(nil)
    )
    .frame(width: 420, height: 480)
}

#Preview("Explorer") {
    ParseTreeExplorerView(
        store: ParseTreeStore(),
        annotations: AnnotationBookmarkSession(store: nil)
    )
        .frame(width: 520, height: 520)
}
#endif
