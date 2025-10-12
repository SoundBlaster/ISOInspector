import Foundation
import XCTest
@testable import ISOInspectorKit

final class BoxParserRegistryTests: XCTestCase {
    func testDefaultRegistryParsesFileTypeBox() throws {
        let payload = Data("isom".utf8) + Data([0x00, 0x00, 0x02, 0x00]) + Data("mp41".utf8)
        let totalSize = 8 + payload.count
        let header = BoxHeader(
            type: try FourCharCode("ftyp"),
            totalSize: Int64(totalSize),
            headerSize: 8,
            payloadRange: 8..<Int64(totalSize),
            range: 0..<Int64(totalSize),
            uuid: nil
        )

        var data = Data(count: totalSize)
        data.replaceSubrange(8..<totalSize, with: payload)
        let reader = InMemoryRandomAccessReader(data: data)

        let registry = BoxParserRegistry.shared
        let parsed = try XCTUnwrap(registry.parse(header: header, reader: reader))

        XCTAssertEqual(parsed.fields.map(\.name), ["major_brand", "minor_version", "compatible_brand[0]"])
        XCTAssertEqual(parsed.fields[0].value, "isom")
        XCTAssertEqual(parsed.fields[0].byteRange, 8..<12)
        XCTAssertEqual(parsed.fields[1].value, "512")
        XCTAssertEqual(parsed.fields[1].byteRange, 12..<16)
        XCTAssertEqual(parsed.fields[2].value, "mp41")
        XCTAssertEqual(parsed.fields[2].byteRange, 16..<20)
    }

    func testDefaultRegistryParsesMovieHeaderBox() throws {
        var payload = Data()
        payload.append(0x00) // version
        payload.append(contentsOf: [0x00, 0x00, 0x07]) // flags
        payload.append(contentsOf: UInt32(1).bigEndianBytes) // creation
        payload.append(contentsOf: UInt32(2).bigEndianBytes) // modification
        payload.append(contentsOf: UInt32(600).bigEndianBytes) // timescale
        payload.append(contentsOf: UInt32(1200).bigEndianBytes) // duration
        payload.append(contentsOf: UInt32(0x00010000).bigEndianBytes) // rate 1.0
        payload.append(contentsOf: UInt16(0x0100).bigEndianBytes) // volume 1.0
        payload.append(contentsOf: Data(count: 10)) // reserved
        payload.append(contentsOf: Data(count: 36)) // matrix
        payload.append(contentsOf: Data(count: 24)) // pre-defined
        payload.append(contentsOf: UInt32(99).bigEndianBytes) // next track id

        let totalSize = 8 + payload.count
        let header = BoxHeader(
            type: try FourCharCode("mvhd"),
            totalSize: Int64(totalSize),
            headerSize: 8,
            payloadRange: 8..<Int64(totalSize),
            range: 0..<Int64(totalSize),
            uuid: nil
        )

        var data = Data(count: totalSize)
        data.replaceSubrange(8..<totalSize, with: payload)
        let reader = InMemoryRandomAccessReader(data: data)

        let registry = BoxParserRegistry.shared
        let parsed = try XCTUnwrap(registry.parse(header: header, reader: reader))
        let fieldNames = parsed.fields.map(\.name)
        XCTAssertTrue(fieldNames.contains("timescale"))
        XCTAssertTrue(fieldNames.contains("duration"))
        XCTAssertTrue(fieldNames.contains("rate"))
        XCTAssertTrue(fieldNames.contains("volume"))
        XCTAssertEqual(parsed.fields.first(where: { $0.name == "timescale" })?.value, "600")
        XCTAssertEqual(parsed.fields.first(where: { $0.name == "duration" })?.value, "1200")
    }

    func testRegistryAllowsOverrides() throws {
        var registry = BoxParserRegistry()
        let customType = try FourCharCode("cust")
        registry.register(parser: { header, _ in
            ParsedBoxPayload(fields: [
                ParsedBoxPayload.Field(
                    name: "identifier",
                    value: header.identifierString,
                    description: nil,
                    byteRange: nil
                )
            ])
        }, for: customType)

        let header = BoxHeader(
            type: customType,
            totalSize: 8,
            headerSize: 8,
            payloadRange: 8..<8,
            range: 0..<8,
            uuid: nil
        )
        let reader = InMemoryRandomAccessReader(data: Data(count: 8))

        let parsed = try XCTUnwrap(registry.parse(header: header, reader: reader))
        XCTAssertEqual(parsed.fields.first?.value, "cust")
    }
}

private extension FixedWidthInteger {
    var bigEndianBytes: [UInt8] {
        withUnsafeBytes(of: self.bigEndian, Array.init)
    }
}
