#if canImport(Combine)
    import Combine
    import Foundation
    import XCTest
    @testable import ISOInspectorApp
    @testable import ISOInspectorKit

    @MainActor
    final class DocumentViewModelTests: XCTestCase {
        func testInitializationSetsSelectionAndExports() throws {
            let (snapshot, expectedFirstID) = try Self.makeSampleSnapshot()
            let store = ParseTreeStore(initialSnapshot: snapshot, initialState: .finished)
            let annotations = AnnotationBookmarkSession(store: nil)

            let viewModel = DocumentViewModel(store: store, annotations: annotations)

            XCTAssertEqual(viewModel.snapshot, snapshot)
            XCTAssertEqual(viewModel.nodeViewModel.selectedNodeID, expectedFirstID)
            XCTAssertTrue(viewModel.exportAvailability.canExportDocument)
            XCTAssertTrue(viewModel.exportAvailability.canExportSelection)
            XCTAssertEqual(viewModel.validationSummary.errorCount, 1)
            XCTAssertEqual(viewModel.validationSummary.warningCount, 1)
            XCTAssertEqual(viewModel.validationSummary.infoCount, 0)
            XCTAssertEqual(viewModel.hexViewModel.highlightedRange, 0..<4)
        }

        func testSnapshotClearingResetsSelectionAndExportAvailability() throws {
            let (snapshot, _) = try Self.makeSampleSnapshot()
            let store = ParseTreeStore(initialSnapshot: snapshot, initialState: .finished)
            let annotations = AnnotationBookmarkSession(store: nil)
            let viewModel = DocumentViewModel(store: store, annotations: annotations)

            store.shutdown()
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))

            XCTAssertEqual(viewModel.snapshot, .empty)
            XCTAssertNil(viewModel.nodeViewModel.selectedNodeID)
            XCTAssertFalse(viewModel.exportAvailability.canExportDocument)
            XCTAssertFalse(viewModel.exportAvailability.canExportSelection)
        }

        func testFilterUpdateKeepsSelectionVisible() throws {
            let (snapshot, _) = try Self.makeSampleSnapshot(secondSeverity: .warning)
            let store = ParseTreeStore(initialSnapshot: snapshot, initialState: .finished)
            let annotations = AnnotationBookmarkSession(store: nil)
            let viewModel = DocumentViewModel(store: store, annotations: annotations)

            viewModel.outlineViewModel.filter = ParseTreeOutlineFilter(
                focusedSeverities: [.warning]
            )
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))

            let expectedID = snapshot.nodes.last?.id
            XCTAssertEqual(viewModel.nodeViewModel.selectedNodeID, expectedID)
            XCTAssertTrue(viewModel.exportAvailability.canExportSelection)
        }

        private static func makeSampleSnapshot(
            secondSeverity: ValidationIssue.Severity = .warning
        ) throws -> (ParseTreeSnapshot, ParseTreeNode.ID) {
            let headerA = try makeHeader(offset: 0, type: "ftyp")
            let headerB = try makeHeader(offset: 32, type: "moov")
            let payload = ParsedBoxPayload(
                fields: [
                    ParsedBoxPayload.Field(
                        name: "major_brand",
                        value: "isom",
                        description: nil,
                        byteRange: 0..<4
                    )
                ]
            )
            let issueA = ValidationIssue(ruleID: "VR-001", message: "Root", severity: .error)
            let issueB = ValidationIssue(
                ruleID: "VR-002", message: "Child", severity: secondSeverity)
            let child = ParseTreeNode(header: headerB, validationIssues: [issueB])
            let root = ParseTreeNode(
                header: headerA,
                payload: payload,
                validationIssues: [issueA],
                children: [child]
            )
            let snapshot = ParseTreeSnapshot(
                nodes: [root, child],
                validationIssues: [issueA, issueB],
                lastUpdatedAt: Date()
            )
            return (snapshot, root.id)
        }

        private static func makeHeader(offset: Int64, type: String) throws -> BoxHeader {
            let fourcc = try IIFourCharCode(type)
            return BoxHeader(
                type: fourcc,
                totalSize: 48,
                headerSize: 8,
                payloadRange: offset + 8..<offset + 16,
                range: offset..<offset + 48,
                uuid: nil
            )
        }
    }
#endif
