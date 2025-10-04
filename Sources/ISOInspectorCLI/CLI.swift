import Foundation
import ISOInspectorKit

public enum ISOInspectorCLIRunner {
    public static func run(arguments: [String] = CommandLine.arguments) {
        if arguments.contains("--help") || arguments.contains("-h") {
            print(helpText())
            return
        }

        ISOInspectorCLIIO.printWelcome()
    }

    public static func helpText() -> String {
        "isoinspect — ISO BMFF (MP4/QuickTime) inspector CLI\n" +
        "  --help, -h    Show this help message.\n" +
        "Additional subcommands will be introduced per tasks D1–D4 in the PRD."
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
