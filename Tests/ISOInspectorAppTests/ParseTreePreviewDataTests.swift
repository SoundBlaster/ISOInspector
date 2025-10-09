#if canImport(Combine)
import XCTest
@testable import ISOInspectorApp
import ISOInspectorKit

final class ParseTreePreviewDataTests: XCTestCase {
    func testSampleSnapshotProvidesBoxHeaders() throws {
        let snapshot = ParseTreePreviewData.sampleSnapshot
        let headers = snapshot.nodes.map(\.header)
        XCTAssertEqual(headers.count, 4)
        XCTAssertEqual(headers.first?.type, try FourCharCode("ftyp"))
    }
}
#endif
