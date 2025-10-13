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

    private func makeController(store: DocumentRecentsStoring) -> DocumentSessionController {
        DocumentSessionController(
            parseTreeStore: ParseTreeStore(bridge: ParsePipelineEventBridge()),
            annotations: AnnotationBookmarkSession(store: nil),
            recentsStore: store,
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

private struct ImmediateWorkQueue: DocumentSessionWorkQueue {
    func execute(_ work: @escaping () -> Void) {
        work()
    }
}
#endif
