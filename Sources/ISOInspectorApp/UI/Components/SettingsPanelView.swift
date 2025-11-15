#if canImport(SwiftUI) && canImport(Combine)
  import SwiftUI
  import FoundationUI

  /// Floating settings panel view with FoundationUI components
  ///
  /// `SettingsPanelView` provides a unified interface for managing both permanent
  /// and session-scoped settings. It features:
  /// - Sidebar navigation using SidebarPattern (Permanent, Session, Advanced)
  /// - Content sections with FoundationUI cards for settings groups
  /// - Async settings loading on view appearance
  /// - Reset affordances for permanent and session settings
  ///
  /// ## Design System Integration
  /// Uses FoundationUI components:
  /// - ``SidebarPattern`` for sidebar navigation
  /// - ``Card`` for settings groups
  /// - Design System spacing and typography tokens
  ///
  /// ## Platform Adaptation
  /// - macOS: Floating NSPanel or detent-based sheet
  /// - iPad: Modal sheet with detents (.medium, .large)
  /// - iPhone: Full-screen modal
  ///
  /// ## See Also
  /// - ``SettingsPanelViewModel``
  /// - ``ValidationSettingsView``
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
    @State private var showResetPermanentConfirmation = false
    @State private var showResetSessionConfirmation = false

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
        )
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

              Divider()

              Button("Reset to Defaults") {
                showResetPermanentConfirmation = true
              }
              .buttonStyle(.bordered)
              .accessibilityIdentifier("ResetPermanentSettingsButton")
            }
            .padding(DS.Spacing.l)
          }
        }
        .padding(DS.Spacing.l)
      }
      .accessibilityIdentifier("PermanentSettingsContent")
      .alert("Reset Permanent Settings?", isPresented: $showResetPermanentConfirmation) {
        Button("Cancel", role: .cancel) {}
        Button("Reset", role: .destructive) {
          Task {
            await viewModel.resetPermanentSettings()
          }
        }
      } message: {
        Text(
          "This will restore all permanent settings to their default values. This action cannot be undone."
        )
      }
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

              if viewModel.hasSessionOverrides {
                HStack {
                  Image(systemName: "exclamationmark.circle")
                    .foregroundColor(.orange)
                  Text("Session has custom overrides")
                    .font(DS.Typography.caption)
                    .foregroundColor(.secondary)
                }
              }

              Divider()

              Button("Reset to Global") {
                showResetSessionConfirmation = true
              }
              .buttonStyle(.bordered)
              .accessibilityIdentifier("ResetSessionSettingsButton")
            }
            .padding(DS.Spacing.l)
          }
        }
        .padding(DS.Spacing.l)
      }
      .accessibilityIdentifier("SessionSettingsContent")
      .alert("Reset Session Settings?", isPresented: $showResetSessionConfirmation) {
        Button("Cancel", role: .cancel) {}
        Button("Reset", role: .destructive) {
          Task {
            await viewModel.resetSessionSettings()
          }
        }
      } message: {
        Text(
          "This will reset all session settings to match global defaults. This action only affects the current document session."
        )
      }
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
        // Mock store for preview
        struct MockStore: UserPreferencesPersisting {
          func loadPreferences() throws -> UserPreferences? { .default }
          func savePreferences(_ preferences: UserPreferences) throws {}
          func reset() throws {}
        }

        let mockStore = MockStore()
        let viewModel = SettingsPanelViewModel(preferencesStore: mockStore)
        return SettingsPanelView(viewModel: viewModel)
      }
    }
  #endif
#endif
