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
        payload.append(contentsOf: [
            UInt32(0x00010000), // a
            0, // b
            0, // u
            0, // c
            UInt32(0x00010000), // d
            0, // v
            0, // x
            0, // y
            UInt32(0x40000000) // w
        ].flatMap { $0.bigEndianBytes })
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
        XCTAssertEqual(parsed.fields.map(\.name), [
            "version",
            "flags",
            "creation_time",
            "modification_time",
            "timescale",
            "duration",
            "rate",
            "volume",
            "matrix.a",
            "matrix.b",
            "matrix.u",
            "matrix.c",
            "matrix.d",
            "matrix.v",
            "matrix.x",
            "matrix.y",
            "matrix.w",
            "next_track_ID"
        ])
        XCTAssertEqual(value(named: "timescale", in: parsed), "600")
        XCTAssertEqual(value(named: "duration", in: parsed), "1200")
        XCTAssertEqual(value(named: "rate", in: parsed), "1.00")
        XCTAssertEqual(value(named: "volume", in: parsed), "1.00")
        XCTAssertEqual(value(named: "matrix.a", in: parsed), "1.0000")
        XCTAssertEqual(value(named: "matrix.d", in: parsed), "1.0000")
        XCTAssertEqual(value(named: "matrix.w", in: parsed), "1.000000")

        let detail = try XCTUnwrap(parsed.movieHeader)
        XCTAssertEqual(detail.version, 0)
        XCTAssertEqual(detail.creationTime, 1)
        XCTAssertEqual(detail.modificationTime, 2)
        XCTAssertEqual(detail.timescale, 600)
        XCTAssertFalse(detail.durationIs64Bit)
        XCTAssertEqual(detail.duration, 1200)
        XCTAssertEqual(detail.rate, 1.0, accuracy: 0.0001)
        XCTAssertEqual(detail.volume, 1.0, accuracy: 0.0001)
        XCTAssertEqual(detail.matrix, .identity)
        XCTAssertEqual(detail.nextTrackID, 99)
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
        payload.append(contentsOf: [
            UInt32(0x00020000),
            UInt32(0xFFFF0000),
            UInt32(0x20000000),
            UInt32(0x00008000),
            UInt32(0x00010000),
            UInt32(0xE0000000),
            UInt32(0x00000000),
            UInt32(0x00010000),
            UInt32(0x40000000)
        ].flatMap { $0.bigEndianBytes })
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
        XCTAssertEqual(value(named: "matrix.a", in: parsed), "2.0000")
        XCTAssertEqual(value(named: "matrix.b", in: parsed), "-1.0000")
        XCTAssertEqual(value(named: "matrix.u", in: parsed), "0.500000")
        XCTAssertEqual(value(named: "matrix.c", in: parsed), "0.5000")
        XCTAssertEqual(value(named: "matrix.v", in: parsed), "-0.500000")
        XCTAssertEqual(value(named: "matrix.w", in: parsed), "1.000000")
        XCTAssertEqual(value(named: "next_track_ID", in: parsed), "42")

        let detail = try XCTUnwrap(parsed.movieHeader)
        XCTAssertEqual(detail.version, 1)
        XCTAssertEqual(detail.creationTime, 1)
        XCTAssertEqual(detail.modificationTime, 2)
        XCTAssertEqual(detail.timescale, 600)
        XCTAssertTrue(detail.durationIs64Bit)
        XCTAssertEqual(detail.duration, 1200)
        XCTAssertEqual(detail.rate, 1.5, accuracy: 0.0001)
        XCTAssertEqual(detail.volume, 1.0, accuracy: 0.0001)
        XCTAssertEqual(detail.matrix.a, 2.0, accuracy: 0.0001)
        XCTAssertEqual(detail.matrix.b, -1.0, accuracy: 0.0001)
        XCTAssertEqual(detail.matrix.u, 0.5, accuracy: 0.0001)
        XCTAssertEqual(detail.matrix.c, 0.5, accuracy: 0.0001)
        XCTAssertEqual(detail.matrix.v, -0.5, accuracy: 0.0001)
        XCTAssertEqual(detail.matrix.w, 1.0, accuracy: 0.0001)
    }

    func testDefaultRegistryParsesMediaDataBoxRecordsOffsets() throws {
        let payloadLength = 32
        let totalSize = 8 + payloadLength
        let startOffset: Int64 = 2048
        let header = BoxHeader(
            type: try FourCharCode("mdat"),
            totalSize: Int64(totalSize),
            headerSize: 8,
            payloadRange: (startOffset + 8)..<(startOffset + Int64(totalSize)),
            range: startOffset..<(startOffset + Int64(totalSize)),
            uuid: nil
        )

        var data = Data(count: Int(startOffset) + totalSize)
        data.replaceSubrange(Int(startOffset) + 8..<(Int(startOffset) + totalSize), with: Data(count: payloadLength))
        let reader = InMemoryRandomAccessReader(data: data)

        let parsed = try XCTUnwrap(BoxParserRegistry.shared.parse(header: header, reader: reader))

        let mediaData = try XCTUnwrap(parsed.mediaData)
        XCTAssertEqual(mediaData.headerStartOffset, startOffset)
        XCTAssertEqual(mediaData.headerEndOffset, startOffset + 8)
        XCTAssertEqual(mediaData.totalSize, Int64(totalSize))
        XCTAssertEqual(mediaData.payloadRange, (startOffset + 8)..<(startOffset + Int64(totalSize)))
        XCTAssertEqual(mediaData.payloadLength, Int64(payloadLength))
        XCTAssertTrue(parsed.fields.isEmpty)
    }

    func testDefaultRegistryParsesLargeMediaDataBoxRecordsOffsets() throws {
        let payloadLength = 128
        let headerSize: Int64 = 16
        let totalSize = headerSize + Int64(payloadLength)
        let startOffset: Int64 = 8192
        let header = BoxHeader(
            type: try FourCharCode("mdat"),
            totalSize: totalSize,
            headerSize: headerSize,
            payloadRange: (startOffset + headerSize)..<(startOffset + totalSize),
            range: startOffset..<(startOffset + totalSize),
            uuid: nil
        )

        var data = Data(count: Int(startOffset + totalSize))
        let payloadStart = Int(startOffset + headerSize)
        data.replaceSubrange(payloadStart..<payloadStart + payloadLength, with: Data(count: payloadLength))
        let reader = InMemoryRandomAccessReader(data: data)

        let parsed = try XCTUnwrap(BoxParserRegistry.shared.parse(header: header, reader: reader))

        let mediaData = try XCTUnwrap(parsed.mediaData)
        XCTAssertEqual(mediaData.headerStartOffset, startOffset)
        XCTAssertEqual(mediaData.headerEndOffset, startOffset + headerSize)
        XCTAssertEqual(mediaData.totalSize, totalSize)
        XCTAssertEqual(mediaData.payloadRange, (startOffset + headerSize)..<(startOffset + totalSize))
        XCTAssertEqual(mediaData.payloadLength, Int64(payloadLength))
        XCTAssertTrue(parsed.fields.isEmpty)
    }

    func testDefaultRegistryParsesFreeBoxAsPadding() throws {
        let payloadLength = 24
        let totalSize = 8 + payloadLength
        let startOffset: Int64 = 16384
        let header = BoxHeader(
            type: try FourCharCode("free"),
            totalSize: Int64(totalSize),
            headerSize: 8,
            payloadRange: (startOffset + 8)..<(startOffset + Int64(totalSize)),
            range: startOffset..<(startOffset + Int64(totalSize)),
            uuid: nil
        )

        var data = Data(count: Int(startOffset) + totalSize)
        data.replaceSubrange(Int(startOffset) + 8..<(Int(startOffset) + totalSize), with: Data(count: payloadLength))
        let reader = InMemoryRandomAccessReader(data: data)

        let parsed = try XCTUnwrap(BoxParserRegistry.shared.parse(header: header, reader: reader))

        let padding = try XCTUnwrap(parsed.padding)
        XCTAssertEqual(padding.type.rawValue, "free")
        XCTAssertEqual(padding.headerStartOffset, startOffset)
        XCTAssertEqual(padding.headerEndOffset, startOffset + 8)
        XCTAssertEqual(padding.totalSize, Int64(totalSize))
        XCTAssertEqual(padding.payloadRange, (startOffset + 8)..<(startOffset + Int64(totalSize)))
        XCTAssertEqual(padding.payloadLength, Int64(payloadLength))
        XCTAssertTrue(parsed.fields.isEmpty)
    }

    func testDefaultRegistryParsesSkipBoxAsPadding() throws {
        let payloadLength = 0
        let headerSize: Int64 = 8
        let totalSize = headerSize + Int64(payloadLength)
        let startOffset: Int64 = 19456
        let header = BoxHeader(
            type: try FourCharCode("skip"),
            totalSize: totalSize,
            headerSize: headerSize,
            payloadRange: (startOffset + headerSize)..<(startOffset + totalSize),
            range: startOffset..<(startOffset + totalSize),
            uuid: nil
        )

        let reader = InMemoryRandomAccessReader(data: Data(count: Int(startOffset + totalSize)))

        let parsed = try XCTUnwrap(BoxParserRegistry.shared.parse(header: header, reader: reader))

        let padding = try XCTUnwrap(parsed.padding)
        XCTAssertEqual(padding.type.rawValue, "skip")
        XCTAssertEqual(padding.headerStartOffset, startOffset)
        XCTAssertEqual(padding.headerEndOffset, startOffset + headerSize)
        XCTAssertEqual(padding.totalSize, totalSize)
        XCTAssertEqual(padding.payloadRange, (startOffset + headerSize)..<(startOffset + totalSize))
        XCTAssertEqual(padding.payloadLength, 0)
        XCTAssertTrue(parsed.fields.isEmpty)
    }

    func testDefaultRegistryParsesSoundMediaHeaderBox() throws {
        var payload = Data()
        payload.append(0x00) // version
        payload.append(contentsOf: [0x00, 0x00, 0x00]) // flags
        payload.append(contentsOf: UInt16(0x0180).bigEndianBytes) // balance 1.5 in 8.8 fixed
        payload.append(contentsOf: UInt16(0x0000).bigEndianBytes) // reserved

        let totalSize = 8 + payload.count
        let header = BoxHeader(
            type: try FourCharCode("smhd"),
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
        XCTAssertEqual(value(named: "balance", in: parsed), "1.50")
        XCTAssertEqual(value(named: "balance_raw", in: parsed), "384")
        XCTAssertEqual(value(named: "reserved", in: parsed), "0")

        let detail = try XCTUnwrap(parsed.soundMediaHeader)
        XCTAssertEqual(detail.version, 0)
        XCTAssertEqual(detail.flags, 0)
        XCTAssertEqual(detail.balance, 1.5, accuracy: 0.0001)
        XCTAssertEqual(detail.balanceRaw, 0x0180)
    }

    func testDefaultRegistryParsesVideoMediaHeaderBox() throws {
        var payload = Data()
        payload.append(0x00) // version
        payload.append(contentsOf: [0x00, 0x00, 0x01]) // flags with single low bit set
        payload.append(contentsOf: UInt16(0x0002).bigEndianBytes) // graphics mode (component alpha)
        payload.append(contentsOf: UInt16(0x8000).bigEndianBytes) // opcolor red
        payload.append(contentsOf: UInt16(0x4000).bigEndianBytes) // opcolor green
        payload.append(contentsOf: UInt16(0xFFFF).bigEndianBytes) // opcolor blue

        let totalSize = 8 + payload.count
        let header = BoxHeader(
            type: try FourCharCode("vmhd"),
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
        XCTAssertEqual(value(named: "flags", in: parsed), "0x000001")
        XCTAssertEqual(value(named: "graphics_mode", in: parsed), "componentAlpha")
        XCTAssertEqual(value(named: "graphics_mode_raw", in: parsed), "2")
        XCTAssertEqual(value(named: "opcolor.red", in: parsed), "0.5000")
        XCTAssertEqual(value(named: "opcolor.red_raw", in: parsed), "32768")
        XCTAssertEqual(value(named: "opcolor.green", in: parsed), "0.2500")
        XCTAssertEqual(value(named: "opcolor.green_raw", in: parsed), "16384")
        XCTAssertEqual(value(named: "opcolor.blue", in: parsed), "1.0000")
        XCTAssertEqual(value(named: "opcolor.blue_raw", in: parsed), "65535")

        let detail = try XCTUnwrap(parsed.videoMediaHeader)
        XCTAssertEqual(detail.version, 0)
        XCTAssertEqual(detail.flags, 1)
        XCTAssertEqual(detail.graphicsMode, 0x0002)
        XCTAssertEqual(detail.graphicsModeDescription, "componentAlpha")
        XCTAssertEqual(detail.opcolor.red.raw, 0x8000)
        XCTAssertEqual(detail.opcolor.red.normalized, 0.5, accuracy: 0.0001)
        XCTAssertEqual(detail.opcolor.green.raw, 0x4000)
        XCTAssertEqual(detail.opcolor.green.normalized, 0.25, accuracy: 0.0001)
        XCTAssertEqual(detail.opcolor.blue.raw, 0xFFFF)
        XCTAssertEqual(detail.opcolor.blue.normalized, 1.0, accuracy: 0.0001)
    }

    func testMovieHeaderParserRejectsTruncatedMatrix() throws {
        var payload = Data()
        payload.append(0x00)
        payload.append(contentsOf: [0x00, 0x00, 0x00])
        payload.append(contentsOf: UInt32(1).bigEndianBytes)
        payload.append(contentsOf: UInt32(1).bigEndianBytes)
        payload.append(contentsOf: UInt32(90).bigEndianBytes)
        payload.append(contentsOf: UInt32(120).bigEndianBytes)
        payload.append(contentsOf: UInt32(0x00010000).bigEndianBytes)
        payload.append(contentsOf: UInt16(0x0100).bigEndianBytes)
        payload.append(contentsOf: Data(count: 10))
        payload.append(contentsOf: Data(count: 20)) // truncated matrix data

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

        XCTAssertNil(try BoxParserRegistry.shared.parse(header: header, reader: reader))
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

    func testTrackHeaderParserParsesVersion0Box() throws {
        let headerAndReader = try makeTrackHeaderFixture(
            version: 0,
            flags: 0x000001,
            creationTime: 1,
            modificationTime: 2,
            trackID: 3,
            duration: 540,
            matrix: .identity,
            width: 1280,
            height: 720,
            volumeRaw: 0x0100
        )

        let parsed = try XCTUnwrap(BoxParserRegistry.shared.parse(
            header: headerAndReader.header,
            reader: headerAndReader.reader
        ))

        XCTAssertEqual(value(named: "version", in: parsed), "0")
        XCTAssertEqual(value(named: "flags", in: parsed), "0x000001")
        XCTAssertEqual(value(named: "creation_time", in: parsed), "1")
        XCTAssertEqual(value(named: "modification_time", in: parsed), "2")
        XCTAssertEqual(value(named: "track_id", in: parsed), "3")
        XCTAssertEqual(value(named: "duration", in: parsed), "540")
        XCTAssertEqual(value(named: "volume", in: parsed), "1.00")
        XCTAssertEqual(value(named: "is_enabled", in: parsed), "true")
        XCTAssertEqual(value(named: "is_in_movie", in: parsed), "false")
        XCTAssertEqual(value(named: "is_in_preview", in: parsed), "false")
        XCTAssertEqual(value(named: "matrix.a", in: parsed), "1.0000")
        XCTAssertEqual(value(named: "matrix.d", in: parsed), "1.0000")
        XCTAssertEqual(value(named: "matrix.w", in: parsed), "1.000000")
        XCTAssertEqual(value(named: "width", in: parsed), "1280.00")
        XCTAssertEqual(value(named: "height", in: parsed), "720.00")

        let detail = try XCTUnwrap(parsed.trackHeader)
        XCTAssertEqual(detail.version, 0)
        XCTAssertEqual(detail.flags, 0x000001)
        XCTAssertEqual(detail.trackID, 3)
        XCTAssertEqual(detail.creationTime, 1)
        XCTAssertEqual(detail.modificationTime, 2)
        XCTAssertEqual(detail.duration, 540)
        XCTAssertFalse(detail.durationIs64Bit)
        XCTAssertEqual(detail.layer, 0)
        XCTAssertEqual(detail.alternateGroup, 0)
        XCTAssertEqual(detail.volume, 1.0, accuracy: 0.0001)
        XCTAssertTrue(detail.isEnabled)
        XCTAssertFalse(detail.isInMovie)
        XCTAssertFalse(detail.isInPreview)
        XCTAssertEqual(detail.matrix, .identity)
        XCTAssertEqual(detail.width, 1280.0, accuracy: 0.0001)
        XCTAssertEqual(detail.height, 720.0, accuracy: 0.0001)
    }

    func testTrackHeaderParserParsesVersion1Box() throws {
        let matrix = ParsedBoxPayload.TransformationMatrix(
            a: 2.0,
            b: -1.0,
            u: 0.5,
            c: 0.5,
            d: 1.0,
            v: -0.5,
            x: 0.0,
            y: 1.0,
            w: 1.0
        )

        let headerAndReader = try makeTrackHeaderFixture(
            version: 1,
            flags: 0x000007,
            creationTime: 10,
            modificationTime: 11,
            trackID: 12,
            duration: 900,
            matrix: matrix,
            width: 1920,
            height: 1080,
            volumeRaw: 0x0100,
            layer: 1,
            alternateGroup: 2
        )

        let parsed = try XCTUnwrap(BoxParserRegistry.shared.parse(
            header: headerAndReader.header,
            reader: headerAndReader.reader
        ))

        XCTAssertEqual(value(named: "version", in: parsed), "1")
        XCTAssertEqual(value(named: "flags", in: parsed), "0x000007")
        XCTAssertEqual(value(named: "track_id", in: parsed), "12")
        XCTAssertEqual(value(named: "duration", in: parsed), "900")
        XCTAssertEqual(value(named: "matrix.a", in: parsed), "2.0000")
        XCTAssertEqual(value(named: "matrix.b", in: parsed), "-1.0000")
        XCTAssertEqual(value(named: "matrix.u", in: parsed), "0.500000")
        XCTAssertEqual(value(named: "matrix.v", in: parsed), "-0.500000")
        XCTAssertEqual(value(named: "width", in: parsed), "1920.00")
        XCTAssertEqual(value(named: "height", in: parsed), "1080.00")
        XCTAssertEqual(value(named: "layer", in: parsed), "1")
        XCTAssertEqual(value(named: "alternate_group", in: parsed), "2")
        XCTAssertEqual(value(named: "is_enabled", in: parsed), "true")
        XCTAssertEqual(value(named: "is_in_movie", in: parsed), "true")
        XCTAssertEqual(value(named: "is_in_preview", in: parsed), "true")

        let detail = try XCTUnwrap(parsed.trackHeader)
        XCTAssertEqual(detail.version, 1)
        XCTAssertEqual(detail.flags, 0x000007)
        XCTAssertEqual(detail.creationTime, 10)
        XCTAssertEqual(detail.modificationTime, 11)
        XCTAssertEqual(detail.trackID, 12)
        XCTAssertEqual(detail.duration, 900)
        XCTAssertTrue(detail.durationIs64Bit)
        XCTAssertEqual(detail.layer, 1)
        XCTAssertEqual(detail.alternateGroup, 2)
        XCTAssertEqual(detail.volume, 1.0, accuracy: 0.0001)
        XCTAssertTrue(detail.isEnabled)
        XCTAssertTrue(detail.isInMovie)
        XCTAssertTrue(detail.isInPreview)
        XCTAssertEqual(detail.matrix.a, 2.0, accuracy: 0.0001)
        XCTAssertEqual(detail.matrix.b, -1.0, accuracy: 0.0001)
        XCTAssertEqual(detail.matrix.u, 0.5, accuracy: 0.0001)
        XCTAssertEqual(detail.matrix.c, 0.5, accuracy: 0.0001)
        XCTAssertEqual(detail.matrix.v, -0.5, accuracy: 0.0001)
        XCTAssertEqual(detail.width, 1920.0, accuracy: 0.0001)
        XCTAssertEqual(detail.height, 1080.0, accuracy: 0.0001)
    }

    func testTrackHeaderParserParsesAudioAndVideoTracksFromBaselineFixture() throws {
        let catalog = try FixtureCatalog.load()
        let fixture = try XCTUnwrap(catalog.fixture(withID: "baseline-sample"))
        let data = try fixture.data(in: .module)
        let reader = InMemoryRandomAccessReader(data: data)
        let headers = try trackHeaders(in: reader)

        let audio = try XCTUnwrap(headers.first { $0.trackID == 1 })
        XCTAssertTrue(audio.isEnabled)
        XCTAssertFalse(audio.isInMovie)
        XCTAssertFalse(audio.isInPreview)
        XCTAssertEqual(audio.volume, 1.0, accuracy: 0.0001)
        XCTAssertEqual(audio.width, 0.0, accuracy: 0.0001)
        XCTAssertEqual(audio.height, 0.0, accuracy: 0.0001)

        let video = try XCTUnwrap(headers.first { $0.trackID == 2 })
        XCTAssertTrue(video.isEnabled)
        XCTAssertFalse(video.isInMovie)
        XCTAssertFalse(video.isInPreview)
        XCTAssertEqual(video.volume, 0.0, accuracy: 0.0001)
        XCTAssertEqual(video.width, 1280.0, accuracy: 0.0001)
        XCTAssertEqual(video.height, 720.0, accuracy: 0.0001)
        XCTAssertFalse(video.isZeroSized)
    }

    func testTrackHeaderParserHandlesDisabledZeroDurationTrack() throws {
        let headerAndReader = try makeTrackHeaderFixture(
            version: 0,
            flags: 0x000000,
            creationTime: 0,
            modificationTime: 0,
            trackID: 33,
            duration: 0,
            matrix: .identity,
            width: 0,
            height: 0,
            volumeRaw: 0x0000
        )

        let parsed = try XCTUnwrap(BoxParserRegistry.shared.parse(
            header: headerAndReader.header,
            reader: headerAndReader.reader
        ))

        let detail = try XCTUnwrap(parsed.trackHeader)
        XCTAssertFalse(detail.isEnabled)
        XCTAssertFalse(detail.isInMovie)
        XCTAssertFalse(detail.isInPreview)
        XCTAssertEqual(detail.duration, 0)
        XCTAssertTrue(detail.isZeroDuration)
        XCTAssertTrue(detail.isZeroSized)
    }

    func testDataReferenceParserEmitsEntries() throws {
        let fixture = try makeDataReferenceFixture()

        let parsed = try XCTUnwrap(BoxParserRegistry.shared.parse(
            header: fixture.header,
            reader: fixture.reader
        ))

        XCTAssertEqual(value(named: "version", in: parsed), "0")
        XCTAssertEqual(value(named: "flags", in: parsed), "0x000000")
        XCTAssertEqual(value(named: "entry_count", in: parsed), "2")

        XCTAssertEqual(value(named: "entries[0].type", in: parsed), "url ")
        XCTAssertEqual(value(named: "entries[0].flags", in: parsed), "0x000001")
        XCTAssertEqual(value(named: "entries[0].self_contained", in: parsed), "true")

        XCTAssertEqual(value(named: "entries[1].type", in: parsed), "urn ")
        XCTAssertEqual(value(named: "entries[1].flags", in: parsed), "0x000000")
        XCTAssertEqual(value(named: "entries[1].name", in: parsed), "external-aac")
        XCTAssertEqual(
            value(named: "entries[1].location", in: parsed),
            "https://cdn.example.com/audio.aac"
        )

        let detail = try XCTUnwrap(parsed.dataReference)
        XCTAssertEqual(detail.entryCount, 2)
        XCTAssertEqual(detail.entries.count, 2)

        let urlEntry = detail.entries[0]
        XCTAssertEqual(urlEntry.type.rawValue, "url ")
        XCTAssertEqual(urlEntry.version, 0)
        XCTAssertEqual(urlEntry.flags, 0x000001)
        guard case .selfContained = urlEntry.location else {
            XCTFail("Expected self-contained location")
            return
        }

        let urnEntry = detail.entries[1]
        XCTAssertEqual(urnEntry.type.rawValue, "urn ")
        XCTAssertEqual(urnEntry.version, 0)
        XCTAssertEqual(urnEntry.flags, 0x000000)
        guard case let .urn(name, location) = urnEntry.location else {
            XCTFail("Expected URN location")
            return
        }
        XCTAssertEqual(name, "external-aac")
        XCTAssertEqual(location, "https://cdn.example.com/audio.aac")
    }

    func testMetadataKeysParserEmitsEntries() throws {
        var payload = Data()
        payload.append(0x00) // version
        payload.append(contentsOf: [0x00, 0x00, 0x00]) // flags

        payload.append(contentsOf: UInt32(2).bigEndianBytes)

        let entries: [(namespace: String, name: String)] = [
            ("mdta", "com.example.title"),
            ("mdta", "com.example.year")
        ]

        for entry in entries {
            let nameData = Data(entry.name.utf8)
            var entryData = Data()
            entryData.append(contentsOf: entry.namespace.utf8)
            entryData.append(nameData)
            payload.append(contentsOf: UInt32(entryData.count).bigEndianBytes)
            payload.append(entryData)
        }

        let totalSize = 8 + payload.count
        let header = BoxHeader(
            type: try FourCharCode("keys"),
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
        XCTAssertEqual(value(named: "entry_count", in: parsed), "2")
        XCTAssertEqual(value(named: "entries[0].namespace", in: parsed), "mdta")
        XCTAssertEqual(value(named: "entries[0].name", in: parsed), "com.example.title")
        XCTAssertEqual(value(named: "entries[1].name", in: parsed), "com.example.year")

        let detail = try XCTUnwrap(parsed.metadataKeyTable)
        XCTAssertEqual(detail.entries.count, 2)
        XCTAssertEqual(detail.entries[0].index, 1)
        XCTAssertEqual(detail.entries[0].namespace, "mdta")
        XCTAssertEqual(detail.entries[0].name, "com.example.title")
        XCTAssertEqual(detail.entries[1].index, 2)
        XCTAssertEqual(detail.entries[1].name, "com.example.year")
    }

    func testMetadataItemListParserDecodesStringAndIntegerValues() throws {
        let titleEntry = makeMetadataItemEntry(
            identifierBytes: [0xA9, 0x6E, 0x61, 0x6D],
            dataBoxes: [
                makeMetadataDataBox(type: 1, locale: 0, data: Data("Example Title".utf8))
            ]
        )

        let tempoValue: UInt16 = 120
        let tempoEntry = makeMetadataItemEntry(
            identifierBytes: [0x00, 0x00, 0x00, 0x01],
            dataBoxes: [
                makeMetadataDataBox(type: 21, locale: 0, data: Data(tempoValue.bigEndianBytes))
            ]
        )

        var payload = Data()
        payload.append(titleEntry)
        payload.append(tempoEntry)

        let totalSize = 8 + payload.count
        let header = BoxHeader(
            type: try FourCharCode("ilst"),
            totalSize: Int64(totalSize),
            headerSize: 8,
            payloadRange: 8..<Int64(totalSize),
            range: 0..<Int64(totalSize),
            uuid: nil
        )

        var data = Data(count: totalSize)
        data.replaceSubrange(8..<totalSize, with: payload)
        let reader = InMemoryRandomAccessReader(data: data)

        let keyEntry = ParsedBoxPayload.MetadataKeyTableBox.Entry(
            index: 1,
            namespace: "mdta",
            name: "com.example.rating"
        )

        let environment = BoxParserRegistry.MetadataEnvironment(
            handlerType: HandlerType(code: try FourCharCode("mdir")),
            keyTable: [1: keyEntry]
        )

        let parsed = try BoxParserRegistry.withMetadataEnvironmentProvider({ _, _ in environment }) {
            try BoxParserRegistry.shared.parse(header: header, reader: reader)
        }

        let payloadResult = try XCTUnwrap(parsed)
        XCTAssertEqual(value(named: "handler_type", in: payloadResult), "mdir")
        XCTAssertEqual(value(named: "entry_count", in: payloadResult), "2")
        XCTAssertEqual(value(named: "entries[0].identifier", in: payloadResult), "©nam")
        XCTAssertEqual(value(named: "entries[0].values[0].value", in: payloadResult), "Example Title")
        XCTAssertEqual(value(named: "entries[1].identifier", in: payloadResult), "key[1]")
        XCTAssertEqual(value(named: "entries[1].name", in: payloadResult), "com.example.rating")
        XCTAssertEqual(value(named: "entries[1].values[0].value", in: payloadResult), "120")

        let detail = try XCTUnwrap(payloadResult.metadataItemList)
        XCTAssertEqual(detail.handlerType?.rawValue, "mdir")
        XCTAssertEqual(detail.entries.count, 2)
        XCTAssertEqual(detail.entries[0].values.first?.kind, .utf8("Example Title"))
        XCTAssertEqual(detail.entries[1].values.first?.kind, .integer(120))
        XCTAssertEqual(detail.entries[1].namespace, "mdta")
        XCTAssertEqual(detail.entries[1].name, "com.example.rating")
    }

    private func makeMetadataItemEntry(identifierBytes: [UInt8], dataBoxes: [Data]) -> Data {
        precondition(identifierBytes.count == 4, "Identifier must be four bytes")
        let payload = dataBoxes.reduce(into: Data(), { $0.append($1) })
        var entry = Data()
        entry.append(contentsOf: UInt32(8 + payload.count).bigEndianBytes)
        entry.append(contentsOf: identifierBytes)
        entry.append(payload)
        return entry
    }

    private func makeMetadataDataBox(type: UInt32, locale: UInt32, data: Data) -> Data {
        var box = Data()
        box.append(contentsOf: UInt32(16 + data.count).bigEndianBytes)
        box.append(contentsOf: "data".utf8)
        box.append(0x00) // version
        box.append(UInt8((type >> 16) & 0xFF))
        box.append(UInt8((type >> 8) & 0xFF))
        box.append(UInt8(type & 0xFF))
        box.append(contentsOf: locale.bigEndianBytes)
        box.append(data)
        return box
    }

    private func makeTrackHeaderFixture(
        version: UInt8,
        flags: UInt32,
        creationTime: UInt64,
        modificationTime: UInt64,
        trackID: UInt32,
        duration: UInt64,
        matrix: ParsedBoxPayload.TransformationMatrix,
        width: UInt32,
        height: UInt32,
        volumeRaw: UInt16,
        layer: Int16 = 0,
        alternateGroup: Int16 = 0
    ) throws -> (header: BoxHeader, reader: InMemoryRandomAccessReader) {
        precondition(version == 0 || version == 1, "Unsupported version")

        var payload = Data()
        payload.append(version)
        payload.append(contentsOf: [UInt8((flags >> 16) & 0xFF), UInt8((flags >> 8) & 0xFF), UInt8(flags & 0xFF)])

        if version == 1 {
            payload.append(contentsOf: creationTime.bigEndianBytes)
            payload.append(contentsOf: modificationTime.bigEndianBytes)
        } else {
            payload.append(contentsOf: UInt32(creationTime).bigEndianBytes)
            payload.append(contentsOf: UInt32(modificationTime).bigEndianBytes)
        }

        payload.append(contentsOf: trackID.bigEndianBytes)
        payload.append(contentsOf: UInt32(0).bigEndianBytes) // reserved

        if version == 1 {
            payload.append(contentsOf: duration.bigEndianBytes)
        } else {
            payload.append(contentsOf: UInt32(duration).bigEndianBytes)
        }

        payload.append(contentsOf: UInt32(0).bigEndianBytes)
        payload.append(contentsOf: UInt32(0).bigEndianBytes)

        payload.append(contentsOf: layer.bigEndianBytes)
        payload.append(contentsOf: alternateGroup.bigEndianBytes)
        payload.append(contentsOf: volumeRaw.bigEndianBytes)
        payload.append(contentsOf: UInt16(0).bigEndianBytes) // reserved

        let matrixRaw = matrix.fixedPointRepresentation()
        payload.append(contentsOf: matrixRaw.flatMap { $0.bigEndianBytes })

        payload.append(contentsOf: UInt32(width << 16).bigEndianBytes)
        payload.append(contentsOf: UInt32(height << 16).bigEndianBytes)

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
        return (header, InMemoryRandomAccessReader(data: data))
    }

    private func trackHeaders(in reader: InMemoryRandomAccessReader) throws -> [ParsedBoxPayload.TrackHeaderBox] {
        let walker = StreamingBoxWalker()
        var headers: [ParsedBoxPayload.TrackHeaderBox] = []
        try walker.walk(
            reader: reader,
            cancellationCheck: {},
            onEvent: { event in
                guard case let .willStartBox(header, _) = event.kind else { return }
                guard header.type.rawValue == "tkhd" else { return }
                if let payload = try? BoxParserRegistry.shared.parse(header: header, reader: reader),
                   let detail = payload.trackHeader {
                    headers.append(detail)
                }
            },
            onFinish: {}
        )
        return headers
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

private extension BoxParserRegistryTests {
    func makeDataReferenceFixture() throws -> (header: BoxHeader, reader: InMemoryRandomAccessReader) {
        let entryCount: UInt32 = 2

        var payload = Data()
        payload.append(0x00) // version
        payload.append(contentsOf: [0x00, 0x00, 0x00]) // flags
        payload.append(contentsOf: entryCount.bigEndianBytes)

        // Entry 0: url , self-contained (no location payload)
        payload.append(contentsOf: UInt32(12).bigEndianBytes)
        payload.append(contentsOf: "url ".utf8)
        payload.append(0x00) // version
        payload.append(contentsOf: [0x00, 0x00, 0x01]) // flags (self-contained)

        // Entry 1: urn with name + location strings
        let name = Data("external-aac".utf8)
        let location = Data("https://cdn.example.com/audio.aac".utf8)
        var urnEntry = Data()
        urnEntry.append(name)
        urnEntry.append(0x00)
        urnEntry.append(location)
        urnEntry.append(0x00)
        let urnSize = UInt32(12 + urnEntry.count)
        payload.append(contentsOf: urnSize.bigEndianBytes)
        payload.append(contentsOf: "urn ".utf8)
        payload.append(0x00) // version
        payload.append(contentsOf: [0x00, 0x00, 0x00]) // flags
        payload.append(urnEntry)

        let totalSize = 8 + payload.count
        let header = BoxHeader(
            type: try FourCharCode("dref"),
            totalSize: Int64(totalSize),
            headerSize: 8,
            payloadRange: 8..<Int64(totalSize),
            range: 0..<Int64(totalSize),
            uuid: nil
        )

        var data = Data(count: totalSize)
        data.replaceSubrange(8..<totalSize, with: payload)
        return (header, InMemoryRandomAccessReader(data: data))
    }
}

private extension ParsedBoxPayload.TransformationMatrix {
    func fixedPointRepresentation() -> [Int32] {
        [
            Int32((a * 65536.0).rounded()),
            Int32((b * 65536.0).rounded()),
            Int32((u * Double(1 << 30)).rounded()),
            Int32((c * 65536.0).rounded()),
            Int32((d * 65536.0).rounded()),
            Int32((v * Double(1 << 30)).rounded()),
            Int32((x * 65536.0).rounded()),
            Int32((y * 65536.0).rounded()),
            Int32((w * Double(1 << 30)).rounded())
        ]
    }
}
