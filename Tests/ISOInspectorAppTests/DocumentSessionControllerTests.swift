#if canImport(Combine) && canImport(SwiftUI)
import Combine
import XCTest
@testable import ISOInspectorApp
@testable import ISOInspectorKit

@MainActor
final class DocumentSessionControllerTests: XCTestCase {
    func testInitializerLoadsRecentsFromStore() throws {
        let expected = [sampleRecent(index: 1)]
        let store = DocumentRecentsStoreStub(initialRecents: expected)
        let controller = makeController(store: store)
        XCTAssertEqual(controller.recents, expected)
    }

    func testOpeningDocumentStartsParsingAndUpdatesRecents() throws {
        let store = DocumentRecentsStoreStub(initialRecents: [])
        let controller = makeController(store: store)
        let url = URL(fileURLWithPath: "/tmp/example.mp4")
        var cancellables: Set<AnyCancellable> = []
        let finished = expectation(description: "Parsing finished")

        controller.parseTreeStore.$state
            .dropFirst()
            .sink { state in
                if state == .finished {
                    finished.fulfill()
                }
            }
            .store(in: &cancellables)

        controller.openDocument(at: url)
        wait(for: [finished], timeout: 1.0)

        XCTAssertEqual(controller.recents.first?.url.standardizedFileURL, url.standardizedFileURL)
        XCTAssertEqual(store.savedRecents?.first?.url.standardizedFileURL, url.standardizedFileURL)
        XCTAssertEqual(controller.currentDocument?.url.standardizedFileURL, url.standardizedFileURL)
        XCTAssertEqual(controller.parseTreeStore.fileURL?.standardizedFileURL, url.standardizedFileURL)
        XCTAssertEqual(controller.parseTreeStore.state, .finished)
    }

    func testInitializerRestoresSessionSnapshotAndPersistsUpdates() throws {
        let recentsStore = DocumentRecentsStoreStub(initialRecents: [])
        let sessionStore = WorkspaceSessionStoreStub()
        let annotationStore = AnnotationBookmarkStoreStub()

        let focusURL = URL(fileURLWithPath: "/tmp/focus.mp4")
        let otherURL = URL(fileURLWithPath: "/tmp/other.mp4")

        let focusRecent = DocumentRecent(
            url: focusURL,
            bookmarkData: Data([0x01]),
            displayName: "Focus",
            lastOpened: Date(timeIntervalSince1970: 10)
        )
        let otherRecent = DocumentRecent(
            url: otherURL,
            bookmarkData: nil,
            displayName: "Other",
            lastOpened: Date(timeIntervalSince1970: 5)
        )

        sessionStore.loadedSnapshot = WorkspaceSessionSnapshot(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            createdAt: Date(timeIntervalSince1970: 1),
            updatedAt: Date(timeIntervalSince1970: 2),
            appVersion: "1.0",
            files: [
                WorkspaceSessionFileSnapshot(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!,
                    recent: focusRecent,
                    orderIndex: 0,
                    lastSelectionNodeID: 99,
                    isPinned: false,
                    scrollOffset: nil,
                    bookmarkDiffs: []
                ),
                WorkspaceSessionFileSnapshot(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!,
                    recent: otherRecent,
                    orderIndex: 1,
                    lastSelectionNodeID: nil,
                    isPinned: false,
                    scrollOffset: nil,
                    bookmarkDiffs: []
                )
            ],
            focusedFileURL: focusURL,
            lastSceneIdentifier: nil,
            windowLayouts: []
        )

        let controller = makeController(
            store: recentsStore,
            sessionStore: sessionStore,
            annotationsStore: annotationStore
        )

        XCTAssertEqual(controller.recents.count, 2)
        XCTAssertEqual(controller.recents.first?.url.standardizedFileURL, focusURL.standardizedFileURL)
        XCTAssertEqual(controller.currentDocument?.url.standardizedFileURL, focusURL.standardizedFileURL)
        XCTAssertEqual(controller.annotations.currentSelectedNodeID, 99)
        XCTAssertEqual(sessionStore.savedSnapshots.count, 1)
        let persisted = try XCTUnwrap(sessionStore.savedSnapshots.first)
        XCTAssertEqual(persisted.files.count, 2)
        XCTAssertEqual(persisted.files.first?.lastSelectionNodeID, 99)
    }

    func testSelectionChangePersistsUpdatedSession() throws {
        let recentsStore = DocumentRecentsStoreStub(initialRecents: [])
        let sessionStore = WorkspaceSessionStoreStub()
        let annotationStore = AnnotationBookmarkStoreStub()
        let controller = makeController(
            store: recentsStore,
            sessionStore: sessionStore,
            annotationsStore: annotationStore
        )

        let url = URL(fileURLWithPath: "/tmp/example.mp4")
        controller.openDocument(at: url)
        XCTAssertEqual(sessionStore.savedSnapshots.count, 1)

        controller.annotations.setSelectedNode(123)

        XCTAssertEqual(sessionStore.savedSnapshots.count, 2)
        XCTAssertEqual(sessionStore.savedSnapshots.last?.files.first?.lastSelectionNodeID, 123)
    }

    private func makeController(
        store: DocumentRecentsStoring,
        sessionStore: WorkspaceSessionStoring? = nil,
        annotationsStore: AnnotationBookmarkStoring? = nil
    ) -> DocumentSessionController {
        DocumentSessionController(
            parseTreeStore: ParseTreeStore(bridge: ParsePipelineEventBridge()),
            annotations: AnnotationBookmarkSession(store: annotationsStore),
            recentsStore: store,
            sessionStore: sessionStore,
            pipelineFactory: { ParsePipeline(buildStream: { _, _ in .finishedStream }) },
            readerFactory: { _ in StubRandomAccessReader() },
            workQueue: ImmediateWorkQueue()
        )
    }

    private func sampleRecent(index: Int) -> DocumentRecent {
        DocumentRecent(
            url: URL(fileURLWithPath: "/tmp/sample-\(index).mp4"),
            bookmarkData: nil,
            displayName: "Sample \(index)",
            lastOpened: Date(timeIntervalSince1970: TimeInterval(index))
        )
    }
}

private extension ParsePipeline.EventStream {
    static var finishedStream: ParsePipeline.EventStream {
        AsyncThrowingStream { continuation in
            continuation.finish()
        }
    }
}

private final class StubRandomAccessReader: RandomAccessReader {
    let length: Int64 = 0

    func read(at offset: Int64, count: Int) throws -> Data {
        Data(count: count)
    }
}

private final class DocumentRecentsStoreStub: DocumentRecentsStoring {
    var initialRecents: [DocumentRecent]
    private(set) var savedRecents: [DocumentRecent]?

    init(initialRecents: [DocumentRecent]) {
        self.initialRecents = initialRecents
    }

    func load() throws -> [DocumentRecent] {
        initialRecents
    }

    func save(_ recents: [DocumentRecent]) throws {
        savedRecents = recents
    }
}

private final class WorkspaceSessionStoreStub: WorkspaceSessionStoring {
    var loadedSnapshot: WorkspaceSessionSnapshot?
    private(set) var savedSnapshots: [WorkspaceSessionSnapshot] = []
    private(set) var clearCallCount = 0

    func loadCurrentSession() throws -> WorkspaceSessionSnapshot? {
        loadedSnapshot
    }

    func saveCurrentSession(_ snapshot: WorkspaceSessionSnapshot) throws {
        savedSnapshots.append(snapshot)
    }

    func clearCurrentSession() throws {
        clearCallCount += 1
    }
}

private final class AnnotationBookmarkStoreStub: AnnotationBookmarkStoring {
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

private struct ImmediateWorkQueue: DocumentSessionWorkQueue {
    func execute(_ work: @escaping () -> Void) {
        work()
    }
}
#endif
