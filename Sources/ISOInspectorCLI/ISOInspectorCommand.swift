import ArgumentParser
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
        public struct Inspect: ParsableCommand {
            public static let configuration = CommandConfiguration(
                abstract: "Stream parse events, validation summaries, and research log hooks for a media file."
            )

            public init() {}

            public mutating func run() throws {
                // @todo PDD:1h Execute streaming inspection by consuming ParsePipeline events (Task D2).
                throw CleanExit.message("The inspect command will stream parse events once Task D2 is implemented.")
            }
        }

        public struct Validate: ParsableCommand {
            public static let configuration = CommandConfiguration(
                abstract: "Validate ISO BMFF files with streaming rules and contextual metadata."
            )

            public init() {}

            public mutating func run() throws {
                // @todo PDD:1h Produce validation reports with streaming pipeline once Task D2 defines output format.
                throw CleanExit.message("The validate command will produce rule summaries when Task D2 lands.")
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
