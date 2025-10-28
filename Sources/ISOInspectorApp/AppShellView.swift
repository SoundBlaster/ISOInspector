#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI
import NestedA11yIDs
import ISOInspectorKit

struct AppShellView: View {
    static let corruptionRibbonDismissedDefaultsKey = "corruption-warning-ribbon-dismissed"

    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var controller: DocumentSessionController
    @ObservedObject private var documentViewModel: DocumentViewModel
    @State private var isImporterPresented = false
    @State private var importError: ImportError?
    @AppStorage(Self.corruptionRibbonDismissedDefaultsKey) private
    var isCorruptionRibbonDismissed = false

    init(controller: DocumentSessionController) {
        self._controller = ObservedObject(wrappedValue: controller)
        self._documentViewModel = ObservedObject(wrappedValue: controller.documentViewModel)
    }

    var body: some View {
        content
            .onChangeCompat(of: scenePhase) { phase in
                handleScenePhaseChange(phase)
            }
    }

    private var content: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .navigationSplitViewStyle(.balanced)
        .overlay(alignment: .top) {
            VStack(spacing: 12) {
                if shouldShowCorruptionRibbon {
                    CorruptionWarningRibbon(
                        metrics: controller.issueMetrics,
                        onTap: controller.focusIntegrityDiagnostics,
                        onDismiss: dismissCorruptionRibbon
                    )
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                if let failure = controller.loadFailure {
                    DocumentLoadFailureBanner(
                        failure: failure,
                        retryAction: controller.retryLastFailure,
                        dismissAction: controller.dismissLoadFailure,
                        openFileAction: { isImporterPresented = true }
                    )
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.top)
        }
        .animation(
            .spring(response: 0.4, dampingFraction: 0.85), value: controller.loadFailure?.id
        )
        .animation(
            .spring(response: 0.4, dampingFraction: 0.85), value: shouldShowCorruptionRibbon
        )
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: controller.allowedContentTypes,
            allowsMultipleSelection: false,
            onCompletion: handleImportResult
        )
        .alert(importError?.title ?? "", isPresented: importErrorBinding) {
            Button("OK", role: .cancel) { importError = nil }
        } message: {
            if let message = importError?.message {
                Text(message)
            }
        }
        .alert(item: exportStatusBinding) { status in
            Alert(
                title: Text(status.title),
                message: Text(status.message),
                dismissButton: .default(Text("OK"), action: controller.dismissExportStatus)
            )
        }
        .onOpenURL { url in
            controller.openDocument(at: url)
        }
        .onChangeCompat(of: controller.issueMetrics.totalCount) { newValue in
            if newValue == 0 {
                isCorruptionRibbonDismissed = false
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    Button("Export JSON…") {
                        Task { await controller.exportJSON(scope: .document) }
                    }
                    .disabled(!documentViewModel.exportAvailability.canExportDocument)

                    Button("Export Issue Summary…") {
                        Task { await controller.exportIssueSummary(scope: .document) }
                    }
                    .disabled(!documentViewModel.exportAvailability.canExportDocument)

                    Divider()

                    Button("Export Selected JSON…") {
                        guard let nodeID = documentViewModel.nodeViewModel.selectedNodeID else { return }
                        Task { await controller.exportJSON(scope: .selection(nodeID)) }
                    }
                    .disabled(!documentViewModel.exportAvailability.canExportSelection)

                    Button("Export Selected Issue Summary…") {
                        guard let nodeID = documentViewModel.nodeViewModel.selectedNodeID else { return }
                        Task { await controller.exportIssueSummary(scope: .selection(nodeID)) }
                    }
                    .disabled(!documentViewModel.exportAvailability.canExportSelection)
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .disabled(
                    !documentViewModel.exportAvailability.canExportDocument
                        && !documentViewModel.exportAvailability.canExportSelection
                )
            }
        }
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        if phase == .background || phase == .inactive {
            controller.parseTreeStore.shutdown()
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("ISO Inspector")
                    .font(.title2)
                    .bold()
                Text("Inspect MP4 and QuickTime files")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Button {
                isImporterPresented = true
            } label: {
                Label("Open File…", systemImage: "folder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            List {
                Section("Recents") {
                    if controller.recents.isEmpty {
                        Text("Choose a file to start building your recents list.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(controller.recents) { recent in
                            Button {
                                controller.openRecent(recent)
                            } label: {
                                RecentRow(recent: recent)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete(perform: controller.removeRecent)
                    }
                }
            }
            .listStyle(.sidebar)

            Spacer()
        }
        .padding()
        .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.root)
    }

    private var detail: some View {
        Group {
            if controller.currentDocument != nil {
                ParseTreeExplorerView(
                    viewModel: documentViewModel,
                    exportSelectionJSONAction: exportSelectionJSONHandler,
                    exportSelectionIssueSummaryAction: exportSelectionIssueSummaryHandler,
                    exportDocumentJSONAction: exportDocumentJSONHandler,
                    exportDocumentIssueSummaryAction: exportDocumentIssueSummaryHandler
                )
                .frame(minWidth: 640, minHeight: 480)
            } else {
                OnboardingView(openAction: { isImporterPresented = true })
            }
        }
    }

    private func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            controller.openDocument(at: url)
        case .failure(let error):
            importError = ImportError(
                title: "Failed to open file", message: error.localizedDescription)
        }
    }

    private var importErrorBinding: Binding<Bool> {
        Binding(
            get: { importError != nil },
            set: { newValue in
                if !newValue {
                    importError = nil
                }
            }
        )
    }

    private var exportStatusBinding: Binding<DocumentSessionController.ExportStatus?> {
        Binding(
            get: { controller.exportStatus },
            set: { newValue in
                if newValue == nil {
                    controller.dismissExportStatus()
                }
            }
        )
    }

    private var exportSelectionJSONHandler: (ParseTreeNode.ID) -> Void {
        { nodeID in
            Task { await controller.exportJSON(scope: .selection(nodeID)) }
        }
    }

    private var exportSelectionIssueSummaryHandler: (ParseTreeNode.ID) -> Void {
        { nodeID in
            Task { await controller.exportIssueSummary(scope: .selection(nodeID)) }
        }
    }

    private var exportDocumentJSONHandler: () -> Void {
        {
            Task { await controller.exportJSON(scope: .document) }
        }
    }

    private var exportDocumentIssueSummaryHandler: () -> Void {
        {
            Task { await controller.exportIssueSummary(scope: .document) }
        }
    }

    private var shouldShowCorruptionRibbon: Bool {
        controller.issueMetrics.totalCount > 0 && !isCorruptionRibbonDismissed
    }

    private func dismissCorruptionRibbon() {
        isCorruptionRibbonDismissed = true
    }
}

private struct CorruptionWarningRibbon: View {
    let metrics: ParseIssueStore.IssueMetrics
    let onTap: () -> Void
    let onDismiss: () -> Void

    private var headlineText: String {
        let components = [
            makeCountText(count: metrics.errorCount, label: "error"),
            makeCountText(count: metrics.warningCount, label: "warning"),
            makeCountText(count: metrics.infoCount, label: "info"),
        ].compactMap { $0 }
        return components.joined(separator: ", ")
    }

    private var depthText: String {
        guard metrics.deepestAffectedDepth > 0 else {
            return "Surface-level impact"
        }
        return "Impacts depth \(metrics.deepestAffectedDepth)"
    }

    private var accessibilityLabel: String {
        var components: [String] = ["Integrity issues detected", headlineText]
        if metrics.deepestAffectedDepth > 0 {
            components.append("Deepest affected depth: \(metrics.deepestAffectedDepth)")
        }
        components.append("Double-tap to view the integrity report")
        return components.joined(separator: ". ")
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(Color.orange)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Tolerant parsing detected issues")
                    .font(.subheadline)
                    .bold()
                Text(headlineText)
                    .font(.subheadline)
                Text(depthText)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 12)

            HStack(spacing: 6) {
                Text("View Integrity Report")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .accessibilityHidden(true)
            }
            .foregroundColor(.orange)

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.secondary)
                    .font(.system(size: 18, weight: .semibold))
                    .padding(4)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Dismiss corruption warning")
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.orange.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 14, y: 6)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: Text("View Integrity Report"), onTap)
        .accessibilityAction(.escape, onDismiss)
    }

    private func makeCountText(count: Int, label: String) -> String? {
        guard count > 0 else { return nil }
        if count == 1 {
            return "1 \(label)"
        }
        return "\(count) \(label)s"
    }
}

#if DEBUG
private struct CorruptionWarningRibbon_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CorruptionWarningRibbon(
                metrics: ParseIssueStore.IssueMetrics(
                    errorCount: 2,
                    warningCount: 5,
                    infoCount: 1,
                    deepestAffectedDepth: 4
                ),
                onTap: {},
                onDismiss: {}
            )
            .padding()
            .previewLayout(.sizeThatFits)

            CorruptionWarningRibbon(
                metrics: ParseIssueStore.IssueMetrics(
                    warningCount: 1
                ),
                onTap: {},
                onDismiss: {}
            )
            .padding()
            .previewLayout(.sizeThatFits)
            .preferredColorScheme(.dark)
        }
    }
}
#endif

private struct DocumentLoadFailureBanner: View {
    let failure: DocumentSessionController.DocumentLoadFailure
    let retryAction: () -> Void
    let dismissAction: () -> Void
    let openFileAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 6) {
                    Text(failure.title)
                        .font(.headline)
                    Text(failure.message)
                        .font(.subheadline)
                    if let details = failure.details, !details.isEmpty {
                        Text(details)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    Text(failure.recoverySuggestion)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .textSelection(.enabled)

                Spacer()

                Button(action: dismissAction) {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Color.secondary)
                        .font(.system(size: 16, weight: .semibold))
                        .padding(4)
                        .accessibilityHidden(true)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Dismiss error")
                .accessibilityAddTraits(.isButton)
            }

            HStack(spacing: 12) {
                Button("Try Again", action: retryAction)
                    .buttonStyle(.borderedProminent)
                Button("Open File…", action: openFileAction)
                    .buttonStyle(.bordered)
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.red.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 14, y: 6)
        .accessibilityIdentifier("document-load-failure-banner")
    }
}

private struct RecentRow: View {
    let recent: DocumentRecent
    private let dateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(recent.displayName)
                .font(.headline)
            Text(formattedDate())
                .font(.caption)
                .foregroundColor(.secondary)
            Text(recent.url.path)
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.7))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formattedDate() -> String {
        dateFormatter.localizedString(for: recent.lastOpened, relativeTo: Date())
    }
}

private struct OnboardingView: View {
    let openAction: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "film")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            VStack(spacing: 8) {
                Text("Open an MP4 or QuickTime file to begin")
                    .font(.title2)
                    .bold()
                Text(
                    "Use the Open File button to select a document. Recently opened files will appear in the sidebar for quick access."
                )
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            }
            Button(action: openAction) {
                Label("Open File…", systemImage: "folder")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

private struct ImportError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
#endif
