import XCTest

@testable import ISOInspectorKit

final class FourCharContainerCodeTests: XCTestCase {
    func testAllCasesMatchExpectedRawValues() {
        let expected: Set<String> = [
            "moov", "trak", "mdia", "minf", "dinf", "stbl", "edts", "mvex", "moof", "traf", "mfra",
            "tref", "udta", "strk", "strd", "sinf", "schi", "stsd", "meta", "ilst",
        ]
        let actual = Set(FourCharContainerCode.allCases.map(\.rawValue))
        XCTAssertEqual(actual, expected)
    }

    func testInitializationFromFourCharCode() throws {
        for code in FourCharContainerCode.allCases {
            let fourCC = try FourCharCode(code.rawValue)
            XCTAssertEqual(FourCharContainerCode(fourCharCode: fourCC), code)
            XCTAssertEqual(code.fourCharCode, fourCC)
        }
    }

    func testInitializationFromUnknownFourCharCodeFails() throws {
        let invalid = try FourCharCode("free")
        XCTAssertNil(FourCharContainerCode(fourCharCode: invalid))
    }

    func testContainerLookupFromString() {
        XCTAssertTrue(FourCharContainerCode.isContainer("moov"))
        XCTAssertTrue(FourCharContainerCode.isContainer("trak"))
        XCTAssertFalse(FourCharContainerCode.isContainer(MediaAndIndexBoxCode.mediaData.rawValue))
    }

    func testContainerLookupFromFourCharCode() throws {
        XCTAssertTrue(FourCharContainerCode.isContainer(try FourCharCode("moov")))
        XCTAssertFalse(FourCharContainerCode.isContainer(try FourCharCode("ftyp")))
    }

    func testSetAccessorsExposeAllCases() {
        XCTAssertEqual(FourCharContainerCode.allCasesSet, Set(FourCharContainerCode.allCases))
        XCTAssertEqual(
            FourCharContainerCode.rawValueSet, Set(FourCharContainerCode.allCases.map(\.rawValue)))
    }
}
