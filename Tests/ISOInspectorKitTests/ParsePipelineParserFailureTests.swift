import Foundation
import Testing

@testable import ISOInspectorKit

@Suite struct ParsePipelineParserFailureTests {
    private enum ParserFailure: Error { case injected }

    @Test func parserFailureLeavesPayloadEmptyAndParsingContinues() async throws {
        let badType = try FourCharCode("bad1")
        var registry = BoxParserRegistry()
        registry.register(parser: { _, _ in throw ParserFailure.injected }, for: badType)
        let data = Data([
            0, 0, 0, 8, 0x62, 0x61, 0x64, 0x31,
            0, 0, 0, 8, 0x66, 0x72, 0x65, 0x65,
        ])
        let reader = InMemoryRandomAccessReader(data: data)
        var events: [ParseEvent] = []
        for try await event in ParsePipeline.live(registry: registry).events(for: reader) {
            events.append(event)
        }

        #expect(events.count == 4)
        let first = try #require(events.first)
        if case .willStartBox(let header, _) = first.kind {
            #expect(header.type == badType)
            #expect(first.payload == nil)
        } else { Issue.record("Expected the first box to start") }

        let next = try #require(events.first { event in
            if case .willStartBox(let header, _) = event.kind {
                return header.type.rawValue == "free"
            }
            return false
        })
        #expect(next.payload != nil)
        let last = try #require(events.last)
        if case .didFinishBox(let header, _) = last.kind {
            #expect(header.type.rawValue == "free")
        } else { Issue.record("Expected the following box to finish") }
    }
}
