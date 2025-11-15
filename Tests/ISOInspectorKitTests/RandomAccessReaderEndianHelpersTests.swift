import XCTest

@testable import ISOInspectorKit

final class RandomAccessReaderEndianHelpersTests: XCTestCase {
  func testReadUInt32BigEndian() throws {
    let bytes: [UInt8] = [0x12, 0x34, 0x56, 0x78]
    let reader = InMemoryRandomAccessReader(data: Data(bytes))

    let value = try reader.readUInt32(at: 0)

    XCTAssertEqual(value, 0x1234_5678)
  }

  func testReadUInt64BigEndian() throws {
    let bytes: [UInt8] = [
      0x01, 0x23, 0x45, 0x67,
      0x89, 0xAB, 0xCD, 0xEF,
    ]
    let reader = InMemoryRandomAccessReader(data: Data(bytes))

    let value = try reader.readUInt64(at: 0)

    XCTAssertEqual(value, 0x0123_4567_89AB_CDEF)
  }

  func testReadFourCC() throws {
    let bytes: [UInt8] = [0x66, 0x74, 0x79, 0x70]  // "ftyp"
    let reader = InMemoryRandomAccessReader(data: Data(bytes))

    let fourCC = try reader.readFourCC(at: 0)

    XCTAssertEqual(fourCC.rawValue, "ftyp")
  }

  func testReadUInt32TruncatedReadThrows() throws {
    let reader = InMemoryRandomAccessReader(data: Data([0x00, 0x01, 0x02]))

    XCTAssertThrowsError(try reader.readUInt32(at: 0)) { error in
      guard
        case RandomAccessReaderValueDecodingError.truncatedRead(let expected, let actual) = error
      else {
        XCTFail("Unexpected error: \(error)")
        return
      }
      XCTAssertEqual(expected, 4)
      XCTAssertEqual(actual, 3)
    }
  }
}
