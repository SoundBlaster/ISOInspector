#if canImport(SwiftUI)
import SwiftUI
import FoundationUI

/// A text input wrapper that integrates FoundationUI's DS.TextInput
/// with ISO Inspector's validation and formatting requirements.
///
/// This component wraps FoundationUI's `DS.TextInput` to provide:
/// - Built-in validation error display
/// - Platform-adaptive keyboard types
/// - Copyable text support
/// - Enhanced accessibility
///
/// ## Usage
///
/// ```swift
/// struct SearchView: View {
///     @State private var searchText = ""
///     @State private var validationError: String? = nil
///
///     var body: some View {
///         BoxTextInputView(
///             text: $searchText,
///             placeholder: "Search boxes...",
///             validationError: validationError,
///             keyboardType: .default
///         )
///     }
/// }
/// ```
///
/// ## Design Tokens
///
/// - Spacing: `DS.Spacing.s` for padding
/// - Radius: `DS.Radius.card` for rounded corners
/// - Colors: `DS.Color.errorBG` for validation errors
///
/// ## Accessibility
///
/// - VoiceOver: Announces placeholder, value, and errors
/// - Keyboard: Standard text editing shortcuts
/// - Dynamic Type: Scales with user preferences
///
/// - SeeAlso: `BoxToggleView`, `BoxPickerView`
@MainActor
public struct BoxTextInputView: View {
    // MARK: - Properties

    /// Binding to the text content
    @Binding var text: String

    /// Placeholder text shown when input is empty
    let placeholder: String

    /// Optional validation error message
    let validationError: String?

    /// Keyboard type for platform-specific input optimization
    let keyboardType: KeyboardType

    /// Callback when editing state changes (focus gained/lost)
    let onEditingChanged: (Bool) -> Void

    // MARK: - Keyboard Type

    public enum KeyboardType {
        case `default`
        case numberPad
        case decimalPad
        case URL
        case emailAddress

        #if os(iOS)
        var uiKeyboardType: UIKeyboardType {
            switch self {
            case .default: return .default
            case .numberPad: return .numberPad
            case .decimalPad: return .decimalPad
            case .URL: return .URL
            case .emailAddress: return .emailAddress
            }
        }
        #endif
    }

    // MARK: - Initialization

    /// Creates a text input view with optional validation.
    ///
    /// - Parameters:
    ///   - text: Binding to the text content
    ///   - placeholder: Placeholder text when empty
    ///   - validationError: Optional error message to display
    ///   - keyboardType: Platform-specific keyboard type
    ///   - onEditingChanged: Callback when editing state changes
    public init(
        text: Binding<String>,
        placeholder: String = "",
        validationError: String? = nil,
        keyboardType: KeyboardType = .default,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self._text = text
        self.placeholder = placeholder
        self.validationError = validationError
        self.keyboardType = keyboardType
        self.onEditingChanged = onEditingChanged
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // @todo #220 Replace with DS.TextInput from FoundationUI
            // Current implementation uses native SwiftUI TextField as placeholder
            // Next steps:
            // 1. Import FoundationUI DS.TextInput component
            // 2. Apply design tokens for padding/corners/shadows
            // 3. Add copyable text support via DS.Copyable
            // 4. Platform-adaptive keyboard types
            // 5. Enhanced error state styling
            textField

            if let error = validationError {
                errorLabel(error)
            }
        }
    }

    // MARK: - Private Helpers

    private var textField: some View {
        TextField(placeholder, text: $text, onEditingChanged: onEditingChanged)
            .textFieldStyle(.roundedBorder)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(validationError != nil ? Color.red : Color.clear, lineWidth: 2)
            )
            #if os(iOS)
            .keyboardType(keyboardType.uiKeyboardType)
            #endif
            .accessibilityLabel(placeholder)
            .accessibilityValue(text.isEmpty ? "Empty" : text)
    }

    private func errorLabel(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundColor(.red)
            .accessibilityLabel("Error: \(message)")
    }
}

// MARK: - Previews

#Preview("Text Input States") {
    VStack(alignment: .leading, spacing: 24) {
        BoxTextInputView(
            text: .constant(""),
            placeholder: "Enter box name..."
        )

        BoxTextInputView(
            text: .constant("ftyp"),
            placeholder: "Enter box name..."
        )

        BoxTextInputView(
            text: .constant("invalid"),
            placeholder: "Enter box name...",
            validationError: "Box name must be exactly 4 characters"
        )

        BoxTextInputView(
            text: .constant(""),
            placeholder: "Enter offset...",
            keyboardType: .numberPad
        )
    }
    .padding()
}

#endif
