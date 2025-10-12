import ArgumentParser
import Foundation
import ISOInspectorKit

public struct ISOInspectorCommand: AsyncParsableCommand {
    public init() {}

    public static let configuration = CommandConfiguration(
        commandName: "isoinspector",
        abstract: "\(ISOInspectorKit.projectName) CLI for streaming ISO Base Media (MP4/QuickTime) inspection.",
        discussion: "Inspect, validate, and export parse events with shared streaming services. Subcommands land in subsequent tasks.",
        subcommands: [
            Commands.Inspect.self,
            Commands.Validate.self,
            Commands.Export.self
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
            let context = contextFactory(options)
            ISOInspectorCommandContextStore.bootstrap(with: context)
        }
    }

    public struct GlobalOptions: ParsableArguments, Sendable {
        public init() {}

        // @todo PDD:45m Surface global logging and telemetry toggles once streaming metrics are exposed to the CLI.
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
