import Foundation
import Testing

@testable import ISOInspectorKit

@Suite struct NALValidationPipelineTests {
    @Test(arguments: [ParsePipeline.Options.strict, .tolerant])
    func reportsCorruptNALAndContinuesParsing(options: ParsePipeline.Options) async throws {
        var data = try fixture()
        // First video sample in this public test fixture; preserve all MP4 box boundaries.
        data.replaceSubrange(4445..<4449, with: [0xcd, 0x38, 0xcc, 0xfe])
        let events = try await parse(data, options: options)
        let issues = events.flatMap(\.validationIssues).filter { $0.ruleID == "VR-019" }
        #expect(issues.count == 1)
        let issue = try #require(issues.first)
        #expect(issue.severity == .error)
        #expect(issue.message.contains("3443051774"))
        #expect(issue.message.contains("sample 1"))
        #expect(events.contains { event in
            if case .didFinishBox(let header, _) = event.kind { return header.type.rawValue == "mdat" }
            return false
        })
    }

    @Test func validFixtureHasNoNALFramingIssues() async throws {
        let events = try await parse(fixture())
        #expect(events.flatMap(\.validationIssues).allSatisfy { $0.ruleID != "VR-019" })
    }

    private func fixture() throws -> Data {
        let url = try #require(Bundle.module.url(forResource: "bear-1280x720", withExtension: "txt"))
        return try #require(Data(base64Encoded: String(contentsOf: url, encoding: .utf8), options: .ignoreUnknownCharacters))
    }

    private func parse(_ data: Data, options: ParsePipeline.Options = .strict) async throws -> [ParseEvent] {
        var events: [ParseEvent] = []
        for try await event in ParsePipeline.live(options: options).events(for: InMemoryRandomAccessReader(data: data)) {
            events.append(event)
        }
        return events
    }
}
