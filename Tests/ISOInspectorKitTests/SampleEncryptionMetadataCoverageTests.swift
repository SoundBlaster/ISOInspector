import XCTest
@testable import ISOInspectorKit

final class SampleEncryptionMetadataCoverageTests: XCTestCase {
    private var catalog: FixtureCatalog!
    private var pipeline: ParsePipeline!

    override func setUpWithError() throws {
        catalog = try FixtureCatalog.load()
        pipeline = .live()
    }

    func testSampleEncryptionFixtureEmitsStructuredMetadata() async throws {
        let fixture = try XCTUnwrap(catalog.fixture(withID: "sample-encryption-placeholder"))
        let data = try fixture.data(in: .module)
        let reader = InMemoryRandomAccessReader(data: data)

        let senc = try FourCharCode("senc")
        let saio = try FourCharCode("saio")
        let saiz = try FourCharCode("saiz")

        var sampleEncryptionBoxes: [ParsedBoxPayload.SampleEncryptionBox] = []
        var auxOffsetBoxes: [ParsedBoxPayload.SampleAuxInfoOffsetsBox] = []
        var auxSizeBoxes: [ParsedBoxPayload.SampleAuxInfoSizesBox] = []

        for try await event in pipeline.events(for: reader, context: .init()) {
            guard case let .willStartBox(header, _) = event.kind else { continue }
            guard let payload = event.payload else { continue }

            switch header.type {
            case senc:
                if let detail = payload.sampleEncryption {
                    sampleEncryptionBoxes.append(detail)
                }
            case saio:
                if let detail = payload.sampleAuxInfoOffsets {
                    auxOffsetBoxes.append(detail)
                }
            case saiz:
                if let detail = payload.sampleAuxInfoSizes {
                    auxSizeBoxes.append(detail)
                }
            default:
                break
            }
        }

        XCTAssertEqual(sampleEncryptionBoxes.count, 1, "Expected one sample encryption box")
        XCTAssertEqual(auxOffsetBoxes.count, 1, "Expected one auxiliary info offsets box")
        XCTAssertEqual(auxSizeBoxes.count, 1, "Expected one auxiliary info sizes box")

        let encryption = try XCTUnwrap(sampleEncryptionBoxes.first)
        XCTAssertEqual(encryption.sampleCount, 2)
        XCTAssertEqual(encryption.algorithmIdentifier, 0x010203)
        XCTAssertEqual(encryption.perSampleIVSize, 8)
        XCTAssertTrue(encryption.overrideTrackEncryptionDefaults)
        XCTAssertTrue(encryption.usesSubsampleEncryption)
        let sampleInfoRange = try XCTUnwrap(encryption.sampleInfoRange)
        XCTAssertEqual(
            encryption.sampleInfoByteLength,
            sampleInfoRange.upperBound - sampleInfoRange.lowerBound
        )

        let offsets = try XCTUnwrap(auxOffsetBoxes.first)
        XCTAssertEqual(offsets.entryCount, 2)
        XCTAssertEqual(offsets.entrySize, .eightBytes)
        XCTAssertEqual(offsets.entriesByteLength, 16)
        XCTAssertEqual(offsets.auxInfoType?.rawValue, "cenc")
        XCTAssertEqual(offsets.auxInfoTypeParameter, 1)

        let sizes = try XCTUnwrap(auxSizeBoxes.first)
        XCTAssertEqual(sizes.entryCount, 2)
        XCTAssertEqual(sizes.defaultSampleInfoSize, 0)
        XCTAssertEqual(sizes.auxInfoType?.rawValue, "cenc")
        XCTAssertEqual(sizes.auxInfoTypeParameter, 1)
        XCTAssertEqual(sizes.variableEntriesByteLength, 2)
    }
}
