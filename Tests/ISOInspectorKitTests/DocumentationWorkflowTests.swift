import XCTest

final class DocumentationWorkflowTests: XCTestCase {
    func testDoccCatalogsExistForAllPrimaryTargets() throws {
        let fileURL = URL(fileURLWithPath: #filePath)
        let repoRoot = fileURL.deletingLastPathComponent()  // DocumentationWorkflowTests.swift
            .deletingLastPathComponent()  // ISOInspectorKitTests
            .deletingLastPathComponent()  // Tests

        let requiredDocs = [
            "Sources/ISOInspectorKit/ISOInspectorKit.docc/Documentation.md",
            "Sources/ISOInspectorCLI/ISOInspectorCLI.docc/Documentation.md",
            "Sources/ISOInspectorApp/ISOInspectorApp.docc/Documentation.md",
        ]

        for relativePath in requiredDocs {
            let path = repoRoot.appendingPathComponent(relativePath).path
            XCTAssertTrue(
                FileManager.default.fileExists(atPath: path),
                "Expected DocC documentation entry point at \(relativePath), but it was not found.")
        }
    }

    func testDocumentationGenerationScriptIsPresent() throws {
        let fileURL = URL(fileURLWithPath: #filePath)
        let repoRoot = fileURL.deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent()

        let scriptPath = repoRoot.appendingPathComponent("scripts/generate_documentation.sh").path
        XCTAssertTrue(
            FileManager.default.isExecutableFile(atPath: scriptPath),
            "Expected executable documentation generation script at scripts/generate_documentation.sh"
        )
    }
}
