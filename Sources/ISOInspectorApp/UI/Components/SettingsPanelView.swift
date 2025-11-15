#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI
import FoundationUI

struct SettingsPanelView: View {
    @ObservedObject var viewModel: SettingsPanelViewModel

    var body: some View {
        SidebarPattern(
            sections: sidebarSections,
            selection: $selectedSectionID
        ) { sectionID in
            detailContent(for: sectionID)
        }
        .task {
            await viewModel.loadSettings()
        }
        .accessibilityIdentifier("SettingsPanelView")
    }

    // MARK: - Private Helpers

    @State private var selectedSectionID: String? = "permanent"

    private var sidebarSections: [SidebarPattern<String, AnyView>.Section] {
        [
            SidebarPattern.Section(
                id: "settings",
                title: "Settings",
                items: [
                    SidebarPattern.Item(
                        id: "permanent",
                        title: "Permanent",
                        iconSystemName: "gearshape",
                        accessibilityLabel: "Permanent Settings"
                    ),
                    SidebarPattern.Item(
                        id: "session",
                        title: "Session",
                        iconSystemName: "doc",
                        accessibilityLabel: "Session Settings"
                    ),
                    SidebarPattern.Item(
                        id: "advanced",
                        title: "Advanced",
                        iconSystemName: "slider.horizontal.3",
                        accessibilityLabel: "Advanced Settings"
                    ),
                ]
            ),
        ]
    }

    @ViewBuilder
    private func detailContent(for sectionID: String?) -> AnyView {
        guard let sectionID = sectionID else {
            return AnyView(
                Text("Select a section")
                    .foregroundColor(.secondary)
            )
        }

        switch sectionID {
        case "permanent":
            return AnyView(permanentSettingsContent)
        case "session":
            return AnyView(sessionSettingsContent)
        case "advanced":
            return AnyView(advancedSettingsContent)
        default:
            return AnyView(
                Text("Unknown section")
                    .foregroundColor(.secondary)
            )
        }
    }

    private var permanentSettingsContent: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.l) {
                Card {
                    VStack(alignment: .leading, spacing: DS.Spacing.m) {
                        Text("Permanent Settings")
                            .font(DS.Typography.title)
                        Text(
                            "These settings persist across all sessions and app restarts."
                        )
                        .font(DS.Typography.caption)
                        .foregroundColor(.secondary)

                        Divider()

                        // @todo #222 Add validation preset controls
                        // @todo #222 Add telemetry/logging verbosity controls
                        Text("Settings controls will appear here")
                            .foregroundColor(.secondary)

                        Button("Reset to Global") {
                            Task {
                                await viewModel.resetPermanentSettings()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(DS.Spacing.l)
                }
            }
            .padding(DS.Spacing.l)
        }
        .accessibilityIdentifier("PermanentSettingsContent")
    }

    private var sessionSettingsContent: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.l) {
                Card {
                    VStack(alignment: .leading, spacing: DS.Spacing.m) {
                        Text("Session Settings")
                            .font(DS.Typography.title)
                        Text("These settings only affect the current document session.")
                            .font(DS.Typography.caption)
                            .foregroundColor(.secondary)

                        Divider()

                        // @todo #222 Add workspace scope controls
                        // @todo #222 Add pane layout controls
                        Text("Session controls will appear here")
                            .foregroundColor(.secondary)
                    }
                    .padding(DS.Spacing.l)
                }
            }
            .padding(DS.Spacing.l)
        }
        .accessibilityIdentifier("SessionSettingsContent")
    }

    private var advancedSettingsContent: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.l) {
                Card {
                    VStack(alignment: .leading, spacing: DS.Spacing.m) {
                        Text("Advanced Settings")
                            .font(DS.Typography.title)
                        Text("Advanced configuration options.")
                            .font(DS.Typography.caption)
                            .foregroundColor(.secondary)

                        Divider()

                        // @todo #222 Add advanced configuration controls
                        Text("Advanced controls will appear here")
                            .foregroundColor(.secondary)
                    }
                    .padding(DS.Spacing.l)
                }
            }
            .padding(DS.Spacing.l)
        }
        .accessibilityIdentifier("AdvancedSettingsContent")
    }
}

// MARK: - Preview

#if DEBUG
    struct SettingsPanelView_Previews: PreviewProvider {
        static var previews: some View {
            SettingsPanelView(viewModel: SettingsPanelViewModel())
        }
    }
#endif
#endif
