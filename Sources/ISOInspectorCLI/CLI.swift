import Dispatch
import Foundation
import ISOInspectorKit

public struct ISOInspectorCLIEnvironment: Sendable {
    public var refreshCatalog: @Sendable (_ source: URL, _ output: URL) throws -> Void
    public var makeReader: @Sendable (_ url: URL) throws -> RandomAccessReader
    public var parsePipeline: ParsePipeline
    public var formatter: EventConsoleFormatter
    public var issueStore: ParseIssueStore { issueStoreBox.value }
    public var print: @Sendable (String) -> Void
    public var printError: @Sendable (String) -> Void
    public var makeResearchLogWriter: @Sendable (_ location: URL) throws -> any ResearchLogRecording
    public var defaultResearchLogURL: @Sendable () -> URL
    public var logVerbosity: LogVerbosity
    public var telemetryEnabled: Bool
    public var auditInfo: @Sendable (String) -> Void
    public var auditError: @Sendable (String) -> Void
    public var filesystemAccessAuditTrail: FilesystemAccessAuditTrail
    public var makeFilesystemAccessInstance:
        @Sendable (_ logger: FilesystemAccessLogger) -> FilesystemAccess
    private var issueStoreBox: UncheckedSendableValue<ParseIssueStore>

    public init(
        refreshCatalog: @escaping @Sendable (_ source: URL, _ output: URL) throws -> Void,
        makeReader: @escaping @Sendable (_ url: URL) throws -> RandomAccessReader = { url in
            try ChunkedFileReader(fileURL: url)
        },
        parsePipeline: ParsePipeline = .live(options: .strict),
        issueStore: ParseIssueStore? = nil,
        formatter: EventConsoleFormatter = EventConsoleFormatter(),
        print: @escaping @Sendable (String) -> Void = { Swift.print($0) },
        printError: @escaping @Sendable (String) -> Void = { message in
            let data = Data((message + "\n").utf8)
            FileHandle.standardError.write(data)
        },
        makeResearchLogWriter:
            @escaping @Sendable (_ location: URL) throws -> any ResearchLogRecording = { url in
                try ResearchLogWriter(fileURL: url)
            },
        defaultResearchLogURL: @escaping @Sendable () -> URL = {
            ResearchLogWriter.defaultLogURL()
        },
        logVerbosity: LogVerbosity = .standard,
        telemetryEnabled: Bool = true,
        auditInfo: @escaping @Sendable (String) -> Void = { message in
            Swift.print(message)
        },
        auditError: @escaping @Sendable (String) -> Void = { message in
            let data = Data((message + "\n").utf8)
            FileHandle.standardError.write(data)
        },
        filesystemAccessAuditTrail: FilesystemAccessAuditTrail = FilesystemAccessAuditTrail(),
        makeFilesystemAccess:
            @escaping @Sendable (_ logger: FilesystemAccessLogger) -> FilesystemAccess = { logger in
                FilesystemAccess.live(logger: logger)
            }
    ) {
        self.refreshCatalog = refreshCatalog
        self.makeReader = makeReader
        self.parsePipeline = parsePipeline
        if let issueStore {
            self.issueStoreBox = .init(value: issueStore)
        } else {
            let queue = DispatchQueue(label: "ISOInspectorCLI.ParseIssueStore", qos: .userInitiated)
            self.issueStoreBox = .init(value: ParseIssueStore(queue: queue))
        }
        self.formatter = formatter
        self.print = print
        self.printError = printError
        self.makeResearchLogWriter = makeResearchLogWriter
        self.defaultResearchLogURL = defaultResearchLogURL
        self.logVerbosity = logVerbosity
        self.telemetryEnabled = telemetryEnabled
        self.auditInfo = auditInfo
        self.auditError = auditError
        self.filesystemAccessAuditTrail = filesystemAccessAuditTrail
        self.makeFilesystemAccessInstance = makeFilesystemAccess
    }

    public static let live = ISOInspectorCLIEnvironment { source, output in
        let provider = HTTPMP4RARegistryDataProvider(sourceURL: source)
        let refresher = MP4RACatalogRefresher(dataProvider: provider)
        _ = try refresher.writeCatalog(to: output)
    }

    public enum LogVerbosity: Sendable {
        case quiet
        case standard
        case verbose

        public var isQuiet: Bool {
            if case .quiet = self { return true }
            return false
        }

        public var isVerbose: Bool {
            if case .verbose = self { return true }
            return false
        }
    }

    public func makeFilesystemAccess() -> FilesystemAccess {
        if telemetryEnabled {
            let infoSink = auditInfo
            let errorSink = auditError
            let logger = FilesystemAccessLogger(
                info: { infoSink($0) },
                error: { errorSink($0) },
                auditTrail: filesystemAccessAuditTrail,
                makeDate: {
                    Date.init()
                }
            )
            return makeFilesystemAccessInstance(logger)
        } else {
            let logger = FilesystemAccessLogger(
                info: { _ in },
                error: { _ in },
                auditTrail: FilesystemAccessAuditTrail(limit: 0),
                makeDate: {
                    Date.init()
                }
            )
            return makeFilesystemAccessInstance(logger)
        }
    }
}

private struct UncheckedSendableValue<Value>: @unchecked Sendable {
    var value: Value
}

public enum ISOInspectorCLIRunner {
    public static func run(
        arguments: [String] = CommandLine.arguments,
        environment: ISOInspectorCLIEnvironment = .live
    ) {
        let args = Array(arguments.dropFirst())

        if args.contains("--help") || args.contains("-h") {
            environment.print(helpText())
            return
        }

        guard let first = args.first else {
            ISOInspectorCLIIO.printWelcome()
            return
        }

        switch first {
        case "mp4ra":
            handleMP4RACommand(Array(args.dropFirst()), environment: environment)
        case "inspect":
            handleInspectCommand(Array(args.dropFirst()), environment: environment)
        case "export-json":
            handleExportCommand(
                Array(args.dropFirst()),
                environment: environment,
                mode: .json
            )
        case "export-capture":
            handleExportCommand(
                Array(args.dropFirst()),
                environment: environment,
                mode: .capture
            )
        case "export-text":
            handleExportCommand(
                Array(args.dropFirst()),
                environment: environment,
                mode: .text
            )
        default:
            ISOInspectorCLIIO.printWelcome()
        }
    }

    public static func helpText() -> String {
        "isoinspect — ISO BMFF (MP4/QuickTime) inspector CLI\n"
            + "  --help, -h    Show this help message.\n"
            + "  inspect <file> [--research-log <path>] [--tolerant|--strict]\n"
            + "                Stream parse events with metadata, validation summaries, and VR-006 research log entries.\n"
            + "                Use --tolerant to continue through corruption; --strict is the default.\n"
            + "  export-json <file> [--output <path>] [--tolerant|--strict]\n"
            + "                Persist a JSON parse tree exported from streaming parse events.\n"
            + "                Use --tolerant to continue through corruption when exporting.\n"
            + "  export-text <file> [--output <path>] [--tolerant|--strict]\n"
            + "                Write a plaintext issue summary with file metadata and grouped diagnostics.\n"
            + "  export-capture <file> [--output <path>] [--tolerant|--strict]\n"
            + "                Save a binary capture of parse events for later replay.\n"
            + "  mp4ra refresh [--output <path>] [--source <url>]\n"
            + "                Refresh the bundled MP4RABoxes.json using the latest registry export."
    }

    private static func handleMP4RACommand(
        _ arguments: [String],
        environment: ISOInspectorCLIEnvironment
    ) {
        guard let subcommand = arguments.first else {
            environment.printError("mp4ra requires a subcommand. Try 'mp4ra refresh'.")
            return
        }

        switch subcommand {
        case "refresh":
            switch parseRefreshOptions(Array(arguments.dropFirst())) {
            case .success(let options):
                do {
                    try environment.refreshCatalog(options.source, options.output)
                    environment.print("Refreshed MP4RA catalog → \(options.output.path)")
                } catch {
                    environment.printError("Failed to refresh MP4RA catalog: \(error)")
                }
            case .failure(let error):
                environment.printError(error.message)
            }
        default:
            environment.printError("Unknown mp4ra subcommand: \(subcommand)")
        }
    }

    private struct RefreshOptions {
        let source: URL
        let output: URL
    }

    private enum RefreshParseError: Swift.Error {
        case missingOutput
        case invalidSource
        case unknownOption(String)

        var message: String {
            switch self {
            case .missingOutput:
                return "Missing value for --output."
            case .invalidSource:
                return "Invalid value for --source."
            case .unknownOption(let option):
                return "Unknown option for mp4ra refresh: \(option)"
            }
        }
    }

    private static func handleInspectCommand(
        _ arguments: [String],
        environment: ISOInspectorCLIEnvironment
    ) {
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let defaultLogURL = environment.defaultResearchLogURL()

        switch parseInspectOptions(arguments, cwd: cwd, defaultResearchLogURL: defaultLogURL) {
        case .failure(let error):
            environment.printError(error.message)
        case .success(let options):
            do {
                let reader = try environment.makeReader(options.fileURL)
                let researchLog = try environment.makeResearchLogWriter(options.researchLogURL)
                environment.print("Research log → \(options.researchLogURL.path)")
                environment.print(
                    "VR-006 schema v\(ResearchLogSchema.version): \(ResearchLogSchema.fieldNames.joined(separator: ", "))"
                )
                let issueStore = environment.issueStore
                let events = environment.parsePipeline.events(
                    for: reader,
                    context: .init(
                        source: options.fileURL,
                        researchLog: researchLog,
                        options: options.parseOptions,
                        issueStore: issueStore
                    )
                )
                let semaphore = DispatchSemaphore(value: 0)

                Task {
                    do {
                        for try await event in events {
                            environment.print(environment.formatter.format(event))
                        }
                    } catch {
                        environment.printError("Failed to inspect file: \(error)")
                    }
                    semaphore.signal()
                }

                semaphore.wait()
                environment.emitCorruptionSummaryIfNeeded(
                    parseOptions: options.parseOptions,
                    issueStore: issueStore
                )
            } catch {
                environment.printError("Failed to inspect file: \(error)")
            }
        }
    }

    private struct InspectOptions {
        let fileURL: URL
        let researchLogURL: URL
        let parseOptions: ParsePipeline.Options
    }

    private enum InspectParseError: Swift.Error {
        case missingFilePath
        case missingResearchLogPath
        case unknownOption(String)
        case conflictingParseMode

        var message: String {
            switch self {
            case .missingFilePath:
                return "inspect requires a file path."
            case .missingResearchLogPath:
                return "Missing value for --research-log."
            case .unknownOption(let value):
                return "Unknown option for inspect: \(value)"
            case .conflictingParseMode:
                return "Cannot combine --tolerant and --strict for inspect."
            }
        }
    }

    private static func parseInspectOptions(
        _ arguments: [String],
        cwd: URL,
        defaultResearchLogURL: URL
    ) -> Result<InspectOptions, InspectParseError> {
        var iterator = arguments.makeIterator()
        var researchLogURL = defaultResearchLogURL
        var requestedOptions: ParsePipeline.Options?
        var filePath: String?

        while let argument = iterator.next() {
            switch argument {
            case "--research-log":
                guard let value = iterator.next() else {
                    return .failure(.missingResearchLogPath)
                }
                let resolved = URL(fileURLWithPath: value, relativeTo: cwd)
                researchLogURL = resolved.standardizedFileURL
            case "--tolerant":
                if let current = requestedOptions, current == .strict {
                    return .failure(.conflictingParseMode)
                }
                requestedOptions = .tolerant
            case "--strict":
                if let current = requestedOptions, current == .tolerant {
                    return .failure(.conflictingParseMode)
                }
                requestedOptions = .strict
            default:
                if argument.hasPrefix("-") {
                    return .failure(.unknownOption(argument))
                }
                filePath = argument
            }
        }

        guard let filePath else {
            return .failure(.missingFilePath)
        }

        let fileURL = URL(fileURLWithPath: filePath, relativeTo: cwd).standardizedFileURL
        let options = requestedOptions ?? .strict
        return .success(
            InspectOptions(fileURL: fileURL, researchLogURL: researchLogURL, parseOptions: options))
    }

    private static func parseRefreshOptions(
        _ arguments: [String]
    ) -> Result<RefreshOptions, RefreshParseError> {
        var iterator = arguments.makeIterator()
        var source = MP4RARegistryEndpoints.boxes
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        var output =
            cwd
            .appendingPathComponent("Sources")
            .appendingPathComponent("ISOInspectorKit")
            .appendingPathComponent("Resources")
            .appendingPathComponent("MP4RABoxes.json")
            .standardizedFileURL

        while let argument = iterator.next() {
            switch argument {
            case "--output", "-o":
                guard let path = iterator.next() else {
                    return .failure(.missingOutput)
                }
                let url = URL(fileURLWithPath: path, relativeTo: cwd)
                output = url.standardizedFileURL
            case "--source":
                guard let value = iterator.next(), let url = URL(string: value) else {
                    return .failure(.invalidSource)
                }
                source = url
            default:
                return .failure(.unknownOption(argument))
            }
        }

        return .success(RefreshOptions(source: source, output: output))
    }

    private enum ExportMode {
        case json
        case capture
        case text

        var successMessage: String {
            switch self {
            case .json:
                return "Exported JSON parse tree → "
            case .capture:
                return "Exported parse event capture → "
            case .text:
                return "Exported issue summary → "
            }
        }

        var failurePrefix: String {
            switch self {
            case .json:
                return "Failed to export JSON parse tree: "
            case .capture:
                return "Failed to export parse event capture: "
            case .text:
                return "Failed to export issue summary: "
            }
        }
    }

    private struct ExportOptions {
        let fileURL: URL
        let outputURL: URL
        let parseOptions: ParsePipeline.Options
    }

    private enum ExportParseError: Swift.Error {
        case missingFilePath
        case missingOutput
        case unexpectedArgument(String)
        case unknownOption(String)
        case conflictingParseMode

        var message: String {
            switch self {
            case .missingFilePath:
                return "export commands require a file path."
            case .missingOutput:
                return "Missing value for --output."
            case .unexpectedArgument(let argument):
                return "Unexpected argument for export command: \(argument)"
            case .unknownOption(let option):
                return "Unknown option for export command: \(option)"
            case .conflictingParseMode:
                return "Cannot combine --tolerant and --strict for export commands."
            }
        }
    }

    private enum ExportExecutionError: Swift.Error {
        case unwritableDestination(String)

        var message: String {
            switch self {
            case .unwritableDestination(let path):
                return "Destination is not writable: \(path)"
            }
        }
    }

    private static func handleExportCommand(
        _ arguments: [String],
        environment: ISOInspectorCLIEnvironment,
        mode: ExportMode
    ) {
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let defaultOutput: (URL) -> URL
        switch mode {
        case .json:
            defaultOutput = { fileURL in
                fileURL
                    .appendingPathExtension("isoinspector")
                    .appendingPathExtension("json")
            }
        case .capture:
            defaultOutput = { fileURL in
                fileURL.appendingPathExtension("capture")
            }
        case .text:
            defaultOutput = { fileURL in
                fileURL
                    .appendingPathExtension("isoinspector")
                    .appendingPathExtension("txt")
            }
        }

        switch parseExportOptions(
            arguments,
            cwd: cwd,
            defaultOutput: defaultOutput
        ) {
        case .failure(let error):
            environment.printError(error.message)
        case .success(let options):
            do {
                try validateOutputPath(options.outputURL)
            } catch let validationError as ExportExecutionError {
                environment.printError(validationError.message)
                return
            } catch {
                environment.printError(mode.failurePrefix + "\(error)")
                return
            }

            let semaphore = DispatchSemaphore(value: 0)
            Task {
                do {
                    let reader = try environment.makeReader(options.fileURL)
                    let issueStore = environment.issueStore
                    let stream = environment.parsePipeline.events(
                        for: reader,
                        context: .init(
                            source: options.fileURL,
                            options: options.parseOptions,
                            issueStore: issueStore
                        )
                    )
                    var builder = ParseTreeBuilder()
                    var captured: [ParseEvent] = []

                    for try await event in stream {
                        builder.consume(event)
                        captured.append(event)
                    }

                    let tree = builder.makeTree()

                    let data: Data
                    switch mode {
                    case .json:
                        data = try JSONParseTreeExporter().export(tree: tree)
                    case .capture:
                        data = try ParseEventCaptureEncoder().encode(events: captured)
                    case .text:
                        let metadata = PlaintextIssueSummaryExporter.Metadata(
                            filePath: options.fileURL.standardizedFileURL.path,
                            fileSize: reader.length,
                            analyzedAt: Date(),
                            sha256: nil
                        )
                        let summary = issueStore.makeIssueSummary()
                        let issues = issueStore.issuesSnapshot()
                        data = try PlaintextIssueSummaryExporter().export(
                            tree: tree,
                            metadata: metadata,
                            summary: summary,
                            issues: issues
                        )
                    }

                    try data.write(to: options.outputURL, options: .atomic)
                    environment.print(mode.successMessage + options.outputURL.path)
                } catch {
                    environment.printError(mode.failurePrefix + "\(error)")
                }
                semaphore.signal()
            }

            semaphore.wait()
        }
    }

    private static func parseExportOptions(
        _ arguments: [String],
        cwd: URL,
        defaultOutput: (URL) -> URL
    ) -> Result<ExportOptions, ExportParseError> {
        var iterator = arguments.makeIterator()
        var filePath: String?
        var outputPath: URL?
        var requestedOptions: ParsePipeline.Options?

        while let argument = iterator.next() {
            switch argument {
            case "--output", "-o":
                guard let value = iterator.next() else {
                    return .failure(.missingOutput)
                }
                let resolved = URL(fileURLWithPath: value, relativeTo: cwd)
                outputPath = resolved.standardizedFileURL
            case "--tolerant":
                if let current = requestedOptions, current == .strict {
                    return .failure(.conflictingParseMode)
                }
                requestedOptions = .tolerant
            case "--strict":
                if let current = requestedOptions, current == .tolerant {
                    return .failure(.conflictingParseMode)
                }
                requestedOptions = .strict
            default:
                if argument.hasPrefix("-") {
                    return .failure(.unknownOption(argument))
                }

                if filePath == nil {
                    filePath = argument
                } else {
                    return .failure(.unexpectedArgument(argument))
                }
            }
        }

        guard let filePath else {
            return .failure(.missingFilePath)
        }

        let fileURL = URL(fileURLWithPath: filePath, relativeTo: cwd).standardizedFileURL
        let outputURL = outputPath ?? defaultOutput(fileURL)
        let options = requestedOptions ?? .strict
        return .success(
            ExportOptions(fileURL: fileURL, outputURL: outputURL, parseOptions: options))
    }

    private static func validateOutputPath(_ url: URL) throws {
        let parent = url.deletingLastPathComponent()
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: parent.path, isDirectory: &isDirectory),
            isDirectory.boolValue
        else {
            throw ExportExecutionError.unwritableDestination(parent.path)
        }

        guard FileManager.default.isWritableFile(atPath: parent.path) else {
            throw ExportExecutionError.unwritableDestination(parent.path)
        }
    }
}

extension ISOInspectorCLIEnvironment {
    func emitCorruptionSummaryIfNeeded(
        parseOptions: ParsePipeline.Options,
        issueStore: ParseIssueStore? = nil
    ) {
        guard !parseOptions.abortOnStructuralError else { return }
        let store = issueStore ?? self.issueStore
        let summary = store.makeIssueSummary()
        guard summary.totalCount > 0 else { return }

        print("Corruption summary:")
        print("  Errors: \(summary.count(for: .error))")
        print("  Warnings: \(summary.count(for: .warning))")
        print("  Info: \(summary.count(for: .info))")
        print("  Deepest affected depth: \(summary.deepestAffectedDepth)")
    }
}

enum ISOInspectorCLIIO {
    static func welcomeSummary() -> String {
        ISOInspectorKit.welcomeMessage()
    }

    static func printWelcome() {
        print(welcomeSummary())
    }
}
