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

        public struct Export: ParsableCommand {
            public static let configuration = CommandConfiguration(
                abstract: "Export parse artifacts such as JSON trees or binary captures."
            )

            public init() {}

            public mutating func run() throws {
                // @todo PDD:45m Route export operations to streaming capture utilities as they migrate from ISOInspectorCLIRunner.
                throw CleanExit.message("Export functionality will be migrated from the legacy runner in Task D3 follow-ups.")
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
