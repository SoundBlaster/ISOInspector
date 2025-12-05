/// CardScreen - Card Component Showcase
///
/// Comprehensive demonstration of the Card component with all variations:
/// - All elevation levels (none, low, medium, high)
/// - Different corner radii
/// - Various material backgrounds
/// - Nested content examples
/// - Complex compositions
///
/// ## Component Features
/// - Generic content via @ViewBuilder
/// - Configurable elevation and corner radius
/// - Material background support
/// - Platform-adaptive shadows

import FoundationUI
import SwiftUI

// MARK: - Material Wrapper

/// Hashable wrapper for SwiftUI.Material to use with Picker
private enum MaterialOption: String, CaseIterable, Hashable {
    case thin
    case regular
    case thick

    var material: Material {
        switch self {
        case .thin: return .thin
        case .regular: return .regular
        case .thick: return .thick
        }
    }
}

struct CardScreen: View {
    @State private var selectedElevation: CardElevation = .medium
    @State private var selectedRadius: CGFloat = DS.Radius.card
    @State private var selectedMaterial: MaterialOption = .regular

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                // Component Description
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Card Component").font(DS.Typography.title)

                    Text(
                        "Container component with elevation levels, customizable corner radius, and material backgrounds."
                    ).font(DS.Typography.body).foregroundStyle(.secondary)
                }

                Divider()

                // Controls
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Controls").font(DS.Typography.subheadline)

                    Picker("Elevation", selection: $selectedElevation) {
                        Text("None").tag(CardElevation.none)
                        Text("Low").tag(CardElevation.low)
                        Text("Medium").tag(CardElevation.medium)
                        Text("High").tag(CardElevation.high)
                    }.pickerStyle(.segmented)

                    Picker("Material", selection: $selectedMaterial) {
                        Text("Thin").tag(MaterialOption.thin)
                        Text("Regular").tag(MaterialOption.regular)
                        Text("Thick").tag(MaterialOption.thick)
                    }.pickerStyle(.segmented)
                }

                Divider()

                // All Elevations
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("All Elevation Levels").font(DS.Typography.subheadline)

                    HStack(spacing: DS.Spacing.m) {
                        ForEach([CardElevation.none, .low, .medium, .high], id: \.self) {
                            elevation in
                            Card(elevation: elevation, cornerRadius: DS.Radius.card) {
                                VStack(spacing: DS.Spacing.s) {
                                    Text(elevationLabel(elevation)).font(DS.Typography.caption)
                                    Text("Card").font(DS.Typography.body)
                                }.padding(DS.Spacing.l)
                            }
                        }
                    }

                    CodeSnippetView(
                        code: """
                            Card(elevation: .medium, cornerRadius: DS.Radius.card) {
                                Text("Content")
                            }
                            """)
                }

                Divider()

                // Material Backgrounds
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Material Backgrounds").font(DS.Typography.subheadline)

                    HStack(spacing: DS.Spacing.m) {
                        ForEach(MaterialOption.allCases, id: \.self) { materialOption in
                            Card(
                                elevation: .none, cornerRadius: DS.Radius.card,
                                material: materialOption.material
                            ) {
                                VStack(spacing: DS.Spacing.s) {
                                    Text(materialOption.rawValue.capitalized).font(
                                        DS.Typography.caption)
                                    Text("Material").font(DS.Typography.body)
                                }.padding(DS.Spacing.l)
                            }
                        }
                    }

                    CodeSnippetView(
                        code: """
                            Card(material: .regular) {
                                Text("Content")
                            }
                            """)
                }

                Divider()

                // Corner Radius Variations
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Corner Radius Variations").font(DS.Typography.subheadline)

                    HStack(spacing: DS.Spacing.m) {
                        ForEach([DS.Radius.small, DS.Radius.medium, DS.Radius.card], id: \.self) {
                            radius in
                            Card(elevation: selectedElevation, cornerRadius: radius) {
                                VStack(spacing: DS.Spacing.s) {
                                    Text("\(Int(radius))pt").font(DS.Typography.caption)
                                    Text("Radius").font(DS.Typography.body)
                                }.padding(DS.Spacing.l)
                            }
                        }
                    }
                }

                Divider()

                // Nested Content
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Complex Nested Content").font(DS.Typography.subheadline)

                    Card(elevation: .medium, cornerRadius: DS.Radius.card) {
                        VStack(alignment: .leading, spacing: DS.Spacing.m) {
                            Text("ISO Box Details").font(DS.Typography.title)

                            KeyValueRow(key: "Type", value: "ftyp")
                            KeyValueRow(key: "Size", value: "32 bytes")
                            KeyValueRow(key: "Offset", value: "0x00000000")

                            HStack {
                                Badge(text: "Valid", level: .success, showIcon: true)
                                Spacer()
                                Badge(text: "ftyp", level: .info, showIcon: false)
                            }
                        }.padding(DS.Spacing.l)
                    }

                    CodeSnippetView(
                        code: """
                            Card(elevation: .medium) {
                                VStack {
                                    Text("Title")
                                    KeyValueRow(key: "Type", value: "ftyp")
                                    Badge(text: "Valid", level: .success)
                                }
                            }
                            """)
                }

                Divider()

                // Component API
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    Text("Component API").font(DS.Typography.subheadline)

                    CodeSnippetView(
                        code: """
                            Card(
                                elevation: CardElevation,       // .none, .low, .medium, .high
                                cornerRadius: CGFloat,          // DS.Radius tokens
                                material: Material,             // .thin, .regular, .thick
                                @ViewBuilder content: () -> Content
                            )
                            """)
                }
            }.padding(DS.Spacing.l)
        }.navigationTitle("Card Component")
        #if os(macOS)
            .frame(minWidth: 700, minHeight: 600)
            #endif
    }

    private func elevationLabel(_ elevation: CardElevation) -> String {
        switch elevation {
        case .none: return "None"
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

}

// MARK: - Previews

#Preview("Card Screen") { NavigationStack { CardScreen() } }

#Preview("Dark Mode") { NavigationStack { CardScreen() }.preferredColorScheme(.dark) }
