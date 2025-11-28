#if canImport(SwiftUI) && canImport(Combine)
  import Combine
  import Foundation
  import ISOInspectorKit

  /// Service responsible for managing validation configuration.
  ///
  /// This service handles:
  /// - Global validation configuration persistence
  /// - Workspace-specific validation overrides
  /// - Validation preset management
  /// - Rule enable/disable configuration
  @MainActor
  final class ValidationConfigurationService: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var validationConfiguration: ValidationConfiguration
    @Published private(set) var globalValidationConfiguration: ValidationConfiguration
    @Published private(set) var validationPresets: [ValidationPreset]
    @Published private(set) var isUsingWorkspaceValidationOverride: Bool

    // MARK: - Private Properties

    private let validationConfigurationStore: ValidationConfigurationPersisting?
    private let diagnostics: any DiagnosticsLogging

    private var sessionValidationConfigurations: [String: ValidationConfiguration] = [:]
    private var presetByID: [String: ValidationPreset] = [:]
    private var currentConfigurationKey: String?
    private var defaultValidationPresetID: String

    // MARK: - Initialization

    init(
      validationConfigurationStore: ValidationConfigurationPersisting?,
      validationPresetLoader: (() throws -> [ValidationPreset])?,
      diagnostics: any DiagnosticsLogging
    ) {
      self.validationConfigurationStore = validationConfigurationStore
      self.diagnostics = diagnostics

      // Load presets
      let loader = validationPresetLoader ?? { try ValidationPreset.loadBundledPresets() }
      var loadedPresets: [ValidationPreset] = []
      do {
        loadedPresets = try loader()
      } catch {
        diagnostics.error("Failed to load validation presets: \(error)")
      }
      self.validationPresets = loadedPresets
      let presetByID = Dictionary(uniqueKeysWithValues: loadedPresets.map { ($0.id, $0) })
      self.presetByID = presetByID
      let defaultPresetID = Self.defaultPresetID(from: loadedPresets)
      self.defaultValidationPresetID = defaultPresetID

      // Load global configuration
      let loadedGlobal: ValidationConfiguration
      if let validationConfigurationStore {
        do {
          loadedGlobal =
            try validationConfigurationStore.loadConfiguration()
            ?? ValidationConfiguration(activePresetID: defaultValidationPresetID)
        } catch {
          diagnostics.error("Failed to load validation configuration: \(error)")
          loadedGlobal = ValidationConfiguration(activePresetID: defaultValidationPresetID)
        }
      } else {
        loadedGlobal = ValidationConfiguration(activePresetID: defaultValidationPresetID)
      }

      let normalizedGlobal = Self.normalizedConfiguration(
        loadedGlobal,
        presetByID: presetByID,
        defaultPresetID: defaultPresetID
      )
      self.globalValidationConfiguration = normalizedGlobal
      self.validationConfiguration = normalizedGlobal
      self.isUsingWorkspaceValidationOverride = false
      self.currentConfigurationKey = nil
    }

    // MARK: - Public Methods

    /// Loads session-specific validation configurations from a snapshot.
    func loadSessionConfigurations(_ snapshot: WorkspaceSessionSnapshot) {
      sessionValidationConfigurations = Dictionary(
        uniqueKeysWithValues: snapshot.files.compactMap { file in
          guard let configuration = file.validationConfiguration else { return nil }
          let key = canonicalIdentifier(for: file.recent.url)
          return (key, normalizedConfiguration(configuration))
        })
    }

    /// Returns session validation configurations for persistence.
    func sessionConfigurationsForPersistence() -> [String: ValidationConfiguration] {
      sessionValidationConfigurations
    }

    /// Updates the active validation configuration for the current document.
    func updateActiveValidationConfiguration(for recent: DocumentRecent) {
      let key = canonicalIdentifier(for: recent.url)
      currentConfigurationKey = key
      if let override = sessionValidationConfigurations[key] {
        validationConfiguration = normalizedConfiguration(override)
        isUsingWorkspaceValidationOverride = true
      } else {
        validationConfiguration = globalValidationConfiguration
        isUsingWorkspaceValidationOverride = false
      }
    }

    /// Selects a validation preset for the specified scope.
    func selectValidationPreset(_ presetID: String, scope: ValidationConfigurationScope) {
      guard presetByID[presetID] != nil else { return }
      switch scope {
      case .global:
        var configuration = globalValidationConfiguration
        configuration.activePresetID = presetID
        configuration.ruleOverrides.removeAll()
        updateGlobalConfiguration(configuration)
      case .workspace:
        guard currentConfigurationKey != nil else { return }
        var configuration =
          sessionValidationConfigurations[currentConfigurationKey!]
          ?? globalValidationConfiguration
        configuration.activePresetID = presetID
        configuration.ruleOverrides.removeAll()
        updateWorkspaceConfiguration(configuration)
      }
    }

    /// Sets a validation rule enabled/disabled state for the specified scope.
    func setValidationRule(
      _ rule: ValidationRuleIdentifier,
      isEnabled: Bool,
      scope: ValidationConfigurationScope
    ) {
      switch scope {
      case .global:
        var configuration = globalValidationConfiguration
        applyOverride(on: &configuration, rule: rule, isEnabled: isEnabled)
        updateGlobalConfiguration(configuration)
      case .workspace:
        guard currentConfigurationKey != nil else { return }
        var configuration =
          sessionValidationConfigurations[currentConfigurationKey!]
          ?? globalValidationConfiguration
        applyOverride(on: &configuration, rule: rule, isEnabled: isEnabled)
        updateWorkspaceConfiguration(configuration)
      }
    }

    /// Resets workspace validation overrides to match global configuration.
    func resetWorkspaceValidationOverrides() {
      updateWorkspaceConfiguration(globalValidationConfiguration)
    }

    /// Creates validation metadata for export.
    func makeValidationMetadata() -> ValidationMetadata {
      ValidationMetadata(
        activePresetID: validationConfiguration.activePresetID,
        disabledRuleIDs: disabledRuleIDs(for: validationConfiguration)
      )
    }

    /// Returns whether the workspace configuration has changed and needs persistence.
    func didUpdateWorkspaceConfiguration() -> Bool {
      guard let key = currentConfigurationKey else { return false }
      return sessionValidationConfigurations[key] != nil
    }

    // MARK: - Private Methods

    private func updateGlobalConfiguration(_ configuration: ValidationConfiguration) {
      let normalized = normalizedConfiguration(configuration)
      guard normalized != globalValidationConfiguration else { return }
      globalValidationConfiguration = normalized
      persistGlobalConfiguration()
      if !isUsingWorkspaceValidationOverride {
        validationConfiguration = normalized
      }
    }

    private func updateWorkspaceConfiguration(_ configuration: ValidationConfiguration) {
      guard let key = currentConfigurationKey else { return }
      let normalized = normalizedConfiguration(configuration)
      if normalized == globalValidationConfiguration {
        sessionValidationConfigurations.removeValue(forKey: key)
        validationConfiguration = globalValidationConfiguration
        isUsingWorkspaceValidationOverride = false
      } else {
        sessionValidationConfigurations[key] = normalized
        validationConfiguration = normalized
        isUsingWorkspaceValidationOverride = true
      }
    }

    private func applyOverride(
      on configuration: inout ValidationConfiguration,
      rule: ValidationRuleIdentifier,
      isEnabled: Bool
    ) {
      let preset = presetByID[configuration.activePresetID]
      let presetValue = preset?.isRuleEnabled(rule) ?? true
      if isEnabled == presetValue {
        configuration.ruleOverrides.removeValue(forKey: rule)
      } else {
        configuration.ruleOverrides[rule] = isEnabled
      }
    }

    private func normalizedConfiguration(
      _ configuration: ValidationConfiguration
    ) -> ValidationConfiguration {
      Self.normalizedConfiguration(
        configuration,
        presetByID: presetByID,
        defaultPresetID: defaultValidationPresetID
      )
    }

    private static func normalizedConfiguration(
      _ configuration: ValidationConfiguration,
      presetByID: [String: ValidationPreset],
      defaultPresetID: String
    ) -> ValidationConfiguration {
      var normalized = configuration
      if presetByID[normalized.activePresetID] == nil {
        normalized.activePresetID = defaultPresetID
        normalized.ruleOverrides.removeAll()
      }
      return normalized
    }

    private func persistGlobalConfiguration() {
      guard let validationConfigurationStore else { return }
      do {
        try validationConfigurationStore.saveConfiguration(globalValidationConfiguration)
      } catch {
        diagnostics.error("Failed to persist validation configuration: \(error)")
      }
    }

    private func disabledRuleIDs(for configuration: ValidationConfiguration) -> [String] {
      ValidationRuleIdentifier.allCases
        .filter { !configuration.isRuleEnabled($0, presets: validationPresets) }
        .map(\.rawValue)
        .sorted()
    }

    private static func defaultPresetID(from presets: [ValidationPreset]) -> String {
      if presets.contains(where: { $0.id == "all-rules" }) {
        return "all-rules"
      }
      return presets.first?.id ?? "all-rules"
    }

    private func canonicalIdentifier(for url: URL) -> String {
      url.standardizedFileURL.resolvingSymlinksInPath().absoluteString
    }
  }

  // MARK: - Supporting Types

  enum ValidationConfigurationScope {
    case global
    case workspace
  }
#endif
