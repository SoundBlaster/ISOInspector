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
    @MainActor final class ValidationConfigurationService: ObservableObject {  // swiftlint:disable:this type_body_length
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

            let presets = Self.loadPresets(using: validationPresetLoader, diagnostics: diagnostics)
            self.validationPresets = presets.presets
            self.presetByID = presets.presetByID
            self.defaultValidationPresetID = presets.defaultPresetID

            let loadedGlobal = Self.loadGlobalConfiguration(
                from: validationConfigurationStore, defaultPresetID: presets.defaultPresetID,
                diagnostics: diagnostics)

            let normalizedGlobal = Self.normalizedConfiguration(
                loadedGlobal, presetByID: presets.presetByID,
                defaultPresetID: presets.defaultPresetID)
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
            _ rule: ValidationRuleIdentifier, isEnabled: Bool, scope: ValidationConfigurationScope
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
                disabledRuleIDs: disabledRuleIDs(for: validationConfiguration))
        }

        /// Returns whether the workspace configuration has changed and needs persistence.
        func didUpdateWorkspaceConfiguration() -> Bool {
            guard let key = currentConfigurationKey else { return false }
            return sessionValidationConfigurations[key] != nil
        }

        // MARK: - Private Methods

        private struct PresetLoadResult {
            let presets: [ValidationPreset]
            let presetByID: [String: ValidationPreset]
            let defaultPresetID: String
        }

        private static func loadPresets(
            using loader: (() throws -> [ValidationPreset])?, diagnostics: any DiagnosticsLogging
        ) -> PresetLoadResult {
            let resolvedLoader = loader ?? { try ValidationPreset.loadBundledPresets() }
            do {
                let presets = try resolvedLoader()
                let presetByID = Dictionary(uniqueKeysWithValues: presets.map { ($0.id, $0) })
                return PresetLoadResult(
                    presets: presets, presetByID: presetByID,
                    defaultPresetID: defaultPresetID(from: presets))
            } catch {
                diagnostics.error("Failed to load validation presets: \(error)")
                return PresetLoadResult(
                    presets: [], presetByID: [:], defaultPresetID: defaultPresetID(from: []))
            }
        }

        private static func loadGlobalConfiguration(
            from store: ValidationConfigurationPersisting?, defaultPresetID: String,
            diagnostics: any DiagnosticsLogging
        ) -> ValidationConfiguration {
            guard let store else { return ValidationConfiguration(activePresetID: defaultPresetID) }

            do {
                return try store.loadConfiguration()
                    ?? ValidationConfiguration(activePresetID: defaultPresetID)
            } catch {
                diagnostics.error("Failed to load validation configuration: \(error)")
                return ValidationConfiguration(activePresetID: defaultPresetID)
            }
        }

        private func updateGlobalConfiguration(_ configuration: ValidationConfiguration) {
            let normalized = normalizedConfiguration(configuration)
            guard normalized != globalValidationConfiguration else { return }
            globalValidationConfiguration = normalized
            persistGlobalConfiguration()
            if !isUsingWorkspaceValidationOverride { validationConfiguration = normalized }
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
            on configuration: inout ValidationConfiguration, rule: ValidationRuleIdentifier,
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

        private func normalizedConfiguration(_ configuration: ValidationConfiguration)
            -> ValidationConfiguration
        {
            Self.normalizedConfiguration(
                configuration, presetByID: presetByID, defaultPresetID: defaultValidationPresetID)
        }

        private static func normalizedConfiguration(
            _ configuration: ValidationConfiguration, presetByID: [String: ValidationPreset],
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
            } catch { diagnostics.error("Failed to persist validation configuration: \(error)") }
        }

        private func disabledRuleIDs(for configuration: ValidationConfiguration) -> [String] {
            ValidationRuleIdentifier.allCases.filter {
                !configuration.isRuleEnabled($0, presets: validationPresets)
            }.map(\.rawValue).sorted()
        }

        private static func defaultPresetID(from presets: [ValidationPreset]) -> String {
            if presets.contains(where: { $0.id == "all-rules" }) { return "all-rules" }
            return presets.first?.id ?? "all-rules"
        }

        private func canonicalIdentifier(for url: URL) -> String {
            url.standardizedFileURL.resolvingSymlinksInPath().absoluteString
        }

        // MARK: - Nested Types

        enum ValidationConfigurationScope {
            case global
            case workspace
        }
    }
#endif
