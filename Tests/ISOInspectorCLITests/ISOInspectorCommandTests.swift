import ArgumentParser
import XCTest
@testable import ISOInspectorCLI
@testable import ISOInspectorKit

final class ISOInspectorCommandTests: XCTestCase {
    func testRunWithoutArgumentsShowsHelpWithPlannedSubcommands() async throws {
        let help = ISOInspectorCommand.helpMessage()
        XCTAssertTrue(help.contains(ISOInspectorKit.projectName))
        XCTAssertTrue(help.localizedCaseInsensitiveContains("inspect"))
        XCTAssertTrue(help.localizedCaseInsensitiveContains("validate"))
        XCTAssertTrue(help.localizedCaseInsensitiveContains("export"))

        var command = try ISOInspectorCommand.parse([])

        do {
            try await command.run()
            XCTFail("Expected CleanExit for help request")
        } catch let exit as CleanExit {
            XCTAssertEqual(exit.description, "--help")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRunBootstrapsSharedContextWithEnvironmentFromFactory() async throws {
        let printed = MutableBox<[String]>([])
        let customEnvironment = ISOInspectorCLIEnvironment(
            refreshCatalog: { _, _ in },
            parsePipeline: .live(),
            formatter: EventConsoleFormatter(),
            print: { printed.value.append($0) },
            printError: { _ in }
        )

        await MainActor.run {
            ISOInspectorCommand.contextFactory = { _ in
                ISOInspectorCommandContext(environment: customEnvironment)
            }
            ISOInspectorCommandContextStore.reset()
        }

        var command = try ISOInspectorCommand.parse([])
        _ = try? await command.run()

        let context = await MainActor.run { ISOInspectorCommandContextStore.current }
        context.environment.print("Hello")

        XCTAssertEqual(printed.value, ["Hello"])

        await MainActor.run {
            ISOInspectorCommandContextStore.reset()
            ISOInspectorCommand.contextFactory = ISOInspectorCommand.defaultContextFactory
        }
    }

    func testInspectCommandStreamsEventsAndRespectsResearchLogOption() async throws {
        final class Recorder: ResearchLogRecording, @unchecked Sendable {
            var entries: [ResearchLogEntry] = []

            func record(_ entry: ResearchLogEntry) {
                entries.append(entry)
            }
        }

        let recorder = Recorder()
        let header = try makeHeader(type: "ftyp", size: 24)
        let descriptor = try XCTUnwrap(BoxCatalog.shared.descriptor(for: header))
        let issue = ValidationIssue(ruleID: "VR-006", message: "Unknown box", severity: .info)
        let event = ParseEvent(
            kind: .willStartBox(header: header, depth: 0),
            offset: header.startOffset,
            metadata: descriptor,
            validationIssues: [issue]
        )

        let printed = MutableBox<[String]>([])
        let errors = MutableBox<[String]>([])
        let environment = ISOInspectorCLIEnvironment(
            refreshCatalog: { _, _ in },
            makeReader: { url in
                XCTAssertEqual(url.path, "/tmp/sample.mp4")
                return StubReader()
            },
            parsePipeline: ParsePipeline(buildStream: { _, context in
                context.researchLog?.record(
                    ResearchLogEntry(
                        boxType: header.identifierString,
                        filePath: context.source?.path ?? "",
                        startOffset: header.startOffset,
                        endOffset: header.endOffset
                    )
                )
                return AsyncThrowingStream { continuation in
                    continuation.yield(event)
                    continuation.finish()
                }
            }),
            formatter: EventConsoleFormatter(),
            print: { printed.value.append($0) },
            printError: { errors.value.append($0) },
            makeResearchLogWriter: { url in
                XCTAssertEqual(url.path, "/tmp/custom-log.json")
                return recorder
            },
            defaultResearchLogURL: { URL(fileURLWithPath: "/tmp/default-log.json") }
        )

        await MainActor.run {
            ISOInspectorCommandContextStore.bootstrap(with: .init(environment: environment))
        }

        var command = try ISOInspectorCommand.Commands.Inspect.parse([
            "/tmp/sample.mp4",
            "--research-log",
            "/tmp/custom-log.json"
        ])

        try await command.run()

        XCTAssertTrue(errors.value.isEmpty)
        XCTAssertEqual(recorder.entries.count, 1)
        XCTAssertTrue(printed.value.first?.contains("Research log") ?? false)
        XCTAssertTrue(printed.value.contains(where: { $0.contains("VR-006 schema v") }))
        XCTAssertTrue(printed.value.contains(where: { $0.contains(descriptor.summary) }))

        await MainActor.run {
            ISOInspectorCommandContextStore.reset()
        }
    }

    func testValidateCommandPrintsSummaryAndSetsExitCodeBasedOnIssues() async throws {
        let header = try makeHeader(type: "ftyp", size: 24)
        let descriptor = try XCTUnwrap(BoxCatalog.shared.descriptor(for: header))
        let warning = ValidationIssue(ruleID: "VR-003", message: "Flags mismatch", severity: .warning)
        let error = ValidationIssue(ruleID: "VR-001", message: "Size mismatch", severity: .error)
        let event = ParseEvent(
            kind: .willStartBox(header: header, depth: 0),
            offset: header.startOffset,
            metadata: descriptor,
            validationIssues: [warning, error]
        )

        let printed = MutableBox<[String]>([])
        let errors = MutableBox<[String]>([])
        let environment = ISOInspectorCLIEnvironment(
            refreshCatalog: { _, _ in },
            makeReader: { _ in StubReader() },
            parsePipeline: ParsePipeline(buildStream: { _, _ in
                AsyncThrowingStream { continuation in
                    continuation.yield(event)
                    continuation.finish()
                }
            }),
            formatter: EventConsoleFormatter(),
            print: { printed.value.append($0) },
            printError: { errors.value.append($0) }
        )

        await MainActor.run {
            ISOInspectorCommandContextStore.bootstrap(with: .init(environment: environment))
        }

        var command = try ISOInspectorCommand.Commands.Validate.parse([
            "/tmp/sample.mp4"
        ])

        do {
            try await command.run()
            XCTFail("Expected ExitCode to be thrown")
        } catch let exit as ExitCode {
            XCTAssertEqual(exit.rawValue, 2)
        }

        XCTAssertTrue(errors.value.isEmpty)
        XCTAssertTrue(printed.value.first?.contains("Validation summary") ?? false)
        XCTAssertTrue(printed.value.contains(where: { $0.contains("Errors: 1") }))
        XCTAssertTrue(printed.value.contains(where: { $0.contains("Warnings: 1") }))
        XCTAssertTrue(printed.value.contains(where: { $0.contains("VR-001") }))
        XCTAssertTrue(printed.value.contains(where: { $0.contains("VR-003") }))

        await MainActor.run {
            ISOInspectorCommandContextStore.reset()
        }
    }
}

private final class MutableBox<Value>: @unchecked Sendable {
    var value: Value

    init(_ value: Value) {
        self.value = value
    }
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
