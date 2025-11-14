#if canImport(SwiftUI)
import SwiftUI
import FoundationUI

/// A toggle control wrapper that integrates FoundationUI's DS.Toggle
/// with ISO Inspector's domain-specific styling and accessibility requirements.
///
/// This component wraps FoundationUI's `DS.Toggle` to provide:
/// - Consistent spacing via design tokens
/// - Semantic color usage
/// - Enhanced accessibility labels
/// - Platform-adaptive behavior
///
/// ## Usage
///
/// ```swift
/// struct SettingsView: View {
///     @State private var isEnabled = false
///
///     var body: some View {
///         BoxToggleView(
///             isOn: $isEnabled,
///             label: "Enable strict validation"
///         )
///     }
/// }
/// ```
///
/// ## Design Tokens
///
/// - Spacing: `DS.Spacing.m` for label-toggle spacing
/// - Typography: System default with semantic weight
/// - Colors: System colors for disabled state
///
/// ## Accessibility
///
/// - VoiceOver: Announces label and state (on/off)
/// - Keyboard: Standard toggle controls (Space to activate)
/// - Dynamic Type: Label scales with user preferences
///
/// - SeeAlso: `BoxTextInputView`, `BoxPickerView`
@MainActor
public struct BoxToggleView: View {
    // MARK: - Properties

    /// Binding to the toggle state
    @Binding var isOn: Bool

    /// The label displayed next to the toggle
    let label: String

    /// Whether the toggle is disabled
    let disabled: Bool

    /// Optional accessibility label (overrides visual label if provided)
    let accessibilityLabel: String?

    // MARK: - Initialization

    /// Creates a toggle view with a label and state binding.
    ///
    /// - Parameters:
    ///   - isOn: Binding to the toggle's on/off state
    ///   - label: The text label displayed next to the toggle
    ///   - disabled: Whether the toggle should be disabled (default: false)
    ///   - accessibilityLabel: Custom accessibility label (default: uses label)
    public init(
        isOn: Binding<Bool>,
        label: String,
        disabled: Bool = false,
        accessibilityLabel: String? = nil
    ) {
        self._isOn = isOn
        self.label = label
        self.disabled = disabled
        self.accessibilityLabel = accessibilityLabel
    }

    // MARK: - Body

    public var body: some View {
        // @todo #220 Replace with DS.Toggle from FoundationUI
        // Current implementation uses native SwiftUI Toggle as placeholder
        // Next steps:
        // 1. Import FoundationUI DS.Toggle component
        // 2. Apply design tokens for spacing/colors
        // 3. Add platform-adaptive styling
        // 4. Verify accessibility compliance
        Toggle(isOn: $isOn) {
            Text(label)
        }
        .disabled(disabled)
        .accessibilityLabel(effectiveAccessibilityLabel)
    }

    // MARK: - Private Helpers

    private var effectiveAccessibilityLabel: String {
        accessibilityLabel ?? label
    }
}

// MARK: - Previews

#Preview("Toggle States") {
    VStack(alignment: .leading, spacing: 16) {
        BoxToggleView(
            isOn: .constant(true),
            label: "Enabled toggle"
        )

        BoxToggleView(
            isOn: .constant(false),
            label: "Disabled toggle",
            disabled: true
        )

        BoxToggleView(
            isOn: .constant(true),
            label: "With custom accessibility",
            accessibilityLabel: "Enable strict validation mode"
        )
    }
    .padding()
}

#endif
