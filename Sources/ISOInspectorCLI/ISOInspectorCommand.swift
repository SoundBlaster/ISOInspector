import ArgumentParser
import Foundation

#if canImport(ISOInspectorKit_iOS)
import ISOInspectorKit_iOS
#endif
#if canImport(ISOInspectorKit_macOS)
import ISOInspectorKit_macOS
#endif
#if canImport(ISOInspectorKit_ipadOS)
import ISOInspectorKit_ipadOS
#endif
#if canImport(ISOInspectorKit)
import ISOInspectorKit
#endif

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

public struct ISOInspectorCommand: AsyncParsableCommand {
    public init() {}

    public static let configuration = CommandConfiguration(
        commandName: "isoinspector",
        abstract: "\(ISOInspectorKit.projectName) CLI for streaming ISO Base Media (MP4/QuickTime) inspection.",
        discussion: "Inspect, validate, and export parse events with shared streaming services. Subcommands land in subsequent tasks.",
        subcommands: [
            Commands.Inspect.self,
            Commands.Validate.self,
            Commands.Export.self,
            Commands.Batch.self
        ],
        helpNames: [.short, .long]
    )

    public static var defaultContextFactory: @Sendable (GlobalOptions) -> ISOInspectorCommandContext {
        { _ in
            ISOInspectorCommandContext(environment: .live)
        }
    }

    @MainActor public static var contextFactory: @Sendable (GlobalOptions) -> ISOInspectorCommandContext = defaultContextFactory

    @OptionGroup
    public var globalOptions: GlobalOptions

    public mutating func run() async throws {
        await Self.bootstrap(with: globalOptions)
        throw CleanExit.helpRequest(self)
    }

    static func bootstrap(with options: GlobalOptions) async {
        await MainActor.run {
            var context = contextFactory(options)
            var environment = context.environment

            switch options.resolvedVerbosity {
            case .quiet:
                environment.logVerbosity = .quiet
                environment.print = { _ in }
            case .verbose:
                let basePrint = environment.print
                environment.logVerbosity = .verbose
                environment.print = { message in
                    basePrint("[verbose] \(message)")
                }
            case .standard:
                environment.logVerbosity = .standard
            }

            switch options.resolvedTelemetryMode {
            case .enabled:
                environment.telemetryEnabled = true
            case .disabled:
                environment.telemetryEnabled = false
            }

            context.environment = environment
            context.verbosity = options.resolvedVerbosity
            context.telemetryMode = options.resolvedTelemetryMode
            ISOInspectorCommandContextStore.bootstrap(with: context)
        }
    }

    public struct GlobalOptions: ParsableArguments, Sendable {
        public init() {}

        public enum Verbosity: Sendable {
            case quiet
            case standard
            case verbose
        }

        public enum TelemetryMode: Sendable {
            case enabled
            case disabled
        }

        @Flag(
            name: [.customShort("q"), .long],
            help: "Suppress standard CLI output, emitting only errors and critical summaries."
        )
        public var quiet: Bool = false

        @Flag(
            name: .long,
            help: "Print additional diagnostics while streaming parse events."
        )
        public var verbose: Bool = false

        @Flag(
            name: .long,
            help: "Enable streaming telemetry metrics even if disabled by defaults."
        )
        public var enableTelemetry: Bool = false

        @Flag(
            name: .long,
            help: "Disable streaming telemetry metrics for this invocation."
        )
        public var disableTelemetry: Bool = false

        public mutating func validate() throws {
            if quiet && verbose {
                throw ValidationError("Specify at most one of --quiet or --verbose.")
            }

            if enableTelemetry && disableTelemetry {
                throw ValidationError("Specify at most one telemetry toggle flag.")
            }
        }

        public var resolvedVerbosity: Verbosity {
            if quiet {
                return .quiet
            }

            if verbose {
                return .verbose
            }

            return .standard
        }

        public var resolvedTelemetryMode: TelemetryMode {
            if disableTelemetry {
                return .disabled
            }

            if enableTelemetry {
                return .enabled
            }

            return .enabled
        }
    }

    public enum Commands {
        public struct Inspect: AsyncParsableCommand {
            public static let configuration = CommandConfiguration(
                abstract: "Stream parse events, validation summaries, and research log hooks for a media file."
            )

            @Argument(help: "Path to the media file to inspect.")
            public var file: String

            @Option(
                name: .long,
                help: "Optional output location for the VR-006 research log (defaults to ~/.isoinspector/research-log.json)."
            )
            public var researchLog: String?

            public init() {}

            public mutating func run() async throws {
                let context = await MainActor.run { ISOInspectorCommandContextStore.current }
                let environment = context.environment
                let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                let fileURL = URL(fileURLWithPath: file, relativeTo: cwd).standardizedFileURL
                let researchLogURL: URL
                if let researchLog {
                    researchLogURL = URL(fileURLWithPath: researchLog, relativeTo: cwd).standardizedFileURL
                } else {
                    researchLogURL = environment.defaultResearchLogURL()
                }

                do {
                    let reader = try environment.makeReader(fileURL)
                    let researchLog = try environment.makeResearchLogWriter(researchLogURL)
                    environment.print("Research log → \(researchLogURL.path)")
                    environment.print(
                        "VR-006 schema v\(ResearchLogSchema.version): \(ResearchLogSchema.fieldNames.joined(separator: ", "))"
                    )

                    let events = environment.parsePipeline.events(
                        for: reader,
                        context: .init(source: fileURL, researchLog: researchLog)
                    )

                    do {
                        for try await event in events {
                            environment.print(environment.formatter.format(event))
                        }
                    } catch {
                        environment.printError("Failed to inspect file: \(error)")
                        throw ExitCode(3)
                    }
                } catch {
                    environment.printError("Failed to inspect file: \(error)")
                    throw ExitCode(3)
                }
            }
        }

        public struct Validate: AsyncParsableCommand {
            public static let configuration = CommandConfiguration(
                abstract: "Validate ISO BMFF files with streaming rules and contextual metadata."
            )

            @Argument(help: "Path to the media file to validate.")
            public var file: String

            public init() {}

            public mutating func run() async throws {
                let context = await MainActor.run { ISOInspectorCommandContextStore.current }
                let environment = context.environment
                let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                let fileURL = URL(fileURLWithPath: file, relativeTo: cwd).standardizedFileURL

                do {
                    let reader = try environment.makeReader(fileURL)
                    let events = environment.parsePipeline.events(
                        for: reader,
                        context: .init(source: fileURL)
                    )

                    var counts: [ValidationIssue.Severity: Int] = [:]
                    var details: [ValidationIssue.Severity: [String]] = [:]

                    do {
                        for try await event in events {
                            for issue in event.validationIssues {
                                counts[issue.severity, default: 0] += 1
                                details[issue.severity, default: []].append("\(issue.ruleID): \(issue.message)")
                            }
                        }
                    } catch {
                        environment.printError("Failed to validate file: \(error)")
                        throw ExitCode(3)
                    }

                    environment.print("Validation summary for \(fileURL.path)")
                    for severity in ValidationIssue.Severity.displayOrder {
                        let count = counts[severity, default: 0]
                        environment.print("\(severity.displayLabel): \(count)")
                        if let messages = details[severity], !messages.isEmpty {
                            for message in messages {
                                environment.print("  • \(message)")
                            }
                        }
                    }

                    if counts[.error, default: 0] > 0 {
                        throw ExitCode(2)
                    }

                    if counts[.warning, default: 0] > 0 {
                        throw ExitCode(1)
                    }
                } catch let exit as ExitCode {
                    throw exit
                } catch {
                    environment.printError("Failed to validate file: \(error)")
                    throw ExitCode(3)
                }
            }
        }

        public struct Export: AsyncParsableCommand {
            public static let configuration = CommandConfiguration(
                abstract: "Export parse artifacts such as JSON trees or binary captures.",
                subcommands: [JSON.self, Capture.self]
            )

            public init() {}

            public mutating func run() async throws {
                throw CleanExit.helpRequest(Self.self)
            }

            public struct JSON: AsyncParsableCommand {
                public static let configuration = CommandConfiguration(
                    commandName: "json",
                    abstract: "Export a JSON representation of the parsed ISO BMFF tree."
                )

                @OptionGroup
                public var options: Export.Options

                public init() {}

                public mutating func run() async throws {
                    try await Export.execute(mode: .json, with: options)
                }
            }

            public struct Capture: AsyncParsableCommand {
                public static let configuration = CommandConfiguration(
                    commandName: "capture",
                    abstract: "Export a binary capture of parse events for replay."
                )

                @OptionGroup
                public var options: Export.Options

                public init() {}

                public mutating func run() async throws {
                    try await Export.execute(mode: .capture, with: options)
                }
            }

            public struct Options: ParsableArguments, Sendable {
                @Argument(help: "Path to the media file to export.")
                var file: String

                @Option(
                    name: [.customLong("output"), .short],
                    help: "Optional output location for the exported artifact."
                )
                var output: String?

                public init() {}
            }

            enum Mode {
                case json
                case capture

                func defaultOutput(for fileURL: URL) -> URL {
                    switch self {
                    case .json:
                        return fileURL
                            .appendingPathExtension("isoinspector")
                            .appendingPathExtension("json")
                    case .capture:
                        return fileURL.appendingPathExtension("capture")
                    }
                }

                var successMessage: String {
                    switch self {
                    case .json:
                        return "Exported JSON parse tree → "
                    case .capture:
                        return "Exported parse event capture → "
                    }
                }

                var failurePrefix: String {
                    switch self {
                    case .json:
                        return "Failed to export JSON parse tree: "
                    case .capture:
                        return "Failed to export parse event capture: "
                    }
                }
            }

            enum ExecutionError: Swift.Error {
                case unwritableDestination(String)

                var message: String {
                    switch self {
                    case .unwritableDestination(let path):
                        return "Destination is not writable: \(path)"
                    }
                }
            }

            static func execute(mode: Mode, with options: Options) async throws {
                let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                let fileURL = URL(fileURLWithPath: options.file, relativeTo: cwd).standardizedFileURL
                let outputURL: URL
                if let output = options.output {
                    outputURL = URL(fileURLWithPath: output, relativeTo: cwd).standardizedFileURL
                } else {
                    outputURL = mode.defaultOutput(for: fileURL)
                }

                let context = await MainActor.run { ISOInspectorCommandContextStore.current }
                let environment = context.environment

                do {
                    try validateOutputPath(outputURL)

                    let reader = try environment.makeReader(fileURL)
                    let events = environment.parsePipeline.events(
                        for: reader,
                        context: .init(source: fileURL)
                    )

                    var builder = ParseTreeBuilder()
                    var captured: [ParseEvent] = []

                    do {
                        for try await event in events {
                            builder.consume(event)
                            captured.append(event)
                        }
                    } catch {
                        environment.printError(mode.failurePrefix + "\(error)")
                        throw ExitCode(3)
                    }

                    let data: Data
                    switch mode {
                    case .json:
                        let tree = builder.makeTree()
                        data = try JSONParseTreeExporter().export(tree: tree)
                    case .capture:
                        data = try ParseEventCaptureEncoder().encode(events: captured)
                    }

                    try data.write(to: outputURL, options: .atomic)
                    environment.print(mode.successMessage + outputURL.path)
                } catch let executionError as ExecutionError {
                    environment.printError(executionError.message)
                    throw ExitCode(3)
                } catch let exit as ExitCode {
                    throw exit
                } catch {
                    environment.printError(mode.failurePrefix + "\(error)")
                    throw ExitCode(3)
                }
            }

            static func validateOutputPath(_ url: URL) throws {
                let parent = url.deletingLastPathComponent()
                var isDirectory: ObjCBool = false
                guard FileManager.default.fileExists(atPath: parent.path, isDirectory: &isDirectory),
                      isDirectory.boolValue else {
                    throw ExecutionError.unwritableDestination(parent.path)
                }

                guard FileManager.default.isWritableFile(atPath: parent.path) else {
                    throw ExecutionError.unwritableDestination(parent.path)
                }
            }
        }

        public struct Batch: AsyncParsableCommand {
            public static let configuration = CommandConfiguration(
                abstract: "Validate multiple ISO BMFF files and emit an aggregated summary."
            )

            @Argument(help: "File paths, directory globs, or directories to validate.")
            public var inputs: [String] = []

            @Option(
                name: .long,
                help: "Optional CSV output path for the aggregated summary table."
            )
            public var csv: String?

            public init() {}

            public mutating func validate() throws {
                if inputs.isEmpty {
                    throw ValidationError("Specify at least one input path or glob pattern.")
                }
            }

            public mutating func run() async throws {
                let context = await MainActor.run { ISOInspectorCommandContextStore.current }
                let environment = context.environment
                let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                let resolver = InputResolver(fileManager: .default)
                let resolution = resolver.resolve(inputs: inputs, relativeTo: cwd)

                switch resolution {
                case .failure(let error):
                    environment.printError(error.message)
                    throw ExitCode(3)
                case .success(let resolved):
                    for pattern in resolved.unmatchedPatterns {
                        environment.printError("No files matched pattern: \(pattern)")
                    }

                    var builder = BatchValidationSummary.Builder()
                    let fileManager = FileManager.default

                    for fileURL in resolved.files {
                        let fallbackSize: Int64?
                        if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
                           let number = attributes[.size] as? NSNumber {
                            fallbackSize = number.int64Value
                        } else {
                            fallbackSize = nil
                        }

                        do {
                            let reader = try environment.makeReader(fileURL)
                            var boxCount = 0
                            var severityCounts: [ValidationIssue.Severity: Int] = [:]
                            let events = environment.parsePipeline.events(
                                for: reader,
                                context: .init(source: fileURL)
                            )

                            do {
                                for try await event in events {
                                    if case .willStartBox = event.kind {
                                        boxCount += 1
                                    }

                                    for issue in event.validationIssues {
                                        severityCounts[issue.severity, default: 0] += 1
                                    }
                                }
                            } catch {
                                environment.printError("Failed to process \(fileURL.path): \(error)")
                                builder.appendParseFailure(
                                    fileURL: fileURL,
                                    size: reader.length,
                                    reason: String(describing: error)
                                )
                                continue
                            }

                            let errorCount = severityCounts[.error, default: 0]
                            let warningCount = severityCounts[.warning, default: 0]
                            let infoCount = severityCounts[.info, default: 0]

                            let status: BatchValidationSummary.Status
                            if errorCount > 0 {
                                status = .validationFailed
                            } else if warningCount > 0 {
                                status = .warnings
                            } else {
                                status = .success
                            }

                            builder.append(
                                fileURL: fileURL,
                                metrics: .init(
                                    size: reader.length,
                                    counts: .init(
                                        boxes: boxCount,
                                        errors: errorCount,
                                        warnings: warningCount,
                                        info: infoCount
                                    ),
                                    status: status
                                )
                            )
                        } catch let exit as ExitCode {
                            throw exit
                        } catch {
                            environment.printError("Failed to open \(fileURL.path): \(error)")
                            builder.appendParseFailure(
                                fileURL: fileURL,
                                size: fallbackSize,
                                reason: String(describing: error)
                            )
                        }
                    }

                    let summary = builder.build()
                    environment.print("Batch validation summary")
                    for line in summary.formattedLines() {
                        environment.print(line)
                    }

                    if let csv {
                        let csvURL = URL(fileURLWithPath: csv, relativeTo: cwd).standardizedFileURL
                        do {
                            try Export.validateOutputPath(csvURL)
                            try summary.csvData().write(to: csvURL, options: .atomic)
                            environment.print("CSV summary → \(csvURL.path)")
                        } catch let executionError as Export.ExecutionError {
                            environment.printError(executionError.message)
                            throw ExitCode(3)
                        } catch let exit as ExitCode {
                            throw exit
                        } catch {
                            environment.printError("Failed to write CSV summary: \(error)")
                            throw ExitCode(3)
                        }
                    }

                    if summary.hasParseFailures {
                        throw ExitCode(3)
                    }

                    if summary.hasValidationFailures {
                        throw ExitCode(2)
                    }

                    if summary.hasWarnings {
                        throw ExitCode(1)
                    }
                }
            }

            struct ResolvedInputs {
                let files: [URL]
                let unmatchedPatterns: [String]
            }

            struct ResolutionError: Swift.Error {
                let message: String
            }

            struct InputResolver {
                let fileManager: FileManager

                func resolve(inputs: [String], relativeTo cwd: URL) -> Result<ResolvedInputs, ResolutionError> {
                    var collected: [URL] = []
                    var unmatched: [String] = []
                    var seen: Set<String> = []

                    for input in inputs {
                        let expanded = (input as NSString).expandingTildeInPath

                        if Self.containsGlob(in: expanded) {
                            let matches = Self.expandGlob(expanded, relativeTo: cwd)
                            if matches.isEmpty {
                                unmatched.append(input)
                            } else {
                                for url in matches {
                                    let standardized = url.standardizedFileURL
                                    if seen.insert(standardized.path).inserted {
                                        collected.append(standardized)
                                    }
                                }
                            }
                            continue
                        }

                        let resolved = URL(fileURLWithPath: expanded, relativeTo: cwd).standardizedFileURL
                        var isDirectory: ObjCBool = false
                        if fileManager.fileExists(atPath: resolved.path, isDirectory: &isDirectory) {
                            if isDirectory.boolValue {
                                let files = collectFiles(in: resolved)
                                if files.isEmpty {
                                    unmatched.append(input)
                                } else {
                                    for file in files {
                                        let standardized = file.standardizedFileURL
                                        if seen.insert(standardized.path).inserted {
                                            collected.append(standardized)
                                        }
                                    }
                                }
                            } else {
                                if seen.insert(resolved.path).inserted {
                                    collected.append(resolved)
                                }
                            }
                        } else {
                            unmatched.append(input)
                        }
                    }

                    if collected.isEmpty {
                        if unmatched.isEmpty {
                            return .failure(.init(message: "No files matched the provided inputs."))
                        }

                        return .failure(
                            .init(message: "No files matched the provided inputs: \(unmatched.joined(separator: ", "))")
                        )
                    }

                    collected.sort { $0.path < $1.path }
                    return .success(.init(files: collected, unmatchedPatterns: unmatched))
                }

                private func collectFiles(in directory: URL) -> [URL] {
                    guard let enumerator = fileManager.enumerator(
                        at: directory,
                        includingPropertiesForKeys: [.isRegularFileKey],
                        options: [.skipsPackageDescendants, .skipsHiddenFiles]
                    ) else {
                        return []
                    }

                    var results: [URL] = []
                    for case let fileURL as URL in enumerator {
                        do {
                            let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
                            if values.isRegularFile == true {
                                results.append(fileURL)
                            }
                        } catch {
                            continue
                        }
                    }
                    return results
                }

                private static func containsGlob(in input: String) -> Bool {
                    input.contains { character in
                        character == "*" || character == "?" || character == "["
                    }
                }

                private static func expandGlob(_ pattern: String, relativeTo cwd: URL) -> [URL] {
                    let resolvedPattern: String
                    if pattern.hasPrefix("/") {
                        resolvedPattern = pattern
                    } else {
                        resolvedPattern = cwd.appendingPathComponent(pattern).path
                    }

#if os(Windows)
                    _ = cwd
                    return []
#else
                    return resolvedPattern.withCString { pointer in
                        var globResult = glob_t()
                        defer { globfree(&globResult) }
                        let flags: Int32
#if canImport(Darwin)
                        flags = GLOB_TILDE
#elseif canImport(Glibc)
                        flags = GLOB_TILDE
#else
                        flags = 0
#endif
                        let status = glob(pointer, flags, nil, &globResult)
                        guard status == 0, let pathVector = globResult.gl_pathv else { return [] }
                        let count = Int(globResult.gl_pathc)
                        var matches: [URL] = []
                        for index in 0..<count {
                            if let cString = pathVector[index] {
                                let path = String(cString: cString)
                                matches.append(URL(fileURLWithPath: path).standardizedFileURL)
                            }
                        }
                        return matches
                    }
#endif
                }
            }
        }
    }
}

private extension ValidationIssue.Severity {
    static var displayOrder: [ValidationIssue.Severity] { [.error, .warning, .info] }

    var displayLabel: String {
        switch self {
        case .error:
            return "Errors"
        case .warning:
            return "Warnings"
        case .info:
            return "Info"
        }
    }
}
