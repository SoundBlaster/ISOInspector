import XCTest
@testable import ISOInspectorCLI
@testable import ISOInspectorKit

final class ISOInspectorCLIScaffoldTests: XCTestCase {
    func testWelcomeSummaryIncludesProjectNameAndFocus() {
        let summary = ISOInspectorCLIIO.welcomeSummary()
        XCTAssertTrue(summary.contains(ISOInspectorKit.projectName))
        XCTAssertTrue(summary.contains("Phase A"))
    }

    func testHelpTextMentionsMP4RARefreshCommand() {
        let help = ISOInspectorCLIRunner.helpText()
        XCTAssertTrue(help.contains("mp4ra"))
        XCTAssertTrue(help.contains("refresh"))
    }

    func testHelpTextMentionsInspectCommand() {
        let help = ISOInspectorCLIRunner.helpText()
        XCTAssertTrue(help.contains("inspect"))
    }

    func testRunExecutesMP4RARefreshWithParsedArguments() throws {
        let capturedSource = MutableBox<URL?>(nil)
        let capturedOutput = MutableBox<URL?>(nil)
        let environment = ISOInspectorCLIEnvironment(
            refreshCatalog: { source, output in
                capturedSource.value = source
                capturedOutput.value = output
            },
            makeReader: { _ in StubReader() },
            parsePipeline: ParsePipeline(buildStream: { _ in AsyncThrowingStream { $0.finish() } }),
            formatter: EventConsoleFormatter(),
            print: { _ in },
            printError: { _ in }
        )

        ISOInspectorCLIRunner.run(
            arguments: [
                "isoinspect",
                "mp4ra",
                "refresh",
                "--source",
                "https://example.com/custom.json",
                "--output",
                "/tmp/catalog.json"
            ],
            environment: environment
        )

        XCTAssertEqual(capturedSource.value, URL(string: "https://example.com/custom.json"))
        XCTAssertEqual(capturedOutput.value?.path, "/tmp/catalog.json")
    }

    func testRunInspectPrintsFormattedEvents() throws {
        let header = try makeHeader(type: "ftyp", size: 24)
        let descriptor = try XCTUnwrap(BoxCatalog.shared.descriptor(for: header))
        let issue = ValidationIssue(
            ruleID: "VR-006",
            message: "Unknown box encountered",
            severity: .info
        )
        let event = ParseEvent(
            kind: .willStartBox(header: header, depth: 0),
            offset: 0,
            metadata: descriptor,
            validationIssues: [issue]
        )
        final class Recorder: ResearchLogRecording, @unchecked Sendable {
            func record(_ entry: ResearchLogEntry) {}
        }

        let printed = MutableBox<[String]>([])
        let environment = ISOInspectorCLIEnvironment(
            refreshCatalog: { _, _ in },
            makeReader: { _ in StubReader() },
            parsePipeline: ParsePipeline(buildStream: { _ in
                AsyncThrowingStream { continuation in
                    continuation.yield(event)
                    continuation.finish()
                }
            }),
            formatter: EventConsoleFormatter(),
            print: { printed.value.append($0) },
            printError: { _ in },
            makeResearchLogWriter: { url in
                XCTAssertEqual(url.path, "/tmp/research-log.json")
                return Recorder()
            },
            defaultResearchLogURL: { URL(fileURLWithPath: "/tmp/research-log.json") }
        )

        ISOInspectorCLIRunner.run(
            arguments: [
                "isoinspect",
                "inspect",
                "/tmp/sample.mp4"
            ],
            environment: environment
        )

        XCTAssertTrue(printed.value.first?.contains("Research log") ?? false)
        XCTAssertTrue(printed.value.dropFirst().first?.contains("VR-006 schema v") ?? false)
        let output = try XCTUnwrap(printed.value.dropFirst(2).first)
        XCTAssertTrue(output.contains(descriptor.name))
        XCTAssertTrue(output.contains(descriptor.summary))
        XCTAssertTrue(output.contains(issue.message))
    }

    func testRunInspectAppendsResearchLogEntries() throws {
        final class Recorder: ResearchLogRecording, @unchecked Sendable {
            var entries: [ResearchLogEntry] = []

            func record(_ entry: ResearchLogEntry) {
                entries.append(entry)
            }
        }

        let recorder = Recorder()
        let header = try makeHeader(type: "zzzz", size: 16)
        let issue = ValidationIssue(ruleID: "VR-006", message: "Unknown", severity: .info)
        let event = ParseEvent(
            kind: .willStartBox(header: header, depth: 0),
            offset: 0,
            metadata: nil,
            validationIssues: [issue]
        )

        let printed = MutableBox<[String]>([])
        let environment = ISOInspectorCLIEnvironment(
            refreshCatalog: { _, _ in },
            makeReader: { _ in StubReader() },
            parsePipeline: ParsePipeline(buildStream: { _, context in
                context.researchLog?.record(ResearchLogEntry(
                    boxType: header.identifierString,
                    filePath: context.source?.path ?? "",
                    startOffset: header.startOffset,
                    endOffset: header.endOffset
                ))
                return AsyncThrowingStream { continuation in
                    continuation.yield(event)
                    continuation.finish()
                }
            }),
            formatter: EventConsoleFormatter(),
            print: { printed.value.append($0) },
            printError: { _ in },
            makeResearchLogWriter: { url in
                XCTAssertEqual(url.path, "/tmp/research-log.json")
                return recorder
            },
            defaultResearchLogURL: { URL(fileURLWithPath: "/tmp/research-log.json") }
        )

        ISOInspectorCLIRunner.run(
            arguments: [
                "isoinspect",
                "inspect",
                "/tmp/sample.mp4"
            ],
            environment: environment
        )

        XCTAssertTrue(printed.value.contains(where: { $0.contains("/tmp/research-log.json") }))
        XCTAssertTrue(printed.value.contains(where: { $0.contains("VR-006 schema v") }))
        XCTAssertEqual(recorder.entries.count, 1)
        let entry = try XCTUnwrap(recorder.entries.first)
        XCTAssertEqual(entry.boxType, "zzzz")
        XCTAssertEqual(entry.filePath, "/tmp/sample.mp4")
        XCTAssertEqual(entry.startOffset, header.startOffset)
        XCTAssertEqual(entry.endOffset, header.endOffset)
    }

    func testRunInspectRequiresFilePath() {
        let errors = MutableBox<[String]>([])
        let environment = ISOInspectorCLIEnvironment(
            refreshCatalog: { _, _ in },
            makeReader: { _ in StubReader() },
            parsePipeline: ParsePipeline(buildStream: { _ in AsyncThrowingStream { $0.finish() } }),
            formatter: EventConsoleFormatter(),
            print: { _ in },
            printError: { errors.value.append($0) }
        )

        ISOInspectorCLIRunner.run(
            arguments: [
                "isoinspect",
                "inspect"
            ],
            environment: environment
        )

        XCTAssertEqual(errors.value.last, "inspect requires a file path.")
    }

    private struct StubReader: RandomAccessReader {
        let length: Int64 = 0

        func read(at offset: Int64, count: Int) throws -> Data { Data() }
    }

    private func makeHeader(type: String, size: Int64) throws -> BoxHeader {
        let fourCC = try FourCharCode(type)
        let range = Int64(0)..<size
        let payloadRange = Int64(8)..<size
        return BoxHeader(
            type: fourCC,
            totalSize: size,
            headerSize: 8,
            payloadRange: payloadRange,
            range: range,
            uuid: nil
        )
    }
}

private final class MutableBox<Value>: @unchecked Sendable {
    var value: Value

    init(_ value: Value) {
        self.value = value
    }
}
