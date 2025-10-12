import ArgumentParser
import XCTest
@testable import ISOInspectorCLI
@testable import ISOInspectorKit

final class ISOInspectorCommandTests: XCTestCase {
    func testRunWithoutArgumentsShowsHelpWithPlannedSubcommands() async throws {
        let help = ISOInspectorCommand.helpMessage()
        XCTAssertTrue(help.contains(ISOInspectorKit.projectName))
        XCTAssertTrue(help.localizedCaseInsensitiveContains("inspect"))
        XCTAssertTrue(help.localizedCaseInsensitiveContains("validate"))
        XCTAssertTrue(help.localizedCaseInsensitiveContains("export"))

        var command = try ISOInspectorCommand.parse([])

        do {
            try await command.run()
            XCTFail("Expected CleanExit for help request")
        } catch let exit as CleanExit {
            XCTAssertEqual(exit.description, "--help")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRunBootstrapsSharedContextWithEnvironmentFromFactory() async throws {
        let printed = MutableBox<[String]>([])
        let customEnvironment = ISOInspectorCLIEnvironment(
            refreshCatalog: { _, _ in },
            parsePipeline: .live(),
            formatter: EventConsoleFormatter(),
            print: { printed.value.append($0) },
            printError: { _ in }
        )

        await MainActor.run {
            ISOInspectorCommand.contextFactory = { _ in
                ISOInspectorCommandContext(environment: customEnvironment)
            }
            ISOInspectorCommandContextStore.reset()
        }

        var command = try ISOInspectorCommand.parse([])
        _ = try? await command.run()

        let context = await MainActor.run { ISOInspectorCommandContextStore.current }
        context.environment.print("Hello")

        XCTAssertEqual(printed.value, ["Hello"])

        await MainActor.run {
            ISOInspectorCommandContextStore.reset()
            ISOInspectorCommand.contextFactory = ISOInspectorCommand.defaultContextFactory
        }
    }
}

private final class MutableBox<Value>: @unchecked Sendable {
    var value: Value

    init(_ value: Value) {
        self.value = value
    }
}
