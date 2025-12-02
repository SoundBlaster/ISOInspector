import SwiftUI

/// A section header component for organizing content with optional dividers
///
/// The SectionHeader component provides visual hierarchy and content organization
/// for inspector views, lists, and structured layouts. It displays an uppercase
/// title with optional horizontal divider for clear content separation.
///
/// ## Design System Integration
/// SectionHeader uses the following Design System tokens:
/// - **Spacing**: `DS.Spacing.s`, `DS.Spacing.m` for consistent padding
/// - **Typography**: `DS.Typography.caption` for section header text
/// - **Colors**: System secondary colors for dividers
///
/// ## Usage
/// ```swift
/// // Basic section header without divider
/// SectionHeader(title: "File Properties")
///
/// // Section header with divider
/// SectionHeader(title: "Metadata", showDivider: true)
///
/// // In a VStack layout
/// VStack(alignment: .leading, spacing: DS.Spacing.m) {
///     SectionHeader(title: "Basic Information", showDivider: true)
///     Text("Content goes here")
/// }
/// ```
///
/// ## Accessibility
/// SectionHeader provides:
/// - Accessibility header trait (`.isHeader`) for proper VoiceOver navigation
/// - Uppercase text transformation for visual consistency
/// - Proper heading level semantics
/// - Support for Dynamic Type text scaling
///
/// ## Platform Support
/// - iOS 17.0+
/// - iPadOS 17.0+
/// - macOS 14.0+
///
/// ## See Also
/// - ``DS/Typography``
/// - ``DS/Spacing``
public struct SectionHeader: View {
    // MARK: - Properties

    /// The title text displayed in the section header
    public let title: String

    /// Whether to show a horizontal divider below the title
    public let showDivider: Bool

    // MARK: - Initialization

    /// Creates a new SectionHeader component
    ///
    /// ## Example
    /// ```swift
    /// SectionHeader(title: "File Properties")
    /// SectionHeader(title: "Metadata", showDivider: true)
    /// ```
    ///
    /// ## Parameters
    /// - title: The section title text (displayed in uppercase)
    /// - showDivider: Whether to display a horizontal divider below the title (default: false)
    ///
    /// ## Accessibility
    /// The section header automatically receives the `.isHeader` accessibility trait
    /// for proper VoiceOver navigation and heading level semantics.
    public init(title: String, showDivider: Bool = false) {
        self.title = title
        self.showDivider = showDivider
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            Text(title).font(DS.Typography.caption).textCase(.uppercase).foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)

            if showDivider { Divider() }
        }
    }
}

// MARK: - SwiftUI Previews

#Preview("Basic Header") {
    VStack(alignment: .leading, spacing: DS.Spacing.m) {
        SectionHeader(title: "File Properties")
        Text("Example content").font(DS.Typography.body)
    }.padding()
}

#Preview("Header with Divider") {
    VStack(alignment: .leading, spacing: DS.Spacing.m) {
        SectionHeader(title: "Metadata", showDivider: true)
        Text("Example content").font(DS.Typography.body)
    }.padding()
}

#Preview("Multiple Sections") {
    ScrollView {
        VStack(alignment: .leading, spacing: DS.Spacing.xl) {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                SectionHeader(title: "Basic Information", showDivider: true)
                Text("Content for basic information").font(DS.Typography.body)
            }

            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                SectionHeader(title: "Technical Details", showDivider: true)
                Text("Content for technical details").font(DS.Typography.body)
            }

            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                SectionHeader(title: "Box Structure", showDivider: true)
                Text("Content for box structure").font(DS.Typography.body)
            }
        }.padding()
    }
}

#Preview("Dark Mode") {
    VStack(alignment: .leading, spacing: DS.Spacing.m) {
        SectionHeader(title: "Box Structure", showDivider: true)
        Text("Example content in dark mode").font(DS.Typography.body)
    }.padding().preferredColorScheme(.dark)
}

#Preview("Various Titles") {
    VStack(alignment: .leading, spacing: DS.Spacing.l) {
        SectionHeader(title: "Short")
        SectionHeader(title: "Medium Length Title", showDivider: true)
        SectionHeader(title: "This is a much longer section header title", showDivider: true)
        SectionHeader(title: "with special ⚠️ chars", showDivider: false)
    }.padding()
}

#Preview("Real World Usage") {
    ScrollView {
        VStack(alignment: .leading, spacing: DS.Spacing.xl) {
            // File properties section
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                SectionHeader(title: "File Properties", showDivider: true)

                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    HStack {
                        Text("Name:").font(DS.Typography.body)
                        Text("example.mp4").font(DS.Typography.code)
                    }
                    HStack {
                        Text("Size:").font(DS.Typography.body)
                        Text("42.3 MB").font(DS.Typography.body)
                    }
                }
            }

            // Metadata section
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                SectionHeader(title: "Metadata", showDivider: true)

                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    HStack {
                        Text("Type:").font(DS.Typography.body)
                        Badge(text: "VIDEO", level: .info)
                    }
                    HStack {
                        Text("Status:").font(DS.Typography.body)
                        Badge(text: "VALID", level: .success)
                    }
                }
            }

            // Box structure section
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                SectionHeader(title: "Box Structure", showDivider: true)

                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text("ftyp - File Type Box").font(DS.Typography.body)
                    Text("moov - Movie Box").font(DS.Typography.body)
                    Text("mdat - Media Data Box").font(DS.Typography.body)
                }
            }
        }.padding()
    }
}

// MARK: - AgentDescribable Conformance

@available(iOS 17.0, macOS 14.0, *) @MainActor extension SectionHeader: AgentDescribable {
    public var componentType: String { "SectionHeader" }

    public var properties: [String: Any] { ["title": title, "showDivider": showDivider] }

    public var semantics: String {
        let dividerDesc = showDivider ? "with divider" : "without divider"
        return """
            A section header displaying '\(title)' \(dividerDesc). \
            Provides visual hierarchy and content organization.
            """
    }
}
