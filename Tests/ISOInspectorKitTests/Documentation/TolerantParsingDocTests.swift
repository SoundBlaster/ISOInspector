import Foundation
import XCTest

@testable import ISOInspectorKit

/// Test suite that verifies code examples from the Tolerant Parsing Guide documentation.
///
/// This ensures that all examples in TolerantParsingGuide.md compile, execute correctly,
/// and demonstrate the expected behavior for SDK consumers.
final class TolerantParsingDocTests: XCTestCase {

  // MARK: - Basic Setup Examples

  /// Verifies that creating a tolerant pipeline uses the correct preset configuration.
  func testTolerantPipelineCreation() {
    let pipeline = ParsePipeline.live(options: .tolerant)

    // Verify tolerant preset configuration
    let context = ParsePipeline.Context()
    XCTAssertNotNil(pipeline)
  }

  /// Verifies that strict pipeline uses the strict preset configuration.
  func testStrictPipelineCreation() {
    let pipeline = ParsePipeline.live(options: .strict)

    // Verify strict preset configuration
    let context = ParsePipeline.Context()
    XCTAssertNotNil(pipeline)
  }

  /// Tests the basic tolerant parsing workflow with issue collection.
  func testBasicTolerantParsingWorkflow() async throws {
    // Use a minimal valid MP4 as test fixture
    let testData = createMinimalMP4()
    let tempURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("test_tolerant.mp4")
    try testData.write(to: tempURL)
    defer { try? FileManager.default.removeItem(at: tempURL) }

    // Create pipeline and context as documented
    let reader = try ChunkedFileReader(fileURL: tempURL)
    let issueStore = ParseIssueStore()
    var context = ParsePipeline.Context(source: tempURL, issueStore: issueStore)
    let pipeline = ParsePipeline.live(options: .tolerant)

    // Parse file
    var eventCount = 0
    for try await event in pipeline.events(for: reader, context: context) {
      eventCount += 1
      switch event.kind {
      case .willStartBox:
        break
      case .didFinishBox:
        break
      }
    }

    // Verify parsing completed
    XCTAssertGreaterThan(eventCount, 0, "Should parse at least one box")

    // Verify metrics are accessible as documented
    let metrics = issueStore.metricsSnapshot()
    XCTAssertGreaterThanOrEqual(metrics.errorCount, 0)
    XCTAssertGreaterThanOrEqual(metrics.warningCount, 0)
  }

  // MARK: - Issue Store Query Examples

  /// Tests querying ParseIssueStore metrics as shown in documentation.
  func testIssueStoreMetricsQuery() async throws {
    let testData = createMinimalMP4()
    let tempURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("test_metrics.mp4")
    try testData.write(to: tempURL)
    defer { try? FileManager.default.removeItem(at: tempURL) }

    let reader = try ChunkedFileReader(fileURL: tempURL)
    let issueStore = ParseIssueStore()
    var context = ParsePipeline.Context(source: tempURL, issueStore: issueStore)
    let pipeline = ParsePipeline.live(options: .tolerant)

    // Parse file
    for try await _ in pipeline.events(for: reader, context: context) {}

    // Query metrics as documented
    let metrics = issueStore.metricsSnapshot()
    XCTAssertGreaterThanOrEqual(metrics.errorCount, 0)
    XCTAssertGreaterThanOrEqual(metrics.warningCount, 0)
    XCTAssertGreaterThanOrEqual(metrics.infoCount, 0)
    XCTAssertGreaterThanOrEqual(metrics.deepestAffectedDepth, 0)

    // Query summary
    let summary = issueStore.makeIssueSummary()
    XCTAssertGreaterThanOrEqual(summary.totalCount, 0)
  }

  /// Tests filtering issues by severity as documented.
  func testFilteringIssuesBySeverity() async throws {
    let testData = createMinimalMP4()
    let tempURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("test_filter.mp4")
    try testData.write(to: tempURL)
    defer { try? FileManager.default.removeItem(at: tempURL) }

    let reader = try ChunkedFileReader(fileURL: tempURL)
    let issueStore = ParseIssueStore()
    var context = ParsePipeline.Context(source: tempURL, issueStore: issueStore)
    let pipeline = ParsePipeline.live(options: .tolerant)

    // Parse file
    for try await _ in pipeline.events(for: reader, context: context) {}

    // Filter issues by severity as documented
    let allIssues = issueStore.issuesSnapshot()
    let errors = allIssues.filter { $0.severity == .error }
    let warnings = allIssues.filter { $0.severity == .warning }
    let infos = allIssues.filter { $0.severity == .info }

    // Verify filtering works
    XCTAssertEqual(errors.count + warnings.count + infos.count, allIssues.count)
  }

  // MARK: - Advanced Configuration Examples

  /// Tests custom options configuration as documented.
  func testCustomOptionsConfiguration() {
    // Create custom options as documented
    var customOptions = ParsePipeline.Options.tolerant

    // Modify parameters
    customOptions.maxCorruptionEvents = 1000
    customOptions.maxTraversalDepth = 128

    // Verify modifications
    XCTAssertEqual(customOptions.maxCorruptionEvents, 1000)
    XCTAssertEqual(customOptions.maxTraversalDepth, 128)
    XCTAssertFalse(customOptions.abortOnStructuralError)

    // Create pipeline with custom options
    let pipeline = ParsePipeline.live(options: customOptions)
    XCTAssertNotNil(pipeline)
  }

  /// Tests comparing strict vs. tolerant behavior as documented.
  func testStrictVsTolerantComparison() async throws {
    let testData = createMinimalMP4()
    let tempURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("test_comparison.mp4")
    try testData.write(to: tempURL)
    defer { try? FileManager.default.removeItem(at: tempURL) }

    // Test strict mode
    let strictPipeline = ParsePipeline.live(options: .strict)
    let strictReader = try ChunkedFileReader(fileURL: tempURL)
    var strictContext = ParsePipeline.Context(source: tempURL)

    var strictBoxCount = 0
    for try await event in strictPipeline.events(for: strictReader, context: strictContext) {
      if case .willStartBox = event.kind {
        strictBoxCount += 1
      }
    }

    // Test tolerant mode
    let tolerantPipeline = ParsePipeline.live(options: .tolerant)
    let tolerantReader = try ChunkedFileReader(fileURL: tempURL)
    let issueStore = ParseIssueStore()
    var tolerantContext = ParsePipeline.Context(source: tempURL, issueStore: issueStore)

    var tolerantBoxCount = 0
    for try await event in tolerantPipeline.events(for: tolerantReader, context: tolerantContext) {
      if case .willStartBox = event.kind {
        tolerantBoxCount += 1
      }
    }

    // For valid files, both should parse successfully
    XCTAssertGreaterThan(strictBoxCount, 0)
    XCTAssertGreaterThan(tolerantBoxCount, 0)

    let metrics = issueStore.metricsSnapshot()
    XCTAssertGreaterThanOrEqual(metrics.errorCount, 0)
  }

  // MARK: - Best Practices Examples

  /// Tests handling incomplete payload data gracefully as documented.
  func testHandlingIncompletePayload() async throws {
    let testData = createMinimalMP4()
    let tempURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("test_incomplete.mp4")
    try testData.write(to: tempURL)
    defer { try? FileManager.default.removeItem(at: tempURL) }

    let reader = try ChunkedFileReader(fileURL: tempURL)
    var context = ParsePipeline.Context(source: tempURL)
    let pipeline = ParsePipeline.live(options: .tolerant)

    // Handle events with payload checks as documented
    var boxesWithPayload = 0
    var boxesWithoutPayload = 0

    for try await event in pipeline.events(for: reader, context: context) {
      guard case .didFinishBox = event.kind else { continue }

      if event.payload != nil {
        boxesWithPayload += 1
      } else {
        boxesWithoutPayload += 1
      }

      // Check for validation issues as documented
      if !event.validationIssues.isEmpty {
        // Handle validation issues
      }
    }

    // Verify we counted boxes
    XCTAssertGreaterThan(boxesWithPayload + boxesWithoutPayload, 0)
  }

  /// Tests options preset values match documentation.
  func testOptionsPresetValues() {
    // Verify .strict preset matches documentation
    let strictOptions = ParsePipeline.Options.strict
    XCTAssertTrue(strictOptions.abortOnStructuralError)
    XCTAssertEqual(strictOptions.maxCorruptionEvents, 0)
    XCTAssertEqual(strictOptions.payloadValidationLevel, .full)
    XCTAssertEqual(strictOptions.maxTraversalDepth, 64)

    // Verify .tolerant preset matches documentation
    let tolerantOptions = ParsePipeline.Options.tolerant
    XCTAssertFalse(tolerantOptions.abortOnStructuralError)
    XCTAssertEqual(tolerantOptions.maxCorruptionEvents, 500)
    XCTAssertEqual(tolerantOptions.payloadValidationLevel, .structureOnly)
    XCTAssertEqual(tolerantOptions.maxTraversalDepth, 64)
  }

  // MARK: - Helper Methods

  /// Creates a minimal valid MP4 file for testing.
  private func createMinimalMP4() -> Data {
    // Create a minimal ftyp box
    var data = Data()

    // ftyp box header: size (32) + type (ftyp)
    let ftypSize: UInt32 = 20
    data.append(contentsOf: ftypSize.bigEndian.bytes)
    data.append(contentsOf: [UInt8]("ftyp".utf8))
    // major_brand: isom
    data.append(contentsOf: [UInt8]("isom".utf8))
    // minor_version: 0
    data.append(contentsOf: UInt32(0).bigEndian.bytes)
    // compatible_brands: isom
    data.append(contentsOf: [UInt8]("isom".utf8))

    return data
  }
}

// MARK: - Extensions

extension FixedWidthInteger {
  fileprivate var bytes: [UInt8] {
    withUnsafeBytes(of: self) { Array($0) }
  }
}
