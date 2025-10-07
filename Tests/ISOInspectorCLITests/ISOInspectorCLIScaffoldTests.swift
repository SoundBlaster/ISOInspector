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

    func testRunExecutesMP4RARefreshWithParsedArguments() throws {
        var capturedSource: URL?
        var capturedOutput: URL?
        let environment = ISOInspectorCLIEnvironment(
            refreshCatalog: { source, output in
                capturedSource = source
                capturedOutput = output
            },
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
                "/tmp/catalog.json"
            ],
            environment: environment
        )

        XCTAssertEqual(capturedSource, URL(string: "https://example.com/custom.json"))
        XCTAssertEqual(capturedOutput?.path, "/tmp/catalog.json")
    }
}
