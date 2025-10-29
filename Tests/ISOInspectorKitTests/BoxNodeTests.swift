import XCTest
@testable import ISOInspectorKit

final class BoxNodeTests: XCTestCase {
    func testInitializerCapturesAllComponents() throws {
        let header = try BoxHeader(
            type: IIFourCharCode("ftyp"),
            totalSize: 32,
            headerSize: 16,
            payloadRange: 16..<32,
            range: 0..<32,
            uuid: nil
        )
        let metadata = BoxDescriptor(
            identifier: .init(type: header.type, extendedType: nil),
            name: "File Type",
            summary: "File type and compatibility",
            category: "File",
            specification: "ISO",
            version: 1,
            flags: 0
        )
        let payload = ParsedBoxPayload(fields: [])
        let issues = [ValidationIssue(ruleID: "VR-001", message: "Test", severity: .warning)]
        let child = BoxNode(header: header)

        let node = BoxNode(
            header: header,
            metadata: metadata,
            payload: payload,
            validationIssues: issues,
            children: [child]
        )

        XCTAssertEqual(node.header, header)
        XCTAssertEqual(node.metadata, metadata)
        XCTAssertEqual(node.payload, payload)
        XCTAssertEqual(node.validationIssues, issues)
        XCTAssertEqual(node.children, [child])
    }
}
