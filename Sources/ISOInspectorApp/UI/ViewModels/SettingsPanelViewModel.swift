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
    @Published private(set) var hasSessionOverrides: Bool = false

    private let preferencesStore: UserPreferencesPersisting
    private weak var sessionController: DocumentSessionController?
    private let logger = Logger(subsystem: "ISOInspectorApp", category: "SettingsPanel")

    init(
      preferencesStore: UserPreferencesPersisting,
      sessionController: DocumentSessionController? = nil
    ) {
      self.preferencesStore = preferencesStore
      self.sessionController = sessionController
      logger.debug("SettingsPanelViewModel initialized")
    }

    func loadSettings() async {
      isLoading = true
      errorMessage = nil

      do {
        // Load permanent settings from UserPreferencesStore
        permanentSettings = try preferencesStore.loadPreferences() ?? .default
        logger.debug("Permanent settings loaded successfully")

        // Load session settings from DocumentSessionController
        if let sessionController = sessionController {
          sessionSettings = SessionSettings(
            validationConfiguration: sessionController.validationConfiguration,
            globalValidationConfiguration: sessionController.globalValidationConfiguration
          )
          hasSessionOverrides = sessionController.isUsingWorkspaceValidationOverride
          logger.debug("Session settings loaded successfully")
        } else {
          sessionSettings = SessionSettings()
          hasSessionOverrides = false
        }
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

    func resetSessionSettings() async {
      isLoading = true
      errorMessage = nil

      guard let sessionController = sessionController else {
        logger.warning("Cannot reset session settings: DocumentSessionController not available")
        isLoading = false
        return
      }

      sessionController.resetWorkspaceValidationOverrides()
      await loadSettings()  // Reload to refresh UI
      logger.debug("Session settings reset completed")

      isLoading = false
    }

    func selectValidationPreset(
      _ presetID: String,
      scope: DocumentSessionController.ValidationConfigurationScope
    ) {
      guard let sessionController = sessionController else {
        logger.warning("Cannot update validation preset: DocumentSessionController not available")
        return
      }

      sessionController.selectValidationPreset(presetID, scope: scope)

      // Update local state
      Task {
        await loadSettings()
      }
    }

    func setValidationRule(
      _ rule: ValidationRuleIdentifier,
      isEnabled: Bool,
      scope: DocumentSessionController.ValidationConfigurationScope
    ) {
      guard let sessionController = sessionController else {
        logger.warning("Cannot update validation rule: DocumentSessionController not available")
        return
      }

      sessionController.setValidationRule(rule, isEnabled: isEnabled, scope: scope)

      // Update local state
      Task {
        await loadSettings()
      }
    }
  }

  // MARK: - Supporting Types

  struct SessionSettings: Equatable {
    var validationConfiguration: ValidationConfiguration
    var globalValidationConfiguration: ValidationConfiguration

    // @todo #222 Add workspace scope properties (per document vs. shared)
    // @todo #222 Add pane layout properties
    // @todo #222 Add recently opened tabs

    init(
      validationConfiguration: ValidationConfiguration = ValidationConfiguration(
        activePresetID: "default"
      ),
      globalValidationConfiguration: ValidationConfiguration = ValidationConfiguration(
        activePresetID: "default"
      )
    ) {
      self.validationConfiguration = validationConfiguration
      self.globalValidationConfiguration = globalValidationConfiguration
    }

    var hasOverrides: Bool {
      validationConfiguration != globalValidationConfiguration
    }
  }
#endif
