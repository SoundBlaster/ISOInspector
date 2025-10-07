import Dispatch
import Foundation
import ISOInspectorKit

public struct ISOInspectorCLIEnvironment {
    public var refreshCatalog: (_ source: URL, _ output: URL) throws -> Void
    public var makeReader: (_ url: URL) throws -> RandomAccessReader
    public var parsePipeline: ParsePipeline
    public var formatter: EventConsoleFormatter
    public var print: (String) -> Void
    public var printError: (String) -> Void

    public init(
        refreshCatalog: @escaping (_ source: URL, _ output: URL) throws -> Void,
        makeReader: @escaping (_ url: URL) throws -> RandomAccessReader = { url in
            try ChunkedFileReader(fileURL: url)
        },
        parsePipeline: ParsePipeline = .live(),
        formatter: EventConsoleFormatter = EventConsoleFormatter(),
        print: @escaping (String) -> Void = { Swift.print($0) },
        printError: @escaping (String) -> Void = { message in fputs(message + "\n", stderr) }
    ) {
        self.refreshCatalog = refreshCatalog
        self.makeReader = makeReader
        self.parsePipeline = parsePipeline
        self.formatter = formatter
        self.print = print
        self.printError = printError
    }

    public static let live = ISOInspectorCLIEnvironment { source, output in
        let provider = HTTPMP4RARegistryDataProvider(sourceURL: source)
        let refresher = MP4RACatalogRefresher(dataProvider: provider)
        _ = try refresher.writeCatalog(to: output)
    }
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
        default:
            ISOInspectorCLIIO.printWelcome()
        }
    }

    public static func helpText() -> String {
        "isoinspect — ISO BMFF (MP4/QuickTime) inspector CLI\n" +
            "  --help, -h    Show this help message.\n" +
            "  inspect <file> Stream parse events with metadata and validation summaries.\n" +
            "  mp4ra refresh [--output <path>] [--source <url>]\n" +
            "                Refresh the bundled MP4RABoxes.json using the latest registry export."
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
        guard let path = arguments.first else {
            environment.printError("inspect requires a file path.")
            return
        }

        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let fileURL = URL(fileURLWithPath: path, relativeTo: cwd).standardizedFileURL

        do {
            let reader = try environment.makeReader(fileURL)
            let events = environment.parsePipeline.events(for: reader)
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
        } catch {
            environment.printError("Failed to inspect file: \(error)")
        }
    }

    private static func parseRefreshOptions(
        _ arguments: [String]
    ) -> Result<RefreshOptions, RefreshParseError> {
        var iterator = arguments.makeIterator()
        var source = MP4RARegistryEndpoints.boxes
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        var output = cwd
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
}

enum ISOInspectorCLIIO {
    static func welcomeSummary() -> String {
        ISOInspectorKit.welcomeMessage()
    }

    static func printWelcome() {
        print(welcomeSummary())
    }
}
