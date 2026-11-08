import XCTest

final class CIWorkflowConfigurationTests: XCTestCase {
    private var repositoryRoot: URL {
        var url = URL(fileURLWithPath: #filePath)
        // Ascend to Tests/ISOInspectorKitTests
        url.deleteLastPathComponent()  // current file
        url.deleteLastPathComponent()  // ISOInspectorKitTests
        url.deleteLastPathComponent()  // Tests
        return url
    }

    func testPullRequestsHaveAnAlwaysPresentGateAndLinuxTests() throws {
        let workflows = repositoryRoot.appendingPathComponent(".github/workflows", isDirectory: true)
        let gate = try String(contentsOf: workflows.appendingPathComponent("pr-quality-gate.yml"), encoding: .utf8)
        let linux = try String(contentsOf: workflows.appendingPathComponent("swift-linux.yml"), encoding: .utf8)

        XCTAssertTrue(
            linux.contains("swift build"), "Expected Linux workflow to build the package")
        XCTAssertTrue(
            linux.contains("swift test"), "Expected Linux workflow to run the test suite")
        XCTAssertTrue(
            gate.contains("pull_request:"), "Quality gate should trigger on pull requests")
        XCTAssertTrue(gate.contains("name: PR Quality Gate"))
        XCTAssertTrue(gate.contains("uses: ./.github/workflows/swift-linux.yml"))
    }
}
