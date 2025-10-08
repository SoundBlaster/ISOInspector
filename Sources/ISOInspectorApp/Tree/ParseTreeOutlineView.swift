#if canImport(SwiftUI) && canImport(Combine)
import Combine
import SwiftUI
import ISOInspectorKit

struct ParseTreeExplorerView: View {
    @ObservedObject var store: ParseTreeStore
    @StateObject private var outlineViewModel = ParseTreeOutlineViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            ParseTreeOutlineView(viewModel: outlineViewModel)
        }
        .padding()
        .onAppear {
            outlineViewModel.bind(to: store.$snapshot.eraseToAnyPublisher())
        }
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
}

struct ParseTreeOutlineView: View {
    @ObservedObject var viewModel: ParseTreeOutlineViewModel

    var body: some View {
        VStack(spacing: 12) {
            searchBar
            severityFilterBar
            outlineList
        }
    }

    private var searchBar: some View {
        TextField("Search boxes, names, or summaries", text: $viewModel.searchText)
            .textFieldStyle(.roundedBorder)
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
                        ParseTreeOutlineRowView(row: row) {
                            if !row.node.children.isEmpty {
                                viewModel.toggleExpansion(for: row.id)
                            }
                        }
                        .id(row.id)
                    }
                }
            }
        }
    }

    private func binding(for severity: ValidationIssue.Severity) -> Binding<Bool> {
        Binding(
            get: { viewModel.filter.focusedSeverities.contains(severity) },
            set: { viewModel.setSeverity(severity, isEnabled: $0) }
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
}

private struct ParseTreeOutlineRowView: View {
    let row: ParseTreeOutlineRow
    let toggleExpansion: () -> Void

    var body: some View {
        Button(action: toggleExpansion) {
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
            }
            .padding(.vertical, 6)
            .padding(.leading, CGFloat(row.depth) * 16 + 4)
            .padding(.trailing, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
        }
        .buttonStyle(.plain)
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

    private var background: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(row.isSearchMatch ? Color.accentColor.opacity(0.12) : Color.clear)
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

#Preview("Outline View") {
    ParseTreeOutlineView(viewModel: {
        let model = ParseTreeOutlineViewModel()
        model.apply(snapshot: ParseTreePreviewData.sampleSnapshot)
        return model
    }())
    .frame(width: 420, height: 480)
}

#Preview("Explorer") {
    ParseTreeExplorerView(store: ParseTreeStore())
        .frame(width: 520, height: 520)
}
#endif
