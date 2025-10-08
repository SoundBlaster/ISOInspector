import XCTest
@testable import ISOInspectorKit

final class ResearchLogPreviewProviderTests: XCTestCase {
    func testValidPreviewFixtureProducesAudit() throws {
        let snapshot = ResearchLogPreviewProvider.validFixture()

        switch snapshot.state {
        case let .ready(audit):
            XCTAssertEqual(audit.schemaVersion, ResearchLogSchema.version)
            XCTAssertEqual(audit.fieldNames, ResearchLogSchema.fieldNames)
            XCTAssertEqual(audit.entryCount, 2)
            XCTAssertTrue(audit.logExists)
            XCTAssertTrue(snapshot.diagnostics.contains(where: { $0.contains("VR-006") }))
        default:
            XCTFail("Expected ready snapshot, received \(snapshot.state)")
        }
    }

    func testMissingPreviewFixtureFlagsMissingLog() {
        let snapshot = ResearchLogPreviewProvider.missingFixture()

        switch snapshot.state {
        case let .missingFixture(audit):
            XCTAssertFalse(audit.logExists)
            XCTAssertTrue(snapshot.diagnostics.contains(where: { $0.lowercased().contains("missing") }))
        default:
            XCTFail("Expected missing fixture snapshot, received \(snapshot.state)")
        }
    }

    func testSchemaMismatchFixtureSurfacesFieldDifferences() {
        let snapshot = ResearchLogPreviewProvider.schemaMismatchFixture()

        switch snapshot.state {
        case let .schemaMismatch(expected, actual):
            XCTAssertEqual(expected, ResearchLogSchema.fieldNames.sorted())
            XCTAssertTrue(actual.contains("type"))
            XCTAssertTrue(snapshot.diagnostics.contains(where: { $0.lowercased().contains("schema mismatch") }))
        default:
            XCTFail("Expected schema mismatch snapshot, received \(snapshot.state)")
        }
    }
}
