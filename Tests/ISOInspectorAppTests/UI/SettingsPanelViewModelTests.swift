#if canImport(SwiftUI) && canImport(Combine)
import Combine
import Foundation
import XCTest
@testable import ISOInspectorApp
@testable import ISOInspectorKit

@MainActor
final class SettingsPanelViewModelTests: XCTestCase {
    func testInitializationSetsDefaultState() {
        let viewModel = SettingsPanelViewModel()

        XCTAssertEqual(viewModel.activeSection, .permanent)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadPermanentSettingsUpdatesState() async {
        let viewModel = SettingsPanelViewModel()

        await viewModel.loadSettings()

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.permanentSettings)
    }

    func testActiveSectionCanBeChanged() {
        let viewModel = SettingsPanelViewModel()

        viewModel.setActiveSection(.session)

        XCTAssertEqual(viewModel.activeSection, .session)
    }

    func testResetPermanentSettingsClearsChanges() async {
        let viewModel = SettingsPanelViewModel()
        await viewModel.loadSettings()

        await viewModel.resetPermanentSettings()

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
}
#endif
