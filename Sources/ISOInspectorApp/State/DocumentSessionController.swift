#if canImport(SwiftUI) && canImport(Combine)
import Combine
import Dispatch
import Foundation

#if canImport(ISOInspectorKit_iOS)
import ISOInspectorKit_iOS
#endif
#if canImport(ISOInspectorKit_macOS)
import ISOInspectorKit_macOS
#endif
#if canImport(ISOInspectorKit_ipadOS)
import ISOInspectorKit_ipadOS
#endif
import UniformTypeIdentifiers

@MainActor
final class DocumentSessionController: ObservableObject {
    @Published private(set) var recents: [DocumentRecent]
    @Published private(set) var currentDocument: DocumentRecent?

    let parseTreeStore: ParseTreeStore
    let annotations: AnnotationBookmarkSession

    private let recentsStore: DocumentRecentsStoring
    private let pipelineFactory: () -> ParsePipeline
    private let readerFactory: (URL) throws -> RandomAccessReader
    private let workQueue: DocumentSessionWorkQueue
    private let recentLimit: Int
    private let sessionStore: WorkspaceSessionStoring?

    private var currentSessionID: UUID?
    private var currentSessionCreatedAt: Date?
    private var sessionFileIDs: [String: UUID] = [:]
    private var pendingSessionSnapshot: WorkspaceSessionSnapshot?
    private var annotationsSelectionCancellable: AnyCancellable?

    init(
        parseTreeStore: ParseTreeStore? = nil,
        annotations: AnnotationBookmarkSession? = nil,
        recentsStore: DocumentRecentsStoring,
        sessionStore: WorkspaceSessionStoring? = nil,
        pipelineFactory: @escaping () -> ParsePipeline = { .live() },
        readerFactory: @escaping (URL) throws -> RandomAccessReader = { try ChunkedFileReader(fileURL: $0) },
        workQueue: DocumentSessionWorkQueue = DocumentSessionBackgroundQueue(),
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
        guard let resolvedURL = resolveURL(for: recent) else {
            removeRecent(with: recent.url)
            return
        }
        var normalized = recent
        normalized.url = resolvedURL.standardizedFileURL
        openDocument(recent: normalized)
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
                // @todo PDD:30m Surface document load failures in the app shell UI once design for error banners lands.
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
            // @todo PDD:30m Surface recents persistence failures in diagnostics once logging pipeline is available.
        }
    }

    private func makeBookmarkData(for url: URL) -> Data? {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        return try? url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
        #else
        return nil
        #endif
    }

    private func resolveURL(for recent: DocumentRecent) -> URL? {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        if let bookmark = recent.bookmarkData {
            var isStale = false
            if let url = try? URL(resolvingBookmarkData: bookmark, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale) {
                if isStale, let refreshed = try? url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil) {
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
                // @todo PDD:30m Surface session persistence failures once diagnostics pipeline is available.
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
            // @todo PDD:30m Surface session persistence failures once diagnostics pipeline is available.
        }
    }

    private func canonicalIdentifier(for url: URL) -> String {
        url.standardizedFileURL.resolvingSymlinksInPath().absoluteString
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
