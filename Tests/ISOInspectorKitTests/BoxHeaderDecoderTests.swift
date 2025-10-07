import XCTest
@testable import ISOInspectorKit

final class BoxHeaderDecoderTests: XCTestCase {
    func testStandardBoxHeaderDecoding() throws {
        var data = Data()
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x18]) // size 24
        data.append(contentsOf: [0x66, 0x74, 0x79, 0x70]) // ftyp
        data.append(contentsOf: Array(repeating: 0x00, count: 16))
        let reader = InMemoryRandomAccessReader(data: data)

        let header = try BoxHeaderDecoder.readHeader(
            from: reader,
            at: 0,
            inParentRange: 0..<Int64(data.count)
        )

        XCTAssertEqual(header.type.rawValue, "ftyp")
        XCTAssertEqual(header.totalSize, 24)
        XCTAssertEqual(header.headerSize, 8)
        XCTAssertEqual(header.payloadRange, 8..<24)
        XCTAssertNil(header.uuid)
    }

    func testLargeSizeHeaderDecoding() throws {
        var data = Data()
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x01])
        data.append(contentsOf: [0x6D, 0x6F, 0x6F, 0x76]) // moov
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x40]) // size 64
        data.append(contentsOf: Array(repeating: 0xFF, count: 64 - 16))
        let reader = InMemoryRandomAccessReader(data: data)

        let header = try BoxHeaderDecoder.readHeader(
            from: reader,
            at: 0,
            inParentRange: 0..<Int64(data.count)
        )

        XCTAssertEqual(header.type.rawValue, FourCharContainerCode.movie.rawValue)
        XCTAssertEqual(header.totalSize, 64)
        XCTAssertEqual(header.headerSize, 16)
        XCTAssertEqual(header.payloadRange, 16..<64)
    }

    func testUUIDBoxHeaderDecoding() throws {
        let uuidBytes: [UInt8] = [
            0x11, 0x22, 0x33, 0x44,
            0x55, 0x66, 0x77, 0x88,
            0x99, 0xAA, 0xBB, 0xCC,
            0xDD, 0xEE, 0xFF, 0x00
        ]
        var data = Data()
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x28]) // size 40
        data.append(contentsOf: [0x75, 0x75, 0x69, 0x64]) // uuid
        data.append(contentsOf: uuidBytes)
        data.append(contentsOf: Array(repeating: 0x00, count: 40 - 24))
        let reader = InMemoryRandomAccessReader(data: data)

        let header = try BoxHeaderDecoder.readHeader(
            from: reader,
            at: 0,
            inParentRange: 0..<Int64(data.count)
        )

        XCTAssertEqual(header.type.rawValue, "uuid")
        XCTAssertEqual(header.headerSize, 24)
        XCTAssertEqual(header.totalSize, 40)
        XCTAssertEqual(header.payloadRange, 24..<40)
        XCTAssertEqual(header.uuid, UUID(uuid: (
            uuidBytes[0], uuidBytes[1], uuidBytes[2], uuidBytes[3],
            uuidBytes[4], uuidBytes[5], uuidBytes[6], uuidBytes[7],
            uuidBytes[8], uuidBytes[9], uuidBytes[10], uuidBytes[11],
            uuidBytes[12], uuidBytes[13], uuidBytes[14], uuidBytes[15]
        )))
    }

    func testZeroSizedBoxExpandsToParentRangeEnd() throws {
        var data = Data()
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])
        data.append(contentsOf: [0x6D, 0x64, 0x61, 0x74]) // mdat
        let reader = InMemoryRandomAccessReader(data: data + Data(repeating: 0xAA, count: 24))

        let header = try BoxHeaderDecoder.readHeader(
            from: reader,
            at: 0,
            inParentRange: 0..<Int64(32)
        )

        XCTAssertEqual(header.totalSize, 32)
        XCTAssertEqual(header.headerSize, 8)
        XCTAssertEqual(header.payloadRange, 8..<32)
    }

    func testZeroSizedBoxWithoutParentRangeThrows() throws {
        var data = Data()
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])
        data.append(contentsOf: [0x6D, 0x64, 0x61, 0x74])
        let reader = InMemoryRandomAccessReader(data: data)

        XCTAssertThrowsError(
            try BoxHeaderDecoder.readHeader(from: reader, at: 0, inParentRange: nil)
        ) { error in
            guard case BoxHeaderDecodingError.zeroSizeWithoutParent = error else {
                XCTFail("Unexpected error: \(error)")
                return
            }
        }
    }

    func testHeaderExtendingBeyondParentThrows() throws {
        var data = Data()
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x20]) // size 32
        data.append(contentsOf: [0x6D, 0x64, 0x61, 0x74])
        data.append(contentsOf: Array(repeating: 0x00, count: 32 - 8))
        let reader = InMemoryRandomAccessReader(data: data)

        XCTAssertThrowsError(
            try BoxHeaderDecoder.readHeader(from: reader, at: 0, inParentRange: 0..<Int64(16))
        ) { error in
            guard case let BoxHeaderDecodingError.exceedsParent(expectedEnd, parentEnd) = error else {
                XCTFail("Unexpected error: \(error)")
                return
            }
            XCTAssertEqual(expectedEnd, 32)
            XCTAssertEqual(parentEnd, 16)
        }
    }

    func testTruncatedHeaderThrows() throws {
        var data = Data()
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x01])
        data.append(contentsOf: [0x6D, 0x64, 0x61, 0x74])
        data.append(contentsOf: [0x00, 0x00, 0x00]) // truncated largesize
        let reader = InMemoryRandomAccessReader(data: data)

        XCTAssertThrowsError(
            try BoxHeaderDecoder.readHeader(from: reader, at: 0, inParentRange: 0..<Int64(64))
        ) { error in
            guard case let BoxHeaderDecodingError.truncatedField(expected, actual) = error else {
                XCTFail("Unexpected error: \(error)")
                return
            }
            XCTAssertEqual(expected, 8)
            XCTAssertEqual(actual, 3)
        }
    }
}
