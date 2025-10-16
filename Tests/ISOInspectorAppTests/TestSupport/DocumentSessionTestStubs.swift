#if canImport(Combine) && canImport(SwiftUI)
import Combine
import Foundation
import ISOInspectorApp
import ISOInspectorKit

final class DocumentRecentsStoreStub: DocumentRecentsStoring {
    var initialRecents: [DocumentRecent]
    private(set) var savedRecents: [DocumentRecent]?
    var saveHandler: (([DocumentRecent]) throws -> Void)?

    init(initialRecents: [DocumentRecent]) {
        self.initialRecents = initialRecents
    }

    func load() throws -> [DocumentRecent] {
        initialRecents
    }

    func save(_ recents: [DocumentRecent]) throws {
        savedRecents = recents
        if let saveHandler {
            try saveHandler(recents)
        }
    }
}

final class WorkspaceSessionStoreStub: WorkspaceSessionStoring {
    var loadedSnapshot: WorkspaceSessionSnapshot?
    private(set) var savedSnapshots: [WorkspaceSessionSnapshot] = []
    private(set) var clearCallCount = 0
    var saveHandler: ((WorkspaceSessionSnapshot) throws -> Void)?
    var clearHandler: (() throws -> Void)?

    func loadCurrentSession() throws -> WorkspaceSessionSnapshot? {
        loadedSnapshot
    }

    func saveCurrentSession(_ snapshot: WorkspaceSessionSnapshot) throws {
        savedSnapshots.append(snapshot)
        if let saveHandler {
            try saveHandler(snapshot)
        }
    }

    func clearCurrentSession() throws {
        clearCallCount += 1
        if let clearHandler {
            try clearHandler()
        }
    }
}

final class DiagnosticsLoggerStub: DiagnosticsLogging {
    private(set) var infos: [String] = []
    private(set) var errors: [String] = []

    func info(_ message: String) {
        infos.append(message)
    }

    func error(_ message: String) {
        errors.append(message)
    }
}

final class AnnotationBookmarkStoreStub: AnnotationBookmarkStoring {
    func annotations(for file: URL) throws -> [AnnotationRecord] { [] }

    func bookmarks(for file: URL) throws -> [BookmarkRecord] { [] }

    func createAnnotation(for file: URL, nodeID: Int64, note: String) throws -> AnnotationRecord {
        AnnotationRecord(id: UUID(), nodeID: nodeID, note: note, createdAt: Date(), updatedAt: Date())
    }

    func updateAnnotation(for file: URL, annotationID: UUID, note: String) throws -> AnnotationRecord {
        AnnotationRecord(id: annotationID, nodeID: nodeIDPlaceholder, note: note, createdAt: Date(), updatedAt: Date())
    }

    func deleteAnnotation(for file: URL, annotationID: UUID) throws {}

    func setBookmark(for file: URL, nodeID: Int64, isBookmarked: Bool) throws {}

    private var nodeIDPlaceholder: Int64 { 0 }
}

struct ImmediateWorkQueue: DocumentSessionWorkQueue {
    func execute(_ work: @escaping () -> Void) {
        work()
    }
}

extension ParsePipeline.EventStream {
    static var finishedStream: ParsePipeline.EventStream {
        AsyncThrowingStream { continuation in
            continuation.finish()
        }
    }
}

final class StubRandomAccessReader: RandomAccessReader {
    let length: Int64 = 0

    func read(at offset: Int64, count: Int) throws -> Data {
        Data(count: count)
    }
}
#endif
