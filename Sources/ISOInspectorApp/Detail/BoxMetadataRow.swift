import FoundationUI
import SwiftUI

/// A wrapper component for displaying metadata rows in the ISOInspectorApp
///
/// `BoxMetadataRow` provides a consistent, accessible interface for displaying
/// key-value metadata pairs throughout the ISOInspector UI. It wraps the FoundationUI
/// KeyValueRow component and integrates copyable actions for field values.
///
/// ## Design System Integration
/// - Inherits dark mode adaptation automatically from FoundationUI
/// - Uses Design System typography tokens (body for keys, code for values)
/// - Maintains accessibility compliance (WCAG 2.1 AA)
/// - Supports both horizontal and vertical layouts
///
/// ## Usage
/// ```swift
/// // Basic metadata display
/// BoxMetadataRow(label: "Type", value: "ftyp")
///
/// // With copyable action
/// BoxMetadataRow(label: "Offset", value: "0x00001234", copyable: true)
///
/// // Vertical layout for long values
/// BoxMetadataRow(
///     label: "Description",
///     value: "A very long description",
///     layout: .vertical,
///     copyable: true
/// )
/// ```
///
/// ## Features
/// - **Consistent Styling:** Unified appearance across all metadata displays
/// - **Copyable Values:** Built-in copy-to-clipboard with visual feedback
/// - **Dark Mode Support:** Automatic adaptation to system appearance
/// - **Accessible:** Full VoiceOver support and WCAG 2.1 AA compliance
/// - **Responsive Layouts:** Horizontal (compact) and vertical (long content) modes
///
/// ## See Also
/// - KeyValueRow - Underlying component
/// - KeyValueLayout - Layout enumeration
/// - ``ParseTreeDetailView`` - Primary usage location
///
public struct BoxMetadataRow: View {
  // MARK: - Properties

  /// The label/key text displayed for the metadata field
  public let label: String

  /// The value text displayed (typically rendered in monospaced font)
  public let value: String

  /// The layout style (horizontal or vertical)
  public let layout: KeyValueLayout

  /// Whether the value text can be copied to clipboard
  public let copyable: Bool

  // MARK: - Initialization

  /// Creates a new BoxMetadataRow component
  ///
  /// - Parameters:
  ///   - label: The label/key text to display
  ///   - value: The value text to display (rendered in monospaced font)
  ///   - layout: The layout style (horizontal or vertical). Default: `.horizontal`
  ///   - copyable: Whether to enable copy-to-clipboard functionality. Default: `false`
  public init(
    label: String,
    value: String,
    layout: KeyValueLayout = .horizontal,
    copyable: Bool = false
  ) {
    self.label = label
    self.value = value
    self.layout = layout
    self.copyable = copyable
  }

  // MARK: - Body

  public var body: some View {
    KeyValueRow(
      key: label,
      value: value,
      layout: layout,
      copyable: copyable
    )
  }
}

// MARK: - SwiftUI Previews

#Preview("BoxMetadataRow - Horizontal Layout") {
  VStack(alignment: .leading, spacing: DS.Spacing.m) {
    BoxMetadataRow(label: "Type", value: "ftyp")
    BoxMetadataRow(label: "Size", value: "1024 bytes")
    BoxMetadataRow(label: "Offset", value: "0x00001234")
    BoxMetadataRow(label: "Duration", value: "5:32")
  }
  .padding()
}

#Preview("BoxMetadataRow - Vertical Layout") {
  VStack(alignment: .leading, spacing: DS.Spacing.l) {
    BoxMetadataRow(
      label: "Description",
      value: "This is a very long description that works better in vertical layout",
      layout: .vertical
    )
    BoxMetadataRow(
      label: "Full Path",
      value: "/Users/username/Documents/Projects/ISOInspector/test.iso",
      layout: .vertical
    )
  }
  .padding()
}

#Preview("BoxMetadataRow - Copyable Values") {
  VStack(alignment: .leading, spacing: DS.Spacing.m) {
    BoxMetadataRow(label: "Type", value: "ftyp", copyable: true)
    BoxMetadataRow(label: "Size", value: "1024 bytes", copyable: true)
    BoxMetadataRow(label: "Offset", value: "0x00001234", copyable: true)
    BoxMetadataRow(label: "Hash", value: "0xDEADBEEF", copyable: true)
  }
  .padding()
}

#Preview("BoxMetadataRow - Dark Mode") {
  VStack(alignment: .leading, spacing: DS.Spacing.m) {
    BoxMetadataRow(label: "Type", value: "ftyp", copyable: true)
    BoxMetadataRow(
      label: "Description",
      value: "Long description in dark mode",
      layout: .vertical
    )
    BoxMetadataRow(label: "Offset", value: "0x00001234", copyable: true)
  }
  .padding()
  .preferredColorScheme(.dark)
}

#Preview("BoxMetadataRow - Real World ISO Metadata") {
  ScrollView {
    VStack(alignment: .leading, spacing: DS.Spacing.l) {
      // Box information section
      VStack(alignment: .leading, spacing: DS.Spacing.m) {
        BoxMetadataRow(label: "Box Type", value: "ftyp", copyable: true)
        BoxMetadataRow(label: "Size", value: "32 bytes", copyable: true)
        BoxMetadataRow(label: "Offset", value: "0x00000000", copyable: true)
        BoxMetadataRow(
          label: "Description",
          value: "File Type Box - defines brand and version compatibility",
          layout: .vertical
        )
      }

      // Extended metadata
      VStack(alignment: .leading, spacing: DS.Spacing.m) {
        BoxMetadataRow(label: "Major Brand", value: "isom", copyable: true)
        BoxMetadataRow(label: "Minor Version", value: "512", copyable: true)
        BoxMetadataRow(
          label: "Compatible Brands",
          value: "isom, iso2, avc1, mp41",
          layout: .vertical,
          copyable: true
        )
      }
    }
    .padding()
  }
}

// MARK: - AgentDescribable Conformance

@available(iOS 17.0, macOS 14.0, *)
@MainActor
extension BoxMetadataRow: AgentDescribable {
  public var componentType: String {
    "BoxMetadataRow"
  }

  public var properties: [String: Any] {
    [
      "label": label,
      "value": value,
      "layout": layout == .horizontal ? "horizontal" : "vertical",
      "copyable": copyable,
    ]
  }

  public var semantics: String {
    let layoutDesc = layout == .horizontal ? "side-by-side" : "stacked vertically"
    let copyableDesc = copyable ? " with copyable value" : ""
    return "A metadata row displaying '\(label)': '\(value)' \(layoutDesc)\(copyableDesc)."
  }
}
