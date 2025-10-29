#if canImport(AppKit) && canImport(SwiftUI) && canImport(Combine)
import AppKit
import Combine
import SwiftUI
import XCTest
@testable import ISOInspectorApp
@testable import ISOInspectorKit

@MainActor
final class ParseTreeStreamingSelectionAutomationTests: XCTestCase {
    func testStreamingSessionAppliesDefaultSelection() throws {
        let header = BoxHeader(
            type: try IIFourCharCode("ftyp"),
            totalSize: 24,
            headerSize: 8,
            payloadRange: 8..<24,
            range: 0..<24,
            uuid: nil
        )
        let descriptor = BoxDescriptor(
            identifier: .init(type: header.type, extendedType: nil),
            name: "File Type",
            summary: "Baseline",
            category: "format",
            specification: nil,
            version: 0,
            flags: nil
        )
        let events: [ParseEvent] = [
            ParseEvent(kind: .willStartBox(header: header, depth: 0), offset: 0, metadata: descriptor),
            ParseEvent(kind: .didFinishBox(header: header, depth: 0), offset: 24, metadata: descriptor)
        ]
        let pipeline = ParsePipeline(buildStream: { _, _ in
            AsyncThrowingStream { continuation in
                let task = Task {
                    for event in events {
                        try? await Task.sleep(nanoseconds: 10_000_000)
                        continuation.yield(event)
                    }
                    continuation.finish()
                }
                continuation.onTermination = { @Sendable _ in
                    task.cancel()
                }
            }
        })

        let store = ParseTreeStore()
        let annotations = AnnotationBookmarkSession(store: nil)
        let outlineViewModel = ParseTreeOutlineViewModel()
        let detailViewModel = ParseTreeDetailViewModel(hexSliceProvider: nil, annotationProvider: nil)

        let documentViewModel = DocumentViewModel(
            store: store,
            annotations: annotations,
            outlineViewModel: outlineViewModel,
            detailViewModel: detailViewModel
        )

        let view = ParseTreeExplorerView(
            viewModel: documentViewModel
        )
        let hostingView = NSHostingView(rootView: view.frame(width: 800, height: 600))
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        window.makeKeyAndOrderFront(nil)

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

        var cancellables: Set<AnyCancellable> = []

        let outlineExpectation = expectation(description: "Outline rows populated")
        outlineViewModel.$rows
            .dropFirst()
            .sink { rows in
                if let first = rows.first, first.id == header.startOffset {
                    outlineExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        let detailExpectation = expectation(description: "Detail updates for default selection")
        detailViewModel.$detail
            .compactMap { $0?.header }
            .removeDuplicates()
            .sink { emittedHeader in
                if emittedHeader == header {
                    detailExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        let finishedExpectation = expectation(description: "Parsing finished")
        store.$state
            .dropFirst()
            .sink { state in
                if state == .finished {
                    finishedExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        store.start(
            pipeline: pipeline,
            reader: StubReader(data: Data(repeating: 0, count: 64)),
            context: .init(source: URL(fileURLWithPath: "/tmp/sample.mp4"))
        )

        wait(for: [outlineExpectation, detailExpectation, finishedExpectation], timeout: 2.0)

        XCTAssertEqual(detailViewModel.detail?.header, header)
        XCTAssertEqual(outlineViewModel.rows.first?.id, header.startOffset)

        window.close()
    }
}

private struct StubReader: RandomAccessReader {
    let data: Data

    var length: Int64 { Int64(data.count) }

    func read(at offset: Int64, count: Int) throws -> Data {
        let lower = max(0, min(Int(offset), data.count))
        let upper = min(data.count, lower + count)
        return data.subdata(in: lower..<upper)
    }
}
#endif
