import XCTest

@testable import ISOInspectorKit

final class CorruptFixtureCorpusTests: XCTestCase {
  private struct Manifest: Decodable {
    struct Corruption: Decodable {
      let category: String
      let pattern: String
      let affectedBoxes: [String]
      let expectedIssues: [String]
    }

    struct Fixture: Decodable {
      let id: String
      let filename: String
      let title: String
      let description: String
      let corruption: Corruption
      let smokeTest: Bool
    }

    let version: Int
    let fixtures: [Fixture]
  }

  private enum FixtureMaterializationError: LocalizedError {
    case missingBase64(String)
    case invalidBase64(String)

    var errorDescription: String? {
      switch self {
      case .missingBase64(let filename):
        return "Missing base64 source for fixture \(filename)"
      case .invalidBase64(let filename):
        return "Fixture \(filename) contains invalid base64 payload"
      }
    }
  }

  private lazy var manifestURL: URL = {
    let root = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()  // CorruptFixtureCorpusTests.swift
      .deletingLastPathComponent()  // ISOInspectorKitTests
      .deletingLastPathComponent()  // Tests
    return
      root
      .appendingPathComponent("Documentation")
      .appendingPathComponent("FixtureCatalog")
      .appendingPathComponent("corrupt-fixtures.json")
  }()

  private lazy var fixturesRoot: URL = {
    let root = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()  // CorruptFixtureCorpusTests.swift
      .deletingLastPathComponent()  // ISOInspectorKitTests
      .deletingLastPathComponent()  // Tests
    return
      root
      .appendingPathComponent("Fixtures")
      .appendingPathComponent("Corrupt")
  }()

  func testManifestDefinesCorruptionScenarios() throws {
    let data = try Data(contentsOf: manifestURL)
    let manifest = try JSONDecoder().decode(Manifest.self, from: data)

    XCTAssertEqual(manifest.version, 1)
    XCTAssertGreaterThanOrEqual(manifest.fixtures.count, 10)

    var identifiers: Set<String> = []
    for fixture in manifest.fixtures {
      XCTAssertFalse(fixture.id.isEmpty, "Fixture id should not be empty")
      XCTAssertTrue(identifiers.insert(fixture.id).inserted, "Duplicate fixture id \(fixture.id)")
      XCTAssertFalse(fixture.filename.isEmpty, "Fixture \(fixture.id) missing filename")
      XCTAssertFalse(fixture.title.isEmpty, "Fixture \(fixture.id) missing title")
      XCTAssertFalse(fixture.description.isEmpty, "Fixture \(fixture.id) missing description")
      XCTAssertFalse(
        fixture.corruption.expectedIssues.isEmpty, "Fixture \(fixture.id) missing expected issues")
      let base64URL = fixturesRoot.appendingPathComponent("\(fixture.filename).base64")
      XCTAssertTrue(
        FileManager.default.fileExists(atPath: base64URL.path),
        "Fixture \(fixture.id) missing base64 source \(base64URL.lastPathComponent)"
      )
    }
  }

  func testTolerantPipelineProcessesSmokeFixtures() async throws {
    let data = try Data(contentsOf: manifestURL)
    let manifest = try JSONDecoder().decode(Manifest.self, from: data)
    let smokeFixtures = manifest.fixtures.filter(\.smokeTest)
    XCTAssertFalse(smokeFixtures.isEmpty, "Manifest must mark at least one smoke fixture")

    let pipeline = ParsePipeline.live(options: .tolerant)

    for fixture in smokeFixtures {
      let url = try fixtureURL(for: fixture.filename)
      let reader = try ChunkedFileReader(fileURL: url)
      let store = ParseIssueStore()
      var context = ParsePipeline.Context(options: .tolerant, issueStore: store)
      context.source = url

      _ = try await collectEvents(from: pipeline.events(for: reader, context: context))

      let issues = store.issuesSnapshot()
      XCTAssertFalse(issues.isEmpty, "Expected issues for fixture \(fixture.id)")
      let codes = Set(issues.map(\.code))
      for expected in fixture.corruption.expectedIssues {
        XCTAssertTrue(
          codes.contains(expected), "Fixture \(fixture.id) missing expected issue \(expected)")
      }
    }
  }

  private func collectEvents(from stream: ParsePipeline.EventStream) async throws -> [ParseEvent] {
    var events: [ParseEvent] = []
    for try await event in stream {
      events.append(event)
    }
    return events
  }

  private func fixtureURL(for filename: String) throws -> URL {
    let binaryURL = fixturesRoot.appendingPathComponent(filename)
    if FileManager.default.fileExists(atPath: binaryURL.path) {
      return binaryURL
    }

    let base64URL = binaryURL.appendingPathExtension("base64")
    guard FileManager.default.fileExists(atPath: base64URL.path) else {
      throw FixtureMaterializationError.missingBase64(filename)
    }

    let encoded = try String(contentsOf: base64URL, encoding: .utf8)
    guard let data = Data(base64Encoded: encoded, options: .ignoreUnknownCharacters) else {
      throw FixtureMaterializationError.invalidBase64(filename)
    }

    try data.write(to: binaryURL, options: [.atomic])
    return binaryURL
  }
}
