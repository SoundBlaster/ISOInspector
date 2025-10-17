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

    #if os(macOS)
        private let bookmarkCreationOptions: URL.BookmarkCreationOptions = [.withSecurityScope]
        private let bookmarkResolutionOptions: URL.BookmarkResolutionOptions = [.withSecurityScope]
    #else
        private let bookmarkCreationOptions: URL.BookmarkCreationOptions = []
        private let bookmarkResolutionOptions: URL.BookmarkResolutionOptions = []
    #endif

    @MainActor
    final class DocumentSessionController: ObservableObject {
        @Published private(set) var recents: [DocumentRecent]
        @Published private(set) var currentDocument: DocumentRecent?
        @Published private(set) var loadFailure: DocumentLoadFailure?

        let parseTreeStore: ParseTreeStore
        let annotations: AnnotationBookmarkSession

        private let recentsStore: DocumentRecentsStoring
        private let pipelineFactory: () -> ParsePipeline
        private let readerFactory: (URL) throws -> RandomAccessReader
        private let workQueue: DocumentSessionWorkQueue
        private let recentLimit: Int
        private let sessionStore: WorkspaceSessionStoring?
        private let diagnostics: any DiagnosticsLogging
        private let bookmarkStore: BookmarkPersistenceManaging?
        private let bookmarkDataProvider: (URL) -> Data?

        private let logger = Logger(subsystem: "ISOInspectorApp", category: "DocumentSession")

        private var currentSessionID: UUID?
        private var currentSessionCreatedAt: Date?
        private var sessionFileIDs: [String: UUID] = [:]
        private var sessionBookmarkDiffs: [String: [WorkspaceSessionBookmarkDiff]] = [:]
        private var pendingSessionSnapshot: WorkspaceSessionSnapshot?
        private var annotationsSelectionCancellable: AnyCancellable?
        private var lastFailedRecent: DocumentRecent?
        private var activeSecurityScopedURL: URL?

        init(
            parseTreeStore: ParseTreeStore? = nil,
            annotations: AnnotationBookmarkSession? = nil,
            recentsStore: DocumentRecentsStoring,
            sessionStore: WorkspaceSessionStoring? = nil,
            pipelineFactory: @escaping () -> ParsePipeline = { .live() },
            readerFactory: @escaping (URL) throws -> RandomAccessReader = {
                try ChunkedFileReader(fileURL: $0)
            },
            workQueue: DocumentSessionWorkQueue = DocumentSessionBackgroundQueue(),
            diagnostics: (any DiagnosticsLogging)? = nil,
            recentLimit: Int = 10,
            bookmarkStore: BookmarkPersistenceManaging? = nil,
            bookmarkDataProvider: ((URL) -> Data?)? = nil
        ) {
            let resolvedParseTreeStore = parseTreeStore ?? ParseTreeStore()
            let resolvedAnnotations = annotations ?? AnnotationBookmarkSession(store: nil)

            self.parseTreeStore = resolvedParseTreeStore
            self.annotations = resolvedAnnotations
            self.recentsStore = recentsStore
            self.sessionStore = sessionStore
            self.pipelineFactory = pipelineFactory
            self.readerFactory = readerFactory
            self.workQueue = workQueue
            self.recentLimit = recentLimit
            self.diagnostics =
                diagnostics
                ?? DiagnosticsLogger(
                    subsystem: "ISOInspectorApp",
                    category: "DocumentSessionPersistence"
                )
            self.bookmarkStore = bookmarkStore
            if let bookmarkDataProvider {
                self.bookmarkDataProvider = bookmarkDataProvider
            } else {
                self.bookmarkDataProvider = { url in
                    #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
                        return try? url.bookmarkData(
                            options: bookmarkCreationOptions,
                            includingResourceValuesForKeys: nil,
                            relativeTo: nil
                        )
                    #else
                        return nil
                    #endif
                }
            }
            self.recents = (try? recentsStore.load()) ?? []
            migrateRecentsForBookmarkStore()

            annotationsSelectionCancellable = resolvedAnnotations.$currentSelectedNodeID
                .dropFirst()
                .sink { [weak self] _ in
                    guard let self, !self.recents.isEmpty else { return }
                    self.persistSession()
                }

            if let sessionStore, let snapshot = try? sessionStore.loadCurrentSession() {
                currentSessionID = snapshot.id
                currentSessionCreatedAt = snapshot.createdAt
                applySessionSnapshot(snapshot)
                pendingSessionSnapshot = snapshot
                restoreSessionIfNeeded()
            }
        }

        deinit {
            // Clean up security-scoped resource access on deallocation
            if let activeURL = activeSecurityScopedURL {
                activeURL.stopAccessingSecurityScopedResource()
            }
        }

        func openDocument(at url: URL) {
            var recent = DocumentRecent(
                url: url.standardizedFileURL,
                bookmarkData: nil,
                displayName: url.lastPathComponent,
                lastOpened: Date()
            )
            recent.bookmarkData = makeBookmarkData(for: recent.url)
            openDocument(recent: recent)
        }

        func openRecent(_ recent: DocumentRecent) {
            switch normalizeRecent(recent) {
            case .success(let normalized):
                openDocument(recent: normalized)
            case .failure(let error):
                var failedRecent = recent
                failedRecent.url = recent.url.standardizedFileURL
                handleRecentAccessFailure(failedRecent, error: error)
            }
        }

        func removeRecent(at offsets: IndexSet) {
            let urls = offsets.compactMap { index -> URL? in
                guard recents.indices.contains(index) else { return nil }
                return recents[index].url
            }
            for url in urls {
                removeRecent(with: url)
            }
        }

        func dismissLoadFailure() {
            loadFailure = nil
            lastFailedRecent = nil
        }

        func retryLastFailure() {
            guard let recent = lastFailedRecent else { return }
            openDocument(recent: recent)
        }

        var allowedContentTypes: [UTType] {
            [.mpeg4Movie, .quickTimeMovie]
        }

        private func openDocument(recent: DocumentRecent, restoredSelection: Int64? = nil) {
            workQueue.execute { [weak self] in
                guard let self else { return }

                // First, resolve any bookmarks to get the correct URL
                let resolvedRecent: DocumentRecent
                if recent.bookmarkData != nil || recent.bookmarkIdentifier != nil {
                    // This recent has a bookmark, resolve it first
                    switch self.normalizeRecent(recent) {
                    case .success(let normalized):
                        resolvedRecent = normalized
                    case .failure(let error):
                        var failedRecent = recent
                        failedRecent.url = recent.url.standardizedFileURL
                        if Thread.isMainThread {
                            self.handleRecentAccessFailure(failedRecent, error: error)
                        } else {
                            Task { @MainActor in
                                self.handleRecentAccessFailure(failedRecent, error: error)
                            }
                        }
                        return
                    }
                } else {
                    resolvedRecent = recent
                }

                // Start accessing security-scoped resource on the resolved URL
                let standardized = resolvedRecent.url.standardizedFileURL
                let didStartAccessing = standardized.startAccessingSecurityScopedResource()

                do {
                    let record = self.resolveBookmarkRecord(
                        for: resolvedRecent, url: standardized, allowCreation: true)
                    let bookmark =
                        record?.bookmarkData ?? resolvedRecent.bookmarkData
                        ?? self.makeBookmarkData(for: standardized)
                    let reader = try self.readerFactory(standardized)
                    let pipeline = self.pipelineFactory()
                    var preparedRecent = resolvedRecent
                    preparedRecent.url = standardized
                    if let record {
                        preparedRecent = self.applyBookmarkRecord(record, to: preparedRecent)
                    } else {
                        preparedRecent.bookmarkData = preparedRecent.bookmarkData ?? bookmark
                    }
                    preparedRecent.displayName =
                        preparedRecent.displayName.isEmpty
                        ? standardized.lastPathComponent : preparedRecent.displayName
                    if Thread.isMainThread {
                        self.startSession(
                            url: standardized,
                            securityScopedURL: didStartAccessing ? standardized : nil,
                            bookmark: bookmark,
                            bookmarkRecord: record,
                            reader: reader,
                            pipeline: pipeline,
                            recent: preparedRecent,
                            restoredSelection: restoredSelection
                        )
                    } else {
                        Task { @MainActor in
                            self.startSession(
                                url: standardized,
                                securityScopedURL: didStartAccessing ? standardized : nil,
                                bookmark: bookmark,
                                bookmarkRecord: record,
                                reader: reader,
                                pipeline: pipeline,
                                recent: preparedRecent,
                                restoredSelection: restoredSelection
                            )
                        }
                    }
                } catch {
                    var failedRecent = recent
                    failedRecent.url = recent.url.standardizedFileURL
                    if Thread.isMainThread {
                        self.emitLoadFailure(for: failedRecent, error: error)
                    } else {
                        Task { @MainActor in
                            self.emitLoadFailure(for: failedRecent, error: error)
                        }
                    }
                }
            }
        }

        // swiftlint:disable:next function_parameter_count
        private func startSession(
            url: URL,
            securityScopedURL: URL?,
            bookmark: Data?,
            bookmarkRecord: BookmarkPersistenceStore.Record?,
            reader: RandomAccessReader,
            pipeline: ParsePipeline,
            recent: DocumentRecent,
            restoredSelection: Int64?
        ) {
            // Release previous security-scoped resource if any
            if let previousURL = activeSecurityScopedURL {
                previousURL.stopAccessingSecurityScopedResource()
            }

            // Store the new security-scoped URL to keep access alive
            activeSecurityScopedURL = securityScopedURL
            parseTreeStore.start(pipeline: pipeline, reader: reader, context: .init(source: url))
            annotations.setFileURL(url)
            if let restoredSelection {
                annotations.setSelectedNode(restoredSelection)
            } else {
                annotations.setSelectedNode(nil)
            }
            var updatedRecent = recent
            if let bookmarkRecord {
                updatedRecent = applyBookmarkRecord(bookmarkRecord, to: updatedRecent)
            } else {
                updatedRecent.bookmarkData = bookmark ?? recent.bookmarkData
            }
            updatedRecent.lastOpened = Date()
            updatedRecent.displayName =
                updatedRecent.displayName.isEmpty
                ? url.lastPathComponent : updatedRecent.displayName
            loadFailure = nil
            lastFailedRecent = nil
            currentDocument = updatedRecent
            insertRecent(updatedRecent)
        }

        private func insertRecent(_ recent: DocumentRecent) {
            recents.removeAll { $0.url.standardizedFileURL == recent.url.standardizedFileURL }
            recents.insert(recent, at: 0)
            if recents.count > recentLimit {
                recents = Array(recents.prefix(recentLimit))
            }
            persistRecents()
            persistSession()
        }

        private func removeRecent(with url: URL) {
            recents.removeAll { $0.url.standardizedFileURL == url.standardizedFileURL }
            persistRecents()
            persistSession()
        }

        private func persistRecents() {
            do {
                let payload = sanitizeRecentsForPersistence(recents)
                try recentsStore.save(payload)
            } catch {
                let errorDescription = String(describing: error)
                let focusedPath = currentDocument?.url.standardizedFileURL.path ?? "none"
                let allRecents =
                    recents
                    .map { $0.url.standardizedFileURL.path }
                    .joined(separator: ", ")
                diagnostics.error(
                    "Failed to persist recents: error=\(errorDescription); recentsCount=\(recents.count); "
                        + "focusedPath=\(focusedPath); recentsPaths=[\(allRecents)]"
                )
            }
        }

        private func makeBookmarkData(for url: URL) -> Data? {
            bookmarkDataProvider(url)
        }

        private func resolveURL(for recent: DocumentRecent) -> URL? {
            #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
                let standardized = recent.url.standardizedFileURL
                let record = resolveBookmarkRecord(
                    for: recent, url: standardized, allowCreation: false)
                let bookmark = record?.bookmarkData ?? recent.bookmarkData
                if let bookmark {
                    var isStale = false
                    if let url = try? URL(
                        resolvingBookmarkData: bookmark,
                        options: bookmarkResolutionOptions,
                        relativeTo: nil,
                        bookmarkDataIsStale: &isStale
                    ) {
                        if isStale,
                            let refreshed = makeBookmarkData(for: url) {
                            replaceBookmark(for: url, data: refreshed)
                        }
                        if let record {
                            updateRecent(with: record, for: standardized)
                            if let bookmarkStore {
                                _ = try? bookmarkStore.markResolution(
                                    for: url,
                                    state: isStale ? .stale : .succeeded
                                )
                            }
                        }
                        return url
                    }
                }
                if let record {
                    updateRecent(with: record, for: standardized)
                    if let bookmarkStore {
                        _ = try? bookmarkStore.markResolution(for: standardized, state: .failed)
                    }
                }
            #endif
            return recent.url
        }

        private func replaceBookmark(for url: URL, data: Data) {
            guard
                let index = recents.firstIndex(where: {
                    $0.url.standardizedFileURL == url.standardizedFileURL
                })
            else {
                return
            }
            if let bookmarkStore,
                let record = try? bookmarkStore.upsertBookmark(for: url, bookmarkData: data) {
                recents[index] = applyBookmarkRecord(record, to: recents[index])
            } else {
                recents[index].bookmarkData = data
            }
            persistRecents()
            persistSession()
        }

        private func applySessionSnapshot(_ snapshot: WorkspaceSessionSnapshot) {
            let sortedFiles = snapshot.files.sorted { lhs, rhs in
                if lhs.orderIndex == rhs.orderIndex {
                    return lhs.id.uuidString < rhs.id.uuidString
                }
                return lhs.orderIndex < rhs.orderIndex
            }
            if !sortedFiles.isEmpty {
                let loadedRecents = sortedFiles.map(\.recent)
                let migratedRecents =
                    bookmarkStore != nil ? loadedRecents.map(migrateRecentBookmark) : loadedRecents
                recents = migratedRecents
                let focusURL = snapshot.focusedFileURL?.standardizedFileURL
                if let focusURL,
                    let focusedIndex = migratedRecents.firstIndex(where: {
                        $0.url.standardizedFileURL == focusURL
                    }) {
                    currentDocument = migratedRecents[focusedIndex]
                } else {
                    currentDocument = migratedRecents.first
                }
            }
            sessionFileIDs = Dictionary(
                uniqueKeysWithValues: sortedFiles.map { file in
                    (canonicalIdentifier(for: file.recent.url), file.id)
                })
            sessionBookmarkDiffs = Dictionary(
                uniqueKeysWithValues: sortedFiles.map { file in
                    (canonicalIdentifier(for: file.recent.url), file.bookmarkDiffs)
                })
        }

        private func restoreSessionIfNeeded() {
            guard let snapshot = pendingSessionSnapshot else { return }
            pendingSessionSnapshot = nil
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
            openDocument(recent: focused.recent, restoredSelection: focused.lastSelectionNodeID)
        }

        private func persistSession() {
            guard let sessionStore else { return }
            if recents.isEmpty {
                do {
                    try sessionStore.clearCurrentSession()
                    currentSessionID = nil
                    currentSessionCreatedAt = nil
                    sessionFileIDs.removeAll()
                    sessionBookmarkDiffs.removeAll()
                } catch {
                    let errorDescription = String(describing: error)
                    diagnostics.error(
                        "Failed to clear persisted session: error=\(errorDescription); "
                            + "sessionID=\(currentSessionID?.uuidString ?? "none")"
                    )
                }
                return
            }

            let now = Date()
            if currentSessionCreatedAt == nil {
                currentSessionCreatedAt = now
            }
            let sessionID = currentSessionID ?? UUID()
            currentSessionID = sessionID

            var snapshots: [WorkspaceSessionFileSnapshot] = []
            snapshots.reserveCapacity(recents.count)
            var nextDiffs: [String: [WorkspaceSessionBookmarkDiff]] = [:]

            for (index, recent) in recents.enumerated() {
                let canonical = canonicalIdentifier(for: recent.url)
                let fileID = sessionFileIDs[canonical] ?? UUID()
                sessionFileIDs[canonical] = fileID
                let selection: Int64?
                if let currentURL = annotations.currentFileURL,
                    currentURL.standardizedFileURL == recent.url.standardizedFileURL {
                    selection = annotations.currentSelectedNodeID
                } else {
                    selection = nil
                }
                let persistedRecent = sanitizeRecentsForPersistence([recent]).first ?? recent
                let diffs = sessionBookmarkDiffs[canonical] ?? []
                nextDiffs[canonical] = diffs
                snapshots.append(
                    WorkspaceSessionFileSnapshot(
                        id: fileID,
                        recent: persistedRecent,
                        orderIndex: index,
                        lastSelectionNodeID: selection,
                        isPinned: false,
                        scrollOffset: nil,
                        bookmarkIdentifier: recent.bookmarkIdentifier,
                        bookmarkDiffs: diffs
                    )
                )
            }

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

            do {
                try sessionStore.saveCurrentSession(snapshot)
            } catch {
                let errorDescription = String(describing: error)
                diagnostics.error(
                    "Failed to persist session snapshot: error=\(errorDescription); "
                        + "sessionID=\(snapshot.id.uuidString); focusedPath=\(snapshot.focusedFileURL?.standardizedFileURL.path ?? "none")"
                )
            }
        }

        private func canonicalIdentifier(for url: URL) -> String {
            url.standardizedFileURL.resolvingSymlinksInPath().absoluteString
        }

        private func migrateRecentsForBookmarkStore() {
            guard bookmarkStore != nil, !recents.isEmpty else { return }
            let migrated = recents.map(migrateRecentBookmark)
            if migrated != recents {
                recents = migrated
                persistRecents()
            }
        }

        private func migrateRecentBookmark(_ recent: DocumentRecent) -> DocumentRecent {
            guard let bookmarkStore else { return recent }
            let standardized = recent.url.standardizedFileURL
            if let identifier = recent.bookmarkIdentifier,
                let record = try? bookmarkStore.record(withID: identifier) {
                return applyBookmarkRecord(record, to: recent)
            }
            if let record = try? bookmarkStore.record(for: standardized) {
                return applyBookmarkRecord(record, to: recent)
            }
            if let data = recent.bookmarkData,
                let record = try? bookmarkStore.upsertBookmark(
                    for: standardized, bookmarkData: data) {
                return applyBookmarkRecord(record, to: recent)
            }
            return recent
        }

        private func sanitizeRecentsForPersistence(_ recents: [DocumentRecent]) -> [DocumentRecent] {
            guard bookmarkStore != nil else { return recents }
            return recents.map { recent in
                var sanitized = recent
                if sanitized.bookmarkIdentifier != nil {
                    sanitized.bookmarkData = nil
                }
                return sanitized
            }
        }

        private func applyBookmarkRecord(
            _ record: BookmarkPersistenceStore.Record, to recent: DocumentRecent
        ) -> DocumentRecent {
            var updated = recent
            updated.bookmarkIdentifier = record.id
            updated.bookmarkData = nil
            return updated
        }

        private func updateRecent(with record: BookmarkPersistenceStore.Record, for url: URL) {
            let standardized = url.standardizedFileURL
            // Must update @Published properties on main thread to avoid SwiftUI/menu crashes
            if Thread.isMainThread {
                if let index = recents.firstIndex(where: {
                    $0.url.standardizedFileURL == standardized
                }) {
                    recents[index] = applyBookmarkRecord(record, to: recents[index])
                }
                if let current = currentDocument, current.url.standardizedFileURL == standardized {
                    currentDocument = applyBookmarkRecord(record, to: current)
                }
            } else {
                Task { @MainActor in
                    if let index = self.recents.firstIndex(where: {
                        $0.url.standardizedFileURL == standardized
                    }) {
                        self.recents[index] = self.applyBookmarkRecord(
                            record, to: self.recents[index])
                    }
                    if let current = self.currentDocument,
                        current.url.standardizedFileURL == standardized {
                        self.currentDocument = self.applyBookmarkRecord(record, to: current)
                    }
                }
            }
        }

        private func resolveBookmarkRecord(
            for recent: DocumentRecent,
            url: URL,
            allowCreation: Bool
        ) -> BookmarkPersistenceStore.Record? {
            guard let bookmarkStore else { return nil }
            if let identifier = recent.bookmarkIdentifier,
                let record = try? bookmarkStore.record(withID: identifier) {
                return record
            }
            if let record = try? bookmarkStore.record(for: url) {
                return record
            }
            if let data = recent.bookmarkData,
                let record = try? bookmarkStore.upsertBookmark(for: url, bookmarkData: data) {
                return record
            }
            if allowCreation, let data = makeBookmarkData(for: url) {
                return try? bookmarkStore.upsertBookmark(for: url, bookmarkData: data)
            }
            return nil
        }

        private func normalizeRecent(_ recent: DocumentRecent) -> Result<
            DocumentRecent, DocumentAccessError
        > {
            guard let resolvedURL = resolveURL(for: recent) else {
                return .failure(.unresolvedBookmark)
            }
            let standardized = resolvedURL.standardizedFileURL
            // Note: We can't check isReadableFile here because security-scoped resources
            // need to be activated first. File accessibility will be checked when
            // attempting to create the FileHandle in openDocument().
            var normalized = recent
            normalized.url = standardized
            return .success(normalized)
        }

        private func handleRecentAccessFailure(_ recent: DocumentRecent, error: DocumentAccessError) {
            removeRecent(with: recent.url)
            emitLoadFailure(for: recent, error: error)
        }

        private func emitLoadFailure(for recent: DocumentRecent, error: Error?) {
            var standardizedRecent = recent
            standardizedRecent.url = recent.url.standardizedFileURL
            let displayName = failureDisplayName(for: standardizedRecent)
            let defaultSuggestion =
                "Verify that the file exists and you have permission to read it, then try again."

            var message = "ISO Inspector couldn't open “\(displayName)”."
            var suggestion = defaultSuggestion
            var details: String?

            if let localizedError = error as? LocalizedError {
                if let description = localizedError.errorDescription?.trimmingCharacters(
                    in: .whitespacesAndNewlines), !description.isEmpty {
                    message = description
                }
                if let recovery = localizedError.recoverySuggestion?.trimmingCharacters(
                    in: .whitespacesAndNewlines), !recovery.isEmpty {
                    suggestion = recovery
                }
                if let reason = localizedError.failureReason?.trimmingCharacters(
                    in: .whitespacesAndNewlines), !reason.isEmpty {
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

            loadFailure = DocumentLoadFailure(
                fileURL: standardizedRecent.url,
                fileDisplayName: displayName,
                message: message,
                recoverySuggestion: suggestion,
                details: details
            )
            lastFailedRecent = standardizedRecent
        }

        private func failureDisplayName(for recent: DocumentRecent) -> String {
            let trimmed = recent.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
            let lastComponent = recent.url.lastPathComponent
            return lastComponent.isEmpty ? recent.url.absoluteString : lastComponent
        }

        private func isReadableFile(at url: URL) -> Bool {
            FileManager.default.isReadableFile(atPath: url.path)
        }
    }

    extension DocumentSessionController {
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
                "Unable to open “\(fileDisplayName)”"
            }
        }
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

    protocol DocumentSessionWorkQueue {
        func execute(_ work: @escaping () -> Void)
    }

    struct DocumentSessionBackgroundQueue: DocumentSessionWorkQueue {
        private let queue: DispatchQueue

        init(
            queue: DispatchQueue = DispatchQueue(
                label: "isoinspector.document-session", qos: .userInitiated)
        ) {
            self.queue = queue
        }

        func execute(_ work: @escaping () -> Void) {
            queue.async(execute: work)
        }
    }
#endif
