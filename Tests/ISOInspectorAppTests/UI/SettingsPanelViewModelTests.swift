#if canImport(SwiftUI) && canImport(Combine)
import Combine
import Foundation
import XCTest
@testable import ISOInspectorApp
@testable import ISOInspectorKit

@MainActor
final class SettingsPanelViewModelTests: XCTestCase {
    var mockStore: MockUserPreferencesStore!
    var sut: SettingsPanelViewModel!

    override func setUp() {
        super.setUp()
        mockStore = MockUserPreferencesStore()
        sut = SettingsPanelViewModel(preferencesStore: mockStore)
    }

    override func tearDown() {
        sut = nil
        mockStore = nil
        super.tearDown()
    }

    func testInitializationSetsDefaultState() {
        XCTAssertEqual(sut.activeSection, .permanent)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func testLoadPermanentSettingsUpdatesState() async {
        await sut.loadSettings()

        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.permanentSettings)
        XCTAssertEqual(sut.permanentSettings, .default)
    }

    func testLoadPermanentSettings_LoadsFromStore() async {
        let customPreferences = UserPreferences(
            validationPresetID: "strict",
            loggingVerbosity: 3
        )
        mockStore.storedPreferences = customPreferences

        await sut.loadSettings()

        XCTAssertEqual(sut.permanentSettings, customPreferences)
    }

    func testActiveSectionCanBeChanged() {
        sut.setActiveSection(.session)

        XCTAssertEqual(sut.activeSection, .session)
    }

    func testResetPermanentSettings_CallsStoreReset() async {
        await sut.loadSettings()

        await sut.resetPermanentSettings()

        XCTAssertTrue(mockStore.resetCalled)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.permanentSettings, .default)
    }

    func testUpdatePermanentSettings_SavesToStore() async {
        let updatedPreferences = UserPreferences(
            validationPresetID: "lenient",
            telemetryVerbosity: 1
        )

        await sut.updatePermanentSettings(updatedPreferences)

        XCTAssertEqual(mockStore.storedPreferences, updatedPreferences)
        XCTAssertEqual(sut.permanentSettings, updatedPreferences)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func testUpdatePermanentSettings_OnError_RevertsState() async {
        mockStore.shouldThrowOnSave = true
        let originalPreferences = UserPreferences()
        mockStore.storedPreferences = originalPreferences
        await sut.loadSettings()

        let failedUpdate = UserPreferences(validationPresetID: "strict")
        await sut.updatePermanentSettings(failedUpdate)

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertEqual(sut.permanentSettings, originalPreferences)
    }

    // MARK: - Session Settings Tests

    func testLoadSettings_WithoutSessionController_LoadsDefaultSessionSettings() async {
        await sut.loadSettings()

        XCTAssertNotNil(sut.sessionSettings)
        XCTAssertFalse(sut.hasSessionOverrides)
    }

    func testResetSessionSettings_WithoutSessionController_DoesNotCrash() async {
        await sut.resetSessionSettings()

        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    // @todo #222 Add tests with mock DocumentSessionController for session settings integration
    // @todo #222 Test selectValidationPreset with both .global and .workspace scopes
    // @todo #222 Test setValidationRule with both scopes
    // @todo #222 Test hasSessionOverrides badge indicator when workspace differs from global
}


// MARK: - Mock Store

final class MockUserPreferencesStore: UserPreferencesPersisting {
    var storedPreferences: UserPreferences?
    var resetCalled = false
    var shouldThrowOnSave = false
    var shouldThrowOnLoad = false

    func loadPreferences() throws -> UserPreferences? {
        if shouldThrowOnLoad {
            throw NSError(domain: "TestError", code: 1, userInfo: nil)
        }
        return storedPreferences
    }

    func savePreferences(_ preferences: UserPreferences) throws {
        if shouldThrowOnSave {
            throw NSError(domain: "TestError", code: 2, userInfo: nil)
        }
        storedPreferences = preferences
    }

    func reset() throws {
        resetCalled = true
        storedPreferences = nil
    }
}
#endif
