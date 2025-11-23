#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI
import FoundationUI
import ISOInspectorKit

struct IntegritySummaryView: View {
    @ObservedObject var viewModel: IntegritySummaryViewModel
    var onIssueSelected: ((ParseIssue) -> Void)?
    var onExportJSON: (@MainActor () -> Void)?
    var onExportIssueSummary: (@MainActor () -> Void)?

    var body: some View {
        ScrollView {
            header

            sortBar

            filterBar
            if viewModel.displayedIssues.isEmpty {
                emptyState
            } else {
                issueList
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                Text("Integrity Summary")
                    .font(.title3)
                    .bold()
                Text("Tolerant parsing issues detected")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, DS.Spacing.m)
        .padding(.top, DS.Spacing.m)
    }

    private var sortBar: some View {
        HStack {
            sortControls

            Spacer()
        }
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            Text("Filters:")

            ForEach(ParseIssue.Severity.allCases, id: \.self) { severity in
                Button {
                    binding(for: severity).wrappedValue.toggle()
                } label: {
                    Badge(
                        level: badgeLevel(for: severity),
                        showIcon: true
                    )
                    .opacity(isFilterActive(for: severity) ? 1 : 0.35)
                }
                .buttonStyle(.plain)
            }

            Button {
                viewModel.clearFilters()
            } label: {
                Image(systemName: "xmark.circle")
            }
            .buttonStyle(.plain)
            .disabled(viewModel.severityFilter.isEmpty)

            Spacer()
        }
    }

    private var sortControls: some View {
        Picker("Sort:", selection: $viewModel.sortOrder) {
            Text("Severity").tag(IntegritySummaryViewModel.SortOrder.severity)
            Text("Offset").tag(IntegritySummaryViewModel.SortOrder.offset)
            Text("Node").tag(IntegritySummaryViewModel.SortOrder.affectedNode)
        }
        .pickerStyle(.segmented)
    }

    private var issueList: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(Array(viewModel.displayedIssues.enumerated()), id: \.offset) { _, issue in
                IssueRow(issue: issue) {
                    onIssueSelected?(issue)
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

    private func isFilterActive(for severity: ParseIssue.Severity) -> Bool {
        viewModel.severityFilter.contains(severity)
    }

    private func badgeLevel(for severity: ParseIssue.Severity) -> BadgeLevel {
        switch severity {
        case .info:
            return .info
        case .warning:
            return .warning
        case .error:
            return .error
        }
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
    onExportJSON: (@MainActor () -> Void)?,
    onExportIssueSummary: (@MainActor () -> Void)?
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
        HStack(alignment: .top, spacing: DS.Spacing.m) {
            Image(systemName: issue.severity.iconName)
                .font(.title3)
                .foregroundColor(issue.severity.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
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
        .padding(.vertical, DS.Spacing.s)
        .padding(.horizontal, DS.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous)
                .fill(Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }
}

extension ParseIssue.Severity {
    fileprivate var label: String {
        switch self {
        case .info: return "Info"
        case .warning: return "Warning"
        case .error: return "Error"
        }
    }

    fileprivate var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }

    fileprivate var iconName: String {
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

        _viewModel = StateObject(
            wrappedValue: IntegritySummaryViewModel(issueStore: store.issueStore))
    }

    var body: some View {
        IntegritySummaryView(viewModel: viewModel)
            .frame(width: 700, height: 500)
    }
}
#endif
