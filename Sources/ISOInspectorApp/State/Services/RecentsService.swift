#if canImport(SwiftUI) && canImport(Combine)
  import Combine
  import Foundation
  import ISOInspectorKit

  /// Service responsible for managing recent documents list.
  ///
  /// This service handles:
  /// - Maintaining the list of recently opened documents
  /// - Persisting recent documents to storage
  /// - Adding and removing recent entries
  /// - Enforcing the recent documents limit
  @MainActor
  final class RecentsService: ObservableObject {
    // MARK: - Published Properties

    @Published var recents: [DocumentRecent]
    @Published private(set) var lastFailedRecent: DocumentRecent?

    // MARK: - Private Properties

    private let recentsStore: DocumentRecentsStoring
    private let recentLimit: Int
    private let diagnostics: any DiagnosticsLogging
    private let bookmarkService: BookmarkService

    // MARK: - Initialization

    init(
      recentsStore: DocumentRecentsStoring,
      recentLimit: Int = 10,
      diagnostics: any DiagnosticsLogging,
      bookmarkService: BookmarkService
    ) {
      self.recentsStore = recentsStore
      self.recentLimit = recentLimit
      self.diagnostics = diagnostics
      self.bookmarkService = bookmarkService

      self.recents = (try? recentsStore.load()) ?? []

      // Migrate recents for bookmark store if needed
      migrateRecentsForBookmarkStore()
    }

    // MARK: - Public Methods

    /// Inserts a recent document at the front of the list.
    func insertRecent(_ recent: DocumentRecent) {
      recents.removeAll { $0.url.standardizedFileURL == recent.url.standardizedFileURL }
      recents.insert(recent, at: 0)
      if recents.count > recentLimit {
        recents = Array(recents.prefix(recentLimit))
      }
      persistRecents()
    }

    /// Removes a recent document by URL.
    func removeRecent(with url: URL) {
      recents.removeAll { $0.url.standardizedFileURL == url.standardizedFileURL }
      persistRecents()
    }

    /// Removes recent documents at the specified offsets.
    func removeRecent(at offsets: IndexSet) -> Bool {
      var didRemove = false
      let urls = offsets.compactMap { index -> URL? in
        guard recents.indices.contains(index) else { return nil }
        didRemove = true
        return recents[index].url
      }
      for url in urls {
        removeRecent(with: url)
      }
      return didRemove || (!offsets.isEmpty && recents.isEmpty)
    }

    /// Updates a recent document with bookmark record information.
    func updateRecent(with record: BookmarkPersistenceStore.Record, for url: URL) {
      let standardized = url.standardizedFileURL
      if let index = recents.firstIndex(where: {
        $0.url.standardizedFileURL == standardized
      }) {
        recents[index] = bookmarkService.applyBookmarkRecord(record, to: recents[index])
      }
    }

    /// Sets the last failed recent document.
    func setLastFailedRecent(_ recent: DocumentRecent?) {
      lastFailedRecent = recent
    }

    /// Returns a display-friendly name for a recent document in error scenarios.
    func failureDisplayName(for recent: DocumentRecent) -> String {
      let trimmed = recent.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
      if !trimmed.isEmpty {
        return trimmed
      }
      let lastComponent = recent.url.lastPathComponent
      return lastComponent.isEmpty ? recent.url.absoluteString : lastComponent
    }

    // MARK: - Private Methods

    private func persistRecents() {
      do {
        let payload = bookmarkService.sanitizeRecentsForPersistence(recents)
        try recentsStore.save(payload)
      } catch {
        let errorDescription = (error as NSError).localizedDescription
        let allRecents =
          recents
          .map { $0.url.standardizedFileURL.path }
          .joined(separator: ", ")
        diagnostics.error(
          "Failed to persist recents: error=\(errorDescription); recentsCount=\(recents.count); "
            + "recentsPaths=[\(allRecents)]"
        )
      }
    }

    private func migrateRecentsForBookmarkStore() {
      guard !recents.isEmpty else { return }
      let migrated = recents.map(bookmarkService.migrateRecentBookmark)
      if migrated != recents {
        recents = migrated
        persistRecents()
      }
    }
  }
#endif
