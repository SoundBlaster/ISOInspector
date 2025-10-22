#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI
import ISOInspectorKit

struct ValidationSettingsView: View {
    @ObservedObject var controller: DocumentSessionController
    @State private var selectedScope: DocumentSessionController.ValidationConfigurationScope

    init(controller: DocumentSessionController) {
        self.controller = controller
        if controller.currentDocument != nil {
            _selectedScope = State(initialValue: .workspace)
        } else {
            _selectedScope = State(initialValue: .global)
        }
    }

    var body: some View {
        Form {
            scopeSection
            presetSection
            ruleSection
            if effectiveScope == .workspace {
                resetSection
            }
        }
        .padding()
        .onChange(of: controller.currentDocument) { _, document in
            if document == nil {
                selectedScope = .global
            }
        }
    }

    private var scopeSection: some View {
        Section("Scope") {
            Picker("Apply changes to", selection: $selectedScope) {
                Text("Global Defaults").tag(DocumentSessionController.ValidationConfigurationScope.global)
                Text("Current Workspace").tag(DocumentSessionController.ValidationConfigurationScope.workspace)
            }
            .pickerStyle(.segmented)
            .disabled(!workspaceAvailable)

            Text(scopeDescription)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private var presetSection: some View {
        Section("Presets") {
            if controller.validationPresets.isEmpty {
                Text("No presets available.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(controller.validationPresets, id: \.id) { preset in
                    Button {
                        controller.selectValidationPreset(preset.id, scope: effectiveScope)
                    } label: {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(preset.name)
                                    .fontWeight(preset.id == activeConfiguration.activePresetID ? .semibold : .regular)
                                Text(preset.summary)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if preset.id == activeConfiguration.activePresetID {
                                if isCustomSelection {
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.accentColor)
                                        Text("Custom")
                                            .font(.caption)
                                            .foregroundColor(.accentColor)
                                    }
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var ruleSection: some View {
        Section("Rules") {
            ForEach(ValidationRuleIdentifier.allCases, id: \.self) { rule in
                Toggle(isOn: binding(for: rule)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(rule.displayName)
                        Text(rule.summary)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var resetSection: some View {
        Section {
            Button("Reset to Global") {
                controller.resetWorkspaceValidationOverrides()
            }
            .disabled(!controller.isUsingWorkspaceValidationOverride)
        }
    }

    private var workspaceAvailable: Bool {
        controller.currentDocument != nil
    }

    private var effectiveScope: DocumentSessionController.ValidationConfigurationScope {
        workspaceAvailable ? selectedScope : .global
    }

    private var activeConfiguration: ValidationConfiguration {
        switch effectiveScope {
        case .global:
            return controller.globalValidationConfiguration
        case .workspace:
            return controller.validationConfiguration
        }
    }

    private var isCustomSelection: Bool {
        effectiveScope == .workspace && controller.isUsingWorkspaceValidationOverride
    }

    private var scopeDescription: String {
        if !workspaceAvailable {
            return "Open a document to configure workspace overrides."
        }
        switch effectiveScope {
        case .global:
            return "Global defaults apply to new workspaces."
        case .workspace:
            return "Changes apply to \(controller.currentDocument?.displayName ?? "this workspace")."
        }
    }

    private func binding(for rule: ValidationRuleIdentifier) -> Binding<Bool> {
        Binding(
            get: {
                activeConfiguration.isRuleEnabled(rule, presets: controller.validationPresets)
            },
            set: { newValue in
                controller.setValidationRule(rule, isEnabled: newValue, scope: effectiveScope)
            }
        )
    }
}
#endif
