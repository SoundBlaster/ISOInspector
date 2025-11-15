import XCTest

@testable import ISOInspectorKit

final class MappedReaderTests: XCTestCase {
  private var temporaryURL: URL!

  override func setUpWithError() throws {
    try super.setUpWithError()
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    temporaryURL = directory.appendingPathComponent("fixture.bin")
  }

  override func tearDownWithError() throws {
    if let url = temporaryURL?.deletingLastPathComponent() {
      try? FileManager.default.removeItem(at: url)
    }
    temporaryURL = nil
    try super.tearDownWithError()
  }

  func testReadReturnsSliceOfMappedData() throws {
    let payload = Data((0..<1024).map { UInt8($0 % 247) })
    try payload.write(to: temporaryURL)

    let reader = try MappedReader(fileURL: temporaryURL)

    XCTAssertEqual(reader.length, Int64(payload.count))

    let slice = try reader.read(at: 128, count: 256)
    XCTAssertEqual(slice, payload.subdata(in: 128..<384))
  }

  func testReadWithZeroCountReturnsEmptyData() throws {
    let payload = Data((0..<128).map { UInt8($0 % 211) })
    try payload.write(to: temporaryURL)

    let reader = try MappedReader(fileURL: temporaryURL)

    let data = try reader.read(at: 32, count: 0)
    XCTAssertEqual(data, Data())
  }

  func testOffsetBeyondFileLengthThrows() throws {
    let payload = Data((0..<64).map { UInt8($0) })
    try payload.write(to: temporaryURL)

    let reader = try MappedReader(fileURL: temporaryURL)

    XCTAssertThrowsError(try reader.read(at: 1024, count: 1)) { error in
      guard let mappedError = error as? RandomAccessReaderError else {
        XCTFail("Unexpected error: \(error)")
        return
      }
      guard case .boundsError(let bounds) = mappedError else {
        XCTFail("Unexpected error: \(mappedError)")
        return
      }
      XCTAssertEqual(bounds, .requestedRangeOutOfBounds(offset: 1024, count: 1))
    }
  }

  func testNegativeOffsetThrowsBoundsError() throws {
    let payload = Data((0..<32).map { UInt8($0) })
    try payload.write(to: temporaryURL)

    let reader = try MappedReader(fileURL: temporaryURL)

    XCTAssertThrowsError(try reader.read(at: -1, count: 1)) { error in
      guard let mappedError = error as? RandomAccessReaderError else {
        XCTFail("Unexpected error: \(error)")
        return
      }
      guard case .boundsError(let bounds) = mappedError else {
        XCTFail("Unexpected error: \(mappedError)")
        return
      }
      XCTAssertEqual(bounds, .invalidOffset(-1))
    }
  }

  func testNegativeCountThrowsBoundsError() throws {
    let payload = Data((0..<32).map { UInt8($0) })
    try payload.write(to: temporaryURL)

    let reader = try MappedReader(fileURL: temporaryURL)

    XCTAssertThrowsError(try reader.read(at: 0, count: -1)) { error in
      guard let mappedError = error as? RandomAccessReaderError else {
        XCTFail("Unexpected error: \(error)")
        return
      }
      guard case .boundsError(let bounds) = mappedError else {
        XCTFail("Unexpected error: \(error)")
        return
      }
      XCTAssertEqual(bounds, .invalidCount(-1))
    }
  }

  func testOverflowingRangeThrowsOverflowError() throws {
    let payload = Data((0..<32).map { UInt8($0) })
    try payload.write(to: temporaryURL)

    let reader = try MappedReader(fileURL: temporaryURL)

    XCTAssertThrowsError(try reader.read(at: Int64.max - 4, count: 10)) { error in
      guard let mappedError = error as? RandomAccessReaderError else {
        XCTFail("Unexpected error: \(error)")
        return
      }
      guard case .overflowError = mappedError else {
        XCTFail("Unexpected error: \(mappedError)")
        return
      }
    }
  }

  func testRangeExtendingBeyondFileLengthThrows() throws {
    let payload = Data((0..<256).map { UInt8($0 % 193) })
    try payload.write(to: temporaryURL)

    let reader = try MappedReader(fileURL: temporaryURL)

    XCTAssertThrowsError(try reader.read(at: 200, count: 100)) { error in
      guard let mappedError = error as? RandomAccessReaderError else {
        XCTFail("Unexpected error: \(error)")
        return
      }
      guard case .boundsError(let bounds) = mappedError else {
        XCTFail("Unexpected error: \(mappedError)")
        return
      }
      XCTAssertEqual(bounds, .requestedRangeOutOfBounds(offset: 200, count: 100))
    }
  }

  func testInitialisingWithMissingFileThrows() {
    let missingURL = temporaryURL.appendingPathComponent("missing.bin")

    XCTAssertThrowsError(try MappedReader(fileURL: missingURL)) { error in
      guard let mappedError = error as? MappedReader.Error else {
        XCTFail("Unexpected error: \(error)")
        return
      }
      guard case .fileNotFound = mappedError else {
        XCTFail("Unexpected error: \(error)")
        return
      }
    }
  }
}
