#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI
import ISOInspectorKit

struct IntegritySummaryView: View {
    @ObservedObject var viewModel: IntegritySummaryViewModel
    var onIssueSelected: ((ParseIssue) -> Void)?
    var onExportJSON: (() -> Void)?
    var onExportIssueSummary: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            filterBar
            if viewModel.displayedIssues.isEmpty {
                emptyState
            } else {
                issueList
            }
        }
        .padding()
        .toolbar { exportToolbar }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Integrity Summary")
                    .font(.title2)
                    .bold()
                Text("Tolerant parsing issues detected")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            sortControls
        }
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            Text("Filter:")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(ParseIssue.Severity.allCases, id: \.self) { severity in
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
            }

            Spacer()

            if !viewModel.severityFilter.isEmpty {
                Button("Clear filters") {
                    viewModel.clearFilters()
                }
                .font(.caption)
            }
        }
    }

    private var sortControls: some View {
        HStack(spacing: 8) {
            Text("Sort by:")
                .font(.caption)
                .foregroundColor(.secondary)

            Picker("Sort", selection: $viewModel.sortOrder) {
                Text("Severity").tag(IntegritySummaryViewModel.SortOrder.severity)
                Text("Offset").tag(IntegritySummaryViewModel.SortOrder.offset)
                Text("Node").tag(IntegritySummaryViewModel.SortOrder.affectedNode)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 300)
        }
    }

    private var issueList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(Array(viewModel.displayedIssues.enumerated()), id: \.offset) { _, issue in
                    IssueRow(issue: issue) {
                        onIssueSelected?(issue)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 44))
                .foregroundColor(.green)
            Text("No integrity issues")
                .font(.headline)
            Text("The file parsed successfully without any issues.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func binding(for severity: ParseIssue.Severity) -> Binding<Bool> {
        Binding(
            get: { viewModel.severityFilter.contains(severity) },
            set: { _ in viewModel.toggleSeverityFilter(severity) }
        )
    }

    private func filterBackground(for severity: ParseIssue.Severity) -> Color {
        let isActive = viewModel.severityFilter.contains(severity)
        return severity.color.opacity(isActive ? 0.25 : 0.08)
    }

    private func filterForeground(for severity: ParseIssue.Severity) -> Color {
        let isActive = viewModel.severityFilter.contains(severity)
        return isActive ? severity.color : .secondary
    }

    private var shouldShowExportToolbar: Bool {
        IntegritySummaryToolbarPolicy.shouldShowToolbar(
            platform: IntegritySummaryToolbarPolicy.currentPlatform,
            hasJSONExport: onExportJSON != nil,
            hasIssueSummaryExport: onExportIssueSummary != nil
        )
    }

    private var exportToolbar: some ToolbarContent {
        buildIntegrityExportToolbar(
            shouldShowToolbar: shouldShowExportToolbar,
            onExportJSON: onExportJSON,
            onExportIssueSummary: onExportIssueSummary
        )
    }
}

@ToolbarContentBuilder
private func buildIntegrityExportToolbar(
    shouldShowToolbar: Bool,
    onExportJSON: (() -> Void)?,
    onExportIssueSummary: (() -> Void)?
) -> some ToolbarContent {
    if shouldShowToolbar, let onExportJSON, let onExportIssueSummary {
        ToolbarItemGroup(placement: .automatic) {
            Menu {
                Button {
                    onExportJSON()
                } label: {
                    Label("Export JSON…", systemImage: "square.and.arrow.down")
                }

                Button {
                    onExportIssueSummary()
                } label: {
                    Label("Export Issue Summary…", systemImage: "doc.text")
                }
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
        }
    }
}

enum IntegritySummaryToolbarPolicy {
    enum Platform {
        case macOS
        case iOSLike
    }

    static var currentPlatform: Platform {
#if os(macOS)
        .macOS
#else
        .iOSLike
#endif
    }

    static func shouldShowToolbar(
        platform: Platform,
        hasJSONExport: Bool,
        hasIssueSummaryExport: Bool
    ) -> Bool {
        guard hasJSONExport && hasIssueSummaryExport else {
            return false
        }

        switch platform {
        case .macOS:
            return false
        case .iOSLike:
            return true
        }
    }
}

private struct IssueRow: View {
    let issue: ParseIssue
    let onSelect: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: issue.severity.iconName)
                .font(.title3)
                .foregroundColor(issue.severity.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(issue.code)
                        .font(.body)
                        .fontWeight(.semibold)
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(issue.severity.label.uppercased())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(issue.severity.color)
                }

                Text(issue.message)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                HStack(spacing: 12) {
                    if let byteRange = issue.byteRange {
                        Label(
                            "Offset: \(byteRange.lowerBound)",
                            systemImage: "arrow.down.right.and.arrow.up.left"
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }

                    if !issue.affectedNodeIDs.isEmpty {
                        Label(
                            "Node: \(issue.affectedNodeIDs.first ?? 0)",
                            systemImage: "square.stack.3d.up"
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            Button(action: onSelect) {
                Image(systemName: "arrow.right.circle")
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
            .help("Focus this issue in the tree view")
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
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

#Preview("Integrity Summary") {
    IntegritySummaryPreview()
}

private struct IntegritySummaryPreview: View {
    @StateObject private var viewModel: IntegritySummaryViewModel

    init() {
        let store = ParseTreeStore()
        store.issueStore.record(
            ParseIssue(
                severity: .error,
                code: "ERR-001",
                message: "Critical error in ftyp box",
                byteRange: 100..<200,
                affectedNodeIDs: [1]
            ),
            depth: 1
        )
        store.issueStore.record(
            ParseIssue(
                severity: .warning,
                code: "WARN-001",
                message: "Non-standard box order detected",
                byteRange: 300..<400,
                affectedNodeIDs: [2]
            ),
            depth: 2
        )
        store.issueStore.record(
            ParseIssue(
                severity: .info,
                code: "INFO-001",
                message: "Optional box missing",
                byteRange: 500..<600,
                affectedNodeIDs: [3]
            ),
            depth: 1
        )

        _viewModel = StateObject(wrappedValue: IntegritySummaryViewModel(issueStore: store.issueStore))
    }

    var body: some View {
        IntegritySummaryView(viewModel: viewModel)
            .frame(width: 700, height: 500)
    }
}
#endif
