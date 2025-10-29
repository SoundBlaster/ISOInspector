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
        XCTAssertTrue(help.localizedCaseInsensitiveContains("batch"))

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

    func testBootstrapAppliesQuietVerbosityAndSuppressesStandardOutput() async throws {
        let printed = MutableBox<[String]>([])
        let environment = ISOInspectorCLIEnvironment(
            refreshCatalog: { _, _ in },
            parsePipeline: .live(),
            formatter: EventConsoleFormatter(),
            print: { printed.value.append($0) },
            printError: { _ in }
        )

        await MainActor.run {
            ISOInspectorCommand.contextFactory = { _ in
                ISOInspectorCommandContext(environment: environment)
            }
            ISOInspectorCommandContextStore.reset()
        }

        let options = try ISOInspectorCommand.GlobalOptions.parse(["--quiet"])

        await ISOInspectorCommand.bootstrap(with: options)

        let context = await MainActor.run { ISOInspectorCommandContextStore.current }
        context.environment.print("Hidden")

        XCTAssertTrue(printed.value.isEmpty)
        XCTAssertEqual(context.verbosity, .quiet)
        XCTAssertTrue(context.environment.logVerbosity.isQuiet)

        await MainActor.run {
            ISOInspectorCommandContextStore.reset()
            ISOInspectorCommand.contextFactory = ISOInspectorCommand.defaultContextFactory
        }
    }

    func testBootstrapAppliesVerboseVerbosityAndPrefixesOutput() async throws {
        let printed = MutableBox<[String]>([])
        let environment = ISOInspectorCLIEnvironment(
            refreshCatalog: { _, _ in },
            parsePipeline: .live(),
            formatter: EventConsoleFormatter(),
            print: { printed.value.append($0) },
            printError: { _ in }
        )

        await MainActor.run {
            ISOInspectorCommand.contextFactory = { _ in
                ISOInspectorCommandContext(environment: environment)
            }
            ISOInspectorCommandContextStore.reset()
        }

        let options = try ISOInspectorCommand.GlobalOptions.parse(["--verbose"])

        await ISOInspectorCommand.bootstrap(with: options)

        let context = await MainActor.run { ISOInspectorCommandContextStore.current }
        context.environment.print("Loud")

        XCTAssertEqual(printed.value, ["[verbose] Loud"])
        XCTAssertEqual(context.verbosity, .verbose)
        XCTAssertTrue(context.environment.logVerbosity.isVerbose)

        await MainActor.run {
            ISOInspectorCommandContextStore.reset()
            ISOInspectorCommand.contextFactory = ISOInspectorCommand.defaultContextFactory
        }
    }

    func testBootstrapDisablesTelemetryWhenRequested() async throws {
        let environment = ISOInspectorCLIEnvironment(
            refreshCatalog: { _, _ in }
        )

        await MainActor.run {
            ISOInspectorCommand.contextFactory = { _ in
                ISOInspectorCommandContext(environment: environment)
            }
            ISOInspectorCommandContextStore.reset()
        }

        let options = try ISOInspectorCommand.GlobalOptions.parse(["--disable-telemetry"])

        await ISOInspectorCommand.bootstrap(with: options)

        let context = await MainActor.run { ISOInspectorCommandContextStore.current }
        XCTAssertFalse(context.environment.telemetryEnabled)
        XCTAssertEqual(context.telemetryMode, .disabled)

        await MainActor.run {
            ISOInspectorCommandContextStore.reset()
            ISOInspectorCommand.contextFactory = ISOInspectorCommand.defaultContextFactory
        }
    }

    func testBootstrapReEnablesTelemetryWhenEnvironmentDefaultsDisabled() async throws {
        let environment = ISOInspectorCLIEnvironment(
            refreshCatalog: { _, _ in },
            telemetryEnabled: false
        )

        await MainActor.run {
            ISOInspectorCommand.contextFactory = { _ in
                ISOInspectorCommandContext(environment: environment)
            }
            ISOInspectorCommandContextStore.reset()
        }

        let options = try ISOInspectorCommand.GlobalOptions.parse(["--enable-telemetry"])

        await ISOInspectorCommand.bootstrap(with: options)

        let context = await MainActor.run { ISOInspectorCommandContextStore.current }
        XCTAssertTrue(context.environment.telemetryEnabled)
        XCTAssertEqual(context.telemetryMode, .enabled)

        await MainActor.run {
            ISOInspectorCommandContextStore.reset()
            ISOInspectorCommand.contextFactory = ISOInspectorCommand.defaultContextFactory
        }
    }

    func testGlobalOptionsResolvesValidationConfigurationFromPresetAliasAndOverrides() throws {
        let options = try ISOInspectorCommand.GlobalOptions.parse([
            "--structural-only",
            "--disable-rule", "VR-006",
            "--enable-rule", "VR-001"
        ])

        let presets = try ValidationPreset.loadBundledPresets()
        let defaultPresetID = ISOInspectorCommand.GlobalOptions.defaultPresetID(in: presets)
        let result = try options.makeValidationConfiguration(
            presets: presets,
            defaultPresetID: defaultPresetID
        )

        XCTAssertEqual(result.configuration.activePresetID, "structural")
        XCTAssertEqual(
            result.configuration.ruleOverrides[ValidationRuleIdentifier.researchLogRecording],
            false
        )
        XCTAssertEqual(
            result.configuration.ruleOverrides[ValidationRuleIdentifier.structuralSize],
            true
        )
        XCTAssertTrue(result.wasCustomized)
    }

    func testGlobalOptionsRejectsUnknownRuleIdentifiers() {
        XCTAssertThrowsError(try ISOInspectorCommand.GlobalOptions.parse([
            "--disable-rule", "VR-999"
        ])) { error in
            XCTAssertTrue(String(describing: error).contains("VR-999"))
        }
    }

    func testGlobalOptionsRejectsConflictingPresetSelections() {
        XCTAssertThrowsError(try ISOInspectorCommand.GlobalOptions.parse([
            "--preset", "all-rules",
            "--structural-only"
        ])) { error in
            let description = String(describing: error)
            XCTAssertTrue(description.localizedCaseInsensitiveContains("preset"))
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
            ISOInspectorCommand.contextFactory = { _ in
                ISOInspectorCommandContext(environment: environment)
            }
            ISOInspectorCommandContextStore.reset()
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
            ISOInspectorCommand.contextFactory = ISOInspectorCommand.defaultContextFactory
        }
    }

    func testValidateCommandFiltersDisabledRulesAndPrintsPresetMetadata() async throws {
        let header = try makeHeader(type: "ftyp", size: 24)
        let descriptor = try XCTUnwrap(BoxCatalog.shared.descriptor(for: header))
        let disabledIssue = ValidationIssue(
            ruleID: ValidationRuleIdentifier.researchLogRecording.rawValue,
            message: "Research log advisory",
            severity: .info
        )
        let errorIssue = ValidationIssue(
            ruleID: ValidationRuleIdentifier.structuralSize.rawValue,
            message: "Size mismatch",
            severity: .error
        )
        let event = ParseEvent(
            kind: .willStartBox(header: header, depth: 0),
            offset: header.startOffset,
            metadata: descriptor,
            validationIssues: [disabledIssue, errorIssue]
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

        let presets = [
            ValidationPreset(id: "all-rules", name: "All", summary: ""),
            ValidationPreset(
                id: "structural",
                name: "Structural Focus",
                summary: "",
                rules: [
                    ValidationPreset.RuleState(
                        ruleID: .movieDataOrdering,
                        isEnabled: false
                    ),
                    ValidationPreset.RuleState(
                        ruleID: .researchLogRecording,
                        isEnabled: false
                    )
                ]
            )
        ]

        let configuration = ValidationConfiguration(activePresetID: "structural")

        await MainActor.run {
            ISOInspectorCommand.contextFactory = { _ in
                ISOInspectorCommandContext(
                    environment: environment,
                    validationConfiguration: configuration,
                    validationPresets: presets,
                    validationConfigurationWasCustomized: true
                )
            }
            ISOInspectorCommandContextStore.reset()
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
        XCTAssertTrue(printed.value.contains("Validation preset: structural"))
        XCTAssertTrue(printed.value.contains(where: { $0.contains("VR-005") }))
        XCTAssertTrue(printed.value.contains(where: { $0.contains("VR-006") }))
        XCTAssertTrue(printed.value.contains(where: { $0.contains("Errors: 1") }))
        XCTAssertFalse(printed.value.contains(where: { $0.contains("Info: 1") }))

        await MainActor.run {
            ISOInspectorCommandContextStore.reset()
            ISOInspectorCommand.contextFactory = ISOInspectorCommand.defaultContextFactory
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
            ISOInspectorCommand.contextFactory = { _ in
                ISOInspectorCommandContext(environment: environment)
            }
            ISOInspectorCommandContextStore.reset()
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
            ISOInspectorCommand.contextFactory = ISOInspectorCommand.defaultContextFactory
        }
    }

    func testValidateCommandEmitsCodecWarningsFromFixture() async throws {
        let data = try loadFixtureData(named: "codec_invalid_configs")
        let printed = MutableBox<[String]>([])
        let errors = MutableBox<[String]>([])
        let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let fileURL = temporaryDirectory.appendingPathComponent("codec-invalid.mp4")
        try data.write(to: fileURL)

        let environment = ISOInspectorCLIEnvironment(
            refreshCatalog: { _, _ in },
            makeReader: { url in
                XCTAssertEqual(url, fileURL)
                return try ChunkedFileReader(fileURL: url)
            },
            parsePipeline: .live(),
            formatter: EventConsoleFormatter(),
            print: { printed.value.append($0) },
            printError: { errors.value.append($0) }
        )

        await MainActor.run {
            ISOInspectorCommand.contextFactory = { _ in
                ISOInspectorCommandContext(environment: environment)
            }
            ISOInspectorCommandContextStore.reset()
        }

        var command = try ISOInspectorCommand.Commands.Validate.parse([
            fileURL.path
        ])

        do {
            try await command.run()
            XCTFail("Expected ExitCode to be thrown")
        } catch let exit as ExitCode {
            XCTAssertEqual(exit.rawValue, 2)
        }

        XCTAssertTrue(errors.value.isEmpty)
        XCTAssertTrue(printed.value.contains(where: { $0.contains("Validation summary") }))
        XCTAssertTrue(printed.value.contains(where: { $0.contains("Errors: 2") }))
        XCTAssertTrue(printed.value.contains(where: { $0.contains("VR-018") && $0.contains("avcC") }))
        XCTAssertTrue(printed.value.contains(where: { $0.contains("VR-018") && $0.contains("hvcC") }))

        await MainActor.run {
            ISOInspectorCommandContextStore.reset()
            ISOInspectorCommand.contextFactory = ISOInspectorCommand.defaultContextFactory
        }
    }

    func testInspectCommandSurfacesSampleEncryptionMetadata() async throws {
        final class NullResearchLog: ResearchLogRecording, @unchecked Sendable {
            func record(_: ResearchLogEntry) {}
        }

        let data = try loadFixtureData(named: "sample_encryption_metadata")
        let printed = MutableBox<[String]>([])
        let errors = MutableBox<[String]>([])
        let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let fileURL = temporaryDirectory.appendingPathComponent("encryption-fragment.m4s")
        try data.write(to: fileURL)

        let environment = ISOInspectorCLIEnvironment(
            refreshCatalog: { _, _ in },
            makeReader: { url in
                XCTAssertEqual(url, fileURL)
                return try ChunkedFileReader(fileURL: url)
            },
            parsePipeline: .live(),
            formatter: EventConsoleFormatter(),
            print: { printed.value.append($0) },
            printError: { errors.value.append($0) },
            makeResearchLogWriter: { url in
                XCTAssertEqual(
                    url.deletingLastPathComponent().path,
                    temporaryDirectory.path
                )
                return NullResearchLog()
            },
            defaultResearchLogURL: { temporaryDirectory.appendingPathComponent("research-log.json") }
        )

        await MainActor.run {
            ISOInspectorCommand.contextFactory = { _ in
                ISOInspectorCommandContext(environment: environment)
            }
            ISOInspectorCommandContextStore.reset()
        }

        var command = try ISOInspectorCommand.Commands.Inspect.parse([
            fileURL.path
        ])

        try await command.run()

        XCTAssertTrue(errors.value.isEmpty)
        XCTAssertTrue(printed.value.contains(where: { $0.contains("encryption") && $0.contains("samples=2") }))
        XCTAssertTrue(printed.value.contains(where: { $0.contains("aux_offsets") && $0.contains("bytes_per_entry=8") }))
        XCTAssertTrue(printed.value.contains(where: { $0.contains("aux_sizes") && $0.contains("entry_count=2") }))

        await MainActor.run {
            ISOInspectorCommandContextStore.reset()
            ISOInspectorCommand.contextFactory = ISOInspectorCommand.defaultContextFactory
        }
    }

    func testBatchCommandAggregatesResultsAndWritesCSV() async throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let firstFile = temporaryDirectory.appendingPathComponent("alpha.mp4")
        let secondFile = temporaryDirectory.appendingPathComponent("beta.mp4")
        _ = FileManager.default.createFile(atPath: firstFile.path, contents: Data(repeating: 0, count: 16))
        _ = FileManager.default.createFile(atPath: secondFile.path, contents: Data(repeating: 1, count: 24))

        let header = try makeHeader(type: "ftyp", size: 24)
        let descriptor = try XCTUnwrap(BoxCatalog.shared.descriptor(for: header))
        let infoIssue = ValidationIssue(ruleID: "VR-006", message: "Research detail", severity: .info)
        let warningIssue = ValidationIssue(ruleID: "VR-003", message: "Flags mismatch", severity: .warning)
        let errorIssue = ValidationIssue(ruleID: "VR-001", message: "Size mismatch", severity: .error)

        let eventsByFile: [URL: [ParseEvent]] = [
            firstFile: [
                ParseEvent(
                    kind: .willStartBox(header: header, depth: 0),
                    offset: header.startOffset,
                    metadata: descriptor,
                    validationIssues: [infoIssue]
                )
            ],
            secondFile: [
                ParseEvent(
                    kind: .willStartBox(header: header, depth: 0),
                    offset: header.startOffset,
                    metadata: descriptor,
                    validationIssues: [warningIssue, errorIssue]
                )
            ]
        ]

        let lengths: [URL: Int64] = [firstFile: 1024, secondFile: 4096]
        let printed = MutableBox<[String]>([])
        let errors = MutableBox<[String]>([])

        let environment = ISOInspectorCLIEnvironment(
            refreshCatalog: { _, _ in },
            makeReader: { url in
                guard let length = lengths[url] else {
                    XCTFail("Unexpected reader request for \(url)")
                    throw CocoaError(.fileReadUnknown)
                }
                return StubReader(length: length)
            },
            parsePipeline: ParsePipeline(buildStream: { _, context in
                AsyncThrowingStream { continuation in
                    guard let source = context.source else {
                        continuation.finish()
                        return
                    }
                    for event in eventsByFile[source, default: []] {
                        continuation.yield(event)
                    }
                    continuation.finish()
                }
            }),
            formatter: EventConsoleFormatter(),
            print: { printed.value.append($0) },
            printError: { errors.value.append($0) }
        )

        await MainActor.run {
            ISOInspectorCommand.contextFactory = { _ in
                ISOInspectorCommandContext(environment: environment)
            }
            ISOInspectorCommandContextStore.reset()
        }

        let csvURL = temporaryDirectory.appendingPathComponent("summary.csv")
        let globPattern = temporaryDirectory.appendingPathComponent("*.mp4").path

        var command = try ISOInspectorCommand.Commands.Batch.parse([
            globPattern,
            "--csv",
            csvURL.path
        ])

        do {
            try await command.run()
            XCTFail("Expected ExitCode to be thrown")
        } catch let exit as ExitCode {
            XCTAssertEqual(exit.rawValue, 2)
        }

        XCTAssertTrue(errors.value.isEmpty)
        XCTAssertEqual(printed.value.first, "Batch validation summary")
        XCTAssertTrue(printed.value.contains(where: { $0.contains(firstFile.lastPathComponent) }))
        XCTAssertTrue(printed.value.contains(where: { $0.contains(secondFile.lastPathComponent) }))
        XCTAssertTrue(printed.value.contains(where: { $0.contains("Totals") }))

        let csv = try String(contentsOf: csvURL, encoding: .utf8)
        XCTAssertTrue(csv.contains("file,size_bytes,boxes,errors,warnings,info,status,notes"))
        XCTAssertTrue(csv.contains(firstFile.lastPathComponent))
        XCTAssertTrue(csv.contains(secondFile.lastPathComponent))

        await MainActor.run {
            ISOInspectorCommandContextStore.reset()
            ISOInspectorCommand.contextFactory = ISOInspectorCommand.defaultContextFactory
        }
    }

    func testGlobalOptionsRejectMutuallyExclusiveVerbosityFlags() {
        XCTAssertThrowsError(try ISOInspectorCommand.GlobalOptions.parse(["--quiet", "--verbose"]))
    }

    func testGlobalOptionsRejectMutuallyExclusiveTelemetryFlags() {
        XCTAssertThrowsError(try ISOInspectorCommand.GlobalOptions.parse(["--enable-telemetry", "--disable-telemetry"]))
    }

    func testExportJSONCommandStreamsEventsAndWritesDefaultOutput() async throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let fileURL = temporaryDirectory.appendingPathComponent("sample.mp4")
        let expectedOutputURL = fileURL
            .appendingPathExtension("isoinspector")
            .appendingPathExtension("json")

        let header = try makeHeader(type: "ftyp", size: 24)
        let descriptor = try XCTUnwrap(BoxCatalog.shared.descriptor(for: header))
        let events = [
            ParseEvent(
                kind: .willStartBox(header: header, depth: 0),
                offset: header.startOffset,
                metadata: descriptor
            ),
            ParseEvent(
                kind: .didFinishBox(header: header, depth: 0),
                offset: header.endOffset,
                metadata: descriptor
            )
        ]

        let printed = MutableBox<[String]>([])
        let errors = MutableBox<[String]>([])
        let environment = ISOInspectorCLIEnvironment(
            refreshCatalog: { _, _ in },
            makeReader: { url in
                XCTAssertEqual(url, fileURL)
                return StubReader()
            },
            parsePipeline: ParsePipeline(buildStream: { _, context in
                XCTAssertEqual(context.source, fileURL)
                return AsyncThrowingStream { continuation in
                    for event in events {
                        continuation.yield(event)
                    }
                    continuation.finish()
                }
            }),
            formatter: EventConsoleFormatter(),
            print: { printed.value.append($0) },
            printError: { errors.value.append($0) }
        )

        await MainActor.run {
            ISOInspectorCommand.contextFactory = { _ in
                ISOInspectorCommandContext(environment: environment)
            }
            ISOInspectorCommandContextStore.reset()
        }

        var command = try ISOInspectorCommand.Commands.Export.JSON.parse([fileURL.path])
        try await command.run()

        let data = try Data(contentsOf: expectedOutputURL)
        XCTAssertFalse(data.isEmpty)
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
        guard let json = jsonObject as? [String: Any] else {
            let payload = String(data: data, encoding: .utf8) ?? "<invalid>"
            XCTFail("Unexpected JSON shape: \(payload)")
            return
        }
        let nodes = json["nodes"] as? [[String: Any]]
        let node = nodes?.first
        XCTAssertEqual(node?["fourcc"] as? String, header.identifierString)
        XCTAssertTrue(errors.value.isEmpty)
        XCTAssertTrue(printed.value.contains(where: { $0.contains(expectedOutputURL.path) }))

        await MainActor.run {
            ISOInspectorCommandContextStore.reset()
            ISOInspectorCommand.contextFactory = ISOInspectorCommand.defaultContextFactory
        }
    }

    func testExportCaptureCommandStreamsEventsAndRespectsOutputOption() async throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let fileURL = temporaryDirectory.appendingPathComponent("sample.mp4")
        let outputURL = temporaryDirectory.appendingPathComponent("capture.isoinspect")

        let header = try makeHeader(type: "moov", size: 32)
        let descriptor = try XCTUnwrap(BoxCatalog.shared.descriptor(for: header))
        let events = [
            ParseEvent(
                kind: .willStartBox(header: header, depth: 0),
                offset: header.startOffset,
                metadata: descriptor
            ),
            ParseEvent(
                kind: .didFinishBox(header: header, depth: 0),
                offset: header.endOffset,
                metadata: descriptor
            )
        ]

        let printed = MutableBox<[String]>([])
        let errors = MutableBox<[String]>([])
        let environment = ISOInspectorCLIEnvironment(
            refreshCatalog: { _, _ in },
            makeReader: { url in
                XCTAssertEqual(url, fileURL)
                return StubReader()
            },
            parsePipeline: ParsePipeline(buildStream: { _, context in
                XCTAssertEqual(context.source, fileURL)
                return AsyncThrowingStream { continuation in
                    for event in events {
                        continuation.yield(event)
                    }
                    continuation.finish()
                }
            }),
            formatter: EventConsoleFormatter(),
            print: { printed.value.append($0) },
            printError: { errors.value.append($0) }
        )

        await MainActor.run {
            ISOInspectorCommand.contextFactory = { _ in
                ISOInspectorCommandContext(environment: environment)
            }
            ISOInspectorCommandContextStore.reset()
        }

        var command = try ISOInspectorCommand.Commands.Export.Capture.parse([
            fileURL.path,
            "--output",
            outputURL.path
        ])

        try await command.run()

        let data = try Data(contentsOf: outputURL)
        let decoded = try ParseEventCaptureDecoder().decode(data: data)
        XCTAssertEqual(decoded, events)
        XCTAssertTrue(errors.value.isEmpty)
        XCTAssertTrue(printed.value.contains(where: { $0.contains(outputURL.path) }))

        await MainActor.run {
            ISOInspectorCommandContextStore.reset()
            ISOInspectorCommand.contextFactory = ISOInspectorCommand.defaultContextFactory
        }
    }

    func testExportCommandThrowsExitCodeWhenOutputDirectoryMissing() async throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let fileURL = temporaryDirectory.appendingPathComponent("sample.mp4")
        let invalidOutput = temporaryDirectory
            .appendingPathComponent("missing")
            .appendingPathComponent("tree.json")

        let printed = MutableBox<[String]>([])
        let errors = MutableBox<[String]>([])
        let environment = ISOInspectorCLIEnvironment(
            refreshCatalog: { _, _ in },
            makeReader: { _ in StubReader() },
            parsePipeline: ParsePipeline(buildStream: { _, _ in
                AsyncThrowingStream { continuation in
                    continuation.finish()
                }
            }),
            formatter: EventConsoleFormatter(),
            print: { printed.value.append($0) },
            printError: { errors.value.append($0) }
        )

        await MainActor.run {
            ISOInspectorCommand.contextFactory = { _ in
                ISOInspectorCommandContext(environment: environment)
            }
            ISOInspectorCommandContextStore.reset()
        }

        var command = try ISOInspectorCommand.Commands.Export.JSON.parse([
            fileURL.path,
            "--output",
            invalidOutput.path
        ])

        do {
            try await command.run()
            XCTFail("Expected ExitCode to be thrown")
        } catch let exit as ExitCode {
            XCTAssertEqual(exit.rawValue, 3)
        }

        XCTAssertTrue(printed.value.isEmpty)
        XCTAssertEqual(errors.value.last, "Destination is not writable: \(invalidOutput.deletingLastPathComponent().path)")

        await MainActor.run {
            ISOInspectorCommandContextStore.reset()
            ISOInspectorCommand.contextFactory = ISOInspectorCommand.defaultContextFactory
        }
    }

    func testFilteredEventPreservesParseIssueMetadata() throws {
        let header = try makeHeader(type: "ftyp", size: 24)
        let parseIssue = ParseIssue(
            severity: .warning,
            code: "guard.zero_size_loop",
            message: "Repeated zero-sized box",
            byteRange: 16..<24,
            affectedNodeIDs: [header.startOffset]
        )
        let validationIssue = ValidationIssue(
            ruleID: ValidationRuleIdentifier.researchLogRecording.rawValue,
            message: "Filtered",
            severity: .info
        )
        let event = ParseEvent(
            kind: .willStartBox(header: header, depth: 0),
            offset: header.startOffset,
            validationIssues: [validationIssue],
            issues: [parseIssue]
        )

        let filtered = ISOInspectorCommand.filteredEvent(
            event,
            removing: [validationIssue.ruleID]
        )

        XCTAssertTrue(filtered.validationIssues.isEmpty)
        XCTAssertEqual(filtered.issues, [parseIssue])
    }
}

private func loadFixtureData(named name: String) throws -> Data {
    let baseDirectory = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("../ISOInspectorKitTests/Fixtures/Media", isDirectory: true)
        .standardized
    let fileURL = baseDirectory.appendingPathComponent("\(name).txt")
    let encoded = try String(contentsOf: fileURL, encoding: .utf8)
    guard let decoded = Data(base64Encoded: encoded, options: [.ignoreUnknownCharacters]) else {
        struct InvalidFixtureData: Error {}
        throw InvalidFixtureData()
    }
    return decoded
}

private final class MutableBox<Value>: @unchecked Sendable {
    var value: Value

    init(_ value: Value) {
        self.value = value
    }
}

private struct StubReader: RandomAccessReader {
    let length: Int64

    init(length: Int64 = 0) {
        self.length = length
    }

    func read(at offset: Int64, count: Int) throws -> Data { Data() }
}

private func makeHeader(type: String, size: Int64) throws -> BoxHeader {
    let fourCC = try IIFourCharCode(type)
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
