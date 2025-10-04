import XCTest

final class CIWorkflowConfigurationTests: XCTestCase {
    private var repositoryRoot: URL {
        var url = URL(fileURLWithPath: #filePath)
        // Ascend to Tests/ISOInspectorKitTests
        url.deleteLastPathComponent() // current file
        url.deleteLastPathComponent() // ISOInspectorKitTests
        url.deleteLastPathComponent() // Tests
        return url
    }

    func testCIWorkflowFileExistsWithSwiftBuildAndTestSteps() throws {
        let workflowURL = repositoryRoot
            .appending(path: ".github")
            .appending(path: "workflows")
            .appending(path: "ci.yml")
        let workflowData = try Data(contentsOf: workflowURL)
        let workflowContents = String(decoding: workflowData, as: UTF8.self)

        XCTAssertTrue(workflowContents.contains("swift build"), "Expected workflow to build the package")
        XCTAssertTrue(workflowContents.contains("swift test"), "Expected workflow to run the test suite")
        XCTAssertTrue(workflowContents.contains("pull_request"), "Workflow should trigger on pull requests")
    }
}
