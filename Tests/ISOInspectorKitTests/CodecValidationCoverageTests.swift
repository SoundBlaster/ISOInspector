import XCTest

@testable import ISOInspectorKit

final class CodecValidationCoverageTests: XCTestCase {
  private var catalog: FixtureCatalog!
  private var pipeline: ParsePipeline!

  override func setUpWithError() throws {
    catalog = try FixtureCatalog.load()
    pipeline = .live()
  }

  func testCodecInvalidConfigsFixtureEmitsAvcAndHevcWarnings() async throws {
    let fixture = try XCTUnwrap(catalog.fixture(withID: "codec-invalid-configs"))
    let data = try fixture.data(in: .module)
    let reader = InMemoryRandomAccessReader(data: data)

    var codecIssues: [ValidationIssue] = []
    for try await event in pipeline.events(for: reader, context: .init()) {
      codecIssues.append(contentsOf: event.validationIssues.filter { $0.ruleID == "VR-018" })
    }

    XCTAssertFalse(codecIssues.isEmpty, "Expected VR-018 warnings for codec validation")
    let messages = codecIssues.map(\.message)
    XCTAssertTrue(
      messages.contains(where: {
        $0.localizedCaseInsensitiveContains("avcC")
          && $0.localizedCaseInsensitiveContains("zero length")
      }))
    XCTAssertTrue(
      messages.contains(where: {
        $0.localizedCaseInsensitiveContains("hvcC")
          && $0.localizedCaseInsensitiveContains("zero length")
      }))
  }
}
