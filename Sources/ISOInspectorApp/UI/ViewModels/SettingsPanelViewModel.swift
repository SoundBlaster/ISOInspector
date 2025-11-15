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
    @Published private(set) var permanentSettings: UserPreferences?
    @Published private(set) var sessionSettings: SessionSettings?

    private let preferencesStore: UserPreferencesPersisting
    private let logger = Logger(subsystem: "ISOInspectorApp", category: "SettingsPanel")

    init(preferencesStore: UserPreferencesPersisting) {
        self.preferencesStore = preferencesStore
        logger.debug("SettingsPanelViewModel initialized")
    }

    func loadSettings() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load permanent settings from UserPreferencesStore
            permanentSettings = try preferencesStore.loadPreferences() ?? .default
            logger.debug("Permanent settings loaded successfully")

            // @todo #222 Load actual session settings from DocumentSessionController
            sessionSettings = SessionSettings()
        } catch {
            errorMessage = "Failed to load settings: \(error.localizedDescription)"
            logger.error("Failed to load settings: \(error.localizedDescription)")
            // @todo #222 Emit diagnostic event via E6 diagnostics logging
        }

        isLoading = false
    }

    func setActiveSection(_ section: Section) {
        activeSection = section
        logger.debug("Active section changed to: \(String(describing: section))")
    }

    func resetPermanentSettings() async {
        isLoading = true
        errorMessage = nil

        do {
            // Reset permanent settings to defaults
            try preferencesStore.reset()
            permanentSettings = .default
            logger.debug("Permanent settings reset completed")
        } catch {
            errorMessage = "Failed to reset settings: \(error.localizedDescription)"
            logger.error("Failed to reset settings: \(error.localizedDescription)")
            // @todo #222 Emit diagnostic event via E6 diagnostics logging
        }

        isLoading = false
    }

    func updatePermanentSettings(_ updatedSettings: UserPreferences) async {
        isLoading = true
        errorMessage = nil

        do {
            // Optimistic write - update UI immediately
            permanentSettings = updatedSettings

            // Persist to disk
            try preferencesStore.savePreferences(updatedSettings)
            logger.debug("Permanent settings saved successfully")
        } catch {
            errorMessage = "Failed to save settings: \(error.localizedDescription)"
            logger.error("Failed to save settings: \(error.localizedDescription)")
            // @todo #222 Emit diagnostic event via E6 diagnostics logging

            // Revert UI state on failure
            permanentSettings = try? preferencesStore.loadPreferences() ?? .default
        }

        isLoading = false
    }

    // @todo #222 Add resetSessionSettings() method
    // @todo #222 Add updateSessionSetting(key:value:) method
}

// MARK: - Supporting Types

struct SessionSettings {
    // @todo #222 Add workspace scope properties
    // @todo #222 Add pane layout properties
    // @todo #222 Add temporary validation overrides

    init() {
        // Minimal stub for now
    }
}
#endif
