#if canImport(SwiftUI) && canImport(Combine)
import XCTest
import SwiftUI
@testable import ISOInspectorApp

@MainActor
final class SettingsPanelAccessibilityTests: XCTestCase {
    var viewModel: SettingsPanelViewModel!
    var mockStore: MockUserPreferencesStore!

    override func setUp() async throws {
        mockStore = MockUserPreferencesStore()
        viewModel = SettingsPanelViewModel(preferencesStore: mockStore)
    }

    override func tearDown() async throws {
        viewModel = nil
        mockStore = nil
    }

    // MARK: - Accessibility Identifier Tests

    func testSidebarSections_haveAccessibilityIdentifiers() {
        // Given: common panel sections
        let sectionIDs = ["permanent", "session", "advanced"]

        // When: checking accessibility IDs
        // Then: each section should have a unique ID
        for sectionID in sectionIDs {
            let id = SettingsPanelA11yID.sidebar.section(sectionID)
            XCTAssertFalse(id.isEmpty, "Section \(sectionID) should have accessibility ID")
            XCTAssertTrue(id.contains(sectionID), "ID should contain section identifier")
        }
    }

    func testSidebarConveniences_matchExpectedValues() {
        // Given: convenience constants
        // When: comparing to function-generated IDs
        // Then: they should match
        XCTAssertEqual(
            SettingsPanelA11yID.sidebar.permanentSection,
            SettingsPanelA11yID.sidebar.section("permanent")
        )
        XCTAssertEqual(
            SettingsPanelA11yID.sidebar.sessionSection,
            SettingsPanelA11yID.sidebar.section("session")
        )
        XCTAssertEqual(
            SettingsPanelA11yID.sidebar.advancedSection,
            SettingsPanelA11yID.sidebar.section("advanced")
        )
    }

    func testPermanentSettings_haveAccessibilityIdentifiers() {
        // Given: permanent settings card
        // When: checking accessibility IDs
        // Then: all interactive elements should have IDs
        XCTAssertFalse(SettingsPanelA11yID.permanentSettings.card.isEmpty)
        XCTAssertFalse(SettingsPanelA11yID.permanentSettings.title.isEmpty)
        XCTAssertFalse(SettingsPanelA11yID.permanentSettings.description.isEmpty)
        XCTAssertFalse(SettingsPanelA11yID.permanentSettings.resetButton.isEmpty)
    }

    func testSessionSettings_haveAccessibilityIdentifiers() {
        // Given: session settings card
        // When: checking accessibility IDs
        // Then: all interactive elements should have IDs
        XCTAssertFalse(SettingsPanelA11yID.sessionSettings.card.isEmpty)
        XCTAssertFalse(SettingsPanelA11yID.sessionSettings.title.isEmpty)
        XCTAssertFalse(SettingsPanelA11yID.sessionSettings.description.isEmpty)
        XCTAssertFalse(SettingsPanelA11yID.sessionSettings.resetButton.isEmpty)
    }

    func testAdvancedSettings_haveAccessibilityIdentifiers() {
        // Given: advanced settings card
        // When: checking accessibility IDs
        // Then: all interactive elements should have IDs
        XCTAssertFalse(SettingsPanelA11yID.advancedSettings.card.isEmpty)
        XCTAssertFalse(SettingsPanelA11yID.advancedSettings.title.isEmpty)
        XCTAssertFalse(SettingsPanelA11yID.advancedSettings.description.isEmpty)
    }

    // MARK: - VoiceOver Label Tests

    func testSectionIdentifiers_areNotEmpty() {
        // Given: section identifiers
        // When: checking string values
        // Then: all identifiers should be non-empty
        XCTAssertFalse(SettingsPanelA11yID.sidebar.permanentSection.isEmpty)
        XCTAssertFalse(SettingsPanelA11yID.sidebar.sessionSection.isEmpty)
        XCTAssertFalse(SettingsPanelA11yID.sidebar.advancedSection.isEmpty)
    }

    // MARK: - Accessibility Hierarchy Tests

    func testAccessibilityIdentifiers_followNamingConvention() {
        // Given: all accessibility IDs
        // When: checking naming structure
        // Then: IDs should follow hierarchical dot notation
        XCTAssertTrue(SettingsPanelA11yID.permanentSettings.card.hasPrefix(SettingsPanelA11yID.root))
        XCTAssertTrue(SettingsPanelA11yID.sessionSettings.card.hasPrefix(SettingsPanelA11yID.root))
        XCTAssertTrue(SettingsPanelA11yID.advancedSettings.card.hasPrefix(SettingsPanelA11yID.root))
    }

    // @todo #222 Add VoiceOver focus order tests
    // @todo #222 Add keyboard navigation tests (⌘, shortcut)
    // @todo #222 Add Dynamic Type scaling tests
    // @todo #222 Add Reduce Motion compliance tests
}
#endif
