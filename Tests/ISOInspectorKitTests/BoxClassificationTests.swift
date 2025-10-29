import XCTest
@testable import ISOInspectorKit

final class BoxClassificationTests: XCTestCase {
    func testMetadataBoxesClassifyAsMetadata() throws {
        let header = try makeHeader(type: "meta")

        let category = BoxClassifier.category(for: header, metadata: nil)

        XCTAssertEqual(category, .metadata)
    }

    func testMediaDataClassifiesAsMedia() throws {
        let header = try makeHeader(type: "mdat")

        let category = BoxClassifier.category(for: header, metadata: nil)

        XCTAssertEqual(category, .media)
    }

    func testStreamingIndicatorsClassifyAsIndexAndFlagged() throws {
        let header = try makeHeader(type: "sidx")

        XCTAssertEqual(BoxClassifier.category(for: header, metadata: nil), .index)
        XCTAssertTrue(BoxClassifier.isStreamingIndicator(header: header))
    }

    func testUnknownTypeFallsBackToOther() throws {
        let header = try makeHeader(type: "free")

        XCTAssertEqual(BoxClassifier.category(for: header, metadata: nil), .other)
    }

    private func makeHeader(type: String) throws -> BoxHeader {
        let fourChar = try IIFourCharCode(type)
        return BoxHeader(
            type: fourChar,
            totalSize: 16,
            headerSize: 8,
            payloadRange: 8..<16,
            range: 0..<16,
            uuid: nil
        )
    }
}
