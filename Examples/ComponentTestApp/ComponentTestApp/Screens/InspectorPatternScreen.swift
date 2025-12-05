/// InspectorPatternScreen - Showcase for InspectorPattern
///
/// Demonstrates the InspectorPattern component with realistic ISO box metadata display.
///
/// Features:
/// - Scrollable inspector with multiple sections
/// - Section headers with dividers
/// - KeyValueRow items with copyable text
/// - Badge components for status indicators
/// - Material background selector
/// - Sample ISO box metadata

import FoundationUI
import SwiftUI

struct InspectorPatternScreen: View {
    /// Selected material for inspector background
    @State private var selectedMaterial: SurfaceMaterial = .regular

    /// Sample ISO box data
    private let sampleBox = MockISOBox.sampleISOHierarchy()[1]  // moov box

    var body: some View {
        InspectorPattern(title: "Box Inspector") {
            VStack(spacing: 0) {
                // Material Selector Section
                SectionHeader(title: "Material", showDivider: true)

                VStack(spacing: DS.Spacing.m) {
                    Text("Select background material:").font(DS.Typography.caption).foregroundStyle(
                        .secondary
                    ).frame(maxWidth: .infinity, alignment: .leading)

                    Picker("Material", selection: $selectedMaterial) {
                        Text("Thin").tag(SurfaceMaterial.thin)
                        Text("Regular").tag(SurfaceMaterial.regular)
                        Text("Thick").tag(SurfaceMaterial.thick)
                        Text("Ultra").tag(SurfaceMaterial.ultra)
                    }.pickerStyle(.segmented)
                }.padding(.horizontal, DS.Spacing.l).padding(.bottom, DS.Spacing.l)

                // Box Information Section
                SectionHeader(title: "Box Information", showDivider: true)

                VStack(spacing: DS.Spacing.m) {
                    // Box Type with Badge
                    HStack {
                        Text("Type").font(DS.Typography.label).foregroundStyle(.secondary)

                        Spacer()

                        Badge(
                            text: sampleBox.boxType.uppercased(),
                            level: sampleBox.status.badgeLevel, showIcon: false)
                    }

                    KeyValueRow(key: "Description", value: sampleBox.typeDescription)

                    KeyValueRow(key: "Size", value: sampleBox.formattedSize, copyable: false)

                    KeyValueRow(key: "Size (hex)", value: sampleBox.hexSize, copyable: true)

                    KeyValueRow(key: "Offset", value: sampleBox.hexOffset, copyable: true)

                    KeyValueRow(key: "Children", value: "\(sampleBox.childCount)", copyable: false)
                }.padding(.horizontal, DS.Spacing.l).padding(.bottom, DS.Spacing.l)

                // Metadata Section
                if !sampleBox.metadata.isEmpty {
                    SectionHeader(title: "Metadata", showDivider: true)

                    VStack(spacing: DS.Spacing.m) {
                        ForEach(Array(sampleBox.metadata.keys.sorted()), id: \.self) { key in
                            if let value = sampleBox.metadata[key] {
                                KeyValueRow(key: key, value: value, copyable: true)
                            }
                        }
                    }.padding(.horizontal, DS.Spacing.l).padding(.bottom, DS.Spacing.l)
                }

                // Statistics Section
                SectionHeader(title: "Statistics", showDivider: true)

                VStack(spacing: DS.Spacing.m) {
                    KeyValueRow(
                        key: "Direct Children", value: "\(sampleBox.childCount)", copyable: false)

                    KeyValueRow(
                        key: "Total Descendants", value: "\(sampleBox.descendantCount)",
                        copyable: false)

                    KeyValueRow(
                        key: "Total Size (bytes)", value: "\(sampleBox.totalSize)", copyable: true)

                    KeyValueRow(
                        key: "Total Size",
                        value: ByteCountFormatter.string(
                            fromByteCount: Int64(sampleBox.totalSize), countStyle: .file),
                        copyable: false)
                }.padding(.horizontal, DS.Spacing.l).padding(.bottom, DS.Spacing.l)

                // Usage Tips Section
                SectionHeader(title: "Usage Tips", showDivider: true)

                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Label {
                        Text("Click copy icon to copy hex values").font(DS.Typography.caption)
                    } icon: {
                        Image(systemName: "doc.on.doc").foregroundStyle(DS.Colors.accent)
                    }

                    Label {
                        Text("Material affects background translucency").font(DS.Typography.caption)
                    } icon: {
                        Image(systemName: "circle.lefthalf.filled").foregroundStyle(
                            DS.Colors.accent)
                    }

                    Label {
                        Text("Toggle Dark Mode to see material effects").font(DS.Typography.caption)
                    } icon: {
                        Image(systemName: "moon.fill").foregroundStyle(DS.Colors.accent)
                    }
                }.padding(.horizontal, DS.Spacing.l).padding(.bottom, DS.Spacing.xl)
            }
        }.material(selectedMaterial.swiftUIMaterial).navigationTitle("InspectorPattern")
    }
}

// MARK: - Previews

#Preview("Light Mode") { NavigationStack { InspectorPatternScreen().preferredColorScheme(.light) } }

#Preview("Dark Mode") { NavigationStack { InspectorPatternScreen().preferredColorScheme(.dark) } }

#Preview("Thin Material") { NavigationStack { InspectorPatternScreen() } }

#Preview("Thick Material") {
    struct ThickMaterialView: View {
        @State private var material: SurfaceMaterial = .thick

        var body: some View { NavigationStack { InspectorPatternScreen() } }
    }

    return ThickMaterialView()
}
