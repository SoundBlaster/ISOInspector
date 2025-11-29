#if canImport(SwiftUI) && canImport(Combine)
  import Foundation
  import ISOInspectorKit

  /// Service responsible for persisting and restoring workspace sessions.
  ///
  /// This service handles:
  /// - Session snapshot creation and storage
  /// - Session restoration on startup
  /// - File ID tracking across sessions
  /// - Bookmark diff tracking for session files
  @MainActor
  final class SessionPersistenceService {
    // MARK: - Properties

    private let sessionStore: WorkspaceSessionStoring?
    private let diagnostics: any DiagnosticsLogging
    private let bookmarkService: BookmarkService

    private(set) var currentSessionID: UUID?
    private(set) var currentSessionCreatedAt: Date?
    private(set) var sessionFileIDs: [String: UUID] = [:]
    private(set) var sessionBookmarkDiffs: [String: [WorkspaceSessionBookmarkDiff]] = [:]
    private(set) var isRestoringSession = false
    private(set) var pendingSessionSnapshot: WorkspaceSessionSnapshot?

    // MARK: - Initialization

    init(
      sessionStore: WorkspaceSessionStoring?,
      diagnostics: any DiagnosticsLogging,
      bookmarkService: BookmarkService
    ) {
      self.sessionStore = sessionStore
      self.diagnostics = diagnostics
      self.bookmarkService = bookmarkService
    }

    // MARK: - Public Methods

    /// Loads the current session snapshot if available.
    func loadCurrentSession() -> WorkspaceSessionSnapshot? {
      guard let sessionStore else { return nil }
      do {
        let snapshot = try sessionStore.loadCurrentSession()
        currentSessionID = snapshot?.id
        currentSessionCreatedAt = snapshot?.createdAt
        return snapshot
      } catch {
        diagnostics.error("Failed to load current session: \(error)")
        return nil
      }
    }

    /// Applies a session snapshot, updating internal state.
    func applySessionSnapshot(_ snapshot: WorkspaceSessionSnapshot) {
      let sortedFiles = snapshot.files.sorted { lhs, rhs in
        if lhs.orderIndex == rhs.orderIndex {
          return lhs.id.uuidString < rhs.id.uuidString
        }
        return lhs.orderIndex < rhs.orderIndex
      }

      sessionFileIDs = Dictionary(
        uniqueKeysWithValues: sortedFiles.map { file in
          (canonicalIdentifier(for: file.recent.url), file.id)
        })

      sessionBookmarkDiffs = Dictionary(
        uniqueKeysWithValues: sortedFiles.map { file in
          (canonicalIdentifier(for: file.recent.url), file.bookmarkDiffs)
        })

      pendingSessionSnapshot = snapshot
    }

    /// Consumes and returns the pending session snapshot for restoration.
    func consumePendingSessionSnapshot() -> WorkspaceSessionSnapshot? {
      let snapshot = pendingSessionSnapshot
      pendingSessionSnapshot = nil
      return snapshot
    }

    /// Sets the restoration flag.
    func setIsRestoringSession(_ value: Bool) {
      isRestoringSession = value
    }

    /// Persists the current session with the provided recents and annotations.
    func persistSession(
      recents: [DocumentRecent],
      currentDocument: DocumentRecent?,
      annotationsFileURL: URL?,
      latestSelectionNodeID: Int64?,
      sessionValidationConfigurations: [String: ValidationConfiguration]
    ) {
      guard let sessionStore else { return }

      if recents.isEmpty {
        clearSession()
        return
      }

      let now = Date()
      let sessionID = ensureSessionIdentifiers(now: now)

      let (snapshots, nextDiffs) = buildSessionSnapshots(
        recents: recents,
        annotationsFileURL: annotationsFileURL,
        latestSelectionNodeID: latestSelectionNodeID,
        sessionValidationConfigurations: sessionValidationConfigurations
      )
      sessionBookmarkDiffs = nextDiffs

      let snapshot = WorkspaceSessionSnapshot(
        id: sessionID,
        createdAt: currentSessionCreatedAt ?? now,
        updatedAt: now,
        appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
        files: snapshots,
        focusedFileURL: currentDocument?.url,
        lastSceneIdentifier: nil,
        windowLayouts: []
      )

      save(snapshot: snapshot, using: sessionStore)
    }

    private func buildSessionSnapshots(
      recents: [DocumentRecent],
      annotationsFileURL: URL?,
      latestSelectionNodeID: Int64?,
      sessionValidationConfigurations: [String: ValidationConfiguration]
    ) -> ([WorkspaceSessionFileSnapshot], [String: [WorkspaceSessionBookmarkDiff]]) {
      var snapshots: [WorkspaceSessionFileSnapshot] = []
      snapshots.reserveCapacity(recents.count)
      var nextDiffs: [String: [WorkspaceSessionBookmarkDiff]] = [:]

      for (index, recent) in recents.enumerated() {
        let canonical = canonicalIdentifier(for: recent.url)
        let fileID = sessionFileIDs[canonical] ?? UUID()
        sessionFileIDs[canonical] = fileID

        let selection = selectionNodeID(
          for: recent.url,
          annotationsFileURL: annotationsFileURL,
          latestSelectionNodeID: latestSelectionNodeID
        )

        let persistedRecent = bookmarkService.sanitizeRecentsForPersistence([recent]).first ?? recent
        let diffs = sessionBookmarkDiffs[canonical] ?? []
        nextDiffs[canonical] = diffs

        let overrideConfiguration = sessionValidationConfigurations[canonical]

        snapshots.append(
          WorkspaceSessionFileSnapshot(
            id: fileID,
            recent: persistedRecent,
            orderIndex: index,
            lastSelectionNodeID: selection,
            isPinned: false,
            scrollOffset: nil,
            bookmarkIdentifier: recent.bookmarkIdentifier,
            bookmarkDiffs: diffs,
            validationConfiguration: overrideConfiguration
          )
        )
      }

      return (snapshots, nextDiffs)
    }

    private func ensureSessionIdentifiers(now: Date) -> UUID {
      if currentSessionCreatedAt == nil {
        currentSessionCreatedAt = now
      }
      let sessionID = currentSessionID ?? UUID()
      currentSessionID = sessionID
      return sessionID
    }

    private func save(snapshot: WorkspaceSessionSnapshot, using sessionStore: WorkspaceSessionStoring) {
      do {
        try sessionStore.saveCurrentSession(snapshot)
      } catch {
        let errorDescription = (error as NSError).localizedDescription
        diagnostics.error(
          "Failed to persist session snapshot: error=\(errorDescription); "
            + "sessionID=\(snapshot.id.uuidString); focusedPath=\(snapshot.focusedFileURL?.standardizedFileURL.path ?? "none")"
        )
      }
    }

    private func selectionNodeID(
      for recentURL: URL,
      annotationsFileURL: URL?,
      latestSelectionNodeID: Int64?
    ) -> Int64? {
      guard
        let currentURL = annotationsFileURL,
        currentURL.standardizedFileURL == recentURL.standardizedFileURL
      else {
        return nil
      }

      return latestSelectionNodeID
    }

    /// Clears the current session.
    func clearSession() {
      guard let sessionStore else { return }
      do {
        try sessionStore.clearCurrentSession()
        currentSessionID = nil
        currentSessionCreatedAt = nil
        sessionFileIDs.removeAll()
        sessionBookmarkDiffs.removeAll()
      } catch {
        let errorDescription = (error as NSError).localizedDescription
        diagnostics.error(
          "Failed to clear persisted session: error=\(errorDescription); "
            + "sessionID=\(currentSessionID?.uuidString ?? "none")"
        )
      }
    }

    // MARK: - Private Methods

    private func canonicalIdentifier(for url: URL) -> String {
      url.standardizedFileURL.resolvingSymlinksInPath().absoluteString
    }
  }
#endif
