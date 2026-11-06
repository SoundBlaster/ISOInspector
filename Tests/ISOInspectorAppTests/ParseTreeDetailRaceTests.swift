#if canImport(Combine)
    import Foundation
    import XCTest
    import ISOInspectorKit
    @testable import ISOInspectorApp

    @MainActor final class ParseTreeDetailRaceTests: XCTestCase {
        func testOldHexResultCannotReplaceNewerRequestForSameNode() async throws {
            let firstStarted = expectation(description: "First hex request started")
            let secondStarted = expectation(description: "Second hex request started")
            let provider = ControlledHexProvider(started: [firstStarted, secondStarted])
            let model = ParseTreeDetailViewModel(hexSliceProvider: provider, annotationProvider: nil)
            let header = BoxHeader(
                type: try FourCharCode("mdat"), totalSize: 32, headerSize: 8,
                payloadRange: 8..<32, range: 0..<32, uuid: nil)
            let node = ParseTreeNode(header: header, metadata: nil, payload: nil, validationIssues: [], children: [])
            model.apply(snapshot: ParseTreeSnapshot(nodes: [node], validationIssues: []))
            model.select(nodeID: node.id)
            let oldTask = try XCTUnwrap(model.hexTask)
            await fulfillment(of: [firstStarted], timeout: 5)
            model.select(nodeID: node.id)
            let newTask = try XCTUnwrap(model.hexTask)
            await fulfillment(of: [secondStarted], timeout: 5)
            await provider.complete(index: 1, slice: HexSlice(offset: 8, bytes: Data([2])))
            await newTask.value
            XCTAssertEqual(model.detail?.hexSlice?.bytes, Data([2]))
            await provider.complete(index: 0, slice: HexSlice(offset: 8, bytes: Data([1])))
            await oldTask.value
            XCTAssertEqual(model.detail?.hexSlice?.bytes, Data([2]))
        }

        func testOldHexErrorCannotReplaceNewerSuccess() async throws {
            let first = expectation(description: "First hex request started")
            let second = expectation(description: "Second hex request started")
            let provider = ControlledHexProvider(started: [first, second])
            let model = ParseTreeDetailViewModel(hexSliceProvider: provider, annotationProvider: nil)
            let header = BoxHeader(
                type: try FourCharCode("mdat"), totalSize: 32, headerSize: 8,
                payloadRange: 8..<32, range: 0..<32, uuid: nil)
            let node = ParseTreeNode(header: header, metadata: nil, payload: nil, validationIssues: [], children: [])
            model.apply(snapshot: ParseTreeSnapshot(nodes: [node], validationIssues: []))
            model.select(nodeID: node.id)
            let oldTask = try XCTUnwrap(model.hexTask)
            await fulfillment(of: [first], timeout: 5)
            model.select(nodeID: node.id)
            let newTask = try XCTUnwrap(model.hexTask)
            await fulfillment(of: [second], timeout: 5)
            await provider.complete(index: 1, slice: HexSlice(offset: 8, bytes: Data([2])))
            await newTask.value
            await provider.fail(index: 0)
            await oldTask.value
            XCTAssertNil(model.hexError)
            XCTAssertEqual(model.detail?.hexSlice?.bytes, Data([2]))
        }

        func testOldAnnotationsCannotReplaceNewerRequestForSameNode() async throws {
            let first = expectation(description: "First annotations request started")
            let second = expectation(description: "Second annotations request started")
            let provider = ControlledAnnotationProvider(started: [first, second])
            let model = ParseTreeDetailViewModel(hexSliceProvider: nil, annotationProvider: provider)
            let header = BoxHeader(
                type: try FourCharCode("mdat"), totalSize: 32, headerSize: 8,
                payloadRange: 8..<32, range: 0..<32, uuid: nil)
            let node = ParseTreeNode(header: header, metadata: nil, payload: nil, validationIssues: [], children: [])
            model.apply(snapshot: ParseTreeSnapshot(nodes: [node], validationIssues: []))
            model.select(nodeID: node.id)
            let oldTask = try XCTUnwrap(model.annotationTask)
            await fulfillment(of: [first], timeout: 5)
            model.select(nodeID: node.id)
            let newTask = try XCTUnwrap(model.annotationTask)
            await fulfillment(of: [second], timeout: 5)
            let newer = PayloadAnnotation(label: "new", value: "2", byteRange: 8..<9)
            let older = PayloadAnnotation(label: "old", value: "1", byteRange: 8..<9)
            await provider.complete(index: 1, annotations: [newer])
            await newTask.value
            await provider.complete(index: 0, annotations: [older])
            await oldTask.value
            XCTAssertEqual(model.annotations, [newer])
        }

        func testHexCancellationIsNotReportedAsFailure() async throws {
            let started = expectation(description: "Hex request started")
            let provider = ControlledHexProvider(started: [started])
            let model = ParseTreeDetailViewModel(hexSliceProvider: provider, annotationProvider: nil)
            let header = BoxHeader(
                type: try FourCharCode("mdat"), totalSize: 32, headerSize: 8,
                payloadRange: 8..<32, range: 0..<32, uuid: nil)
            let node = ParseTreeNode(header: header, metadata: nil, payload: nil, validationIssues: [], children: [])
            model.apply(snapshot: ParseTreeSnapshot(nodes: [node], validationIssues: []))
            model.select(nodeID: node.id)
            let task = try XCTUnwrap(model.hexTask)
            await fulfillment(of: [started], timeout: 5)
            await provider.cancel(index: 0)
            await task.value
            XCTAssertNil(model.hexError)
        }
    }

    private actor ControlledHexProvider: HexSliceProvider {
        private let started: [XCTestExpectation]
        private var pending: [CheckedContinuation<HexSlice, Error>] = []

        init(started: [XCTestExpectation]) { self.started = started }

        func loadSlice(for request: HexSliceRequest) async throws -> HexSlice {
            try await withCheckedThrowingContinuation { continuation in
                pending.append(continuation)
                started[pending.count - 1].fulfill()
            }
        }

        func complete(index: Int, slice: HexSlice) { pending[index].resume(returning: slice) }
        func fail(index: Int) { pending[index].resume(throwing: RaceFailure()) }
        func cancel(index: Int) { pending[index].resume(throwing: CancellationError()) }
    }

    private struct RaceFailure: Error {}

    private actor ControlledAnnotationProvider: PayloadAnnotationProvider {
        private let started: [XCTestExpectation]
        private var pending: [CheckedContinuation<[PayloadAnnotation], Error>] = []
        init(started: [XCTestExpectation]) { self.started = started }
        func annotations(for header: BoxHeader) async throws -> [PayloadAnnotation] {
            try await withCheckedThrowingContinuation { continuation in
                pending.append(continuation)
                started[pending.count - 1].fulfill()
            }
        }
        func complete(index: Int, annotations: [PayloadAnnotation]) {
            pending[index].resume(returning: annotations)
        }
    }
#endif
