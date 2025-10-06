import XCTest
@testable import ISOInspectorKit

final class BoxCatalogTests: XCTestCase {
    func testLookupReturnsDescriptorForKnownFourCharCode() throws {
        let catalog = try BoxCatalog.loadBundledCatalog()
        let header = try makeHeader(type: "ftyp")

        let descriptor = catalog.descriptor(for: header)

        XCTAssertEqual(descriptor?.name, "File Type Box")
        XCTAssertTrue(descriptor?.summary.contains("compatibility") ?? false)
    }

    func testLookupReturnsDescriptorForExtendedType() throws {
        let catalog = try BoxCatalog.loadBundledCatalog()
        let header = try makeHeader(type: "uuid", uuid: UUID(uuidString: "D4807EF2-CA39-4695-8E54-26CB9E46A79F"))

        let descriptor = catalog.descriptor(for: header)

        XCTAssertEqual(descriptor?.name, "KLV Sample Entry")
        XCTAssertEqual(descriptor?.identifier.extendedType, UUID(uuidString: "D4807EF2-CA39-4695-8E54-26CB9E46A79F"))
    }

    func testLookupReturnsNilForUnknownBox() throws {
        let catalog = try BoxCatalog.loadBundledCatalog()
        let header = try makeHeader(type: "zzzz")

        XCTAssertNil(catalog.descriptor(for: header))
    }

    private func makeHeader(type: String, uuid: UUID? = nil) throws -> BoxHeader {
        let code = try FourCharCode(type)
        return BoxHeader(
            type: code,
            totalSize: 32,
            headerSize: uuid == nil ? 8 : 24,
            payloadRange: 8..<32,
            range: 0..<32,
            uuid: uuid
        )
    }
}
