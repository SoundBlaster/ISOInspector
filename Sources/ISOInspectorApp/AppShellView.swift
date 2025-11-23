#if canImport(SwiftUI) && canImport(Combine)
  import SwiftUI
  import NestedA11yIDs
  import ISOInspectorKit
  import FoundationUI

  struct AppShellView: View {
    static let corruptionRibbonDismissedDefaultsKey = "corruption-warning-ribbon-dismissed"

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var windowController: WindowSessionController
    @ObservedObject var appController: DocumentSessionController
    @State private var isImporterPresented = false
    @State private var importError: ImportError?
    @State private var inspectorVisibility = InspectorColumnVisibility()
    @State private var displayMode = InspectorDisplayMode()
    @State private var integrityViewModel: IntegritySummaryViewModel?
    @FocusState private var focusTarget: InspectorFocusTarget?
    private let focusCatalog = InspectorFocusShortcutCatalog.default
    @AppStorage(Self.corruptionRibbonDismissedDefaultsKey) private
      var isCorruptionRibbonDismissed = false

    init(appController: DocumentSessionController) {
      self.appController = appController
      let windowController = WindowSessionController(appSessionController: appController)
      self._windowController = StateObject(wrappedValue: windowController)
    }

    /// Access documentViewModel from windowController.
    ///
    /// IMPORTANT: This MUST be a computed property, not a stored @ObservedObject property.
    /// Initializing @ObservedObject from a local variable in init() breaks the SwiftUI
    /// binding chain, preventing UI updates when documents are loaded.
    ///
    /// See bug #232 for details on the regression that occurred when this was a stored property.
    private var documentViewModel: DocumentViewModel {
      windowController.documentViewModel
    }

    var body: some View {
      content
        .onChangeCompat(of: scenePhase) { phase in
          handleScenePhaseChange(phase)
        }
        .focusedSceneValue(\.inspectorFocusTarget, focusBinding)
        .background(focusCommands)
        .onAppear { focusTarget = .outline }
    }

    private var content: some View {
      NavigationSplitView(columnVisibility: inspectorColumnVisibilityBinding) {
        sidebar
      } content: {
        parseTreeContent
          .frame(minWidth: 320)
      } detail: {
        inspectorDetail
          .frame(minWidth: 360)
          .focused($focusTarget, equals: .detail)
      }
      .navigationSplitViewStyle(.balanced)
      .overlay(alignment: .top) {
        VStack(spacing: DS.Spacing.m) {
          if shouldShowCorruptionRibbon {
            CorruptionWarningRibbon(
              metrics: windowController.issueMetrics,
              onTap: windowController.focusIntegrityDiagnostics,
              onDismiss: dismissCorruptionRibbon
            )
            .padding(.horizontal)
            .transition(.move(edge: .top).combined(with: .opacity))
          }

          if let failure = windowController.loadFailure {
            DocumentLoadFailureBanner(
              failure: failure,
              retryAction: windowController.retryLastFailure,
              dismissAction: windowController.dismissLoadFailure,
              openFileAction: { isImporterPresented = true }
            )
            .padding(.horizontal)
            .transition(.move(edge: .top).combined(with: .opacity))
          }
        }
        .padding(.top)
      }
      .animation(
        .spring(response: 0.4, dampingFraction: 0.85), value: windowController.loadFailure?.id
      )
      .animation(
        .spring(response: 0.4, dampingFraction: 0.85), value: shouldShowCorruptionRibbon
      )
      .fileImporter(
        isPresented: $isImporterPresented,
        allowedContentTypes: appController.allowedContentTypes,
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
          dismissButton: .default(Text("OK"), action: windowController.dismissExportStatus)
        )
      }
      .onOpenURL { url in
        windowController.openDocument(at: url)
      }
      .onChangeCompat(of: documentViewModel.nodeViewModel.selectedNodeID) { newValue in
        if newValue != nil {
          displayMode.current = .selectionDetails
        }
      }
      .onChangeCompat(of: windowController.issueMetrics.totalCount) { newValue in
        if newValue == 0 {
          isCorruptionRibbonDismissed = false
        }
      }
      .toolbar {
        ToolbarItemGroup(placement: .primaryAction) {
          Menu {
            Button("Export JSON…") {
              Task { await windowController.exportJSON(scope: .document) }
            }
            .disabled(!documentViewModel.exportAvailability.canExportDocument)

            Button("Export Issue Summary…") {
              Task { await windowController.exportIssueSummary(scope: .document) }
            }
            .disabled(!documentViewModel.exportAvailability.canExportDocument)

            Divider()

            Button("Export Selected JSON…") {
              guard let nodeID = documentViewModel.nodeViewModel.selectedNodeID else { return }
              Task { await windowController.exportJSON(scope: .selection(nodeID)) }
            }
            .disabled(!documentViewModel.exportAvailability.canExportSelection)

            Button("Export Selected Issue Summary…") {
              guard let nodeID = documentViewModel.nodeViewModel.selectedNodeID else { return }
              Task { await windowController.exportIssueSummary(scope: .selection(nodeID)) }
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
        windowController.parseTreeStore.shutdown()
      }
    }

    private func handleIssueSelected(_ issue: ParseIssue) {
      guard let nodeID = issue.affectedNodeIDs.first else { return }
      documentViewModel.outlineViewModel.revealNode(withID: nodeID)
      documentViewModel.nodeViewModel.select(nodeID: nodeID)
      inspectorVisibility.ensureInspectorVisible()
      displayMode.current = .selectionDetails
      focusTarget = .outline
    }

    private func ensureIntegrityViewModel() {
      if integrityViewModel == nil {
        integrityViewModel = IntegritySummaryViewModel(issueStore: documentViewModel.store.issueStore)
      }
    }

    private func toggleInspectorVisibility() {
      inspectorVisibility.toggleInspectorVisibility()
    }

    private var focusCommands: some View {
      Group {
        ForEach(focusCatalog.shortcuts) { descriptor in
          Button(action: { focusTarget = descriptor.target }) {
            EmptyView()
          }
          .keyboardShortcut(keyEquivalent(for: descriptor), modifiers: [.command, .option])
          .opacity(0)
        }
        Button(action: { navigateToIssue(direction: .down) }) { EmptyView() }
          .keyboardShortcut("e", modifiers: [.command, .shift])
          .opacity(0)
        Button(action: { navigateToIssue(direction: .up) }) { EmptyView() }
          .keyboardShortcut("e", modifiers: [.command, .shift, .option])
          .opacity(0)
        Button(action: { toggleInspectorVisibility() }) { EmptyView() }
          .keyboardShortcut("i", modifiers: [.command, .option])
          .opacity(0)
      }
    }

    private func navigateToIssue(direction: ParseTreeOutlineViewModel.NavigationDirection) {
      let outlineViewModel = documentViewModel.outlineViewModel
      guard
        let targetID = outlineViewModel.issueRowID(
          after: documentViewModel.nodeViewModel.selectedNodeID,
          direction: direction
        )
      else { return }
      outlineViewModel.revealNode(withID: targetID)
      inspectorVisibility.ensureInspectorVisible()
      displayMode.current = .selectionDetails
      focusTarget = .outline
      documentViewModel.nodeViewModel.select(nodeID: targetID)
    }

    private func keyEquivalent(for descriptor: InspectorFocusShortcutDescriptor) -> KeyEquivalent {
      KeyEquivalent(descriptor.key.first ?? " ")
    }

    private var focusBinding: Binding<InspectorFocusTarget?> {
      Binding(
        get: { focusTarget },
        set: { focusTarget = $0 }
      )
    }

    private var selectionBinding: Binding<ParseTreeNode.ID?> {
      Binding(
        get: { documentViewModel.nodeViewModel.selectedNodeID },
        set: { newValue in documentViewModel.nodeViewModel.select(nodeID: newValue) }
      )
    }

    private var inspectorColumnVisibilityBinding: Binding<NavigationSplitViewVisibility> {
      Binding(
        get: { inspectorVisibility.columnVisibility },
        set: { inspectorVisibility.columnVisibility = $0 }
      )
    }

    private var sidebar: some View {
      VStack(alignment: .leading, spacing: DS.Spacing.l) {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
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
            if appController.recents.isEmpty {
              Text("Choose a file to start building your recents list.")
                .foregroundColor(.secondary)
            } else {
              ForEach(appController.recents) { recent in
                Button {
                  windowController.openRecent(recent)
                } label: {
                  RecentRow(recent: recent)
                }
                .buttonStyle(.plain)
              }
              .onDelete(perform: appController.removeRecent)
            }
          }
        }
        .listStyle(.sidebar)

        Spacer()
      }
      .padding(.vertical, DS.Spacing.l)
      .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.root)
    }

    private var parseTreeContent: some View {
      Group {
        if windowController.currentDocument != nil {
          ParseTreeExplorerView(
            viewModel: documentViewModel,
            selectedNodeID: selectionBinding,
            displayMode: $displayMode,
            focusTarget: $focusTarget,
            ensureInspectorVisible: { inspectorVisibility.ensureInspectorVisible() },
            ensureIntegrityViewModel: ensureIntegrityViewModel,
            toggleInspectorVisibility: { toggleInspectorVisibility() },
            exportSelectionJSONAction: exportSelectionJSONHandler,
            exportSelectionIssueSummaryAction: exportSelectionIssueSummaryHandler
          )
          .frame(minWidth: 640, minHeight: 480)
        } else {
          OnboardingView(openAction: { isImporterPresented = true })
        }
      }
    }

    private var inspectorDetail: some View {
      Group {
        if windowController.currentDocument != nil {
          InspectorDetailView(
            detailViewModel: documentViewModel.detailViewModel,
            annotationSession: documentViewModel.annotations,
            selectedNodeID: selectionBinding,
            integrityViewModel: integrityViewModel,
            showsIntegritySummary: displayMode.isShowingIntegritySummary,
            exportDocumentJSONAction: exportDocumentJSONHandler,
            exportDocumentIssueSummaryAction: exportDocumentIssueSummaryHandler,
            onIssueSelected: handleIssueSelected,
            focusTarget: $focusTarget
          )
          .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Inspector.root)
        } else {
          EmptyView()
        }
      }
    }

    private func handleImportResult(_ result: Result<[URL], Error>) {
      switch result {
      case .success(let urls):
        guard let url = urls.first else { return }
        windowController.openDocument(at: url)
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
        get: { windowController.exportStatus },
        set: { newValue in
          if newValue == nil {
            windowController.dismissExportStatus()
          }
        }
      )
    }

    private var exportSelectionJSONHandler: (ParseTreeNode.ID) -> Void {
      { nodeID in
        Task { await windowController.exportJSON(scope: .selection(nodeID)) }
      }
    }

    private var exportSelectionIssueSummaryHandler: (ParseTreeNode.ID) -> Void {
      { nodeID in
        Task { await windowController.exportIssueSummary(scope: .selection(nodeID)) }
      }
    }

    private var exportDocumentJSONHandler: () -> Void {
      {
        Task { await windowController.exportJSON(scope: .document) }
      }
    }

    private var exportDocumentIssueSummaryHandler: () -> Void {
      {
        Task { await windowController.exportIssueSummary(scope: .document) }
      }
    }

    private var shouldShowCorruptionRibbon: Bool {
      windowController.issueMetrics.totalCount > 0 && !isCorruptionRibbonDismissed
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
      HStack(alignment: .center, spacing: DS.Spacing.l) {
        Image(systemName: "exclamationmark.triangle.fill")
          .font(.title3)
          .foregroundStyle(Color.orange)
          .accessibilityHidden(true)

        VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
          Text("Tolerant parsing detected issues")
            .font(.subheadline)
            .bold()
          Text(headlineText)
            .font(.subheadline)
          Text(depthText)
            .font(.footnote)
            .foregroundColor(.secondary)
        }

        Spacer(minLength: DS.Spacing.m)

        HStack(spacing: DS.Spacing.xs) {
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
            .padding(DS.Spacing.xxs)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel("Dismiss corruption warning")
      }
      .padding(.vertical, DS.Spacing.m + 2)
      .padding(.horizontal, DS.Spacing.l + 2)
      .background(
        RoundedRectangle(cornerRadius: DS.Radius.card + 4, style: .continuous)
          .fill(.regularMaterial)
      )
      .overlay(
        RoundedRectangle(cornerRadius: DS.Radius.card + 4, style: .continuous)
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
      VStack(alignment: .leading, spacing: DS.Spacing.m) {
        HStack(alignment: .top, spacing: DS.Spacing.m) {
          Image(systemName: "exclamationmark.triangle.fill")
            .font(.title3)
            .foregroundColor(.orange)
            .accessibilityHidden(true)

          VStack(alignment: .leading, spacing: DS.Spacing.xs) {
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
              .padding(DS.Spacing.xxs)
              .accessibilityHidden(true)
          }
          .buttonStyle(.borderless)
          .accessibilityLabel("Dismiss error")
          .accessibilityAddTraits(.isButton)
        }

        HStack(spacing: DS.Spacing.m) {
          Button("Try Again", action: retryAction)
            .buttonStyle(.borderedProminent)
          Button("Open File…", action: openFileAction)
            .buttonStyle(.bordered)
          Spacer()
        }
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: DS.Radius.card + 4, style: .continuous)
          .fill(.ultraThinMaterial)
      )
      .overlay(
        RoundedRectangle(cornerRadius: DS.Radius.card + 4, style: .continuous)
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
      VStack(alignment: .leading, spacing: 2) {  // @todo #I1.5 Replace spacing: 2 with DS token when xxxs (2pt) is added
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
      VStack(spacing: DS.Spacing.xl) {
        Image(systemName: "film")
          .font(.system(size: 48))
          .foregroundColor(.secondary)
        VStack(spacing: DS.Spacing.s) {
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
