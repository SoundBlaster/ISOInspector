import Foundation
import XCTest

@testable import ISOInspectorKit

/// Fuzzing harness for tolerant parsing that generates 100+ synthetically corrupted MP4
/// fixtures and validates crash-free completion rate ≥99.9%.
///
/// This test suite uses deterministic mutations with seeded RandomNumberGenerator to ensure
/// reproducible failures, captures reproduction artifacts for debugging, and gates the
/// tolerant parsing feature on demonstrable resilience.
final class TolerantParsingFuzzTests: XCTestCase {

  // MARK: - Configuration

  private let fuzzIterations = 100
  private let requiredSuccessRate = 0.999  // 99.9%
  private let reproArtifactsPath = "Documentation/CorruptedFixtures/FuzzArtifacts"

  // MARK: - Core Fuzz Test

  /// Generates 100+ corrupt payloads via deterministic mutations and asserts that
  /// tolerant parsing completes without crashes for ≥99.9% of cases.
  func testFuzzTolerantParsingWith100PlusCorruptPayloads() async throws {
    let generator = CorruptPayloadGenerator(seed: 42)
    let pipeline = ParsePipeline.live(options: .tolerant)
    var statistics = FuzzStatistics()

    for iteration in 0..<fuzzIterations {
      let mutationSeed = UInt64(iteration)
      let corruptPayload = generator.generateCorruptPayload(mutationSeed: mutationSeed)

      do {
        // Write payload to temporary file
        let tempURL = FileManager.default.temporaryDirectory
          .appendingPathComponent("fuzz_\(mutationSeed).mp4")
        try corruptPayload.data.write(to: tempURL, options: [.atomic])
        defer { try? FileManager.default.removeItem(at: tempURL) }

        // Parse with tolerant pipeline
        let reader = try ChunkedFileReader(fileURL: tempURL)
        let store = ParseIssueStore()
        var context = ParsePipeline.Context(options: .tolerant, issueStore: store)
        context.source = tempURL

        let events = try await collectEvents(from: pipeline.events(for: reader, context: context))

        // Record successful completion
        statistics.recordSuccess(
          seed: mutationSeed,
          mutation: corruptPayload.mutation,
          eventCount: events.count,
          issueCount: store.issuesSnapshot().count
        )

      } catch {
        // Record failure with reproduction artifact
        statistics.recordFailure(
          seed: mutationSeed,
          mutation: corruptPayload.mutation,
          error: error
        )

        // Capture reproduction artifact for analysis
        let artifact = ReproductionArtifact(
          seed: mutationSeed,
          mutation: corruptPayload.mutation,
          payload: corruptPayload.data,
          error: error
        )

        try? saveReproductionArtifact(artifact)
      }
    }

    // Assert: ≥99.9% crash-free completion rate
    let successRate = statistics.successRate
    XCTAssertGreaterThanOrEqual(
      successRate,
      requiredSuccessRate,
      """
      Fuzzing harness failed to achieve 99.9% crash-free completion.
      Success rate: \(successRate * 100)%
      Successful: \(statistics.successCount)/\(fuzzIterations)
      Failed: \(statistics.failureCount)/\(fuzzIterations)
      Failures: \(statistics.failures.map { "Seed \($0.seed): \($0.mutation.description)" }.joined(separator: "\n"))
      """
    )

    // Print statistics for visibility
    print(statistics.summary)
  }

  // MARK: - Mutation Coverage Tests

  /// Tests that header truncation mutations are handled gracefully.
  func testHeaderTruncationMutations() async throws {
    let generator = CorruptPayloadGenerator(seed: 100)
    let pipeline = ParsePipeline.live(options: .tolerant)
    var successCount = 0

    for i in 0..<20 {
      let payload = generator.generateHeaderTruncation(mutationSeed: UInt64(i))
      let result = try await parsePayload(payload.data, pipeline: pipeline)
      if result.completed {
        successCount += 1
      }
    }

    let successRate = Double(successCount) / 20.0
    XCTAssertGreaterThanOrEqual(
      successRate, 0.95, "Header truncation mutations should complete ≥95%")
  }

  /// Tests that overlapping range mutations are handled gracefully.
  func testOverlappingRangeMutations() async throws {
    let generator = CorruptPayloadGenerator(seed: 200)
    let pipeline = ParsePipeline.live(options: .tolerant)
    var successCount = 0

    for i in 0..<20 {
      let payload = generator.generateOverlappingRanges(mutationSeed: UInt64(i))
      let result = try await parsePayload(payload.data, pipeline: pipeline)
      if result.completed {
        successCount += 1
      }
    }

    let successRate = Double(successCount) / 20.0
    XCTAssertGreaterThanOrEqual(
      successRate, 0.95, "Overlapping range mutations should complete ≥95%")
  }

  /// Tests that bogus size mutations are handled gracefully.
  func testBogusSizeMutations() async throws {
    let generator = CorruptPayloadGenerator(seed: 300)
    let pipeline = ParsePipeline.live(options: .tolerant)
    var successCount = 0

    for i in 0..<20 {
      let payload = generator.generateBogusSize(mutationSeed: UInt64(i))
      let result = try await parsePayload(payload.data, pipeline: pipeline)
      if result.completed {
        successCount += 1
      }
    }

    let successRate = Double(successCount) / 20.0
    XCTAssertGreaterThanOrEqual(successRate, 0.95, "Bogus size mutations should complete ≥95%")
  }

  // MARK: - CI Integration Test

  /// Ensures fuzzing harness completes within benchmark budget for CI.
  func testFuzzHarnessCompletesWithinBenchmarkBudget() async throws {
    let startTime = Date()
    let generator = CorruptPayloadGenerator(seed: 999)
    let pipeline = ParsePipeline.live(options: .tolerant)

    // Run subset for CI performance validation
    let ciIterations = 20
    for i in 0..<ciIterations {
      let payload = generator.generateCorruptPayload(mutationSeed: UInt64(i))
      _ = try? await parsePayload(payload.data, pipeline: pipeline)
    }

    let duration = Date().timeIntervalSince(startTime)
    let perIterationTime = duration / Double(ciIterations)

    // Assert: per-iteration time reasonable for 100 iterations in CI
    let estimatedTotal = perIterationTime * Double(fuzzIterations)
    XCTAssertLessThan(
      estimatedTotal, 300.0, "Estimated total runtime \(estimatedTotal)s exceeds 5min budget")
  }

  // MARK: - Helper Methods

  private func collectEvents(from stream: ParsePipeline.EventStream) async throws -> [ParseEvent] {
    var events: [ParseEvent] = []
    for try await event in stream {
      events.append(event)
    }
    return events
  }

  private struct ParseResult {
    let completed: Bool
    let eventCount: Int
    let issueCount: Int
  }

  private func parsePayload(_ data: Data, pipeline: ParsePipeline) async throws -> ParseResult {
    let tempURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("parse_\(UUID().uuidString).mp4")
    try data.write(to: tempURL, options: [.atomic])
    defer { try? FileManager.default.removeItem(at: tempURL) }

    let reader = try ChunkedFileReader(fileURL: tempURL)
    let store = ParseIssueStore()
    var context = ParsePipeline.Context(options: .tolerant, issueStore: store)
    context.source = tempURL

    let events = try await collectEvents(from: pipeline.events(for: reader, context: context))

    return ParseResult(
      completed: true,
      eventCount: events.count,
      issueCount: store.issuesSnapshot().count
    )
  }

  private func saveReproductionArtifact(_ artifact: ReproductionArtifact) throws {
    let root = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
    let artifactsDir =
      root
      .appendingPathComponent(reproArtifactsPath)

    try FileManager.default.createDirectory(at: artifactsDir, withIntermediateDirectories: true)

    let filename = "fuzz_repro_seed\(artifact.seed).json"
    let fileURL = artifactsDir.appendingPathComponent(filename)

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(artifact)
    try data.write(to: fileURL, options: [.atomic])

    // Also save binary payload
    let payloadURL = artifactsDir.appendingPathComponent("fuzz_repro_seed\(artifact.seed).mp4")
    try artifact.payload.write(to: payloadURL, options: [.atomic])

    print("Saved reproduction artifact: \(filename)")
  }
}

// MARK: - Support Types

/// Generates deterministically corrupted MP4 payloads using seeded random mutations.
struct CorruptPayloadGenerator {
  private let baseSeed: UInt64

  init(seed: UInt64) {
    self.baseSeed = seed
  }

  func generateCorruptPayload(mutationSeed: UInt64) -> CorruptPayload {
    var rng = SeededRandomNumberGenerator(seed: baseSeed &+ mutationSeed)
    let mutationType = MutationType.allCases.randomElement(using: &rng)!

    switch mutationType {
    case .headerTruncation:
      return generateHeaderTruncation(mutationSeed: mutationSeed)
    case .overlappingRanges:
      return generateOverlappingRanges(mutationSeed: mutationSeed)
    case .bogusSize:
      return generateBogusSize(mutationSeed: mutationSeed)
    case .invalidFourCC:
      return generateInvalidFourCC(mutationSeed: mutationSeed)
    case .zeroSizeLoop:
      return generateZeroSizeLoop(mutationSeed: mutationSeed)
    case .payloadTruncation:
      return generatePayloadTruncation(mutationSeed: mutationSeed)
    }
  }

  func generateHeaderTruncation(mutationSeed: UInt64) -> CorruptPayload {
    var rng = SeededRandomNumberGenerator(seed: baseSeed &+ mutationSeed)
    let truncateAt = Int.random(in: 1...3, using: &rng)  // Truncate header partway

    var data = Data()
    // Incomplete box header
    for _ in 0..<truncateAt {
      data.append(UInt8.random(in: 0...255, using: &rng))
    }

    return CorruptPayload(
      data: data,
      mutation: MutationDescription(
        type: .headerTruncation,
        description: "Header truncated at byte \(truncateAt)"
      )
    )
  }

  func generateOverlappingRanges(mutationSeed: UInt64) -> CorruptPayload {
    var rng = SeededRandomNumberGenerator(seed: baseSeed &+ mutationSeed)

    // Create parent box
    var data = Data()
    let parentSize: UInt32 = 100
    data.append(contentsOf: withUnsafeBytes(of: parentSize.bigEndian) { Data($0) })
    data.append(contentsOf: "moov".data(using: .ascii)!)

    // Add child that exceeds parent range
    let childSize: UInt32 = UInt32.random(in: 200...500, using: &rng)
    data.append(contentsOf: withUnsafeBytes(of: childSize.bigEndian) { Data($0) })
    data.append(contentsOf: "trak".data(using: .ascii)!)

    // Pad to declared parent size
    while data.count < Int(parentSize) {
      data.append(0)
    }

    return CorruptPayload(
      data: data,
      mutation: MutationDescription(
        type: .overlappingRanges,
        description: "Child size \(childSize) exceeds parent \(parentSize)"
      )
    )
  }

  func generateBogusSize(mutationSeed: UInt64) -> CorruptPayload {
    var rng = SeededRandomNumberGenerator(seed: baseSeed &+ mutationSeed)

    var data = Data()
    // Box with impossibly large size
    let bogusSize: UInt32 = UInt32.random(in: 0x7FFF_0000...0xFFFF_FFFF, using: &rng)
    data.append(contentsOf: withUnsafeBytes(of: bogusSize.bigEndian) { Data($0) })
    data.append(contentsOf: "ftyp".data(using: .ascii)!)

    // Add minimal payload
    data.append(contentsOf: "iso5".data(using: .ascii)!)

    return CorruptPayload(
      data: data,
      mutation: MutationDescription(
        type: .bogusSize,
        description: "Box declares size \(bogusSize) but actual payload tiny"
      )
    )
  }

  func generateInvalidFourCC(mutationSeed: UInt64) -> CorruptPayload {
    var rng = SeededRandomNumberGenerator(seed: baseSeed &+ mutationSeed)

    var data = Data()
    let size: UInt32 = 16
    data.append(contentsOf: withUnsafeBytes(of: size.bigEndian) { Data($0) })

    // Non-ASCII fourcc bytes
    for _ in 0..<4 {
      data.append(UInt8.random(in: 0x00...0x1F, using: &rng))
    }

    // Pad payload
    while data.count < Int(size) {
      data.append(0)
    }

    return CorruptPayload(
      data: data,
      mutation: MutationDescription(
        type: .invalidFourCC,
        description: "FourCC contains non-ASCII bytes"
      )
    )
  }

  func generateZeroSizeLoop(mutationSeed: UInt64) -> CorruptPayload {
    var rng = SeededRandomNumberGenerator(seed: baseSeed &+ mutationSeed)

    var data = Data()
    // Parent container
    let parentSize: UInt32 = 100
    data.append(contentsOf: withUnsafeBytes(of: parentSize.bigEndian) { Data($0) })
    data.append(contentsOf: "moov".data(using: .ascii)!)

    // Add multiple zero-size children to trigger loop guard
    let zeroCount = Int.random(in: 10...30, using: &rng)
    for _ in 0..<zeroCount {
      let zeroSize: UInt32 = 0
      data.append(contentsOf: withUnsafeBytes(of: zeroSize.bigEndian) { Data($0) })
      data.append(contentsOf: "trak".data(using: .ascii)!)
    }

    // Pad to parent size
    while data.count < Int(parentSize) {
      data.append(0)
    }

    return CorruptPayload(
      data: data,
      mutation: MutationDescription(
        type: .zeroSizeLoop,
        description: "Parent contains \(zeroCount) zero-size children"
      )
    )
  }

  func generatePayloadTruncation(mutationSeed: UInt64) -> CorruptPayload {
    var rng = SeededRandomNumberGenerator(seed: baseSeed &+ mutationSeed)

    var data = Data()
    let declaredSize: UInt32 = UInt32.random(in: 200...1000, using: &rng)
    let actualSize = Int.random(in: 10...50, using: &rng)  // Much smaller

    data.append(contentsOf: withUnsafeBytes(of: declaredSize.bigEndian) { Data($0) })
    data.append(contentsOf: "moov".data(using: .ascii)!)

    // Actual payload smaller than declared
    for _ in 0..<actualSize {
      data.append(UInt8.random(in: 0...255, using: &rng))
    }

    return CorruptPayload(
      data: data,
      mutation: MutationDescription(
        type: .payloadTruncation,
        description: "Declared size \(declaredSize) but actual \(actualSize + 8)"
      )
    )
  }

  enum MutationType: CaseIterable {
    case headerTruncation
    case overlappingRanges
    case bogusSize
    case invalidFourCC
    case zeroSizeLoop
    case payloadTruncation
  }
}

struct CorruptPayload {
  let data: Data
  let mutation: MutationDescription
}

struct MutationDescription: Codable {
  let type: String
  let description: String

  init(type: CorruptPayloadGenerator.MutationType, description: String) {
    self.type = String(describing: type)
    self.description = description
  }
}

/// Aggregates fuzzing statistics for completion rate analysis.
struct FuzzStatistics {
  private(set) var successCount: Int = 0
  private(set) var failureCount: Int = 0
  private(set) var failures: [FailureRecord] = []

  struct FailureRecord {
    let seed: UInt64
    let mutation: MutationDescription
    let error: Error
  }

  mutating func recordSuccess(
    seed: UInt64, mutation: MutationDescription, eventCount: Int, issueCount: Int
  ) {
    successCount += 1
  }

  mutating func recordFailure(seed: UInt64, mutation: MutationDescription, error: Error) {
    failureCount += 1
    failures.append(FailureRecord(seed: seed, mutation: mutation, error: error))
  }

  var totalCount: Int {
    successCount + failureCount
  }

  var successRate: Double {
    guard totalCount > 0 else { return 0.0 }
    return Double(successCount) / Double(totalCount)
  }

  var summary: String {
    """
    Fuzzing Statistics:
    -------------------
    Total runs: \(totalCount)
    Successful: \(successCount)
    Failed: \(failureCount)
    Success rate: \(String(format: "%.2f%%", successRate * 100))
    """
  }
}

/// Captures reproduction artifacts for failed fuzzing cases.
struct ReproductionArtifact: Codable {
  let seed: UInt64
  let mutation: MutationDescription
  let payload: Data
  let errorDescription: String

  init(seed: UInt64, mutation: MutationDescription, payload: Data, error: Error) {
    self.seed = seed
    self.mutation = mutation
    self.payload = payload
    self.errorDescription = error.localizedDescription
  }
}

/// Seeded random number generator for deterministic fuzzing.
struct SeededRandomNumberGenerator: RandomNumberGenerator {
  private var state: UInt64

  init(seed: UInt64) {
    self.state = seed
  }

  mutating func next() -> UInt64 {
    // Simple LCG (Linear Congruential Generator)
    state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
    return state
  }
}
