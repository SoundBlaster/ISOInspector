// swift-tools-version: 6.0
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
