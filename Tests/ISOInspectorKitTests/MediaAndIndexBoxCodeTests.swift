import XCTest

@testable import ISOInspectorKit

final class MediaAndIndexBoxCodeTests: XCTestCase {
  func testAllCasesMatchRawValues() {
    let expectedRawValues: Set<String> = [
      MediaAndIndexBoxCode.mediaData.rawValue,
      MediaAndIndexBoxCode.segmentIndex.rawValue,
      MediaAndIndexBoxCode.segmentType.rawValue,
    ]

    XCTAssertEqual(MediaAndIndexBoxCode.rawValueSet, expectedRawValues)
    XCTAssertEqual(
      Set(MediaAndIndexBoxCode.allCases),
      Set(expectedRawValues.compactMap(MediaAndIndexBoxCode.init(rawValue:)))
    )
  }

  func testConversionFromFourCharCode() throws {
    let media = MediaAndIndexBoxCode.mediaData.fourCharCode
    let segmentIndex = MediaAndIndexBoxCode.segmentIndex.fourCharCode
    let segmentType = MediaAndIndexBoxCode.segmentType.fourCharCode

    XCTAssertEqual(MediaAndIndexBoxCode(fourCharCode: media), .mediaData)
    XCTAssertEqual(MediaAndIndexBoxCode(fourCharCode: segmentIndex), .segmentIndex)
    XCTAssertEqual(MediaAndIndexBoxCode(fourCharCode: segmentType), .segmentType)
  }

  func testConversionFromBoxHeader() throws {
    let mediaHeader = try makeHeader(type: MediaAndIndexBoxCode.mediaData.rawValue)
    let segmentIndexHeader = try makeHeader(type: MediaAndIndexBoxCode.segmentIndex.rawValue)
    let segmentTypeHeader = try makeHeader(type: MediaAndIndexBoxCode.segmentType.rawValue)

    XCTAssertEqual(MediaAndIndexBoxCode(boxHeader: mediaHeader), .mediaData)
    XCTAssertEqual(MediaAndIndexBoxCode(boxHeader: segmentIndexHeader), .segmentIndex)
    XCTAssertEqual(MediaAndIndexBoxCode(boxHeader: segmentTypeHeader), .segmentType)
  }

  func testUnknownValuesReturnNil() throws {
    let invalidCode = try FourCharCode("free")
    let header = try makeHeader(type: "free")

    XCTAssertNil(MediaAndIndexBoxCode(fourCharCode: invalidCode))
    XCTAssertNil(MediaAndIndexBoxCode(boxHeader: header))
    XCTAssertFalse(MediaAndIndexBoxCode.isMediaPayload(invalidCode))
    XCTAssertFalse(MediaAndIndexBoxCode.isStreamingIndicator(header))
  }

  func testMediaPayloadClassification() throws {
    let mediaHeader = try makeHeader(type: MediaAndIndexBoxCode.mediaData.rawValue)
    let mediaCode = MediaAndIndexBoxCode.mediaData.fourCharCode

    XCTAssertTrue(MediaAndIndexBoxCode.isMediaPayload(mediaHeader))
    XCTAssertTrue(MediaAndIndexBoxCode.isMediaPayload(mediaCode))
    XCTAssertTrue(MediaAndIndexBoxCode.isMediaPayload(MediaAndIndexBoxCode.mediaData.rawValue))

    XCTAssertFalse(MediaAndIndexBoxCode.isMediaPayload(MediaAndIndexBoxCode.segmentIndex.rawValue))
    XCTAssertFalse(MediaAndIndexBoxCode.isMediaPayload(MediaAndIndexBoxCode.segmentType.rawValue))
  }

  func testStreamingIndicatorClassification() throws {
    let segmentIndexHeader = try makeHeader(type: MediaAndIndexBoxCode.segmentIndex.rawValue)
    let segmentTypeHeader = try makeHeader(type: MediaAndIndexBoxCode.segmentType.rawValue)
    let segmentIndexCode = MediaAndIndexBoxCode.segmentIndex.fourCharCode

    XCTAssertTrue(MediaAndIndexBoxCode.isStreamingIndicator(segmentIndexHeader))
    XCTAssertTrue(MediaAndIndexBoxCode.isStreamingIndicator(segmentTypeHeader))
    XCTAssertTrue(MediaAndIndexBoxCode.isStreamingIndicator(segmentIndexCode))
    XCTAssertTrue(
      MediaAndIndexBoxCode.isStreamingIndicator(MediaAndIndexBoxCode.segmentType.rawValue))

    XCTAssertFalse(
      MediaAndIndexBoxCode.isStreamingIndicator(MediaAndIndexBoxCode.mediaData.rawValue))
    XCTAssertFalse(
      MediaAndIndexBoxCode.isStreamingIndicator(
        try makeHeader(type: MediaAndIndexBoxCode.mediaData.rawValue)
      )
    )
  }

  private func makeHeader(type: String) throws -> BoxHeader {
    BoxHeader(
      type: try FourCharCode(type),
      totalSize: 16,
      headerSize: 8,
      payloadRange: 8..<16,
      range: 0..<16,
      uuid: nil
    )
  }
}
