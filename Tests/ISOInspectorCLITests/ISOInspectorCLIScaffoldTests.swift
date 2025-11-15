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

  func testHelpTextMentionsExportCommands() {
    let help = ISOInspectorCLIRunner.helpText()
    XCTAssertTrue(help.contains("export-json"))
    XCTAssertTrue(help.contains("export-text"))
    XCTAssertTrue(help.contains("export-capture"))
  }

  func testRunExportJSONWritesExpectedFile() throws {
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
      ),
    ]

    let outputDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

    let input = outputDirectory.appendingPathComponent("sample.mp4")
    XCTAssertTrue(FileManager.default.createFile(atPath: input.path, contents: Data()))
    let output = outputDirectory.appendingPathComponent("tree.json")

    let printed = MutableBox<[String]>([])
    let errors = MutableBox<[String]>([])
    let environment = ISOInspectorCLIEnvironment(
      refreshCatalog: { _, _ in },
      makeReader: { url in
        XCTAssertEqual(url, input)
        return StubReader()
      },
      parsePipeline: ParsePipeline(buildStream: { _, _ in
        AsyncThrowingStream { continuation in
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

    ISOInspectorCLIRunner.run(
      arguments: [
        "isoinspect",
        "export-json",
        input.path,
        "--output",
        output.path,
      ],
      environment: environment
    )

    XCTAssertTrue(errors.value.isEmpty)
    XCTAssertTrue(FileManager.default.fileExists(atPath: output.path))
    let data = try Data(contentsOf: output)
    var builder = ParseTreeBuilder()
    for event in events {
      builder.consume(event)
    }
    let expected = try JSONParseTreeExporter().export(tree: builder.makeTree())
    XCTAssertEqual(data, expected)
    XCTAssertTrue(printed.value.contains(where: { $0.contains(output.path) }))
  }

  func testRunExportCaptureWritesBinaryCapture() throws {
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
      ),
    ]

    let outputDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

    let input = outputDirectory.appendingPathComponent("sample.mp4")
    XCTAssertTrue(FileManager.default.createFile(atPath: input.path, contents: Data()))
    let output = outputDirectory.appendingPathComponent("capture.bin")

    let printed = MutableBox<[String]>([])
    let errors = MutableBox<[String]>([])
    let environment = ISOInspectorCLIEnvironment(
      refreshCatalog: { _, _ in },
      makeReader: { url in
        XCTAssertEqual(url, input)
        return StubReader()
      },
      parsePipeline: ParsePipeline(buildStream: { _, _ in
        AsyncThrowingStream { continuation in
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

    ISOInspectorCLIRunner.run(
      arguments: [
        "isoinspect",
        "export-capture",
        input.path,
        "--output",
        output.path,
      ],
      environment: environment
    )

    XCTAssertTrue(errors.value.isEmpty)
    XCTAssertTrue(FileManager.default.fileExists(atPath: output.path))
    let data = try Data(contentsOf: output)
    let decoded = try ParseEventCaptureDecoder().decode(data: data)
    XCTAssertEqual(decoded, events)
    XCTAssertTrue(printed.value.contains(where: { $0.contains(output.path) }))
  }

  func testExportCommandsDefaultOutputPathWhenNotProvided() throws {
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
      ),
    ]

    let outputDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

    let input = outputDirectory.appendingPathComponent("sample.mp4")
    XCTAssertTrue(FileManager.default.createFile(atPath: input.path, contents: Data()))
    let expectedJSON =
      input
      .appendingPathExtension("isoinspector")
      .appendingPathExtension("json")
    let expectedCapture =
      input
      .appendingPathExtension("capture")

    let environment = ISOInspectorCLIEnvironment(
      refreshCatalog: { _, _ in },
      makeReader: { _ in StubReader() },
      parsePipeline: ParsePipeline(buildStream: { _, _ in
        AsyncThrowingStream { continuation in
          for event in events {
            continuation.yield(event)
          }
          continuation.finish()
        }
      }),
      formatter: EventConsoleFormatter(),
      print: { _ in },
      printError: { _ in }
    )

    ISOInspectorCLIRunner.run(
      arguments: [
        "isoinspect",
        "export-json",
        input.path,
      ],
      environment: environment
    )

    ISOInspectorCLIRunner.run(
      arguments: [
        "isoinspect",
        "export-capture",
        input.path,
      ],
      environment: environment
    )

    XCTAssertTrue(FileManager.default.fileExists(atPath: expectedJSON.path))
    XCTAssertTrue(FileManager.default.fileExists(atPath: expectedCapture.path))
  }

  func testInspectDefaultsToStrictMode() throws {
    let recordedOptions = MutableBox<[ParsePipeline.Options]>([])
    let environment = ISOInspectorCLIEnvironment(
      refreshCatalog: { _, _ in },
      makeReader: { url in
        XCTAssertEqual(url.path, "/tmp/sample.mp4")
        return StubReader()
      },
      parsePipeline: ParsePipeline(buildStream: { _, context in
        recordedOptions.value.append(context.options)
        return AsyncThrowingStream { continuation in
          continuation.finish()
        }
      }),
      formatter: EventConsoleFormatter(),
      print: { _ in },
      printError: { _ in },
      makeResearchLogWriter: { _ in NullResearchLog() },
      defaultResearchLogURL: { URL(fileURLWithPath: "/tmp/research-log.json") }
    )

    ISOInspectorCLIRunner.run(
      arguments: [
        "isoinspect",
        "inspect",
        "/tmp/sample.mp4",
      ],
      environment: environment
    )

    XCTAssertEqual(recordedOptions.value, [.strict])
  }

  func testInspectTolerantFlagOverridesDefaultMode() throws {
    let recordedOptions = MutableBox<[ParsePipeline.Options]>([])
    let environment = ISOInspectorCLIEnvironment(
      refreshCatalog: { _, _ in },
      makeReader: { url in
        XCTAssertEqual(url.path, "/tmp/sample.mp4")
        return StubReader()
      },
      parsePipeline: ParsePipeline(buildStream: { _, context in
        recordedOptions.value.append(context.options)
        return AsyncThrowingStream { continuation in
          continuation.finish()
        }
      }),
      formatter: EventConsoleFormatter(),
      print: { _ in },
      printError: { _ in },
      makeResearchLogWriter: { _ in NullResearchLog() },
      defaultResearchLogURL: { URL(fileURLWithPath: "/tmp/research-log.json") }
    )

    ISOInspectorCLIRunner.run(
      arguments: [
        "isoinspect",
        "inspect",
        "--tolerant",
        "/tmp/sample.mp4",
      ],
      environment: environment
    )

    XCTAssertEqual(recordedOptions.value, [.tolerant])
  }

  func testInspectRejectsConflictingParseModeFlags() throws {
    let printedErrors = MutableBox<[String]>([])
    let environment = ISOInspectorCLIEnvironment(
      refreshCatalog: { _, _ in },
      makeReader: { _ in StubReader() },
      parsePipeline: ParsePipeline(buildStream: { _, _ in
        AsyncThrowingStream { continuation in
          continuation.finish()
        }
      }),
      formatter: EventConsoleFormatter(),
      print: { _ in },
      printError: { printedErrors.value.append($0) },
      makeResearchLogWriter: { _ in NullResearchLog() },
      defaultResearchLogURL: { URL(fileURLWithPath: "/tmp/research-log.json") }
    )

    ISOInspectorCLIRunner.run(
      arguments: [
        "isoinspect",
        "inspect",
        "--tolerant",
        "--strict",
        "/tmp/sample.mp4",
      ],
      environment: environment
    )

    XCTAssertTrue(
      printedErrors.value.contains(where: { $0.contains("Cannot combine --tolerant and --strict") })
    )
  }

  func testInspectTolerantRunPrintsCorruptionSummaryWhenIssuesRecorded() throws {
    final class NullResearchLog: ResearchLogRecording, @unchecked Sendable {
      func record(_ entry: ResearchLogEntry) {}
    }

    let printed = MutableBox<[String]>([])
    let environment = ISOInspectorCLIEnvironment(
      refreshCatalog: { _, _ in },
      makeReader: { url in
        XCTAssertEqual(url.path, "/tmp/sample.mp4")
        return StubReader()
      },
      parsePipeline: ParsePipeline(buildStream: { _, context in
        context.issueStore?.record(
          ParseIssue(
            severity: .error,
            code: "VR-001",
            message: "Box exceeds parent"
          ),
          depth: 4
        )
        return AsyncThrowingStream { continuation in
          continuation.finish()
        }
      }),
      formatter: EventConsoleFormatter(),
      print: { printed.value.append($0) },
      printError: { _ in },
      makeResearchLogWriter: { _ in NullResearchLog() },
      defaultResearchLogURL: { URL(fileURLWithPath: "/tmp/research-log.json") }
    )

    ISOInspectorCLIRunner.run(
      arguments: [
        "isoinspect",
        "inspect",
        "--tolerant",
        "/tmp/sample.mp4",
      ],
      environment: environment
    )

    XCTAssertTrue(printed.value.contains("Corruption summary:"))
    XCTAssertTrue(printed.value.contains("  Errors: 1"))
    XCTAssertTrue(printed.value.contains("  Warnings: 0"))
    XCTAssertTrue(printed.value.contains("  Info: 0"))
    XCTAssertTrue(printed.value.contains("  Deepest affected depth: 4"))
  }

  func testInspectTolerantRunOmitsCorruptionSummaryWhenNoIssuesRecorded() throws {
    final class NullResearchLog: ResearchLogRecording, @unchecked Sendable {
      func record(_ entry: ResearchLogEntry) {}
    }

    let printed = MutableBox<[String]>([])
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
      printError: { _ in },
      makeResearchLogWriter: { _ in NullResearchLog() },
      defaultResearchLogURL: { URL(fileURLWithPath: "/tmp/research-log.json") }
    )

    ISOInspectorCLIRunner.run(
      arguments: [
        "isoinspect",
        "inspect",
        "--tolerant",
        "/tmp/sample.mp4",
      ],
      environment: environment
    )

    XCTAssertFalse(printed.value.contains("Corruption summary:"))
  }

  func testInspectStrictRunOmitsCorruptionSummaryEvenWhenIssuesRecorded() throws {
    final class NullResearchLog: ResearchLogRecording, @unchecked Sendable {
      func record(_ entry: ResearchLogEntry) {}
    }

    let printed = MutableBox<[String]>([])
    let environment = ISOInspectorCLIEnvironment(
      refreshCatalog: { _, _ in },
      makeReader: { _ in StubReader() },
      parsePipeline: ParsePipeline(buildStream: { _, context in
        context.issueStore?.record(
          ParseIssue(
            severity: .warning,
            code: "VR-002",
            message: "Warning issued"
          ),
          depth: 2
        )
        return AsyncThrowingStream { continuation in
          continuation.finish()
        }
      }),
      formatter: EventConsoleFormatter(),
      print: { printed.value.append($0) },
      printError: { _ in },
      makeResearchLogWriter: { _ in NullResearchLog() },
      defaultResearchLogURL: { URL(fileURLWithPath: "/tmp/research-log.json") }
    )

    ISOInspectorCLIRunner.run(
      arguments: [
        "isoinspect",
        "inspect",
        "--strict",
        "/tmp/sample.mp4",
      ],
      environment: environment
    )

    XCTAssertFalse(printed.value.contains("Corruption summary:"))
  }

  func testExportJSONHonorsTolerantFlag() throws {
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
      ),
    ]

    let recordedOptions = MutableBox<[ParsePipeline.Options]>([])
    let outputDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

    let input = outputDirectory.appendingPathComponent("sample.mp4")
    XCTAssertTrue(FileManager.default.createFile(atPath: input.path, contents: Data()))
    let output = outputDirectory.appendingPathComponent("tree.json")

    let environment = ISOInspectorCLIEnvironment(
      refreshCatalog: { _, _ in },
      makeReader: { url in
        XCTAssertEqual(url, input)
        return StubReader()
      },
      parsePipeline: ParsePipeline(buildStream: { _, context in
        recordedOptions.value.append(context.options)
        return AsyncThrowingStream { continuation in
          for event in events {
            continuation.yield(event)
          }
          continuation.finish()
        }
      }),
      formatter: EventConsoleFormatter(),
      print: { _ in },
      printError: { _ in }
    )

    ISOInspectorCLIRunner.run(
      arguments: [
        "isoinspect",
        "export-json",
        "--tolerant",
        input.path,
        "--output",
        output.path,
      ],
      environment: environment
    )

    XCTAssertEqual(recordedOptions.value, [.tolerant])
    XCTAssertTrue(FileManager.default.fileExists(atPath: output.path))
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
        "/tmp/catalog.json",
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
        "/tmp/sample.mp4",
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
        context.researchLog?.record(
          ResearchLogEntry(
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
        "/tmp/sample.mp4",
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
        "inspect",
      ],
      environment: environment
    )

    XCTAssertEqual(errors.value.last, "inspect requires a file path.")
  }

  func testExportJSONIncludesHandlerMetadata() throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    let input = directory.appendingPathComponent("sample.mp4")
    let output =
      input
      .appendingPathExtension("isoinspector")
      .appendingPathExtension("json")
    try makeHandlerFixture().write(to: input)

    let printedErrors = MutableBox<[String]>([])
    let environment = ISOInspectorCLIEnvironment(
      refreshCatalog: { _, _ in },
      makeReader: { _ in DataBackedReader(data: try Data(contentsOf: input)) },
      parsePipeline: .live(),
      formatter: EventConsoleFormatter(),
      print: { _ in },
      printError: { printedErrors.value.append($0) }
    )

    ISOInspectorCLIRunner.run(
      arguments: [
        "isoinspect",
        "export-json",
        input.path,
      ],
      environment: environment
    )

    XCTAssertTrue(FileManager.default.fileExists(atPath: output.path))
    XCTAssertTrue(printedErrors.value.isEmpty, "Unexpected CLI errors: \(printedErrors.value)")

    let jsonData = try Data(contentsOf: output)
    let json = try XCTUnwrap(JSONSerialization.jsonObject(with: jsonData) as? [String: Any])
    let nodes = try XCTUnwrap(json["nodes"] as? [[String: Any]])
    let handler = try XCTUnwrap(findNode(named: "hdlr", in: nodes))
    let payload = try XCTUnwrap(handler["payload"] as? [[String: Any]])
    let category = try XCTUnwrap(payload.first { ($0["name"] as? String) == "handler_category" })
    XCTAssertEqual(category["value"] as? String, "Metadata")
    let handlerName = try XCTUnwrap(payload.first { ($0["name"] as? String) == "handler_name" })
    XCTAssertEqual(handlerName["value"] as? String, "Metadata Handler")
  }

  func testExportTextProducesIssueSummary() throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    let input = directory.appendingPathComponent("sample.mp4")
    let output =
      input
      .appendingPathExtension("isoinspector")
      .appendingPathExtension("txt")
    try makeHandlerFixture().write(to: input)

    let printedErrors = MutableBox<[String]>([])
    let environment = ISOInspectorCLIEnvironment(
      refreshCatalog: { _, _ in },
      makeReader: { _ in DataBackedReader(data: try Data(contentsOf: input)) },
      parsePipeline: .live(),
      formatter: EventConsoleFormatter(),
      print: { _ in },
      printError: { printedErrors.value.append($0) }
    )

    ISOInspectorCLIRunner.run(
      arguments: [
        "isoinspect",
        "export-text",
        input.path,
      ],
      environment: environment
    )

    XCTAssertTrue(FileManager.default.fileExists(atPath: output.path))
    XCTAssertTrue(printedErrors.value.isEmpty, "Unexpected CLI errors: \(printedErrors.value)")
    let contents = try String(contentsOf: output, encoding: .utf8)
    XCTAssertTrue(contents.contains("File:"))
    XCTAssertTrue(contents.contains("Total Issues: 0"))
    XCTAssertTrue(contents.contains("No issues recorded."))
  }

  func testEnvironmentSupportsParseExporters() async throws {
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
      ),
    ]

    let environment = ISOInspectorCLIEnvironment(
      refreshCatalog: { _, _ in },
      makeReader: { _ in StubReader() },
      parsePipeline: ParsePipeline(buildStream: { _, _ in
        AsyncThrowingStream { continuation in
          for event in events {
            continuation.yield(event)
          }
          continuation.finish()
        }
      }),
      formatter: EventConsoleFormatter(),
      print: { _ in },
      printError: { _ in }
    )

    let reader = try environment.makeReader(URL(fileURLWithPath: "/tmp/sample.mp4"))
    var builder = ParseTreeBuilder()
    var captured: [ParseEvent] = []
    for try await event in environment.parsePipeline.events(for: reader) {
      captured.append(event)
      builder.consume(event)
    }

    let tree = builder.makeTree()
    let jsonData = try JSONParseTreeExporter().export(tree: tree)
    XCTAssertFalse(jsonData.isEmpty)

    let binary = try ParseEventCaptureEncoder().encode(events: captured)
    let roundTripped = try ParseEventCaptureDecoder().decode(data: binary)
    XCTAssertEqual(roundTripped, captured)
  }

  private struct StubReader: RandomAccessReader {
    let length: Int64 = 0

    func read(at offset: Int64, count: Int) throws -> Data { Data() }
  }

  private struct DataBackedReader: RandomAccessReader {
    let data: Data

    var length: Int64 { Int64(data.count) }

    func read(at offset: Int64, count: Int) throws -> Data {
      guard let start = Int(exactly: offset) else {
        throw RandomAccessReaderError.overflowError
      }
      guard count >= 0 else {
        throw RandomAccessReaderError.boundsError(.invalidCount(count))
      }
      guard start >= 0 else {
        throw RandomAccessReaderError.boundsError(.invalidOffset(offset))
      }
      let end = start + count
      guard end <= data.count else {
        throw RandomAccessReaderError.boundsError(
          .requestedRangeOutOfBounds(offset: offset, count: count)
        )
      }
      return data.subdata(in: start..<end)
    }
  }

  private func makeHandlerFixture() -> Data {
    let ftypPayload = Data("isom".utf8) + Data(repeating: 0, count: 12)
    let ftyp = makeBox(type: "ftyp", payload: ftypPayload)

    var handlerPayload = Data()
    handlerPayload.append(0x00)  // version
    handlerPayload.append(contentsOf: [0x00, 0x00, 0x00])  // flags
    handlerPayload.append(contentsOf: UInt32(0).bigEndianBytes)  // pre-defined
    handlerPayload.append(contentsOf: "mdir".utf8)  // metadata handler
    handlerPayload.append(contentsOf: Data(count: 12))  // reserved
    handlerPayload.append(contentsOf: "Metadata Handler".utf8)
    handlerPayload.append(0x00)  // null terminator

    let hdlr = makeBox(type: "hdlr", payload: handlerPayload)
    let mdia = makeBox(type: "mdia", payload: hdlr)
    let trak = makeBox(type: "trak", payload: mdia)
    let moov = makeBox(type: "moov", payload: trak)
    return ftyp + moov
  }

  private func makeBox(type: String, payload: Data) -> Data {
    precondition(type.utf8.count == 4, "Box type must be four characters")
    var data = Data()
    let totalSize = 8 + payload.count
    data.append(contentsOf: UInt32(totalSize).bigEndianBytes)
    data.append(contentsOf: type.utf8)
    data.append(payload)
    return data
  }

  private func findNode(named fourcc: String, in nodes: [[String: Any]]) -> [String: Any]? {
    for node in nodes {
      if node["fourcc"] as? String == fourcc {
        return node
      }
      if let children = node["children"] as? [[String: Any]],
        let match = findNode(named: fourcc, in: children)
      {
        return match
      }
    }
    return nil
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

private final class NullResearchLog: ResearchLogRecording, @unchecked Sendable {
  func record(_ entry: ResearchLogEntry) {}
}

private final class MutableBox<Value>: @unchecked Sendable {
  var value: Value

  init(_ value: Value) {
    self.value = value
  }
}

extension FixedWidthInteger {
  fileprivate var bigEndianBytes: [UInt8] {
    withUnsafeBytes(of: self.bigEndian, Array.init)
  }
}
