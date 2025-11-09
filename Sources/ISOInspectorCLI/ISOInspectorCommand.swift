import ArgumentParser
import Foundation
import ISOInspectorKit

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
        _ = await Self.resolveContext(applying: globalOptions)
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

            let providedPresets = context.validationPresets
            let presets: [ValidationPreset]
            let defaultPresetID: String
            var resolvedConfiguration = context.validationConfiguration
            var wasCustomized = context.validationConfigurationWasCustomized

            if providedPresets.isEmpty {
                let bundled = GlobalOptions.bundledPresets()
                presets = bundled
                defaultPresetID = GlobalOptions.defaultPresetID(in: bundled)
                resolvedConfiguration = ValidationConfiguration(activePresetID: defaultPresetID)
                wasCustomized = false

                do {
                    let result = try options.makeValidationConfiguration(
                        presets: presets,
                        defaultPresetID: defaultPresetID
                    )
                    resolvedConfiguration = result.configuration
                    wasCustomized = result.wasCustomized
                } catch {
                    environment.printError("Failed to resolve validation configuration: \(error)")
                }
            } else {
                presets = providedPresets
                defaultPresetID = GlobalOptions.defaultPresetID(in: presets)
            }

            context.environment = environment
            context.verbosity = options.resolvedVerbosity
            context.telemetryMode = options.resolvedTelemetryMode
            context.validationPresets = presets
            context.validationConfigurationWasCustomized = wasCustomized
            context.validationConfiguration = resolvedConfiguration
            ISOInspectorCommandContextStore.bootstrap(with: context)
        }
    }

    @MainActor static func resolveContext(applying options: GlobalOptions) async -> ISOInspectorCommandContext {
        await bootstrap(with: options)
        return await MainActor.run { ISOInspectorCommandContextStore.current }
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

        @Flag(
            name: .long,
            help: "Continue through corruption without aborting the parse stream."
        )
        public var tolerant: Bool = false

        @Flag(
            name: .long,
            help: "Abort on corruption and surface strict-mode diagnostics (default)."
        )
        public var strict: Bool = false

        @Option(
            name: .long,
            help: ArgumentHelp(
                ISOInspectorCommand.GlobalOptions.presetOptionHelpText(),
                valueName: "PRESET"
            )
        )
        public var preset: String?

        @Flag(
            name: .long,
            help: "Shortcut for '--preset structural'."
        )
        public var structuralOnly: Bool = false

        @Option(
            name: .long,
            parsing: .upToNextOption,
            help: ArgumentHelp(
                ISOInspectorCommand.GlobalOptions.ruleToggleHelpText(action: "Enable"),
                valueName: "RULE_ID"
            )
        )
        public var enableRule: [String] = []

        @Option(
            name: .long,
            parsing: .upToNextOption,
            help: ArgumentHelp(
                ISOInspectorCommand.GlobalOptions.ruleToggleHelpText(action: "Disable"),
                valueName: "RULE_ID"
            )
        )
        public var disableRule: [String] = []

        public mutating func validate() throws {
            if quiet && verbose {
                throw ValidationError("Specify at most one of --quiet or --verbose.")
            }

            if enableTelemetry && disableTelemetry {
                throw ValidationError("Specify at most one telemetry toggle flag.")
            }

            if tolerant && strict {
                throw ValidationError("Specify at most one of --tolerant or --strict.")
            }

            let presets = Self.bundledPresets()
            let defaultPresetID = Self.defaultPresetID(in: presets)
            _ = try resolvedPresetID(presets: presets, defaultPresetID: defaultPresetID)
            _ = try resolvedRuleOverrides()
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

        public var resolvedParseOptions: ParsePipeline.Options {
            if tolerant {
                return .tolerant
            }

            if strict {
                return .strict
            }

            return .strict
        }

        static func defaultPresetID(in presets: [ValidationPreset]) -> String {
            if presets.contains(where: { $0.id == "all-rules" }) {
                return "all-rules"
            }
            return presets.first?.id ?? "all-rules"
        }

        func makeValidationConfiguration(
            presets: [ValidationPreset],
            defaultPresetID: String
        ) throws -> (configuration: ValidationConfiguration, wasCustomized: Bool) {
            let (presetID, presetWasExplicit) = try resolvedPresetID(
                presets: presets,
                defaultPresetID: defaultPresetID
            )
            let overrides = try resolvedRuleOverrides()
            var configuration = ValidationConfiguration(activePresetID: presetID)
            for (identifier, isEnabled) in overrides {
                configuration.ruleOverrides[identifier] = isEnabled
            }
            let wasCustomized = presetWasExplicit || !overrides.isEmpty
            return (configuration, wasCustomized)
        }

        static func bundledPresets() -> [ValidationPreset] {
            (try? ValidationPreset.loadBundledPresets()) ?? []
        }

        private static func presetOptionHelpText() -> String {
            let presets = bundledPresets()
            guard !presets.isEmpty else {
                return "Select a validation preset identifier to configure rule defaults."
            }
            let listings = presets.map { "\($0.id) — \($0.summary)" }
            let aliases = "structural-only → structural"
            return "Select a validation preset identifier (aliases: \(aliases)). Available presets: \(listings.joined(separator: "; "))."
        }

        private static func ruleToggleHelpText(action: String) -> String {
            let identifiers = ValidationRuleIdentifier.allCases
                .map(\.rawValue)
                .sorted()
            return "\(action) specific validation rule identifiers for this run. Known IDs: \(identifiers.joined(separator: ", "))."
        }

        private func resolvedPresetID(
            presets: [ValidationPreset],
            defaultPresetID: String
        ) throws -> (String, Bool) {
            var selections: Set<String> = []
            var wasExplicit = false
            if let preset, !preset.isEmpty {
                selections.insert(preset)
                wasExplicit = true
            }
            for alias in selectedAliasPresetIDs() {
                selections.insert(alias)
                wasExplicit = true
            }

            if selections.count > 1 {
                throw ValidationError("Specify at most one validation preset selector.")
            }

            let selectedID = selections.first ?? defaultPresetID
            if !presets.contains(where: { $0.id == selectedID }) {
                throw ValidationError("Unknown validation preset: \(selectedID)")
            }
            return (selectedID, wasExplicit)
        }

        private func resolvedRuleOverrides() throws -> [ValidationRuleIdentifier: Bool] {
            let mapping = Dictionary(uniqueKeysWithValues: ValidationRuleIdentifier.allCases.map { ($0.rawValue, $0) })
            var overrides: [ValidationRuleIdentifier: Bool] = [:]

            for id in enableRule {
                guard let identifier = mapping[id] else {
                    throw ValidationError("Unknown validation rule identifier: \(id)")
                }
                if let existing = overrides[identifier], existing == false {
                    throw ValidationError("Validation rule \(id) cannot be both enabled and disabled.")
                }
                overrides[identifier] = true
            }

            for id in disableRule {
                guard let identifier = mapping[id] else {
                    throw ValidationError("Unknown validation rule identifier: \(id)")
                }
                if let existing = overrides[identifier], existing == true {
                    throw ValidationError("Validation rule \(id) cannot be both enabled and disabled.")
                }
                overrides[identifier] = false
            }

            return overrides
        }

        private func selectedAliasPresetIDs() -> [String] {
            var ids: [String] = []
            if structuralOnly {
                ids.append("structural")
            }
            return ids
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

            @OptionGroup
            public var globalOptions: ISOInspectorCommand.GlobalOptions

            public init() {
                self._globalOptions = .init()
            }

            public mutating func run() async throws {
                let context = await ISOInspectorCommand.resolveContext(applying: globalOptions)
                let environment = context.environment
                let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                let fileURL = URL(fileURLWithPath: file, relativeTo: cwd).standardizedFileURL
                let researchLogURL: URL
                if let researchLog {
                    researchLogURL = URL(fileURLWithPath: researchLog, relativeTo: cwd).standardizedFileURL
                } else {
                    researchLogURL = environment.defaultResearchLogURL()
                }

                let metadata = ISOInspectorCommand.validationMetadata(
                    configuration: context.validationConfiguration,
                    presets: context.validationPresets
                )
                let disabledRuleIDs = Set(metadata.disabledRuleIDs)
                let parseOptions = globalOptions.resolvedParseOptions

                do {
                    let reader = try environment.makeReader(fileURL)
                    let researchLog = try environment.makeResearchLogWriter(researchLogURL)
                    environment.print("Research log → \(researchLogURL.path)")
                    environment.print(
                        "VR-006 schema v\(ResearchLogSchema.version): \(ResearchLogSchema.fieldNames.joined(separator: ", "))"
                    )
                    ISOInspectorCommand.printValidationMetadataIfNeeded(
                        metadata: metadata,
                        wasCustomized: context.validationConfigurationWasCustomized,
                        using: environment
                    )

                    let issueStore = environment.issueStore
                    let events = environment.parsePipeline.events(
                        for: reader,
                        context: .init(
                            source: fileURL,
                            researchLog: researchLog,
                            options: parseOptions,
                            issueStore: issueStore
                        )
                    )

                    defer {
                        environment.emitCorruptionSummaryIfNeeded(
                            parseOptions: parseOptions,
                            issueStore: issueStore
                        )
                    }

                    do {
                        for try await event in events {
                            let filtered = ISOInspectorCommand.filteredEvent(
                                event,
                                removing: disabledRuleIDs
                            )
                            environment.print(environment.formatter.format(filtered))
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

            @OptionGroup
            public var globalOptions: ISOInspectorCommand.GlobalOptions

            public init() {
                self._globalOptions = .init()
            }

            public mutating func run() async throws {
                let context = await ISOInspectorCommand.resolveContext(applying: globalOptions)
                let environment = context.environment
                let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                let fileURL = URL(fileURLWithPath: file, relativeTo: cwd).standardizedFileURL

                let metadata = ISOInspectorCommand.validationMetadata(
                    configuration: context.validationConfiguration,
                    presets: context.validationPresets
                )
                let disabledRuleIDs = Set(metadata.disabledRuleIDs)
                let parseOptions = globalOptions.resolvedParseOptions

                do {
                    let reader = try environment.makeReader(fileURL)
                    let issueStore = environment.issueStore
                    let events = environment.parsePipeline.events(
                        for: reader,
                        context: .init(
                            source: fileURL,
                            options: parseOptions,
                            issueStore: issueStore
                        )
                    )

                    ISOInspectorCommand.printValidationMetadataIfNeeded(
                        metadata: metadata,
                        wasCustomized: context.validationConfigurationWasCustomized,
                        using: environment
                    )

                    var counts: [ValidationIssue.Severity: Int] = [:]
                    var details: [ValidationIssue.Severity: [String]] = [:]

                    do {
                        for try await event in events {
                            let filtered = ISOInspectorCommand.filteredEvent(
                                event,
                                removing: disabledRuleIDs
                            )
                            for issue in filtered.validationIssues {
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
                subcommands: [JSON.self, Capture.self, Text.self]
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

            public struct Text: AsyncParsableCommand {
                public static let configuration = CommandConfiguration(
                    commandName: "text",
                    abstract: "Export a plaintext issue summary with grouped diagnostics."
                )

                @OptionGroup
                public var options: Export.Options

                public init() {}

                public mutating func run() async throws {
                    try await Export.execute(mode: .text, with: options)
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

                @OptionGroup
                var globalOptions: ISOInspectorCommand.GlobalOptions

                public init() {
                    self._globalOptions = .init()
                }
            }

            enum Mode {
                case json
                case capture
                case text

                func defaultOutput(for fileURL: URL) -> URL {
                    switch self {
                    case .json:
                        return fileURL
                            .appendingPathExtension("isoinspector")
                            .appendingPathExtension("json")
                    case .capture:
                        return fileURL.appendingPathExtension("capture")
                    case .text:
                        return fileURL
                            .appendingPathExtension("isoinspector")
                            .appendingPathExtension("txt")
                    }
                }

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

                let context = await ISOInspectorCommand.resolveContext(applying: options.globalOptions)
                let environment = context.environment
                let parseOptions = options.globalOptions.resolvedParseOptions
                let issueStore = environment.issueStore

                let validationMetadata = ISOInspectorCommand.validationMetadata(
                    configuration: context.validationConfiguration,
                    presets: context.validationPresets
                )
                let disabledRuleIDs = Set(validationMetadata.disabledRuleIDs)

                do {
                    try validateOutputPath(outputURL)

                    let reader = try environment.makeReader(fileURL)
                    let events = environment.parsePipeline.events(
                        for: reader,
                        context: .init(
                            source: fileURL,
                            options: parseOptions,
                            issueStore: issueStore
                        )
                    )

                    var builder = ParseTreeBuilder()
                    var captured: [ParseEvent] = []

                    do {
                        for try await event in events {
                            let filtered = ISOInspectorCommand.filteredEvent(
                                event,
                                removing: disabledRuleIDs
                            )
                            builder.consume(filtered)
                            captured.append(filtered)
                        }
                    } catch {
                        environment.printError(mode.failurePrefix + "\(error)")
                        throw ExitCode(3)
                    }

                    var tree = builder.makeTree()
                    if context.validationConfigurationWasCustomized {
                        tree.validationMetadata = validationMetadata
                    }

                    let data: Data
                    switch mode {
                    case .json:
                        data = try JSONParseTreeExporter().export(tree: tree)
                    case .capture:
                        data = try ParseEventCaptureEncoder().encode(events: captured)
                    case .text:
                        let metadata = PlaintextIssueSummaryExporter.Metadata(
                            filePath: fileURL.standardizedFileURL.path,
                            fileSize: reader.length,
                            analyzedAt: Date(),
                            sha256: nil
                        )
                        let summary = environment.issueStore.makeIssueSummary()
                        let issues = environment.issueStore.issuesSnapshot()
                        data = try PlaintextIssueSummaryExporter().export(
                            tree: tree,
                            metadata: metadata,
                            summary: summary,
                            issues: issues
                        )
                    }

                    try data.write(to: outputURL, options: .atomic)
                    ISOInspectorCommand.printValidationMetadataIfNeeded(
                        metadata: validationMetadata,
                        wasCustomized: context.validationConfigurationWasCustomized,
                        using: environment
                    )
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

            @OptionGroup
            public var globalOptions: ISOInspectorCommand.GlobalOptions

            public init() {
                self._globalOptions = .init()
            }

            public mutating func validate() throws {
                if inputs.isEmpty {
                    throw ValidationError("Specify at least one input path or glob pattern.")
                }
            }

            public mutating func run() async throws {
                let context = await ISOInspectorCommand.resolveContext(applying: globalOptions)
                let environment = context.environment
                let parseOptions = globalOptions.resolvedParseOptions
                let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                let resolver = InputResolver(fileManager: .default)
                let resolution = resolver.resolve(inputs: inputs, relativeTo: cwd)

                let metadata = ISOInspectorCommand.validationMetadata(
                    configuration: context.validationConfiguration,
                    presets: context.validationPresets
                )
                let disabledRuleIDs = Set(metadata.disabledRuleIDs)

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
                            let issueStore = environment.issueStore
                            let events = environment.parsePipeline.events(
                                for: reader,
                                context: .init(
                                    source: fileURL,
                                    options: parseOptions,
                                    issueStore: issueStore
                                )
                            )

                            do {
                                for try await event in events {
                                    let filtered = ISOInspectorCommand.filteredEvent(
                                        event,
                                        removing: disabledRuleIDs
                                    )
                                    if case .willStartBox = filtered.kind {
                                        boxCount += 1
                                    }

                                    for issue in filtered.validationIssues {
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
                    ISOInspectorCommand.printValidationMetadataIfNeeded(
                        metadata: metadata,
                        wasCustomized: context.validationConfigurationWasCustomized,
                        using: environment
                    )
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

extension ISOInspectorCommand {
    static func validationMetadata(
        configuration: ValidationConfiguration,
        presets: [ValidationPreset]
    ) -> ValidationMetadata {
        let disabled = ValidationRuleIdentifier.allCases
            .filter { !configuration.isRuleEnabled($0, presets: presets) }
            .map(\.rawValue)
            .sorted()
        return ValidationMetadata(activePresetID: configuration.activePresetID, disabledRuleIDs: disabled)
    }

    static func filteredEvent(
        _ event: ParseEvent,
        removing disabledRuleIDs: Set<String>
    ) -> ParseEvent {
        guard !event.validationIssues.isEmpty, !disabledRuleIDs.isEmpty else { return event }
        let filtered = event.validationIssues.filter { !disabledRuleIDs.contains($0.ruleID) }
        if filtered.count == event.validationIssues.count {
            return event
        }
        return ParseEvent(
            kind: event.kind,
            offset: event.offset,
            metadata: event.metadata,
            payload: event.payload,
            validationIssues: filtered,
            issues: event.issues
        )
    }

    static func printValidationMetadataIfNeeded(
        metadata: ValidationMetadata,
        wasCustomized: Bool,
        using environment: ISOInspectorCLIEnvironment
    ) {
        guard wasCustomized else { return }
        environment.print("Validation preset: \(metadata.activePresetID)")
        if !metadata.disabledRuleIDs.isEmpty {
            environment.print("Disabled rules: \(metadata.disabledRuleIDs.joined(separator: ", "))")
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
