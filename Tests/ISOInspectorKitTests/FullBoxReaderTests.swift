import XCTest

@testable import ISOInspectorKit

final class FullBoxReaderTests: XCTestCase {
  func testReadsVersionFlagsAndContentRange() throws {
    var payload = Data([0x02, 0x00, 0x10, 0xFF])
    payload.append(contentsOf: [0xAA, 0xBB, 0xCC])
    let totalSize = 8 + payload.count
    let header = BoxHeader(
      type: try FourCharCode("test"),
      totalSize: Int64(totalSize),
      headerSize: 8,
      payloadRange: 8..<Int64(totalSize),
      range: 0..<Int64(totalSize),
      uuid: nil
    )
    var data = Data(count: totalSize)
    data.replaceSubrange(8..<totalSize, with: payload)
    let reader = InMemoryRandomAccessReader(data: data)

    let result = try XCTUnwrap(FullBoxReader.read(header: header, reader: reader))

    XCTAssertEqual(result.version, 0x02)
    XCTAssertEqual(result.flags, 0x0010FF)
    XCTAssertEqual(result.contentRange.lowerBound, header.payloadRange.lowerBound + 4)
    XCTAssertEqual(result.contentRange.upperBound, header.payloadRange.upperBound)
  }

  func testReturnsNilWhenPayloadSmallerThanHeader() throws {
    let payload = Data([0x01, 0x02, 0x03])
    let totalSize = 8 + payload.count
    let header = BoxHeader(
      type: try FourCharCode("test"),
      totalSize: Int64(totalSize),
      headerSize: 8,
      payloadRange: 8..<Int64(totalSize),
      range: 0..<Int64(totalSize),
      uuid: nil
    )
    var data = Data(count: totalSize)
    data.replaceSubrange(8..<totalSize, with: payload)
    let reader = InMemoryRandomAccessReader(data: data)

    XCTAssertNil(try FullBoxReader.read(header: header, reader: reader))
  }

  func testPropagatesReaderErrors() throws {
    struct FailingReader: RandomAccessReader {
      let length: Int64 = 16
      func read(at offset: Int64, count: Int) throws -> Data {
        throw RandomAccessReaderError.ioError(underlying: NSError(domain: "test", code: -1))
      }
    }
    let header = BoxHeader(
      type: try FourCharCode("test"),
      totalSize: 16,
      headerSize: 8,
      payloadRange: 8..<16,
      range: 0..<16,
      uuid: nil
    )

    XCTAssertThrowsError(try FullBoxReader.read(header: header, reader: FailingReader()))
  }
}
