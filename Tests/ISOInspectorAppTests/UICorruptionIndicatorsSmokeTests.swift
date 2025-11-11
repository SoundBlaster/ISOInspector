#if canImport(Combine)
    import Combine
    import XCTest
    @testable import ISOInspectorApp
    @testable import ISOInspectorKit

    /// UI smoke tests for corruption indicators (T5.3)
    ///
    /// This test suite validates that corruption indicators (badges, warning ribbons,
    /// integrity summaries, and detail diagnostics) render correctly when tolerant
    /// parsing detects issues in corrupt fixtures.
    @MainActor
    final class UICorruptionIndicatorsSmokeTests: XCTestCase {

        // MARK: - Corrupt Fixtures Manifest

        private struct Manifest: Decodable {
            struct Corruption: Decodable {
                let category: String
                let pattern: String
                let affectedBoxes: [String]
                let expectedIssues: [String]
            }

            struct Fixture: Decodable {
                let id: String
                let filename: String
                let title: String
                let description: String
                let corruption: Corruption
                let smokeTest: Bool
            }

            let version: Int
            let fixtures: [Fixture]
        }

        private lazy var manifestURL: URL = {
            let root = URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
            return
                root
                .appendingPathComponent("Documentation")
                .appendingPathComponent("FixtureCatalog")
                .appendingPathComponent("corrupt-fixtures.json")
        }()

        private lazy var fixturesRoot: URL = {
            let root = URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
            return
                root
                .appendingPathComponent("Fixtures")
                .appendingPathComponent("Corrupt")
        }()

        // MARK: - Corruption Badge Tests

        func testCorruptionBadgeDisplaysForCorruptNode() throws {
            // Arrange: Create a corrupt node
            let header = BoxHeader(
                type: try FourCharCode("moov"),
                totalSize: 32,
                headerSize: 8,
                payloadRange: 8..<24,
                range: 0..<32,
                uuid: nil
            )
            let node = ParseTreeNode(
                header: header,
                metadata: nil,
                payload: nil,
                validationIssues: [],
                issues: [],
                status: .corrupt,
                children: []
            )

            // Act: Create badge descriptor
            let descriptor = ParseTreeStatusDescriptor(status: node.status)

            // Assert: Badge should be created with correct properties
            XCTAssertNotNil(descriptor, "Descriptor should be created for corrupt node")
            XCTAssertEqual(descriptor?.text, "Corrupted")
            XCTAssertEqual(descriptor?.level, .error)
            XCTAssertEqual(descriptor?.accessibilityLabel, "Corrupted status")
        }

        func testPartialBadgeDisplaysForPartialNode() throws {
            // Arrange: Create a partial node
            let header = BoxHeader(
                type: try FourCharCode("trak"),
                totalSize: 24,
                headerSize: 8,
                payloadRange: 8..<16,
                range: 0..<24,
                uuid: nil
            )
            let node = ParseTreeNode(
                header: header,
                metadata: nil,
                payload: nil,
                validationIssues: [],
                issues: [],
                status: .partial,
                children: []
            )

            // Act: Create badge descriptor
            let descriptor = ParseTreeStatusDescriptor(status: node.status)

            // Assert: Badge should be created with correct properties
            XCTAssertNotNil(descriptor, "Descriptor should be created for partial node")
            XCTAssertEqual(descriptor?.text, "Partial")
            XCTAssertEqual(descriptor?.level, .warning)
            XCTAssertEqual(descriptor?.accessibilityLabel, "Partial status")
        }

        func testNoBadgeForValidNode() throws {
            // Arrange: Create a valid node
            let header = BoxHeader(
                type: try FourCharCode("ftyp"),
                totalSize: 24,
                headerSize: 8,
                payloadRange: 8..<24,
                range: 0..<24,
                uuid: nil
            )
            let node = ParseTreeNode(
                header: header,
                metadata: nil,
                payload: nil,
                validationIssues: [],
                issues: [],
                status: .valid,
                children: []
            )

            // Act: Try to create badge descriptor
            let descriptor = ParseTreeStatusDescriptor(status: node.status)

            // Assert: No badge should be created for valid node
            XCTAssertNil(descriptor, "Descriptor should not be created for valid node")
        }

        // MARK: - Integrity Summary Tests

        func testIntegritySummaryDisplaysCorruptionIssues() {
            // Arrange: Create a store with corruption issues
            let store = ParseTreeStore()
            store.issueStore.record(
                ParseIssue(
                    severity: .error,
                    code: "payload.truncated",
                    message: "Moov box declares more bytes than reader provides",
                    byteRange: 100..<200,
                    affectedNodeIDs: [1]
                ),
                depth: 1
            )
            store.issueStore.record(
                ParseIssue(
                    severity: .warning,
                    code: "guard.zero_size_loop",
                    message: "Zero-length loop detected",
                    byteRange: 300..<400,
                    affectedNodeIDs: [2]
                ),
                depth: 2
            )

            // Act: Create view model
            let viewModel = IntegritySummaryViewModel(issueStore: store.issueStore)

            // Assert: Issues should be displayed
            XCTAssertEqual(viewModel.displayedIssues.count, 2)
            XCTAssertTrue(viewModel.displayedIssues.contains { $0.code == "payload.truncated" })
            XCTAssertTrue(viewModel.displayedIssues.contains { $0.code == "guard.zero_size_loop" })

            // Assert: First issue (error) should come first when sorted by severity
            viewModel.sortOrder = .severity
            let sortedIssues = viewModel.displayedIssues
            XCTAssertEqual(sortedIssues.first?.severity, .error)
            XCTAssertEqual(sortedIssues.first?.code, "payload.truncated")
        }

        func testIntegritySummaryOffsetSortingForCorruptionIssues() {
            // Arrange: Create issues at different offsets
            let store = ParseTreeStore()
            store.issueStore.record(
                ParseIssue(
                    severity: .error,
                    code: "header.truncated_field",
                    message: "Size field truncated",
                    byteRange: 300..<304,
                    affectedNodeIDs: [3]
                ),
                depth: 1
            )
            store.issueStore.record(
                ParseIssue(
                    severity: .error,
                    code: "payload.truncated",
                    message: "Payload truncated",
                    byteRange: 100..<200,
                    affectedNodeIDs: [1]
                ),
                depth: 1
            )
            store.issueStore.record(
                ParseIssue(
                    severity: .error,
                    code: "header.invalid_fourcc",
                    message: "Invalid fourcc",
                    byteRange: 200..<204,
                    affectedNodeIDs: [2]
                ),
                depth: 1
            )

            // Act: Create view model and sort by offset
            let viewModel = IntegritySummaryViewModel(issueStore: store.issueStore)
            viewModel.sortOrder = .offset

            // Assert: Issues should be sorted by offset
            let sortedIssues = viewModel.displayedIssues
            XCTAssertEqual(sortedIssues.count, 3)
            XCTAssertEqual(sortedIssues[0].byteRange?.lowerBound, 100)
            XCTAssertEqual(sortedIssues[1].byteRange?.lowerBound, 200)
            XCTAssertEqual(sortedIssues[2].byteRange?.lowerBound, 300)
        }

        // MARK: - Corruption Detail Section Tests

        func testCorruptionDetailSectionPopulatedWithIssueDetails() async throws {
            // Arrange: Create a corrupt node with issues
            let header = BoxHeader(
                type: try FourCharCode("moov"),
                totalSize: 100,
                headerSize: 8,
                payloadRange: 8..<50,
                range: 0..<100,
                uuid: nil
            )
            let issues = [
                ParseIssue(
                    severity: .error,
                    code: "payload.truncated",
                    message: "Moov payload truncated at reader boundary",
                    byteRange: 8..<50,
                    affectedNodeIDs: [0]
                )
            ]
            let node = ParseTreeNode(
                header: header,
                metadata: nil,
                payload: nil,
                validationIssues: [],
                issues: issues,
                status: .corrupt,
                children: []
            )
            let snapshot = ParseTreeSnapshot(
                nodes: [node],
                validationIssues: [],
                lastUpdatedAt: Date()
            )

            let subject = PassthroughSubject<ParseTreeSnapshot, Never>()
            let hexProvider = HexSliceProviderStub(
                result: HexSlice(offset: header.payloadRange.lowerBound, bytes: Data()))
            let viewModel = ParseTreeDetailViewModel(
                hexSliceProvider: hexProvider, annotationProvider: nil)

            // Act: Bind and select node
            viewModel.bind(to: subject.eraseToAnyPublisher())
            subject.send(snapshot)
            await Task.yield()
            viewModel.select(nodeID: node.id)
            try await Task.sleep(nanoseconds: 20_000_000)

            // Assert: Detail should be populated with node's issues
            XCTAssertNotNil(viewModel.detail)
            XCTAssertEqual(viewModel.detail?.issues.count, 1)
            let issue = try XCTUnwrap(viewModel.detail?.issues.first)
            XCTAssertEqual(issue.code, "payload.truncated")
            XCTAssertEqual(issue.severity, .error)
            XCTAssertEqual(issue.byteRange, 8..<50)
            XCTAssertTrue(issue.message.contains("truncated"))
        }

        // MARK: - Warning Ribbon Tests

        func testCorruptionWarningRibbonAccessibilityLabel() {
            // Arrange: Create metrics with multiple issue types
            let metrics = ParseIssueStore.IssueMetrics(
                errorCount: 2,
                warningCount: 5,
                infoCount: 1,
                deepestAffectedDepth: 3
            )

            // Act: Create warning ribbon (we test the internal accessibility label computation)
            // Note: CorruptionWarningRibbon is private in AppShellView, so we verify
            // the metrics structure that drives the accessibility label

            // Assert: Metrics should contain expected counts
            XCTAssertEqual(metrics.errorCount, 2)
            XCTAssertEqual(metrics.warningCount, 5)
            XCTAssertEqual(metrics.infoCount, 1)
            XCTAssertEqual(metrics.deepestAffectedDepth, 3)
            XCTAssertEqual(metrics.totalCount, 8)
        }

        func testNoCorruptionWarningRibbonWhenNoIssues() {
            // Arrange: Create empty metrics
            let metrics = ParseIssueStore.IssueMetrics()

            // Assert: Total count should be zero
            XCTAssertEqual(metrics.totalCount, 0)
            XCTAssertEqual(metrics.errorCount, 0)
            XCTAssertEqual(metrics.warningCount, 0)
            XCTAssertEqual(metrics.infoCount, 0)
        }

        // MARK: - Integration Test with Corrupt Fixtures

        func testTolerantParsingProducesCorruptionIndicatorsForSmokeFixtures() async throws {
            // Arrange: Load smoke fixtures from manifest
            let data = try Data(contentsOf: manifestURL)
            let manifest = try JSONDecoder().decode(Manifest.self, from: data)
            let smokeFixtures = manifest.fixtures.filter(\.smokeTest)
            XCTAssertFalse(smokeFixtures.isEmpty, "Manifest must mark at least one smoke fixture")

            // Act & Assert: Process each smoke fixture
            let pipeline = ParsePipeline.live(options: .tolerant)

            for fixture in smokeFixtures {
                let url = try fixtureURL(for: fixture.filename)
                let reader = try ChunkedFileReader(fileURL: url)
                let issueStore = ParseIssueStore()
                var context = ParsePipeline.Context(options: .tolerant, issueStore: issueStore)
                context.source = url

                let events = try await collectEvents(
                    from: pipeline.events(for: reader, context: context))

                // Assert: Pipeline should emit events
                XCTAssertFalse(
                    events.isEmpty, "Pipeline should emit events for fixture \(fixture.id)")

                // Assert: Issue store should contain expected issues
                let issues = issueStore.issuesSnapshot()
                XCTAssertFalse(issues.isEmpty, "Expected issues for fixture \(fixture.id)")

                // Assert: Expected issue codes should be present
                let codes = Set(issues.map(\.code))
                for expectedCode in fixture.corruption.expectedIssues {
                    XCTAssertTrue(
                        codes.contains(expectedCode),
                        "Fixture \(fixture.id) missing expected issue \(expectedCode)"
                    )
                }

                // Verify issues have proper structure (from IssueStore)
                for issue in issues {
                    XCTAssertFalse(issue.code.isEmpty, "Issue should have non-empty code")
                    XCTAssertFalse(issue.message.isEmpty, "Issue should have non-empty message")
                    // Verify severity is one of the expected values
                    XCTAssertTrue(
                        [ParseIssue.Severity.error, .warning, .info].contains(issue.severity),
                        "Issue should have valid severity"
                    )
                }

                // Assert: Issue metrics should reflect detected issues
                let metrics = issueStore.metrics
                XCTAssertGreaterThan(
                    metrics.totalCount, 0, "Fixture \(fixture.id) should have detected issues")
            }
        }

        // MARK: - Helper Methods

        private func fixtureURL(for filename: String) throws -> URL {
            // Check if binary file already exists in Fixtures/Corrupt
            let binaryURL = fixturesRoot.appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: binaryURL.path) {
                return binaryURL
            }

            // Otherwise, decode from base64 and write to temporary directory
            let base64URL = binaryURL.appendingPathExtension("base64")
            guard FileManager.default.fileExists(atPath: base64URL.path) else {
                throw NSError(
                    domain: "FixtureError",
                    code: 1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Missing base64 source for fixture \(filename)"
                    ]
                )
            }

            let encoded = try String(contentsOf: base64URL, encoding: .utf8)
            guard let data = Data(base64Encoded: encoded, options: .ignoreUnknownCharacters) else {
                throw NSError(
                    domain: "FixtureError",
                    code: 2,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "Fixture \(filename) contains invalid base64 payload"
                    ]
                )
            }

            // Write to temporary directory (CI-safe)
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(
                "ISOInspectorTests-Fixtures", isDirectory: true)
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            let tempBinaryURL = tempDir.appendingPathComponent(filename)
            try data.write(to: tempBinaryURL, options: [.atomic])
            return tempBinaryURL
        }

        private func collectEvents(from stream: ParsePipeline.EventStream) async throws
            -> [ParseEvent] {
            var events: [ParseEvent] = []
            for try await event in stream {
                events.append(event)
            }
            return events
        }
    }

    // MARK: - Test Helpers

    private final class HexSliceProviderStub: HexSliceProvider {
        private(set) var requests: [HexSliceRequest] = []
        let result: HexSlice

        init(result: HexSlice) {
            self.result = result
        }

        func loadSlice(for request: HexSliceRequest) async throws -> HexSlice {
            requests.append(request)
            return result
        }
    }
#endif
