#if canImport(XCTest)
    import XCTest
    @testable import ISOInspectorApp

    final class InspectorDisplayModeTests: XCTestCase {
        func testDefaultsToSelectionDetails() {
            let mode = InspectorDisplayMode()

            XCTAssertEqual(mode.current, .selectionDetails)
            XCTAssertFalse(mode.isShowingIntegritySummary)
            XCTAssertEqual(mode.toggleButtonLabel, "Show Integrity")
        }

        func testToggleSwitchesModes() {
            var mode = InspectorDisplayMode()

            mode.toggle()

            XCTAssertTrue(mode.isShowingIntegritySummary)
            XCTAssertEqual(mode.current, .integritySummary)
            XCTAssertEqual(mode.toggleButtonLabel, "Show Details")
        }
    }
#endif
