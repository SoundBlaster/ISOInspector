import SwiftUI

/// A pattern for displaying detailed inspector content with a fixed header and
/// scrollable body area.
///
/// `InspectorPattern` provides the baseline layout used throughout ISO
/// Inspector for presenting metadata panels. It respects the Composable Clarity
/// design system layers by combining previously implemented components and
/// tokens.
///
/// ## Usage
/// ```swift
/// InspectorPattern(title: "File Details") {
///     SectionHeader(title: "General Information")
///     KeyValueRow(key: "File Name", value: "example.mp4")
///     KeyValueRow(key: "Size", value: "1.2 GB")
/// }
/// .material(.regular)
/// ```
public struct InspectorPattern<Content: View>: View {
    /// The title displayed in the fixed header.
    public let title: String

    /// The material used for the pattern background.
    public let material: Material

    /// The scrollable content displayed within the inspector.
    public let content: Content

    /// Creates a new inspector pattern with the provided title and content.
    /// - Parameters:
    ///   - title: The title to show within the header area.
    ///   - material: The material background. Defaults to ``Material/thinMaterial``.
    ///   - content: A view builder that produces the inspector body content.
    public init(
        title: String,
        material: Material = .thinMaterial,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.material = material
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                contentContainer
            }
            .scrollIndicators(.hidden)
            // @todo: Integrate lazy loading and state binding once detail editors are introduced.
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            material,
            in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(title))
    }

    @ViewBuilder
    private var header: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            Text(title)
                .font(DS.Typography.title)
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.l)
        .background(material)
    }

    @ViewBuilder
    private var contentContainer: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, platformPadding)
        .padding(.vertical, DS.Spacing.l)
    }

    private var platformPadding: CGFloat {
        #if os(macOS)
        return DS.Spacing.l
        #else
        return DS.Spacing.m
        #endif
    }
}

public extension InspectorPattern {
    /// Returns a new inspector pattern instance with the provided material.
    /// - Parameter material: The material to apply to the pattern background.
    /// - Returns: A new ``InspectorPattern`` retaining the existing title and content.
    func material(_ material: Material) -> InspectorPattern<Content> {
        InspectorPattern(title: title, material: material) {
            content
        }
    }
}

// MARK: - AgentDescribable Conformance

@available(iOS 17.0, macOS 14.0, *)
@MainActor
extension InspectorPattern: AgentDescribable {
    public var componentType: String {
        "InspectorPattern"
    }

    public var properties: [String: Any] {
        [
            "title": title,
            "material": String(describing: material)
        ]
    }

    public var semantics: String {
        """
        A scrollable inspector pattern displaying '\(title)' with material background. \
        Provides detailed metadata display with fixed header and scrollable content area.
        """
    }
}

// MARK: - Preview Catalogue

#Preview("Basic Inspector") {
    InspectorPattern(title: "File Details") {
        SectionHeader(title: "General")
        KeyValueRow(key: "File Name", value: "example.mp4")
        KeyValueRow(key: "Size", value: "1.2 GB")
    }
    .padding(DS.Spacing.l)
}

#Preview("Status Badges") {
    InspectorPattern(title: "Processing Status") {
        SectionHeader(title: "Checks")
        HStack(spacing: DS.Spacing.m) {
            Badge(text: "Validated", level: .success)
            Badge(text: "Warnings", level: .warning)
            Badge(text: "Errors", level: .error)
        }
    }
    .material(.regular)
    .padding(DS.Spacing.l)
}

#Preview("Dark Mode") {
    InspectorPattern(title: "Video Metadata") {
        SectionHeader(title: "Codec Information", showDivider: true)
        KeyValueRow(key: "Codec", value: "H.264")
        KeyValueRow(key: "Profile", value: "High")
        KeyValueRow(key: "Level", value: "4.1")

        SectionHeader(title: "Quality", showDivider: true)
        HStack(spacing: DS.Spacing.m) {
            Badge(text: "HD", level: .success)
            Badge(text: "1080p", level: .info)
        }
    }
    .material(.regular)
    .padding(DS.Spacing.l)
    .preferredColorScheme(.dark)
}

#Preview("Material Variants") {
    ScrollView {
        VStack(spacing: DS.Spacing.l) {
            InspectorPattern(title: "Thin Material", material: .thinMaterial) {
                KeyValueRow(key: "Material", value: "thinMaterial")
                Text("Provides subtle background separation")
                    .font(DS.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            InspectorPattern(title: "Regular Material", material: .regularMaterial) {
                KeyValueRow(key: "Material", value: "regularMaterial")
                Text("Standard background material")
                    .font(DS.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            InspectorPattern(title: "Thick Material", material: .thickMaterial) {
                KeyValueRow(key: "Material", value: "thickMaterial")
                Text("Strong background separation")
                    .font(DS.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            InspectorPattern(title: "Ultra Thin Material", material: .ultraThinMaterial) {
                KeyValueRow(key: "Material", value: "ultraThinMaterial")
                Text("Minimal background separation")
                    .font(DS.Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(DS.Spacing.l)
    }
}

#Preview("Complex Content") {
    InspectorPattern(title: "ISO Box Details") {
        SectionHeader(title: "Box Information", showDivider: true)
        KeyValueRow(key: "Type", value: "moov")
        KeyValueRow(key: "Size", value: "1,234 bytes")
        KeyValueRow(key: "Offset", value: "0x00001000")

        SectionHeader(title: "Status", showDivider: true)
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            HStack(spacing: DS.Spacing.s) {
                Badge(text: "Valid", level: .success)
                Badge(text: "Critical", level: .error)
            }
            Text("Box structure validated successfully")
                .font(DS.Typography.caption)
                .foregroundStyle(.secondary)
        }

        SectionHeader(title: "Children", showDivider: true)
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            HStack {
                Text("mvhd")
                    .font(DS.Typography.code)
                Spacer()
                Badge(text: "Header", level: .info)
            }
            HStack {
                Text("trak")
                    .font(DS.Typography.code)
                Spacer()
                Badge(text: "Track", level: .info)
            }
        }
    }
    .material(.regular)
    .padding(DS.Spacing.l)
}

#Preview("Long Scrollable Content") {
    InspectorPattern(title: "Extended Metadata") {
        ForEach(0..<20, id: \.self) { index in
            if index % 5 == 0 {
                SectionHeader(title: "Section \(index / 5 + 1)", showDivider: true)
            }
            KeyValueRow(key: "Property \(index + 1)", value: "Value \(index + 1)")
        }
    }
    .material(.regular)
    .frame(height: 400)
    .padding(DS.Spacing.l)
}

#Preview("Empty State") {
    InspectorPattern(title: "No Selection") {
        VStack(alignment: .center, spacing: DS.Spacing.l) {
            Spacer()
            Image(systemName: "doc.questionmark")
                .font(.system(size: DS.Spacing.xl * 2))
                .foregroundStyle(.secondary)
            Text("Select an item to view details")
                .font(DS.Typography.body)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    .material(.thin)
    .frame(height: 300)
    .padding(DS.Spacing.l)
}

#Preview("Platform-Specific Padding") {
    VStack(spacing: DS.Spacing.m) {
        Text("Notice different padding on macOS vs iOS")
            .font(DS.Typography.caption)
            .foregroundStyle(.secondary)

        InspectorPattern(title: "Platform Adaptive") {
            SectionHeader(title: "Platform Info")
            #if os(macOS)
            KeyValueRow(key: "Platform", value: "macOS")
            KeyValueRow(key: "Padding", value: "DS.Spacing.l (16pt)")
            #else
            KeyValueRow(key: "Platform", value: "iOS/iPadOS")
            KeyValueRow(key: "Padding", value: "DS.Spacing.m (12pt)")
            #endif
        }
        .material(.regular)
    }
    .padding(DS.Spacing.l)
}

#Preview("Dynamic Type - Small") {
    InspectorPattern(title: "File Details") {
        SectionHeader(title: "Information")
        KeyValueRow(key: "File Name", value: "video.mp4")
        KeyValueRow(key: "Duration", value: "01:23:45")
        KeyValueRow(key: "Size", value: "2.4 GB")
    }
    .material(.regular)
    .padding(DS.Spacing.l)
    .environment(\.dynamicTypeSize, .xSmall)
}

#Preview("Dynamic Type - Large") {
    InspectorPattern(title: "File Details") {
        SectionHeader(title: "Information")
        KeyValueRow(key: "File Name", value: "video.mp4")
        KeyValueRow(key: "Duration", value: "01:23:45")
        KeyValueRow(key: "Size", value: "2.4 GB")
    }
    .material(.regular)
    .padding(DS.Spacing.l)
    .environment(\.dynamicTypeSize, .xxxLarge)
}

#Preview("Real-World ISO Inspector") {
    InspectorPattern(title: "ftyp Box Inspector") {
        SectionHeader(title: "Box Header", showDivider: true)
        KeyValueRow(key: "Type", value: "ftyp")
        KeyValueRow(key: "Size", value: "32 bytes")
        KeyValueRow(key: "Offset", value: "0x00000000")

        SectionHeader(title: "File Type Data", showDivider: true)
        KeyValueRow(key: "Major Brand", value: "isom")
        KeyValueRow(key: "Minor Version", value: "0")
        KeyValueRow(key: "Compatible Brands", value: "isom, iso2, mp41")

        SectionHeader(title: "Validation", showDivider: true)
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            HStack(spacing: DS.Spacing.s) {
                Badge(text: "Valid", level: .success)
                Badge(text: "ISO 14496-12", level: .info)
            }
            Text("Box conforms to ISO base media file format specification")
                .font(DS.Typography.caption)
                .foregroundStyle(.secondary)
        }
    }
    .material(.regular)
    .padding(DS.Spacing.l)
}
