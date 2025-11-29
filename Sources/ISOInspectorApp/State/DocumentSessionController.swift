#if canImport(SwiftUI) && canImport(Combine)
  import Combine
  import Dispatch
  import Foundation
  import ISOInspectorKit
  import OSLog
  import UniformTypeIdentifiers

  protocol BookmarkPersistenceManaging: Sendable {
    func record(for file: URL) throws -> BookmarkPersistenceStore.Record?
    func record(withID id: UUID) throws -> BookmarkPersistenceStore.Record?
    @discardableResult
    func upsertBookmark(for file: URL, bookmarkData: Data) throws
      -> BookmarkPersistenceStore.Record
    @discardableResult
    func markResolution(for file: URL, state: BookmarkPersistenceStore.Record.ResolutionState) throws
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
      let dependencies = Self.makeDependencies(
        parseTreeStore: parseTreeStore,
        annotations: annotations,
        recentsStore: recentsStore,
        sessionStore: sessionStore,
        pipelineFactory: pipelineFactory,
        readerFactory: readerFactory,
        workQueue: workQueue,
        diagnostics: diagnostics,
        recentLimit: recentLimit,
        bookmarkStore: bookmarkStore,
        filesystemAccess: filesystemAccess,
        bookmarkDataProvider: bookmarkDataProvider,
        validationConfigurationStore: validationConfigurationStore,
        validationPresetLoader: validationPresetLoader
      )

      self.parseTreeStore = dependencies.parseTreeStore
      self.annotations = dependencies.annotations
      self.documentViewModel = dependencies.documentViewModel
      self.issueMetrics = dependencies.parseTreeStore.issueMetrics

      self.recentsService = dependencies.recentsService
      self.sessionPersistenceService = dependencies.sessionPersistenceService
      self.validationConfigurationService = dependencies.validationConfigurationService
      self.exportService = dependencies.exportService
      self.documentOpeningCoordinator = dependencies.documentOpeningCoordinator

      setupCoordinatorCallbacks()
      setupObservers(
        resolvedAnnotations: dependencies.annotations,
        resolvedParseTreeStore: dependencies.parseTreeStore)
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

  }

  extension DocumentSessionController {

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

    // MARK: - Dependency Builders

    private struct SessionDependencies {
      let parseTreeStore: ParseTreeStore
      let annotations: AnnotationBookmarkSession
      let documentViewModel: DocumentViewModel
      let recentsService: RecentsService
      let sessionPersistenceService: SessionPersistenceService
      let validationConfigurationService: ValidationConfigurationService
      let exportService: ExportService
      let documentOpeningCoordinator: DocumentOpeningCoordinator
      let diagnostics: any DiagnosticsLogging
    }

    private struct ResolvedContext {
      let parseTreeStore: ParseTreeStore
      let annotations: AnnotationBookmarkSession
      let diagnostics: any DiagnosticsLogging
    }

    // Dependency wiring is centralized here to keep the initializer lean.
    // swiftlint:disable:next function_body_length
    private static func makeDependencies(
      parseTreeStore: ParseTreeStore?,
      annotations: AnnotationBookmarkSession?,
      recentsStore: DocumentRecentsStoring,
      sessionStore: WorkspaceSessionStoring?,
      pipelineFactory: @escaping @Sendable () -> ParsePipeline,
      readerFactory: @escaping @Sendable (URL) throws -> RandomAccessReader,
      workQueue: DocumentSessionWorkQueue,
      diagnostics: (any DiagnosticsLogging)?,
      recentLimit: Int,
      bookmarkStore: BookmarkPersistenceManaging?,
      filesystemAccess: FilesystemAccess,
      bookmarkDataProvider: ((SecurityScopedURL) -> Data?)?,
      validationConfigurationStore: ValidationConfigurationPersisting?,
      validationPresetLoader: (() throws -> [ValidationPreset])?
    ) -> SessionDependencies {
      let context = resolveContext(
        parseTreeStore: parseTreeStore,
        annotations: annotations,
        diagnostics: diagnostics
      )

      let bookmarkService = makeBookmarkService(
        context: context,
        bookmarkStore: bookmarkStore,
        filesystemAccess: filesystemAccess,
        bookmarkDataProvider: bookmarkDataProvider
      )

      let recentsService = makeRecentsService(
        context: context,
        bookmarkService: bookmarkService,
        recentsStore: recentsStore,
        recentLimit: recentLimit
      )

      let parseCoordinationService = makeParseCoordinationService(
        pipelineFactory: pipelineFactory,
        readerFactory: readerFactory,
        workQueue: workQueue
      )

      let sessionPersistenceService = makeSessionPersistenceService(
        context: context,
        bookmarkService: bookmarkService,
        sessionStore: sessionStore
      )

      let validationConfigurationService = makeValidationConfigurationService(
        context: context,
        validationConfigurationStore: validationConfigurationStore,
        validationPresetLoader: validationPresetLoader
      )

      let exportService = makeExportService(
        context: context,
        bookmarkService: bookmarkService,
        validationConfigurationService: validationConfigurationService
      )

      let documentOpeningCoordinator = makeDocumentOpeningCoordinator(
        bookmarkService: bookmarkService,
        parseCoordinationService: parseCoordinationService,
        sessionPersistenceService: sessionPersistenceService,
        validationConfigurationService: validationConfigurationService,
        recentsService: recentsService,
        parseTreeStore: context.parseTreeStore,
        annotations: context.annotations
      )

      let documentViewModel = DocumentViewModel(
        store: context.parseTreeStore, annotations: context.annotations)

      return SessionDependencies(
        parseTreeStore: context.parseTreeStore,
        annotations: context.annotations,
        documentViewModel: documentViewModel,
        recentsService: recentsService,
        sessionPersistenceService: sessionPersistenceService,
        validationConfigurationService: validationConfigurationService,
        exportService: exportService,
        documentOpeningCoordinator: documentOpeningCoordinator,
        diagnostics: context.diagnostics
      )
    }

    private static func resolveContext(
      parseTreeStore: ParseTreeStore?,
      annotations: AnnotationBookmarkSession?,
      diagnostics: (any DiagnosticsLogging)?
    ) -> ResolvedContext {
      let resolvedParseTreeStore = parseTreeStore ?? ParseTreeStore()
      let resolvedAnnotations = annotations ?? AnnotationBookmarkSession(store: nil)
      let resolvedDiagnostics =
        diagnostics
        ?? DiagnosticsLogger(subsystem: "ISOInspectorApp", category: "DocumentSessionPersistence")

      return ResolvedContext(
        parseTreeStore: resolvedParseTreeStore,
        annotations: resolvedAnnotations,
        diagnostics: resolvedDiagnostics
      )
    }

    private static func makeBookmarkService(
      context: ResolvedContext,
      bookmarkStore: BookmarkPersistenceManaging?,
      filesystemAccess: FilesystemAccess,
      bookmarkDataProvider: ((SecurityScopedURL) -> Data?)?
    ) -> BookmarkService {
      BookmarkService(
        bookmarkStore: bookmarkStore,
        filesystemAccess: filesystemAccess,
        bookmarkDataProvider: bookmarkDataProvider
      )
    }

    private static func makeRecentsService(
      context: ResolvedContext,
      bookmarkService: BookmarkService,
      recentsStore: DocumentRecentsStoring,
      recentLimit: Int
    ) -> RecentsService {
      RecentsService(
        recentsStore: recentsStore,
        recentLimit: recentLimit,
        diagnostics: context.diagnostics,
        bookmarkService: bookmarkService
      )
    }

    private static func makeParseCoordinationService(
      pipelineFactory: @escaping @Sendable () -> ParsePipeline,
      readerFactory: @escaping @Sendable (URL) throws -> RandomAccessReader,
      workQueue: DocumentSessionWorkQueue
    ) -> ParseCoordinationService {
      ParseCoordinationService(
        pipelineFactory: pipelineFactory,
        readerFactory: readerFactory,
        workQueue: workQueue
      )
    }

    private static func makeSessionPersistenceService(
      context: ResolvedContext,
      bookmarkService: BookmarkService,
      sessionStore: WorkspaceSessionStoring?
    ) -> SessionPersistenceService {
      SessionPersistenceService(
        sessionStore: sessionStore,
        diagnostics: context.diagnostics,
        bookmarkService: bookmarkService
      )
    }

    private static func makeValidationConfigurationService(
      context: ResolvedContext,
      validationConfigurationStore: ValidationConfigurationPersisting?,
      validationPresetLoader: (() throws -> [ValidationPreset])?
    ) -> ValidationConfigurationService {
      ValidationConfigurationService(
        validationConfigurationStore: validationConfigurationStore,
        validationPresetLoader: validationPresetLoader,
        diagnostics: context.diagnostics
      )
    }

    private static func makeExportService(
      context: ResolvedContext,
      bookmarkService: BookmarkService,
      validationConfigurationService: ValidationConfigurationService
    ) -> ExportService {
      ExportService(
        parseTreeStore: context.parseTreeStore,
        bookmarkService: bookmarkService,
        validationConfigurationService: validationConfigurationService,
        diagnostics: context.diagnostics
      )
    }

    private static func makeDocumentOpeningCoordinator(
      bookmarkService: BookmarkService,
      parseCoordinationService: ParseCoordinationService,
      sessionPersistenceService: SessionPersistenceService,
      validationConfigurationService: ValidationConfigurationService,
      recentsService: RecentsService,
      parseTreeStore: ParseTreeStore,
      annotations: AnnotationBookmarkSession
    ) -> DocumentOpeningCoordinator {
      DocumentOpeningCoordinator(
        bookmarkService: bookmarkService,
        parseCoordinationService: parseCoordinationService,
        sessionPersistenceService: sessionPersistenceService,
        validationConfigurationService: validationConfigurationService,
        recentsService: recentsService,
        parseTreeStore: parseTreeStore,
        annotations: annotations
      )
    }

    // MARK: - Type Aliases

    // Typealiases for backward compatibility with types moved to services
    typealias ExportStatus = ExportService.ExportStatus
    typealias ExportScope = ExportService.ExportScope
    typealias DocumentLoadFailure = DocumentOpeningCoordinator.DocumentLoadFailure
    typealias ValidationConfigurationScope = ValidationConfigurationService.ValidationConfigurationScope
  }

  // MARK: - Supporting Types

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
