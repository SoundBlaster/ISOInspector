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

        let fileType = try XCTUnwrap(parsed.fileType)
        XCTAssertEqual(fileType.majorBrand, try FourCharCode("isom"))
        XCTAssertEqual(fileType.minorVersion, 512)
        XCTAssertEqual(fileType.compatibleBrands, [try FourCharCode("mp41")])
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

    func testDefaultRegistryParsesMovieHeaderVersion1Box() throws {
        var payload = Data()
        payload.append(0x01) // version 1 triggers 64-bit fields
        payload.append(contentsOf: [0x00, 0x00, 0x07])
        payload.append(contentsOf: UInt64(1).bigEndianBytes) // creation
        payload.append(contentsOf: UInt64(2).bigEndianBytes) // modification
        payload.append(contentsOf: UInt32(600).bigEndianBytes) // timescale
        payload.append(contentsOf: UInt64(1200).bigEndianBytes) // duration
        payload.append(contentsOf: UInt32(0x00018000).bigEndianBytes) // rate 1.5
        payload.append(contentsOf: UInt16(0x0100).bigEndianBytes) // volume 1.0
        payload.append(contentsOf: Data(count: 2)) // reserved
        payload.append(contentsOf: Data(count: 8)) // reserved 32-bit fields
        payload.append(contentsOf: Data(count: 36)) // matrix
        payload.append(contentsOf: Data(count: 24)) // predefined
        payload.append(contentsOf: UInt32(42).bigEndianBytes) // next track id

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

        let parsed = try XCTUnwrap(BoxParserRegistry.shared.parse(header: header, reader: reader))

        XCTAssertEqual(value(named: "version", in: parsed), "1")
        XCTAssertEqual(value(named: "flags", in: parsed), "0x000007")
        XCTAssertEqual(value(named: "creation_time", in: parsed), "1")
        XCTAssertEqual(value(named: "modification_time", in: parsed), "2")
        XCTAssertEqual(value(named: "timescale", in: parsed), "600")
        XCTAssertEqual(value(named: "duration", in: parsed), "1200")
        XCTAssertEqual(value(named: "rate", in: parsed), "1.50")
        XCTAssertEqual(value(named: "volume", in: parsed), "1.00")
        XCTAssertEqual(value(named: "next_track_ID", in: parsed), "42")
    }

    func testDefaultRegistryParsesMediaHeaderBoxVersion0() throws {
        var payload = Data()
        payload.append(0x00) // version
        payload.append(contentsOf: [0x00, 0x00, 0x00]) // flags
        payload.append(contentsOf: UInt32(100).bigEndianBytes) // creation
        payload.append(contentsOf: UInt32(200).bigEndianBytes) // modification
        payload.append(contentsOf: UInt32(1000).bigEndianBytes) // timescale
        payload.append(contentsOf: UInt32(5000).bigEndianBytes) // duration
        payload.append(contentsOf: languageBytes("eng")) // language
        payload.append(contentsOf: UInt16(0).bigEndianBytes) // pre-defined

        let totalSize = 8 + payload.count
        let header = BoxHeader(
            type: try FourCharCode("mdhd"),
            totalSize: Int64(totalSize),
            headerSize: 8,
            payloadRange: 8..<Int64(totalSize),
            range: 0..<Int64(totalSize),
            uuid: nil
        )

        var data = Data(count: totalSize)
        data.replaceSubrange(8..<totalSize, with: payload)
        let reader = InMemoryRandomAccessReader(data: data)

        let parsed = try XCTUnwrap(BoxParserRegistry.shared.parse(header: header, reader: reader))
        XCTAssertEqual(value(named: "version", in: parsed), "0")
        XCTAssertEqual(value(named: "flags", in: parsed), "0x000000")
        XCTAssertEqual(value(named: "creation_time", in: parsed), "100")
        XCTAssertEqual(value(named: "modification_time", in: parsed), "200")
        XCTAssertEqual(value(named: "timescale", in: parsed), "1000")
        XCTAssertEqual(value(named: "duration", in: parsed), "5000")
        XCTAssertEqual(value(named: "language", in: parsed), "eng")
        XCTAssertEqual(value(named: "pre_defined", in: parsed), "0")
    }

    func testDefaultRegistryParsesMediaHeaderBoxVersion1() throws {
        var payload = Data()
        payload.append(0x01) // version
        payload.append(contentsOf: [0x00, 0x00, 0x00]) // flags
        payload.append(contentsOf: UInt64(0x0102030405060708).bigEndianBytes) // creation
        payload.append(contentsOf: UInt64(0x1112131415161718).bigEndianBytes) // modification
        payload.append(contentsOf: UInt32(48000).bigEndianBytes) // timescale
        payload.append(contentsOf: UInt64(96000).bigEndianBytes) // duration
        payload.append(contentsOf: languageBytes("jpn")) // language
        payload.append(contentsOf: UInt16(1).bigEndianBytes) // pre-defined

        let totalSize = 8 + payload.count
        let header = BoxHeader(
            type: try FourCharCode("mdhd"),
            totalSize: Int64(totalSize),
            headerSize: 8,
            payloadRange: 8..<Int64(totalSize),
            range: 0..<Int64(totalSize),
            uuid: nil
        )

        var data = Data(count: totalSize)
        data.replaceSubrange(8..<totalSize, with: payload)
        let reader = InMemoryRandomAccessReader(data: data)

        let parsed = try XCTUnwrap(BoxParserRegistry.shared.parse(header: header, reader: reader))
        XCTAssertEqual(value(named: "version", in: parsed), "1")
        XCTAssertEqual(value(named: "flags", in: parsed), "0x000000")
        XCTAssertEqual(value(named: "creation_time", in: parsed), "72623859790382856")
        XCTAssertEqual(value(named: "modification_time", in: parsed), "1230066625199609624")
        XCTAssertEqual(value(named: "timescale", in: parsed), "48000")
        XCTAssertEqual(value(named: "duration", in: parsed), "96000")
        XCTAssertEqual(value(named: "language", in: parsed), "jpn")
        XCTAssertEqual(value(named: "pre_defined", in: parsed), "1")
    }

    func testMediaHeaderParserReturnsNilForShortPayload() throws {
        let payload = Data([0x00, 0x00, 0x00, 0x00])
        let totalSize = 8 + payload.count
        let header = BoxHeader(
            type: try FourCharCode("mdhd"),
            totalSize: Int64(totalSize),
            headerSize: 8,
            payloadRange: 8..<Int64(totalSize),
            range: 0..<Int64(totalSize),
            uuid: nil
        )
        var data = Data(count: totalSize)
        data.replaceSubrange(8..<totalSize, with: payload)
        let reader = InMemoryRandomAccessReader(data: data)

        XCTAssertNil(try BoxParserRegistry.shared.parse(header: header, reader: reader))
    }

    func testDefaultRegistryParsesHandlerBoxWithNullTerminatedName() throws {
        var payload = Data()
        payload.append(0x00) // version
        payload.append(contentsOf: [0x00, 0x00, 0x00]) // flags
        payload.append(contentsOf: UInt32(0).bigEndianBytes) // pre-defined
        payload.append(contentsOf: "vide".utf8) // handler type
        payload.append(contentsOf: Data(count: 12)) // reserved
        payload.append(contentsOf: "Video Handler".utf8)
        payload.append(0x00) // null terminator

        let totalSize = 8 + payload.count
        let header = BoxHeader(
            type: try FourCharCode("hdlr"),
            totalSize: Int64(totalSize),
            headerSize: 8,
            payloadRange: 8..<Int64(totalSize),
            range: 0..<Int64(totalSize),
            uuid: nil
        )

        var data = Data(count: totalSize)
        data.replaceSubrange(8..<totalSize, with: payload)
        let reader = InMemoryRandomAccessReader(data: data)

        let parsed = try XCTUnwrap(BoxParserRegistry.shared.parse(header: header, reader: reader))

        XCTAssertEqual(value(named: "version", in: parsed), "0")
        XCTAssertEqual(value(named: "flags", in: parsed), "0x000000")
        XCTAssertEqual(value(named: "pre_defined", in: parsed), "0")
        XCTAssertEqual(value(named: "handler_type", in: parsed), "vide")
        XCTAssertEqual(value(named: "handler_category", in: parsed), "Video")
        XCTAssertEqual(value(named: "handler_name", in: parsed), "Video Handler")
    }

    func testDefaultRegistryParsesHandlerBoxWithoutTerminator() throws {
        var payload = Data()
        payload.append(0x00) // version
        payload.append(contentsOf: [0x00, 0x00, 0x00]) // flags
        payload.append(contentsOf: UInt32(0).bigEndianBytes) // pre-defined
        payload.append(contentsOf: "soun".utf8) // handler type
        payload.append(contentsOf: Data(count: 12)) // reserved
        payload.append(contentsOf: "Sound Handler".utf8)

        let totalSize = 8 + payload.count
        let header = BoxHeader(
            type: try FourCharCode("hdlr"),
            totalSize: Int64(totalSize),
            headerSize: 8,
            payloadRange: 8..<Int64(totalSize),
            range: 0..<Int64(totalSize),
            uuid: nil
        )

        var data = Data(count: totalSize)
        data.replaceSubrange(8..<totalSize, with: payload)
        let reader = InMemoryRandomAccessReader(data: data)

        let parsed = try XCTUnwrap(BoxParserRegistry.shared.parse(header: header, reader: reader))

        XCTAssertEqual(value(named: "handler_type", in: parsed), "soun")
        XCTAssertEqual(value(named: "handler_category", in: parsed), "Audio")
        XCTAssertEqual(value(named: "handler_name", in: parsed), "Sound Handler")
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

    func testDefaultRegistryParsesTrackHeaderVersion1Box() throws {
        var payload = Data()
        payload.append(0x01) // version 1
        payload.append(contentsOf: [0x00, 0x00, 0x05]) // flags
        payload.append(contentsOf: UInt64(10).bigEndianBytes) // creation
        payload.append(contentsOf: UInt64(11).bigEndianBytes) // modification
        payload.append(contentsOf: UInt32(12).bigEndianBytes) // track id
        payload.append(contentsOf: UInt32(0).bigEndianBytes) // reserved
        payload.append(contentsOf: UInt64(900).bigEndianBytes) // duration
        payload.append(contentsOf: Data(count: 8)) // reserved
        payload.append(contentsOf: Int16(0).bigEndianBytes) // layer
        payload.append(contentsOf: Int16(2).bigEndianBytes) // alternate group
        payload.append(contentsOf: UInt16(0x0100).bigEndianBytes) // volume 1.0
        payload.append(contentsOf: Data(count: 2)) // reserved
        payload.append(contentsOf: Data(count: 36)) // matrix
        payload.append(contentsOf: Data(count: 24)) // predefined
        payload.append(contentsOf: UInt32(42).bigEndianBytes) // next track id
        payload.append(contentsOf: UInt32(1920 << 16).bigEndianBytes) // width 1920
        payload.append(contentsOf: UInt32(1080 << 16).bigEndianBytes) // height 1080

        let totalSize = 8 + payload.count
        let header = BoxHeader(
            type: try FourCharCode("tkhd"),
            totalSize: Int64(totalSize),
            headerSize: 8,
            payloadRange: 8..<Int64(totalSize),
            range: 0..<Int64(totalSize),
            uuid: nil
        )

        var data = Data(count: totalSize)
        data.replaceSubrange(8..<totalSize, with: payload)
        let reader = InMemoryRandomAccessReader(data: data)

        let parsed = try XCTUnwrap(BoxParserRegistry.shared.parse(header: header, reader: reader))

        XCTAssertEqual(value(named: "version", in: parsed), "1")
        XCTAssertEqual(value(named: "track_id", in: parsed), "12")
        XCTAssertEqual(value(named: "duration", in: parsed), "900")
        XCTAssertEqual(value(named: "alternate_group", in: parsed), "2")
        XCTAssertEqual(value(named: "volume", in: parsed), "1.00")
        XCTAssertEqual(value(named: "next_track_ID", in: parsed), "42")
        XCTAssertEqual(value(named: "width", in: parsed), "1920.00")
        XCTAssertEqual(value(named: "height", in: parsed), "1080.00")
    }

    private func languageBytes(_ code: String) -> [UInt8] {
        precondition(code.count == 3, "language code must be 3 letters")
        let scalars = code.unicodeScalars.map { UInt16($0.value) - 0x60 }
        let packed = UInt16(((scalars[0] & 0x1F) << 10) | ((scalars[1] & 0x1F) << 5) | (scalars[2] & 0x1F))
        return packed.bigEndianBytes
    }

    private func value(named name: String, in payload: ParsedBoxPayload) -> String? {
        payload.fields.first(where: { $0.name == name })?.value
    }
}

private extension FixedWidthInteger {
    var bigEndianBytes: [UInt8] {
        withUnsafeBytes(of: self.bigEndian, Array.init)
    }
}
