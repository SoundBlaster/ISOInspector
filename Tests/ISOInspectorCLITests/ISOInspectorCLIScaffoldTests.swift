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
        var capturedSource: URL?
        var capturedOutput: URL?
        let environment = ISOInspectorCLIEnvironment(
            refreshCatalog: { source, output in
                capturedSource = source
                capturedOutput = output
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

        XCTAssertEqual(capturedSource, URL(string: "https://example.com/custom.json"))
        XCTAssertEqual(capturedOutput?.path, "/tmp/catalog.json")
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
        var printed: [String] = []
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
            print: { printed.append($0) },
            printError: { _ in }
        )

        ISOInspectorCLIRunner.run(
            arguments: [
                "isoinspect",
                "inspect",
                "/tmp/sample.mp4"
            ],
            environment: environment
        )

        let output = try XCTUnwrap(printed.first)
        XCTAssertTrue(output.contains(descriptor.name))
        XCTAssertTrue(output.contains(descriptor.summary))
        XCTAssertTrue(output.contains(issue.message))
    }

    func testRunInspectRequiresFilePath() {
        var errors: [String] = []
        let environment = ISOInspectorCLIEnvironment(
            refreshCatalog: { _, _ in },
            makeReader: { _ in StubReader() },
            parsePipeline: ParsePipeline(buildStream: { _ in AsyncThrowingStream { $0.finish() } }),
            formatter: EventConsoleFormatter(),
            print: { _ in },
            printError: { errors.append($0) }
        )

        ISOInspectorCLIRunner.run(
            arguments: [
                "isoinspect",
                "inspect"
            ],
            environment: environment
        )

        XCTAssertEqual(errors.last, "inspect requires a file path.")
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
