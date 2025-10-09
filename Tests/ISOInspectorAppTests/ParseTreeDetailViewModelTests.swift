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
        let viewModel = ParseTreeDetailViewModel(hexSliceProvider: provider, windowSize: 16)

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
    }

    func testHexSliceRequestsPayloadWindow() async throws {
        let node = ParseTreeNode(
            header: makeHeader(identifier: 1, type: "mdat", payloadLength: 512),
            metadata: nil,
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
        let viewModel = ParseTreeDetailViewModel(hexSliceProvider: provider, windowSize: 64)

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
            validationIssues: [],
            children: []
        )
        let snapshot = ParseTreeSnapshot(nodes: [node], validationIssues: [])
        let subject = PassthroughSubject<ParseTreeSnapshot, Never>()
        let provider = HexSliceProviderStub(result: HexSlice(offset: node.header.payloadRange.lowerBound, bytes: Data([0x00])))
        let viewModel = ParseTreeDetailViewModel(hexSliceProvider: provider, windowSize: 32)

        viewModel.bind(to: subject.eraseToAnyPublisher())
        subject.send(snapshot)
        await Task.yield()

        viewModel.select(nodeID: node.id)
        try await Task.sleep(nanoseconds: 20_000_000)

        viewModel.select(nodeID: nil)
        await Task.yield()

        XCTAssertNil(viewModel.detail)
        XCTAssertNil(viewModel.hexError)
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
#endif
