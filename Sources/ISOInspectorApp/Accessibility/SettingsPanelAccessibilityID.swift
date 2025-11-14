import NestedA11yIDs

/// Accessibility identifiers for the Settings Panel
///
/// Provides structured accessibility identifiers for all interactive elements
/// in the floating settings panel, enabling UI testing and VoiceOver support.
///
/// ## Usage
/// ```swift
/// Text("Permanent")
///     .accessibilityIdentifier(SettingsPanelA11yID.sidebar.section("permanent"))
///     // Or use convenience constant:
///     .accessibilityIdentifier(SettingsPanelA11yID.sidebar.permanentSection)
///
/// Button("Reset to Defaults")
///     .accessibilityIdentifier(SettingsPanelA11yID.permanentSettings.resetButton)
/// ```
///
/// ## See Also
/// - ``SettingsPanelView``
/// - ``SettingsPanelViewModel``
public enum SettingsPanelA11yID {
    /// Root identifier for the settings panel
    public static let root = "settings-panel"

    /// Sidebar section identifiers
    public enum sidebar {
        static let root = "\(SettingsPanelA11yID.root).sidebar"

        public static func section(_ sectionID: String) -> String {
            "\(root).section.\(sectionID)"
        }

        // Convenience constants for common sections
        public static let permanentSection = section("permanent")
        public static let sessionSection = section("session")
        public static let advancedSection = section("advanced")
    }

    /// Search bar identifiers
    public enum search {
        static let root = "\(SettingsPanelA11yID.root).search"

        public static let field = "\(root).field"
        public static let clearButton = "\(root).clear-button"
    }

    /// Permanent settings identifiers
    public enum permanentSettings {
        static let root = "\(SettingsPanelA11yID.root).permanent"

        public static let card = "\(root).card"
        public static let title = "\(root).title"
        public static let description = "\(root).description"
        public static let resetButton = "\(root).reset-button"

        // @todo #222 Add validation preset control IDs
        // @todo #222 Add telemetry/logging control IDs
    }

    /// Session settings identifiers
    public enum sessionSettings {
        static let root = "\(SettingsPanelA11yID.root).session"

        public static let card = "\(root).card"
        public static let title = "\(root).title"
        public static let description = "\(root).description"
        public static let resetButton = "\(root).reset-button"

        // @todo #222 Add workspace scope control IDs
        // @todo #222 Add pane layout control IDs
    }

    /// Advanced settings identifiers
    public enum advancedSettings {
        static let root = "\(SettingsPanelA11yID.root).advanced"

        public static let card = "\(root).card"
        public static let title = "\(root).title"
        public static let description = "\(root).description"

        // @todo #222 Add advanced configuration control IDs
    }
}
