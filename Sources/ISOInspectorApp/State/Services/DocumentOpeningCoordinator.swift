#if canImport(SwiftUI) && canImport(Combine)
  import Foundation
  import ISOInspectorKit
  import OSLog

  /// Coordinator responsible for orchestrating document opening workflow.
  ///
  /// This service handles:
  /// - Coordinating between bookmark, parse, and session services
  /// - Managing document opening state transitions
  /// - Session restoration workflow
  /// - Error handling and recovery
  // swiftlint:disable:next type_body_length
  @MainActor
  final class DocumentOpeningCoordinator {
    // MARK: - Properties

    private let bookmarkService: BookmarkService
    private let parseCoordinationService: ParseCoordinationService
    private let sessionPersistenceService: SessionPersistenceService
    private let validationConfigurationService: ValidationConfigurationService
    private let recentsService: RecentsService
    private let parseTreeStore: ParseTreeStore
    private let annotations: AnnotationBookmarkSession
    private let logger = Logger(subsystem: "ISOInspectorApp", category: "DocumentSession")

    private var latestSelectionNodeID: Int64?

    // MARK: - Callbacks

    var onSessionStarted: ((DocumentRecent) -> Void)?
    var onLoadFailure: ((DocumentLoadFailure, DocumentRecent?) -> Void)?

    // MARK: - Initialization

    init(
      bookmarkService: BookmarkService,
      parseCoordinationService: ParseCoordinationService,
      sessionPersistenceService: SessionPersistenceService,
      validationConfigurationService: ValidationConfigurationService,
      recentsService: RecentsService,
      parseTreeStore: ParseTreeStore,
      annotations: AnnotationBookmarkSession
    ) {
      self.bookmarkService = bookmarkService
      self.parseCoordinationService = parseCoordinationService
      self.sessionPersistenceService = sessionPersistenceService
      self.validationConfigurationService = validationConfigurationService
      self.recentsService = recentsService
      self.parseTreeStore = parseTreeStore
      self.annotations = annotations
    }

    // MARK: - Public Methods

    func setLatestSelectionNodeID(_ nodeID: Int64?) {
      latestSelectionNodeID = nodeID
    }

    func openDocument(
      recent: DocumentRecent,
      restoredSelection: Int64? = nil,
      preResolvedScope: SecurityScopedURL? = nil,
      failureRecent: DocumentRecent? = nil
    ) {
      do {
        let accessContext = try bookmarkService.prepareAccess(
          for: recent,
          preResolvedScope: preResolvedScope
        )

        parseCoordinationService.openDocument(
          accessContext: accessContext,
          failureRecent: failureRecent,
          onSuccess: {
            [weak self] scopedURL, bookmark, bookmarkRecord, reader, pipeline, recent,
            restoredSelection in
            self?.startSession(
              scopedURL: scopedURL,
              bookmark: bookmark,
              bookmarkRecord: bookmarkRecord,
              reader: reader,
              pipeline: pipeline,
              recent: recent,
              restoredSelection: restoredSelection
            )
          },
          onFailure: { [weak self] recent, error in
            if let accessError = error as? DocumentAccessError {
              self?.handleRecentAccessFailure(recent, error: accessError)
            } else {
              self?.emitLoadFailure(for: recent, error: error, failedRecent: nil)
            }
          },
          restoredSelection: restoredSelection,
          preResolvedScope: preResolvedScope
        )
      } catch let accessError as DocumentAccessError {
        preResolvedScope?.revoke()
        let targetRecent = failureRecent ?? recent
        handleRecentAccessFailure(targetRecent, error: accessError)
      } catch {
        preResolvedScope?.revoke()
        let targetRecent = failureRecent ?? recent
        emitLoadFailure(for: targetRecent, error: error, failedRecent: nil)
      }
    }

    func applySessionSnapshot(_ snapshot: WorkspaceSessionSnapshot) -> (
      [DocumentRecent], DocumentRecent?
    ) {
      let sortedFiles = snapshot.files.sorted { lhs, rhs in
        if lhs.orderIndex == rhs.orderIndex {
          return lhs.id.uuidString < rhs.id.uuidString
        }
        return lhs.orderIndex < rhs.orderIndex
      }

      guard !sortedFiles.isEmpty else {
        return ([], nil)
      }

      let loadedRecents = sortedFiles.map(\.recent)
      let migratedRecents = loadedRecents.map(bookmarkService.migrateRecentBookmark)

      let focusURL = snapshot.focusedFileURL?.standardizedFileURL
      let currentDocument: DocumentRecent?
      if let focusURL,
        let focusedIndex = migratedRecents.firstIndex(where: {
          $0.url.standardizedFileURL == focusURL
        })
      {
        currentDocument = migratedRecents[focusedIndex]
      } else {
        currentDocument = migratedRecents.first
      }

      return (migratedRecents, currentDocument)
    }

    func restoreSession(_ snapshot: WorkspaceSessionSnapshot) {
      let sortedFiles = snapshot.files.sorted { lhs, rhs in
        if lhs.orderIndex == rhs.orderIndex {
          return lhs.id.uuidString < rhs.id.uuidString
        }
        return lhs.orderIndex < rhs.orderIndex
      }
      guard !sortedFiles.isEmpty else { return }

      let focusURL =
        snapshot.focusedFileURL?.standardizedFileURL
        ?? sortedFiles.first?.recent.url.standardizedFileURL
      guard let focusURL,
        let focused = sortedFiles.first(where: {
          $0.recent.url.standardizedFileURL == focusURL
        })
      else {
        return
      }

      sessionPersistenceService.setIsRestoringSession(true)
      openDocument(
        recent: focused.recent,
        restoredSelection: focused.lastSelectionNodeID,
        preResolvedScope: nil,
        failureRecent: focused.recent
      )
    }

    // MARK: - Private Methods

    private func startSession(
      scopedURL: SecurityScopedURL,
      bookmark: Data?,
      bookmarkRecord: BookmarkPersistenceStore.Record?,
      reader: RandomAccessReader,
      pipeline: ParsePipeline,
      recent: DocumentRecent,
      restoredSelection: Int64?
    ) {
      bookmarkService.setActiveSecurityScopedURL(scopedURL)
      let standardizedURL = scopedURL.url
      validationConfigurationService.updateActiveValidationConfiguration(for: recent)

      parseTreeStore.start(
        pipeline: pipeline,
        reader: reader,
        context: .init(source: standardizedURL)
      )
      annotations.setFileURL(standardizedURL)
      latestSelectionNodeID = restoredSelection
      if let restoredSelection {
        annotations.setSelectedNode(restoredSelection)
      } else {
        annotations.setSelectedNode(nil)
      }

      var updatedRecent = recent
      if let bookmarkRecord {
        updatedRecent = bookmarkService.applyBookmarkRecord(bookmarkRecord, to: updatedRecent)
      } else {
        updatedRecent.bookmarkData = bookmark ?? recent.bookmarkData
      }
      updatedRecent.lastOpened = Date()
      updatedRecent.displayName =
        updatedRecent.displayName.isEmpty
        ? standardizedURL.lastPathComponent : updatedRecent.displayName

      recentsService.setLastFailedRecent(nil)
      recentsService.insertRecent(updatedRecent)
      sessionPersistenceService.setIsRestoringSession(false)

      onSessionStarted?(updatedRecent)
    }

    private func handleRecentAccessFailure(_ recent: DocumentRecent, error: DocumentAccessError) {
      recentsService.removeRecent(with: recent.url)
      emitLoadFailure(for: recent, error: error, failedRecent: recent)
    }

    private func emitLoadFailure(
      for recent: DocumentRecent, error: Error?, failedRecent: DocumentRecent?
    ) {
      var standardizedRecent = recent
      standardizedRecent.url = recent.url.standardizedFileURL
      let displayName = recentsService.failureDisplayName(for: standardizedRecent)
      let defaultSuggestion =
        "Verify that the file exists and you have permission to read it, then try again."

      var message = "ISO Inspector couldn't open \"\(displayName)\"."
      var suggestion = defaultSuggestion
      var details: String?

      if let localizedError = error as? LocalizedError {
        if let description = localizedError.errorDescription?.trimmingCharacters(
          in: .whitespacesAndNewlines), !description.isEmpty
        {
          message = description
        }
        if let recovery = localizedError.recoverySuggestion?.trimmingCharacters(
          in: .whitespacesAndNewlines), !recovery.isEmpty
        {
          suggestion = recovery
        }
        if let reason = localizedError.failureReason?.trimmingCharacters(
          in: .whitespacesAndNewlines), !reason.isEmpty
        {
          details = reason
        }
      } else if let error {
        let localized = error.localizedDescription.trimmingCharacters(
          in: .whitespacesAndNewlines)
        if !localized.isEmpty {
          message = localized
        }
      }

      if let error {
        logger.error(
          "Document open failed for \(standardizedRecent.url.path, privacy: .public): \(String(describing: error), privacy: .public)"
        )
      } else {
        logger.error(
          "Document open failed for \(standardizedRecent.url.path, privacy: .public): no additional error details available"
        )
      }

      let loadFailure = DocumentLoadFailure(
        fileURL: standardizedRecent.url,
        fileDisplayName: displayName,
        message: message,
        recoverySuggestion: suggestion,
        details: details
      )

      recentsService.setLastFailedRecent(standardizedRecent)
      onLoadFailure?(loadFailure, failedRecent)
    }

    // MARK: - Nested Types

    struct DocumentLoadFailure: Identifiable, Equatable {
      let id: UUID
      let fileURL: URL
      let fileDisplayName: String
      let message: String
      let recoverySuggestion: String
      let details: String?

      init(
        id: UUID = UUID(),
        fileURL: URL,
        fileDisplayName: String,
        message: String,
        recoverySuggestion: String,
        details: String?
      ) {
        self.id = id
        self.fileURL = fileURL
        self.fileDisplayName = fileDisplayName
        self.message = message
        self.recoverySuggestion = recoverySuggestion
        self.details = details
      }

      var title: String {
        "Unable to open \"\(fileDisplayName)\""
      }
    }
  }

  // MARK: - Supporting Types

  enum DocumentAccessError: LocalizedError {
    case unreadable(URL)
    case unresolvedBookmark

    var errorDescription: String? {
      switch self {
      case .unreadable(let url):
        return "ISO Inspector couldn't access the file at \(url.path)."
      case .unresolvedBookmark:
        return "ISO Inspector couldn't resolve the saved bookmark for this file."
      }
    }

    var failureReason: String? {
      switch self {
      case .unreadable(let url):
        return
          "The file may have been moved, deleted, or you may not have permission to read it. (\(url.path))"
      case .unresolvedBookmark:
        return "The security-scoped bookmark is no longer valid."
      }
    }

    var recoverySuggestion: String? {
      "Verify that the file exists and you have permission to read it, then try opening it again."
    }
  }
#endif
