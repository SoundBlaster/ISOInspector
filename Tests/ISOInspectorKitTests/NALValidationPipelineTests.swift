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

    @Test(arguments: [ParsePipeline.Options.strict, .tolerant])
    func nalIssueIsCountedOnceWithItsActualByteRange(options: ParsePipeline.Options) async throws {
        var data = try fixture()
        data.replaceSubrange(4445..<4449, with: [0xcd, 0x38, 0xcc, 0xfe])
        let store = ParseIssueStore(queue: DispatchQueue(label: "nal.integrity.test"))
        let context = ParsePipeline.Context(options: options, issueStore: store)
        var events: [ParseEvent] = []
        for try await event in ParsePipeline.live(options: options).events(
            for: InMemoryRandomAccessReader(data: data), context: context
        ) { events.append(event) }
        let recorded = store.issuesSnapshot().filter { $0.code == "VR-019" }
        #expect(recorded.count == 1)
        #expect(store.metricsSnapshot().errorCount == store.issuesSnapshot().filter { $0.severity == .error }.count)
        let issue = try #require(recorded.first)
        #expect(issue.severity == .error)
        #expect(issue.byteRange == 4445..<4449)
        let track = try #require(events.first { event in
            if case .didFinishBox(let header, _) = event.kind { return event.issues.contains(issue) && header.type.rawValue == "trak" }
            return false
        })
        if case .didFinishBox(let header, _) = track.kind {
            #expect(issue.affectedNodeIDs == [header.startOffset])
        }
        #expect(events.contains { event in
            if case .didFinishBox(let header, _) = event.kind { return header.type.rawValue == "mdat" }
            return false
        })
    }

    @Test func validFileDoesNotGainNALIntegrityIssues() async throws {
        let store = ParseIssueStore(queue: DispatchQueue(label: "nal.integrity.valid"))
        let context = ParsePipeline.Context(options: .tolerant, issueStore: store)
        for try await _ in ParsePipeline.live(options: .tolerant).events(
            for: InMemoryRandomAccessReader(data: try fixture()), context: context
        ) {}
        #expect(store.issuesSnapshot().allSatisfy { $0.code != "VR-019" })
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
