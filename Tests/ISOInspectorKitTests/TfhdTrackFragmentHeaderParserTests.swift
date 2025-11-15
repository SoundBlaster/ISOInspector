import XCTest

@testable import ISOInspectorKit

final class TfhdTrackFragmentHeaderParserTests: XCTestCase {
  func testParsesTrackFragmentHeaderDefaults() throws {
    let flags: UInt32 = 0x00023B
    let payload = makeTfhdPayload(
      flags: flags,
      trackID: 0x0102_0304,
      baseDataOffset: 0x0102_0304_0506_0708,
      sampleDescriptionIndex: 0x0102_0304,
      defaultSampleDuration: 0x0203_0405,
      defaultSampleSize: 0x0304_0506,
      defaultSampleFlags: 0x0405_0607
    )
    let parsed = try XCTUnwrap(parseTfhd(payload: payload))

    let fields = Dictionary(uniqueKeysWithValues: parsed.fields.map { ($0.name, $0) })
    XCTAssertEqual(fields["version"]?.value, "0")
    XCTAssertEqual(fields["flags"]?.value, "0x00023B")
    XCTAssertEqual(fields["track_id"]?.value, "16909060")
    XCTAssertEqual(fields["base_data_offset"]?.value, "72623859790382856")
    XCTAssertEqual(fields["sample_description_index"]?.value, "16909060")
    XCTAssertEqual(fields["default_sample_duration"]?.value, "33752069")
    XCTAssertEqual(fields["default_sample_size"]?.value, "50595078")
    XCTAssertEqual(fields["default_sample_flags"]?.value, "0x04050607")

    let detail = try XCTUnwrap(parsed.trackFragmentHeader)
    XCTAssertEqual(detail.version, 0)
    XCTAssertEqual(detail.flags, flags)
    XCTAssertEqual(detail.trackID, 0x0102_0304)
    XCTAssertEqual(detail.baseDataOffset, 0x0102_0304_0506_0708)
    XCTAssertEqual(detail.sampleDescriptionIndex, 0x0102_0304)
    XCTAssertEqual(detail.defaultSampleDuration, 0x0203_0405)
    XCTAssertEqual(detail.defaultSampleSize, 0x0304_0506)
    XCTAssertEqual(detail.defaultSampleFlags, 0x0405_0607)
    XCTAssertTrue(detail.defaultBaseIsMoof)
    XCTAssertFalse(detail.durationIsEmpty)
  }

  func testReturnsNilWhenPayloadTooSmall() throws {
    let parsed = try parseTfhd(payload: Data([0x00, 0x00, 0x00]))
    XCTAssertNil(parsed)
  }

  private func parseTfhd(payload: Data) throws -> ParsedBoxPayload? {
    let totalSize = 8 + payload.count
    var data = Data(count: totalSize)
    data.replaceSubrange(0..<4, with: UInt32(totalSize).bigEndianBytes)
    data.replaceSubrange(4..<8, with: Data("tfhd".utf8))
    data.replaceSubrange(8..<totalSize, with: payload)

    let header = BoxHeader(
      type: try FourCharCode("tfhd"),
      totalSize: Int64(totalSize),
      headerSize: 8,
      payloadRange: 8..<Int64(totalSize),
      range: 0..<Int64(totalSize),
      uuid: nil
    )
    let reader = InMemoryRandomAccessReader(data: data)

    return try BoxParserRegistry.shared.parse(header: header, reader: reader)
  }

  private func makeTfhdPayload(
    flags: UInt32,
    trackID: UInt32,
    baseDataOffset: UInt64,
    sampleDescriptionIndex: UInt32,
    defaultSampleDuration: UInt32,
    defaultSampleSize: UInt32,
    defaultSampleFlags: UInt32
  ) -> Data {
    var payload = Data()
    payload.append(0x00)  // version
    payload.append(contentsOf: flags.bigEndianFlagBytes)
    payload.append(contentsOf: trackID.bigEndianBytes)
    if flags & 0x000001 != 0 {
      payload.append(contentsOf: baseDataOffset.bigEndianBytes)
    }
    if flags & 0x000002 != 0 {
      payload.append(contentsOf: sampleDescriptionIndex.bigEndianBytes)
    }
    if flags & 0x000008 != 0 {
      payload.append(contentsOf: defaultSampleDuration.bigEndianBytes)
    }
    if flags & 0x000010 != 0 {
      payload.append(contentsOf: defaultSampleSize.bigEndianBytes)
    }
    if flags & 0x000020 != 0 {
      payload.append(contentsOf: defaultSampleFlags.bigEndianBytes)
    }
    return payload
  }
}

extension UInt32 {
  fileprivate var bigEndianBytes: [UInt8] {
    withUnsafeBytes(of: bigEndian, Array.init)
  }

  fileprivate var bigEndianFlagBytes: [UInt8] {
    let value = self
    return [
      UInt8((value >> 16) & 0xFF),
      UInt8((value >> 8) & 0xFF),
      UInt8(value & 0xFF),
    ]
  }
}

extension UInt64 {
  fileprivate var bigEndianBytes: [UInt8] {
    withUnsafeBytes(of: bigEndian, Array.init)
  }
}
