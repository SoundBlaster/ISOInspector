import XCTest
@testable import ISOInspectorKit

final class ISOInspectorKitScaffoldTests: XCTestCase {
    func testProjectNameIsStable() throws {
        XCTAssertEqual(ISOInspectorKit.projectName, "ISOInspector")
    }

    func testWelcomeMessageListsFocusAreas() throws {
        let message = ISOInspectorKit.welcomeMessage()
        for focus in ISOInspectorKit.initialFocusAreas {
            XCTAssertTrue(message.contains(focus))
        }
    }
}
