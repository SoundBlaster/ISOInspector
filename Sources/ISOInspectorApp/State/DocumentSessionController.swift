#if canImport(SwiftUI) && canImport(Combine)
  import Combine
  import Dispatch
  import Foundation
  import ISOInspectorKit
  import OSLog
  import UniformTypeIdentifiers

  typealias BookmarkResolutionState = BookmarkPersistenceStore.Record.ResolutionState

  protocol BookmarkPersistenceManaging: Sendable {
    func record(for file: URL) throws -> BookmarkPersistenceStore.Record?
    func record(withID id: UUID) throws -> BookmarkPersistenceStore.Record?
    @discardableResult
    func upsertBookmark(for file: URL, bookmarkData: Data) throws
      -> BookmarkPersistenceStore.Record
    @discardableResult
    func markResolution(for file: URL, state: BookmarkResolutionState) throws
      -> BookmarkPersistenceStore.Record?
    func removeBookmark(for file: URL) throws
  }

  extension BookmarkPersistenceStore: BookmarkPersistenceManaging {}

  @MainActor
  final class DocumentSessionController: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var currentDocument: DocumentRecent? {
      didSet { exportService.setCurrentDocument(currentDocument) }
    }
    @Published private(set) var loadFailure: DocumentLoadFailure?
    @Published private(set) var exportStatus: ExportStatus?
    @Published private(set) var issueMetrics: ParseIssueStore.IssueMetrics

    // MARK: - Public Properties

    let parseTreeStore: ParseTreeStore
    let annotations: AnnotationBookmarkSession
    let documentViewModel: DocumentViewModel

    // MARK: - Services

    private let recentsService: RecentsService
    private let sessionPersistenceService: SessionPersistenceService
    private let validationConfigurationService: ValidationConfigurationService
    private let exportService: ExportService
    private let documentOpeningCoordinator: DocumentOpeningCoordinator

    // MARK: - Private Properties

    private var annotationsSelectionCancellable: AnyCancellable?
    private var issueMetricsCancellable: AnyCancellable?
    private var latestSelectionNodeID: Int64?

    // MARK: - Passthrough Properties

    var recents: [DocumentRecent] { recentsService.recents }
    var validationConfiguration: ValidationConfiguration {
      validationConfigurationService.validationConfiguration
    }
    var globalValidationConfiguration: ValidationConfiguration {
      validationConfigurationService.globalValidationConfiguration
    }
    var validationPresets: [ValidationPreset] { validationConfigurationService.validationPresets }
    var isUsingWorkspaceValidationOverride: Bool {
      validationConfigurationService.isUsingWorkspaceValidationOverride
    }
    var canExportDocument: Bool { exportService.canExportDocument }
    var allowedContentTypes: [UTType] { [.mpeg4Movie, .quickTimeMovie] }

    // MARK: - Initialization

    init(
      parseTreeStore: ParseTreeStore? = nil,
      annotations: AnnotationBookmarkSession? = nil,
      recentsStore: DocumentRecentsStoring,
      sessionStore: WorkspaceSessionStoring? = nil,
      pipelineFactory: @escaping @Sendable () -> ParsePipeline = { .live(options: .tolerant) },
      readerFactory: @escaping @Sendable (URL) throws -> RandomAccessReader = {
        try ChunkedFileReader(fileURL: $0)
      },
      workQueue: DocumentSessionWorkQueue = DocumentSessionBackgroundQueue(),
      diagnostics: (any DiagnosticsLogging)? = nil,
      recentLimit: Int = 10,
      bookmarkStore: BookmarkPersistenceManaging? = nil,
      filesystemAccess: FilesystemAccess = .live(),
      bookmarkDataProvider: ((SecurityScopedURL) -> Data?)? = nil,
      validationConfigurationStore: ValidationConfigurationPersisting? = nil,
      validationPresetLoader: (() throws -> [ValidationPreset])? = nil
    ) {
      let resolvedParseTreeStore = parseTreeStore ?? ParseTreeStore()
      let resolvedAnnotations = annotations ?? AnnotationBookmarkSession(store: nil)
      let resolvedDiagnostics =
        diagnostics
        ?? DiagnosticsLogger(subsystem: "ISOInspectorApp", category: "DocumentSessionPersistence")

      self.parseTreeStore = resolvedParseTreeStore
      self.annotations = resolvedAnnotations
      self.documentViewModel = DocumentViewModel(
        store: resolvedParseTreeStore, annotations: resolvedAnnotations)
      self.issueMetrics = resolvedParseTreeStore.issueMetrics

      // Initialize services
      let bookmarkService = BookmarkService(
        bookmarkStore: bookmarkStore,
        filesystemAccess: filesystemAccess,
        bookmarkDataProvider: bookmarkDataProvider
      )

      self.recentsService = RecentsService(
        recentsStore: recentsStore,
        recentLimit: recentLimit,
        diagnostics: resolvedDiagnostics,
        bookmarkService: bookmarkService
      )

      let parseCoordinationService = ParseCoordinationService(
        pipelineFactory: pipelineFactory,
        readerFactory: readerFactory,
        workQueue: workQueue
      )

      self.sessionPersistenceService = SessionPersistenceService(
        sessionStore: sessionStore,
        diagnostics: resolvedDiagnostics,
        bookmarkService: bookmarkService
      )

      self.validationConfigurationService = ValidationConfigurationService(
        validationConfigurationStore: validationConfigurationStore,
        validationPresetLoader: validationPresetLoader,
        diagnostics: resolvedDiagnostics
      )

      self.exportService = ExportService(
        parseTreeStore: resolvedParseTreeStore,
        bookmarkService: bookmarkService,
        validationConfigurationService: self.validationConfigurationService,
        diagnostics: resolvedDiagnostics
      )

      self.documentOpeningCoordinator = DocumentOpeningCoordinator(
        bookmarkService: bookmarkService,
        parseCoordinationService: parseCoordinationService,
        sessionPersistenceService: self.sessionPersistenceService,
        validationConfigurationService: self.validationConfigurationService,
        recentsService: self.recentsService,
        parseTreeStore: resolvedParseTreeStore,
        annotations: resolvedAnnotations
      )

      setupCoordinatorCallbacks()
      setupObservers(
        resolvedAnnotations: resolvedAnnotations, resolvedParseTreeStore: resolvedParseTreeStore)
      applyValidationConfigurationFilter()
      restoreSessionIfNeeded()
    }

    // MARK: - Setup

    private func setupCoordinatorCallbacks() {
      documentOpeningCoordinator.onSessionStarted = { [weak self] recent in
        guard let self else { return }
        self.loadFailure = nil
        self.currentDocument = recent
        self.persistSession()
      }

      documentOpeningCoordinator.onLoadFailure = { [weak self] failure, _ in
        self?.loadFailure = failure
      }
    }

    private func setupObservers(
      resolvedAnnotations: AnnotationBookmarkSession, resolvedParseTreeStore: ParseTreeStore
    ) {
      latestSelectionNodeID = resolvedAnnotations.currentSelectedNodeID
      annotationsSelectionCancellable = resolvedAnnotations.$currentSelectedNodeID
        .dropFirst()
        .sink { [weak self] value in
          guard let self else { return }
          self.latestSelectionNodeID = value
          self.documentOpeningCoordinator.setLatestSelectionNodeID(value)
          guard !self.recents.isEmpty, !self.sessionPersistenceService.isRestoringSession else {
            return
          }
          self.persistSession()
        }

      issueMetricsCancellable = resolvedParseTreeStore.$issueMetrics
        .receive(on: DispatchQueue.main)
        .sink { [weak self] metrics in
          self?.issueMetrics = metrics
        }
    }

    private func restoreSessionIfNeeded() {
      guard let snapshot = sessionPersistenceService.loadCurrentSession() else { return }
      sessionPersistenceService.applySessionSnapshot(snapshot)
      validationConfigurationService.loadSessionConfigurations(snapshot)

      let (migratedRecents, document) = documentOpeningCoordinator.applySessionSnapshot(snapshot)
      recentsService.recents = migratedRecents
      currentDocument = document

      if let pendingSnapshot = sessionPersistenceService.consumePendingSessionSnapshot() {
        documentOpeningCoordinator.restoreSession(pendingSnapshot)
      }
    }

    // MARK: - Public Methods

    func openDocument(at url: URL) {
      let standardized = url.standardizedFileURL
      let baseRecent = DocumentRecent(
        url: standardized,
        bookmarkData: nil,
        displayName: url.lastPathComponent,
        lastOpened: Date()
      )
      documentOpeningCoordinator.openDocument(recent: baseRecent)
    }

    func openRecent(_ recent: DocumentRecent) {
      documentOpeningCoordinator.openDocument(
        recent: recent, restoredSelection: nil, preResolvedScope: nil, failureRecent: recent)
    }

    func removeRecent(at offsets: IndexSet) {
      if recentsService.removeRecent(at: offsets) {
        persistSession()
      }
    }

    func dismissLoadFailure() {
      loadFailure = nil
      recentsService.setLastFailedRecent(nil)
    }

    func retryLastFailure() {
      guard let recent = recentsService.lastFailedRecent else { return }
      documentOpeningCoordinator.openDocument(recent: recent)
    }

    func dismissExportStatus() {
      exportStatus = nil
    }

    func focusIntegrityDiagnostics() {
      if let nodeID = parseTreeStore.issueStore.issues.first?.affectedNodeIDs.first {
        documentViewModel.nodeViewModel.select(nodeID: nodeID)
      }
    }

    func selectValidationPreset(_ presetID: String, scope: ValidationConfigurationScope) {
      validationConfigurationService.selectValidationPreset(presetID, scope: scope)
      applyValidationConfigurationFilter()
      if validationConfigurationService.didUpdateWorkspaceConfiguration() {
        persistSession()
      }
    }

    func setValidationRule(
      _ rule: ValidationRuleIdentifier,
      isEnabled: Bool,
      scope: ValidationConfigurationScope
    ) {
      validationConfigurationService.setValidationRule(rule, isEnabled: isEnabled, scope: scope)
      applyValidationConfigurationFilter()
      if validationConfigurationService.didUpdateWorkspaceConfiguration() {
        persistSession()
      }
    }

    func resetWorkspaceValidationOverrides() {
      validationConfigurationService.resetWorkspaceValidationOverrides()
      applyValidationConfigurationFilter()
      persistSession()
    }

    func exportJSON(scope: ExportScope) async {
      await exportService.exportJSON(
        scope: scope,
        onSuccess: { [weak self] status in self?.exportStatus = status },
        onFailure: { [weak self] status in self?.exportStatus = status }
      )
    }

    func exportIssueSummary(scope: ExportScope) async {
      await exportService.exportIssueSummary(
        scope: scope,
        onSuccess: { [weak self] status in self?.exportStatus = status },
        onFailure: { [weak self] status in self?.exportStatus = status }
      )
    }

    func canExportSelection(nodeID: ParseTreeNode.ID?) -> Bool {
      exportService.canExportSelection(nodeID: nodeID)
    }

    // MARK: - Private Methods

    private func persistSession() {
      sessionPersistenceService.persistSession(
        recents: recents,
        currentDocument: currentDocument,
        annotationsFileURL: annotations.currentFileURL,
        latestSelectionNodeID: latestSelectionNodeID,
        sessionValidationConfigurations: validationConfigurationService
          .sessionConfigurationsForPersistence()
      )
    }

    private func applyValidationConfigurationFilter() {
      let configuration = validationConfiguration
      let presets = validationPresets
      parseTreeStore.setValidationIssueFilter { issue in
        guard let identifier = ValidationRuleIdentifier(rawValue: issue.ruleID) else {
          return true
        }
        return configuration.isRuleEnabled(identifier, presets: presets)
      }
    }
  }

  // MARK: - Supporting Types

  // Typealiases for backward compatibility with types moved to services
  typealias ExportStatus = ExportService.ExportStatus
  typealias ExportScope = ExportService.ExportScope
  typealias DocumentLoadFailure = DocumentOpeningCoordinator.DocumentLoadFailure
  typealias ValidationConfigurationScope = ValidationConfigurationService.ValidationConfigurationScope

  protocol DocumentSessionWorkQueue {
    func execute(_ work: @Sendable @escaping () -> Void)
  }

  struct DocumentSessionBackgroundQueue: DocumentSessionWorkQueue {
    private let queue: DispatchQueue

    init(
      queue: DispatchQueue = DispatchQueue(
        label: "isoinspector.document-session", qos: .userInitiated)
    ) {
      self.queue = queue
    }

    func execute(_ work: @Sendable @escaping () -> Void) {
      queue.async(execute: work)
    }
  }
#endif
