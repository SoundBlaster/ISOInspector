import Foundation
import XCTest

@testable import ISOInspectorKit

final class ResearchLogTelemetrySmokeTests: XCTestCase {
  func testSmokeTelemetryCapturesResearchLogEntriesFromParsePipeline() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let logURL = directory.appendingPathComponent("research-log.json")
    let logWriter = try ResearchLogWriter(fileURL: logURL)
    let pipeline = ParsePipeline.live(researchLog: logWriter)
    let unknownBox = makeBox(type: "zzzz", payload: Data(count: 8))
    let reader = InMemoryReader(data: unknownBox)
    let source = URL(fileURLWithPath: "/tmp/unknown.mp4")

    var iterator = pipeline.events(for: reader, context: .init(source: source)).makeAsyncIterator()
    while try await iterator.next() != nil {}

    let snapshot = ResearchLogTelemetryProbe.capture(logURL: logURL)

    switch snapshot.state {
    case .ready(let audit):
      XCTAssertEqual(audit.entryCount, 1)
      XCTAssertTrue(snapshot.diagnostics.contains(where: { $0.contains("CLI") }))
      XCTAssertTrue(snapshot.diagnostics.contains(where: { $0.contains("SwiftUI") }))
    default:
      XCTFail("Expected ready snapshot, received \(snapshot.state)")
    }
  }

  func testSmokeTelemetryFlagsMissingResearchLog() {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let logURL = directory.appendingPathComponent("missing-log.json")

    let snapshot = ResearchLogTelemetryProbe.capture(logURL: logURL)

    switch snapshot.state {
    case .missingLog(let audit):
      XCTAssertFalse(audit.logExists)
      XCTAssertTrue(snapshot.diagnostics.contains(where: { $0.lowercased().contains("missing") }))
    default:
      XCTFail("Expected missing log snapshot, received \(snapshot.state)")
    }
  }

  func testSmokeTelemetryFlagsEmptyResearchLog() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let logURL = directory.appendingPathComponent("empty-log.json")
    _ = FileManager.default.createFile(atPath: logURL.path, contents: Data())

    let snapshot = ResearchLogTelemetryProbe.capture(logURL: logURL)

    switch snapshot.state {
    case .emptyLog(let audit):
      XCTAssertEqual(audit.entryCount, 0)
      XCTAssertTrue(snapshot.diagnostics.contains(where: { $0.lowercased().contains("empty") }))
    default:
      XCTFail("Expected empty log snapshot, received \(snapshot.state)")
    }
  }

  func testSmokeTelemetrySurfacesSchemaMismatches() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let logURL = directory.appendingPathComponent("mismatch-log.json")
    let payload = """
      [
          { "type": "zzzz", "path": "/tmp/sample.mp4" }
      ]
      """
    guard let payloadData = payload.data(using: .utf8) else {
      XCTFail("Failed to encode schema mismatch payload")
      return
    }
    _ = FileManager.default.createFile(atPath: logURL.path, contents: payloadData)

    let snapshot = ResearchLogTelemetryProbe.capture(logURL: logURL)

    switch snapshot.state {
    case .schemaMismatch(let expected, let actual):
      XCTAssertEqual(expected, ResearchLogSchema.fieldNames.sorted())
      XCTAssertTrue(actual.contains("type"))
      XCTAssertTrue(snapshot.diagnostics.contains(where: { $0.lowercased().contains("schema") }))
    default:
      XCTFail("Expected schema mismatch snapshot, received \(snapshot.state)")
    }
  }
}

private struct InMemoryReader: RandomAccessReader {
  let data: Data

  var length: Int64 { Int64(data.count) }

  func read(at offset: Int64, count: Int) throws -> Data {
    let lower = Int(offset)
    guard lower >= 0, count >= 0 else {
      throw ReaderError.outOfBounds
    }
    guard lower <= data.count else {
      throw ReaderError.outOfBounds
    }
    let upper = min(data.count, lower + count)
    return data.subdata(in: lower..<upper)
  }

  enum ReaderError: Swift.Error {
    case outOfBounds
  }
}

private func makeBox(type: String, payload: Data) -> Data {
  precondition(type.utf8.count == 4, "Box type must be four characters")
  var data = Data()
  let totalSize = 8 + payload.count
  data.append(contentsOf: UInt32(totalSize).bigEndianBytes)
  data.append(contentsOf: type.utf8)
  data.append(payload)
  return data
}

extension FixedWidthInteger {
  fileprivate var bigEndianBytes: [UInt8] {
    withUnsafeBytes(of: self.bigEndian, Array.init)
  }
}
