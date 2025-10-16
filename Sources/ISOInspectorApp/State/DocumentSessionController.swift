#if canImport(SwiftUI) && canImport(Combine)
import Combine
import Dispatch
import Foundation
import ISOInspectorKit
import OSLog

import UniformTypeIdentifiers

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

    private let logger = Logger(subsystem: "ISOInspectorApp", category: "DocumentSession")

    private var currentSessionID: UUID?
    private var currentSessionCreatedAt: Date?
    private var sessionFileIDs: [String: UUID] = [:]
    private var pendingSessionSnapshot: WorkspaceSessionSnapshot?
    private var annotationsSelectionCancellable: AnyCancellable?
    private var lastFailedRecent: DocumentRecent?

    init(
        parseTreeStore: ParseTreeStore? = nil,
        annotations: AnnotationBookmarkSession? = nil,
        recentsStore: DocumentRecentsStoring,
        sessionStore: WorkspaceSessionStoring? = nil,
        pipelineFactory: @escaping () -> ParsePipeline = { .live() },
        readerFactory: @escaping (URL) throws -> RandomAccessReader = { try ChunkedFileReader(fileURL: $0) },
        workQueue: DocumentSessionWorkQueue = DocumentSessionBackgroundQueue(),
        diagnostics: (any DiagnosticsLogging)? = nil,
        recentLimit: Int = 10
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
        self.diagnostics = diagnostics ?? DiagnosticsLogger(
            subsystem: "ISOInspectorApp",
            category: "DocumentSessionPersistence"
        )
        self.recents = (try? recentsStore.load()) ?? []

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
        case let .success(normalized):
            openDocument(recent: normalized)
        case let .failure(error):
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
            do {
                let standardized = recent.url.standardizedFileURL
                let bookmark = recent.bookmarkData ?? self.makeBookmarkData(for: standardized)
                let reader = try self.readerFactory(standardized)
                let pipeline = self.pipelineFactory()
                var preparedRecent = recent
                preparedRecent.url = standardized
                preparedRecent.bookmarkData = preparedRecent.bookmarkData ?? bookmark
                preparedRecent.displayName = preparedRecent.displayName.isEmpty ? standardized.lastPathComponent : preparedRecent.displayName
                if Thread.isMainThread {
                    self.startSession(
                        url: standardized,
                        bookmark: bookmark,
                        reader: reader,
                        pipeline: pipeline,
                        recent: preparedRecent,
                        restoredSelection: restoredSelection
                    )
                } else {
                    Task { @MainActor in
                        self.startSession(
                            url: standardized,
                            bookmark: bookmark,
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
        bookmark: Data?,
        reader: RandomAccessReader,
        pipeline: ParsePipeline,
        recent: DocumentRecent,
        restoredSelection: Int64?
    ) {
        parseTreeStore.start(pipeline: pipeline, reader: reader, context: .init(source: url))
        annotations.setFileURL(url)
        if let restoredSelection {
            annotations.setSelectedNode(restoredSelection)
        } else {
            annotations.setSelectedNode(nil)
        }
        var updatedRecent = recent
        updatedRecent.bookmarkData = bookmark ?? recent.bookmarkData
        updatedRecent.lastOpened = Date()
        updatedRecent.displayName = updatedRecent.displayName.isEmpty ? url.lastPathComponent : updatedRecent.displayName
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
            try recentsStore.save(recents)
        } catch {
            let errorDescription = String(describing: error)
            let focusedPath = currentDocument?.url.standardizedFileURL.path ?? "none"
            let allRecents = recents
                .map { $0.url.standardizedFileURL.path }
                .joined(separator: ", ")
            diagnostics.error(
                "Failed to persist recents: error=\(errorDescription); recentsCount=\(recents.count); " +
                "focusedPath=\(focusedPath); recentsPaths=[\(allRecents)]"
            )
        }
    }

    private func makeBookmarkData(for url: URL) -> Data? {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        return try? url.bookmarkData(options: bookmarkCreationOptions, includingResourceValuesForKeys: nil, relativeTo: nil)
        #else
        return nil
        #endif
    }

    private func resolveURL(for recent: DocumentRecent) -> URL? {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        if let bookmark = recent.bookmarkData {
            var isStale = false
            if let url = try? URL(
                resolvingBookmarkData: bookmark,
                options: bookmarkResolutionOptions,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ) {
                if isStale,
                   let refreshed = try? url.bookmarkData(
                       options: bookmarkCreationOptions,
                       includingResourceValuesForKeys: nil,
                       relativeTo: nil
                   ) {
                    replaceBookmark(for: url, data: refreshed)
                }
                return url
            }
        }
        #endif
        return recent.url
    }

    private func replaceBookmark(for url: URL, data: Data) {
        guard let index = recents.firstIndex(where: { $0.url.standardizedFileURL == url.standardizedFileURL }) else {
            return
        }
        recents[index].bookmarkData = data
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
            recents = sortedFiles.map(\.recent)
            let focusURL = snapshot.focusedFileURL?.standardizedFileURL
            if let focusURL,
               let focused = sortedFiles.first(where: { $0.recent.url.standardizedFileURL == focusURL }) {
                currentDocument = focused.recent
            } else {
                currentDocument = sortedFiles.first?.recent
            }
        }
        sessionFileIDs = Dictionary(uniqueKeysWithValues: sortedFiles.map { file in
            (canonicalIdentifier(for: file.recent.url), file.id)
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
        let focusURL = snapshot.focusedFileURL?.standardizedFileURL ?? sortedFiles.first?.recent.url.standardizedFileURL
        guard let focusURL,
              let focused = sortedFiles.first(where: { $0.recent.url.standardizedFileURL == focusURL }) else {
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
            } catch {
                let errorDescription = String(describing: error)
                diagnostics.error(
                    "Failed to clear persisted session: error=\(errorDescription); " +
                    "sessionID=\(currentSessionID?.uuidString ?? "none")"
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
            snapshots.append(
                WorkspaceSessionFileSnapshot(
                    id: fileID,
                    recent: recent,
                    orderIndex: index,
                    lastSelectionNodeID: selection,
                    isPinned: false,
                    scrollOffset: nil,
                    bookmarkIdentifier: recent.bookmarkIdentifier,
                    bookmarkDiffs: []
                )
            )
        }

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
                "Failed to persist session snapshot: error=\(errorDescription); " +
                "sessionID=\(snapshot.id.uuidString); focusedPath=\(snapshot.focusedFileURL?.standardizedFileURL.path ?? "none")"
            )
        }
    }

    private func canonicalIdentifier(for url: URL) -> String {
        url.standardizedFileURL.resolvingSymlinksInPath().absoluteString
    }

    private func normalizeRecent(_ recent: DocumentRecent) -> Result<DocumentRecent, DocumentAccessError> {
        guard let resolvedURL = resolveURL(for: recent) else {
            return .failure(.unresolvedBookmark)
        }
        let standardized = resolvedURL.standardizedFileURL
        guard isReadableFile(at: standardized) else {
            return .failure(.unreadable(standardized))
        }
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
        let defaultSuggestion = "Verify that the file exists and you have permission to read it, then try again."

        var message = "ISO Inspector couldn't open “\(displayName)”."
        var suggestion = defaultSuggestion
        var details: String?

        if let localizedError = error as? LocalizedError {
            if let description = localizedError.errorDescription?.trimmingCharacters(in: .whitespacesAndNewlines), !description.isEmpty {
                message = description
            }
            if let recovery = localizedError.recoverySuggestion?.trimmingCharacters(in: .whitespacesAndNewlines), !recovery.isEmpty {
                suggestion = recovery
            }
            if let reason = localizedError.failureReason?.trimmingCharacters(in: .whitespacesAndNewlines), !reason.isEmpty {
                details = reason
            }
        } else if let error {
            let localized = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            if !localized.isEmpty {
                message = localized
            }
        }

        if let error {
            logger.error("Document open failed for \(standardizedRecent.url.path, privacy: .public): \(String(describing: error), privacy: .public)")
        } else {
            logger.error("Document open failed for \(standardizedRecent.url.path, privacy: .public): no additional error details available")
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
        case let .unreadable(url):
            return "ISO Inspector couldn't access the file at \(url.path)."
        case .unresolvedBookmark:
            return "ISO Inspector couldn't resolve the saved bookmark for this file."
        }
    }

    var failureReason: String? {
        switch self {
        case let .unreadable(url):
            return "The file may have been moved, deleted, or you may not have permission to read it. (\(url.path))"
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

    init(queue: DispatchQueue = DispatchQueue(label: "isoinspector.document-session", qos: .userInitiated)) {
        self.queue = queue
    }

    func execute(_ work: @escaping () -> Void) {
        queue.async(execute: work)
    }
}
#endif
