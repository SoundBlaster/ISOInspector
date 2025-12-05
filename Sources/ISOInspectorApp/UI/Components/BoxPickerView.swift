#if canImport(SwiftUI)
    import SwiftUI
    import FoundationUI

    /// A picker control wrapper that integrates FoundationUI's DS.Picker
    /// with ISO Inspector's domain-specific selection patterns.
    ///
    /// This component wraps FoundationUI's `DS.Picker` to provide:
    /// - Type-safe selection with generic value support
    /// - Platform-adaptive picker styles (segmented on macOS, menu on iOS)
    /// - Consistent labeling and accessibility
    /// - Design token integration
    ///
    /// ## Usage
    ///
    /// ```swift
    /// struct ExportView: View {
    ///     enum ExportFormat: String, CaseIterable, Hashable {
    ///         case json = "JSON"
    ///         case yaml = "YAML"
    ///         case csv = "CSV"
    ///     }
    ///
    ///     @State private var selectedFormat: ExportFormat = .json
    ///
    ///     var body: some View {
    ///         BoxPickerView(
    ///             selection: $selectedFormat,
    ///             label: "Export Format",
    ///             options: ExportFormat.allCases.map { (label: $0.rawValue, value: $0) }
    ///         )
    ///     }
    /// }
    /// ```
    ///
    /// ## Design Tokens
    ///
    /// - Spacing: `DS.Spacing.m` for label-picker spacing
    /// - Typography: System default with semantic weight
    /// - Platform Adaptation: Segmented style on macOS, menu on iOS for >3 options
    ///
    /// ## Accessibility
    ///
    /// - VoiceOver: Announces label, selected value, and all options
    /// - Keyboard: Arrow keys navigate options, Return/Space selects
    /// - Dynamic Type: Label and options scale with user preferences
    ///
    /// - SeeAlso: `BoxToggleView`, `BoxTextInputView`
    @MainActor public struct BoxPickerView<T: Hashable>: View {
        // MARK: - Properties

        /// Binding to the selected value
        @Binding var selection: T

        /// The label displayed above or beside the picker
        let label: String

        /// Available options as (label, value) pairs
        let options: [(label: String, value: T)]

        /// Whether to use segmented style (default: automatic based on platform)
        let useSegmentedStyle: Bool?

        // MARK: - Initialization

        /// Creates a picker view with labeled options.
        ///
        /// - Parameters:
        ///   - selection: Binding to the selected value
        ///   - label: The label text for the picker
        ///   - options: Array of (label, value) tuples for picker options
        ///   - useSegmentedStyle: Override automatic style selection (nil = automatic)
        public init(
            selection: Binding<T>, label: String, options: [(label: String, value: T)],
            useSegmentedStyle: Bool? = nil
        ) {
            self._selection = selection
            self.label = label
            self.options = options
            self.useSegmentedStyle = useSegmentedStyle
        }

        // MARK: - Body

        public var body: some View {
            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                Text(label).font(.subheadline).foregroundColor(.secondary)

                // @todo #220 Replace with DS.Picker from FoundationUI
                // Current implementation uses native SwiftUI Picker as placeholder
                // Next steps:
                // 1. Import FoundationUI DS.Picker component
                // 2. Apply platform-adaptive styling:
                //    - macOS: Segmented for ≤4 options, menu for >4
                //    - iOS: Segmented for ≤3 options, menu for >3
                //    - iPadOS: Follow iOS patterns with size class adaptation
                // 3. Integrate design tokens for spacing and sizing
                // 4. Add enhanced accessibility labels
                // 5. Support for custom option rendering (icons, colors)
                pickerView.accessibilityLabel(effectiveAccessibilityLabel)
            }
        }

        // MARK: - Private Helpers

        @ViewBuilder private var pickerView: some View {
            let picker = Picker(label, selection: $selection) {
                ForEach(options, id: \.value) { option in Text(option.label).tag(option.value) }
            }

            if shouldUseSegmentedStyle {
                picker.pickerStyle(.segmented)
            } else {
                picker.pickerStyle(.menu)
            }
        }

        private var shouldUseSegmentedStyle: Bool {
            if let override = useSegmentedStyle { return override }

            // Automatic style selection based on platform and option count
            #if os(macOS)
                // macOS: Segmented for ≤4 options, menu for >4
                return options.count <= 4
            #else
                // iOS/iPadOS: Segmented for ≤3 options, menu for >3
                return options.count <= 3
            #endif
        }

        private var effectiveAccessibilityLabel: String {
            guard let currentOption = options.first(where: { $0.value == selection }) else {
                return "\(label), no selection"
            }
            return "\(label), selected: \(currentOption.label)"
        }
    }

    // MARK: - Previews

    #Preview("Picker Variants") {
        VStack(alignment: .leading, spacing: DS.Spacing.xl) {
            // Segmented picker (few options)
            BoxPickerView(
                selection: .constant("JSON"), label: "Export Format",
                options: [
                    (label: "JSON", value: "JSON"), (label: "YAML", value: "YAML"),
                    (label: "CSV", value: "CSV"),
                ])

            // Menu picker (many options)
            BoxPickerView(
                selection: .constant(3), label: "Parse Depth Limit",
                options: [
                    (label: "Unlimited", value: 0), (label: "1 level", value: 1),
                    (label: "2 levels", value: 2), (label: "3 levels", value: 3),
                    (label: "5 levels", value: 5), (label: "10 levels", value: 10),
                ])

            // Forced segmented style
            BoxPickerView(
                selection: .constant("standard"), label: "Display Density",
                options: [
                    (label: "Compact", value: "compact"), (label: "Standard", value: "standard"),
                ], useSegmentedStyle: true)
        }.padding()
    }

#endif
