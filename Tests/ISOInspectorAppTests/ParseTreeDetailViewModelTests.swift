#if canImport(Combine)
import Combine
import XCTest
@testable import ISOInspectorApp
import ISOInspectorKit

@MainActor
final class ParseTreeDetailViewModelTests: XCTestCase {
    func testSelectingNodePublishesDetailAndHexSlice() async throws {
        let header = makeHeader(identifier: 1, type: "moov", payloadLength: 32)
        let metadata = BoxCatalog.shared.descriptor(for: header)
        let node = ParseTreeNode(
            header: header,
            metadata: metadata,
            payload: nil,
            validationIssues: [
                ValidationIssue(ruleID: "VR-001", message: "problem", severity: .warning)
            ],
            children: []
        )
        let snapshot = ParseTreeSnapshot(
            nodes: [node],
            validationIssues: node.validationIssues,
            lastUpdatedAt: Date(timeIntervalSince1970: 123)
        )
        let subject = PassthroughSubject<ParseTreeSnapshot, Never>()
        let provider = HexSliceProviderStub(result: HexSlice(offset: node.header.payloadRange.lowerBound, bytes: Data([0xAA, 0xBB, 0xCC])))
        let annotation = PayloadAnnotation(label: "major_brand", value: "isom", byteRange: node.header.payloadRange.lowerBound..<(node.header.payloadRange.lowerBound + 4))
        let annotations = PayloadAnnotationProviderStub(result: [annotation])
        let viewModel = ParseTreeDetailViewModel(hexSliceProvider: provider, annotationProvider: annotations, windowSize: 16)

        viewModel.bind(to: subject.eraseToAnyPublisher())

        subject.send(snapshot)
        await Task.yield()

        viewModel.select(nodeID: node.id)
        try await Task.sleep(nanoseconds: 20_000_000)

        guard let detail = viewModel.detail else {
            XCTFail("Expected detail to be populated")
            return
        }

        XCTAssertEqual(detail.header, node.header)
        XCTAssertEqual(detail.metadata, metadata)
        XCTAssertEqual(detail.validationIssues, node.validationIssues)
        XCTAssertEqual(detail.snapshotTimestamp, snapshot.lastUpdatedAt)
        XCTAssertEqual(detail.hexSlice, provider.result)
        XCTAssertNil(viewModel.hexError)
        XCTAssertEqual(viewModel.annotations, [annotation])
        XCTAssertEqual(viewModel.selectedAnnotationID, annotation.id)
        XCTAssertEqual(viewModel.highlightedRange, annotation.byteRange)
    }

    func testAnnotationsDeriveFromPayloadWhenAvailable() async throws {
        let header = makeHeader(identifier: 2, type: "ftyp", payloadLength: 16)
        let payload = ParsedBoxPayload(fields: [
            ParsedBoxPayload.Field(
                name: "major_brand",
                value: "isom",
                description: "Primary brand",
                byteRange: header.payloadRange.lowerBound..<(header.payloadRange.lowerBound + 4)
            )
        ])
        let node = ParseTreeNode(
            header: header,
            metadata: nil,
            payload: payload,
            validationIssues: [],
            children: []
        )
        let snapshot = ParseTreeSnapshot(nodes: [node], validationIssues: [], lastUpdatedAt: Date())
        let subject = PassthroughSubject<ParseTreeSnapshot, Never>()
        let provider = HexSliceProviderStub(result: HexSlice(offset: header.payloadRange.lowerBound, bytes: Data()))
        let viewModel = ParseTreeDetailViewModel(hexSliceProvider: provider, annotationProvider: nil, windowSize: 16)

        viewModel.bind(to: subject.eraseToAnyPublisher())
        subject.send(snapshot)
        await Task.yield()

        viewModel.select(nodeID: node.id)
        try await Task.sleep(nanoseconds: 20_000_000)

        XCTAssertEqual(viewModel.annotations.count, 1)
        let derived = try XCTUnwrap(viewModel.annotations.first)
        XCTAssertEqual(derived.label, "major_brand")
        XCTAssertEqual(derived.value, "isom")
        XCTAssertEqual(derived.byteRange, payload.fields.first?.byteRange)
        XCTAssertNil(viewModel.annotationError)
        XCTAssertEqual(viewModel.selectedAnnotationID, derived.id)
        XCTAssertEqual(viewModel.highlightedRange, derived.byteRange)
    }

    func testHexSliceRequestsPayloadWindow() async throws {
        let node = ParseTreeNode(
            header: makeHeader(identifier: 1, type: "mdat", payloadLength: 512),
            metadata: nil,
            payload: nil,
            validationIssues: [],
            children: []
        )
        let snapshot = ParseTreeSnapshot(
            nodes: [node],
            validationIssues: [],
            lastUpdatedAt: Date()
        )
        let subject = PassthroughSubject<ParseTreeSnapshot, Never>()
        let provider = HexSliceProviderStub(result: HexSlice(offset: node.header.payloadRange.lowerBound, bytes: Data([0x00])))
        let viewModel = ParseTreeDetailViewModel(hexSliceProvider: provider, annotationProvider: nil, windowSize: 64)

        viewModel.bind(to: subject.eraseToAnyPublisher())
        subject.send(snapshot)
        await Task.yield()

        viewModel.select(nodeID: node.id)
        try await Task.sleep(nanoseconds: 20_000_000)

        XCTAssertEqual(provider.requests.count, 1)
        XCTAssertEqual(provider.requests.first?.header, node.header)
        XCTAssertEqual(provider.requests.first?.window.offset, node.header.payloadRange.lowerBound)
        XCTAssertEqual(provider.requests.first?.window.length, 64)
    }

    func testClearingSelectionResetsDetail() async throws {
        let node = ParseTreeNode(
            header: makeHeader(identifier: 1, type: "trak", payloadLength: 40),
            metadata: nil,
            payload: nil,
            validationIssues: [],
            children: []
        )
        let snapshot = ParseTreeSnapshot(nodes: [node], validationIssues: [])
        let subject = PassthroughSubject<ParseTreeSnapshot, Never>()
        let provider = HexSliceProviderStub(result: HexSlice(offset: node.header.payloadRange.lowerBound, bytes: Data([0x00])))
        let viewModel = ParseTreeDetailViewModel(hexSliceProvider: provider, annotationProvider: nil, windowSize: 32)

        viewModel.bind(to: subject.eraseToAnyPublisher())
        subject.send(snapshot)
        await Task.yield()

        viewModel.select(nodeID: node.id)
        try await Task.sleep(nanoseconds: 20_000_000)

        viewModel.select(nodeID: nil)
        await Task.yield()

        XCTAssertNil(viewModel.detail)
        XCTAssertNil(viewModel.hexError)
        XCTAssertTrue(viewModel.annotations.isEmpty)
        XCTAssertNil(viewModel.selectedAnnotationID)
        XCTAssertNil(viewModel.highlightedRange)
    }

    func testSelectingAnnotationUpdatesHighlight() async throws {
        let node = ParseTreeNode(
            header: makeHeader(identifier: 1, type: "ftyp", payloadLength: 16),
            metadata: nil,
            payload: nil,
            validationIssues: [],
            children: []
        )
        let snapshot = ParseTreeSnapshot(nodes: [node], validationIssues: [], lastUpdatedAt: Date())
        let subject = PassthroughSubject<ParseTreeSnapshot, Never>()
        let provider = HexSliceProviderStub(result: HexSlice(offset: node.header.payloadRange.lowerBound, bytes: Data(repeating: 0x00, count: 16)))
        let annotationA = PayloadAnnotation(label: "fieldA", value: "value", byteRange: node.header.payloadRange.lowerBound..<(node.header.payloadRange.lowerBound + 2))
        let annotationB = PayloadAnnotation(label: "fieldB", value: "value", byteRange: (node.header.payloadRange.lowerBound + 2)..<(node.header.payloadRange.lowerBound + 4))
        let annotations = PayloadAnnotationProviderStub(result: [annotationA, annotationB])
        let viewModel = ParseTreeDetailViewModel(hexSliceProvider: provider, annotationProvider: annotations, windowSize: 32)

        viewModel.bind(to: subject.eraseToAnyPublisher())
        subject.send(snapshot)
        await Task.yield()

        viewModel.select(nodeID: node.id)
        try await Task.sleep(nanoseconds: 30_000_000)

        viewModel.select(annotationID: annotationB.id)

        XCTAssertEqual(viewModel.selectedAnnotationID, annotationB.id)
        XCTAssertEqual(viewModel.highlightedRange, annotationB.byteRange)
    }

    func testSelectingByteUpdatesAnnotationSelection() async throws {
        let node = ParseTreeNode(
            header: makeHeader(identifier: 1, type: "ftyp", payloadLength: 16),
            metadata: nil,
            payload: nil,
            validationIssues: [],
            children: []
        )
        let snapshot = ParseTreeSnapshot(nodes: [node], validationIssues: [], lastUpdatedAt: Date())
        let subject = PassthroughSubject<ParseTreeSnapshot, Never>()
        let provider = HexSliceProviderStub(result: HexSlice(offset: node.header.payloadRange.lowerBound, bytes: Data(repeating: 0x11, count: 16)))
        let annotationA = PayloadAnnotation(label: "fieldA", value: "value", byteRange: node.header.payloadRange.lowerBound..<(node.header.payloadRange.lowerBound + 2))
        let annotationB = PayloadAnnotation(label: "fieldB", value: "value", byteRange: (node.header.payloadRange.lowerBound + 2)..<(node.header.payloadRange.lowerBound + 4))
        let annotations = PayloadAnnotationProviderStub(result: [annotationA, annotationB])
        let viewModel = ParseTreeDetailViewModel(hexSliceProvider: provider, annotationProvider: annotations, windowSize: 32)

        viewModel.bind(to: subject.eraseToAnyPublisher())
        subject.send(snapshot)
        await Task.yield()

        viewModel.select(nodeID: node.id)
        try await Task.sleep(nanoseconds: 30_000_000)

        viewModel.selectByte(at: annotationB.byteRange.lowerBound)

        XCTAssertEqual(viewModel.selectedAnnotationID, annotationB.id)
        XCTAssertEqual(viewModel.highlightedRange, annotationB.byteRange)
    }

    // MARK: - Helpers

    private func makeHeader(identifier: Int64, type: String, payloadLength: Int64) -> BoxHeader {
        let start = identifier * 100
        let headerSize: Int64 = 8
        return BoxHeader(
            type: try! FourCharCode(type),
            totalSize: headerSize + payloadLength,
            headerSize: headerSize,
            payloadRange: (start + headerSize)..<(start + headerSize + payloadLength),
            range: start..<(start + headerSize + payloadLength),
            uuid: nil
        )
    }
}

private final class HexSliceProviderStub: HexSliceProvider {
    private(set) var requests: [HexSliceRequest] = []
    let result: HexSlice

    init(result: HexSlice) {
        self.result = result
    }

    func loadSlice(for request: HexSliceRequest) async throws -> HexSlice {
        requests.append(request)
        return result
    }
}

private final class PayloadAnnotationProviderStub: PayloadAnnotationProvider {
    let result: [PayloadAnnotation]

    init(result: [PayloadAnnotation]) {
        self.result = result
    }

    func annotations(for header: BoxHeader) async throws -> [PayloadAnnotation] {
        result
    }
}
#endif
