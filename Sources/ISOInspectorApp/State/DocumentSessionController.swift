#if canImport(SwiftUI) && canImport(Combine)
import Combine
import Dispatch
import Foundation
import ISOInspectorKit
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

    init(
        parseTreeStore: ParseTreeStore = ParseTreeStore(),
        annotations: AnnotationBookmarkSession = AnnotationBookmarkSession(store: nil),
        recentsStore: DocumentRecentsStoring,
        pipelineFactory: @escaping () -> ParsePipeline = { .live() },
        readerFactory: @escaping (URL) throws -> RandomAccessReader = { try ChunkedFileReader(fileURL: $0) },
        workQueue: DocumentSessionWorkQueue = DocumentSessionBackgroundQueue(),
        recentLimit: Int = 10
    ) {
        self.parseTreeStore = parseTreeStore
        self.annotations = annotations
        self.recentsStore = recentsStore
        self.pipelineFactory = pipelineFactory
        self.readerFactory = readerFactory
        self.workQueue = workQueue
        self.recentLimit = recentLimit
        self.recents = (try? recentsStore.load()) ?? []
    }

    func openDocument(at url: URL) {
        let standardized = url.standardizedFileURL
        let bookmark = makeBookmarkData(for: standardized)
        workQueue.execute { [weak self] in
            guard let self else { return }
            do {
                let reader = try self.readerFactory(standardized)
                let pipeline = self.pipelineFactory()
                Task { @MainActor in
                    self.startSession(url: standardized, bookmark: bookmark, reader: reader, pipeline: pipeline)
                }
            } catch {
                // @todo PDD:30m Surface document load failures in the app shell UI once design for error banners lands.
            }
        }
    }

    func openRecent(_ recent: DocumentRecent) {
        guard let resolvedURL = resolveURL(for: recent) else {
            removeRecent(with: recent.url)
            return
        }
        openDocument(at: resolvedURL)
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

    private func startSession(
        url: URL,
        bookmark: Data?,
        reader: RandomAccessReader,
        pipeline: ParsePipeline
    ) {
        parseTreeStore.start(pipeline: pipeline, reader: reader, context: .init(source: url))
        annotations.setFileURL(url)
        let recent = DocumentRecent(
            url: url,
            bookmarkData: bookmark,
            displayName: url.lastPathComponent,
            lastOpened: Date()
        )
        currentDocument = recent
        insertRecent(recent)
    }

    private func insertRecent(_ recent: DocumentRecent) {
        recents.removeAll { $0.url.standardizedFileURL == recent.url.standardizedFileURL }
        recents.insert(recent, at: 0)
        if recents.count > recentLimit {
            recents = Array(recents.prefix(recentLimit))
        }
        persistRecents()
    }

    private func removeRecent(with url: URL) {
        recents.removeAll { $0.url.standardizedFileURL == url.standardizedFileURL }
        persistRecents()
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
