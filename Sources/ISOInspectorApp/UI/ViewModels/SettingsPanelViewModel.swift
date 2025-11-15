#if canImport(SwiftUI) && canImport(Combine)
import Combine
import Foundation
import ISOInspectorKit
import OSLog

@MainActor
final class SettingsPanelViewModel: ObservableObject {
    enum Section {
        case permanent
        case session
        case advanced
    }

    @Published private(set) var activeSection: Section = .permanent
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var permanentSettings: PermanentSettings?
    @Published private(set) var sessionSettings: SessionSettings?

    private let logger = Logger(subsystem: "ISOInspectorApp", category: "SettingsPanel")

    init() {
        logger.debug("SettingsPanelViewModel initialized")
    }

    func loadSettings() async {
        isLoading = true
        errorMessage = nil

        // @todo #222 Load actual permanent settings from UserPreferencesStore
        // @todo #222 Load actual session settings from DocumentSessionController
        permanentSettings = PermanentSettings()

        isLoading = false
        logger.debug("Settings loaded successfully")
    }

    func setActiveSection(_ section: Section) {
        activeSection = section
        logger.debug("Active section changed to: \(String(describing: section))")
    }

    func resetPermanentSettings() async {
        isLoading = true
        errorMessage = nil

        // @todo #222 Call UserPreferencesStore.reset() to clear permanent settings
        // @todo #222 Reload permanent settings after reset
        permanentSettings = PermanentSettings()

        isLoading = false
        logger.debug("Permanent settings reset completed")
    }

    // @todo #222 Add resetSessionSettings() method
    // @todo #222 Add updatePermanentSetting(key:value:) method
    // @todo #222 Add updateSessionSetting(key:value:) method
}

// MARK: - Supporting Types

struct PermanentSettings {
    // @todo #222 Add validation configuration properties
    // @todo #222 Add telemetry/logging verbosity properties
    // @todo #222 Add accessibility preferences

    init() {
        // Minimal stub for now
    }
}

struct SessionSettings {
    // @todo #222 Add workspace scope properties
    // @todo #222 Add pane layout properties
    // @todo #222 Add temporary validation overrides

    init() {
        // Minimal stub for now
    }
}
#endif
