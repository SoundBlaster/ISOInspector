#if canImport(SwiftUI) && canImport(Combine)
  import Foundation
  import ISOInspectorKit

  /// Service responsible for managing security-scoped bookmarks and file access.
  ///
  /// This service handles:
  /// - Security-scoped URL access management
  /// - Bookmark creation and resolution
  /// - Bookmark persistence and migration
  /// - File access preparation for document opening
  @MainActor
  final class BookmarkService {
    // MARK: - Properties

    private let bookmarkStore: BookmarkPersistenceManaging?
    let filesystemAccess: FilesystemAccess
    private let bookmarkDataProvider: (SecurityScopedURL) -> Data?

    private(set) var activeSecurityScopedURL: SecurityScopedURL?

    // MARK: - Initialization

    init(
      bookmarkStore: BookmarkPersistenceManaging?,
      filesystemAccess: FilesystemAccess,
      bookmarkDataProvider: ((SecurityScopedURL) -> Data?)? = nil
    ) {
      self.bookmarkStore = bookmarkStore
      self.filesystemAccess = filesystemAccess
      if let bookmarkDataProvider {
        self.bookmarkDataProvider = bookmarkDataProvider
      } else {
        self.bookmarkDataProvider = { scopedURL in
          try? filesystemAccess.createBookmark(for: scopedURL)
        }
      }
    }

    deinit {
      activeSecurityScopedURL?.revoke()
    }

    // MARK: - Public Methods

    /// Sets the active security-scoped URL, revoking any previous one.
    func setActiveSecurityScopedURL(_ scopedURL: SecurityScopedURL) {
      activeSecurityScopedURL?.revoke()
      activeSecurityScopedURL = scopedURL
    }

    /// Revokes the current security-scoped URL access.
    func revokeActiveAccess() {
      activeSecurityScopedURL?.revoke()
      activeSecurityScopedURL = nil
    }

    /// Creates bookmark data for a security-scoped URL.
    func makeBookmarkData(for scopedURL: SecurityScopedURL) -> Data? {
      bookmarkDataProvider(scopedURL)
    }

    /// Prepares file access for opening a document, resolving bookmarks as needed.
    func prepareAccess(
      for recent: DocumentRecent,
      preResolvedScope: SecurityScopedURL?
    ) throws -> AccessContext {
      if let scope = preResolvedScope {
        return prepareAccessUsingPreResolvedScope(scope, for: recent)
      }
      return try prepareAccessResolvingBookmark(for: recent)
    }

    /// Applies bookmark record data to a recent document.
    func applyBookmarkRecord(
      _ record: BookmarkPersistenceStore.Record,
      to recent: DocumentRecent
    ) -> DocumentRecent {
      var updated = recent
      updated.bookmarkIdentifier = record.id
      updated.bookmarkData = nil
      return updated
    }

    /// Migrates a recent document to use the bookmark store if available.
    func migrateRecentBookmark(_ recent: DocumentRecent) -> DocumentRecent {
      guard let bookmarkStore else { return recent }
      let standardized = recent.url.standardizedFileURL

      if let identifier = recent.bookmarkIdentifier,
        let record = try? bookmarkStore.record(withID: identifier)
      {
        return applyBookmarkRecord(record, to: recent)
      }

      if let record = try? bookmarkStore.record(for: standardized) {
        return applyBookmarkRecord(record, to: recent)
      }

      if let data = recent.bookmarkData,
        let record = try? bookmarkStore.upsertBookmark(for: standardized, bookmarkData: data)
      {
        return applyBookmarkRecord(record, to: recent)
      }

      return recent
    }

    /// Sanitizes recents for persistence, removing bookmark data when bookmark store is used.
    func sanitizeRecentsForPersistence(_ recents: [DocumentRecent]) -> [DocumentRecent] {
      guard bookmarkStore != nil else { return recents }
      return recents.map { recent in
        var sanitized = recent
        if sanitized.bookmarkIdentifier != nil {
          sanitized.bookmarkData = nil
        }
        return sanitized
      }
    }

    // MARK: - Private Methods

    private func prepareAccessUsingPreResolvedScope(
      _ scope: SecurityScopedURL,
      for recent: DocumentRecent
    ) -> AccessContext {
      var preparedRecent = recent
      preparedRecent.url = scope.url
      preparedRecent.displayName =
        preparedRecent.displayName.isEmpty
        ? scope.url.lastPathComponent : preparedRecent.displayName

      var record: BookmarkPersistenceStore.Record?
      var bookmarkData: Data?

      if let bookmarkStore {
        if let identifier = preparedRecent.bookmarkIdentifier,
          let existing = try? bookmarkStore.record(withID: identifier)
        {
          record = existing
        } else if let existing = try? bookmarkStore.record(for: scope.url) {
          record = existing
        } else if let data = makeBookmarkData(for: scope) {
          record = try? bookmarkStore.upsertBookmark(for: scope.url, bookmarkData: data)
        }

        if let record {
          preparedRecent = applyBookmarkRecord(record, to: preparedRecent)
        }
      } else {
        bookmarkData = preparedRecent.bookmarkData ?? makeBookmarkData(for: scope)
        preparedRecent.bookmarkData = bookmarkData
      }

      return AccessContext(
        scopedURL: scope,
        recent: preparedRecent,
        bookmarkRecord: record,
        bookmarkData: bookmarkData
      )
    }

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    private func prepareAccessResolvingBookmark(
      for recent: DocumentRecent
    ) throws -> AccessContext {
      var preparedRecent = recent
      let standardized = recent.url.standardizedFileURL

      var candidateRecord: BookmarkPersistenceStore.Record?
      if let bookmarkStore {
        if let identifier = preparedRecent.bookmarkIdentifier,
          let existing = try? bookmarkStore.record(withID: identifier)
        {
          candidateRecord = existing
        } else if let existing = try? bookmarkStore.record(for: standardized) {
          candidateRecord = existing
        }
      }

      var bookmarkBlob: Data?
      if let candidateRecord {
        bookmarkBlob = candidateRecord.bookmarkData
      } else if let existingData = preparedRecent.bookmarkData {
        bookmarkBlob = existingData
      }

      var resolvedScope: SecurityScopedURL
      var record: BookmarkPersistenceStore.Record? = candidateRecord
      var bookmarkData: Data?

      if let blob = bookmarkBlob {
        do {
          let resolution = try filesystemAccess.resolveBookmarkData(
            blob,
            bookmarkIdentifier: candidateRecord?.id ?? preparedRecent.bookmarkIdentifier
          )
          resolvedScope = resolution.url
          preparedRecent.url = resolution.url.url
          preparedRecent.displayName =
            preparedRecent.displayName.isEmpty
            ? resolution.url.url.lastPathComponent : preparedRecent.displayName

          if let bookmarkStore {
            if resolution.isStale,
              let refreshed = makeBookmarkData(for: resolution.url),
              let updated = try? bookmarkStore.upsertBookmark(
                for: resolution.url.url,
                bookmarkData: refreshed
              )
            {
              record = updated
            }
            let state: BookmarkResolutionState = resolution.isStale ? .stale : .succeeded
            if let updated = try? bookmarkStore.markResolution(
              for: resolution.url.url,
              state: state
            ) {
              record = updated
            }
            if record == nil, !resolution.isStale,
              let refreshed = makeBookmarkData(for: resolution.url)
            {
              record = try? bookmarkStore.upsertBookmark(
                for: resolution.url.url,
                bookmarkData: refreshed
              )
            }
          } else {
            if resolution.isStale {
              bookmarkData = makeBookmarkData(for: resolution.url) ?? blob
            } else {
              bookmarkData = blob
            }
          }
        } catch {
          if let bookmarkStore {
            _ = try? bookmarkStore.markResolution(for: standardized, state: .failed)
            try? bookmarkStore.removeBookmark(for: standardized)
          }
          throw DocumentAccessError.unresolvedBookmark
        }
      } else {
        resolvedScope = try filesystemAccess.adoptSecurityScope(for: standardized)
        preparedRecent.url = resolvedScope.url
        preparedRecent.displayName =
          preparedRecent.displayName.isEmpty
          ? resolvedScope.url.lastPathComponent : preparedRecent.displayName

        if let bookmarkStore,
          let data = makeBookmarkData(for: resolvedScope)
        {
          record = try? bookmarkStore.upsertBookmark(
            for: resolvedScope.url,
            bookmarkData: data
          )
        } else {
          bookmarkData = makeBookmarkData(for: resolvedScope)
        }
      }

      if let record {
        preparedRecent = applyBookmarkRecord(record, to: preparedRecent)
      } else {
        preparedRecent.bookmarkData = bookmarkData
      }

      return AccessContext(
        scopedURL: resolvedScope,
        recent: preparedRecent,
        bookmarkRecord: record,
        bookmarkData: bookmarkData
      )
    }
  }

  // MARK: - Supporting Types

  struct AccessContext: Sendable {
    let scopedURL: SecurityScopedURL
    var recent: DocumentRecent
    var bookmarkRecord: BookmarkPersistenceStore.Record?
    var bookmarkData: Data?
  }

  private enum DocumentAccessError: LocalizedError {
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

  typealias BookmarkResolutionState = BookmarkPersistenceStore.Record.ResolutionState
#endif
