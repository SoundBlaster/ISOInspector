#if canImport(Combine)
    import Combine
    import Foundation
    import XCTest

    @testable import ISOInspectorApp
    @testable import ISOInspectorKit

    final class DocumentReaderIntegrationTests: XCTestCase {
        @MainActor func testLiveParseLoadsSelectedNodeBytes() {
            let data = Data([
                0, 0, 0, 16, 0x66, 0x74, 0x79, 0x70,
                0x69, 0x73, 0x6f, 0x6d, 0, 0, 0, 1,
            ])
            let store = ParseTreeStore()
            let viewModel = DocumentViewModel(
                store: store, annotations: AnnotationBookmarkSession(store: nil))
            let loaded = expectation(description: "Selected node hex bytes loaded")
            var subscriptions: Set<AnyCancellable> = []
            viewModel.detailViewModel.$detail.compactMap { $0?.hexSlice }
                .filter { $0.offset == 8 && $0.bytes == data.subdata(in: 8..<16) }
                .first()
                .sink { _ in loaded.fulfill() }
                .store(in: &subscriptions)

            store.start(pipeline: .live(), reader: InMemoryRandomAccessReader(data: data))
            wait(for: [loaded], timeout: 3)
            XCTAssertNil(viewModel.detailViewModel.hexError)
            store.shutdown()
        }
    }
#endif
