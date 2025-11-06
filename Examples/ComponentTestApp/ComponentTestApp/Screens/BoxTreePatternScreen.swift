/// BoxTreePatternScreen - Showcase for BoxTreePattern
///
/// Demonstrates the BoxTreePattern component with ISO box hierarchy.
///
/// Features:
/// - Hierarchical tree view for ISO box structure
/// - Expand/collapse nodes with animations
/// - Single and multi-select modes
/// - Large dataset test (1000+ nodes)
/// - Performance metrics display
/// - Keyboard navigation

import SwiftUI
import FoundationUI

struct BoxTreePatternScreen: View {
    /// Tree data source
    @State private var useRealData = true

    /// Selection mode
    @State private var selectionMode: TreeSelectionMode = .single

    /// Selected nodes (single mode)
    @State private var selectedNode: MockISOBox?

    /// Selected nodes (multi mode)
    @State private var selectedNodes: Set<MockISOBox> = []

    /// Tree items
    private var treeItems: [MockISOBox] {
        useRealData ? MockISOBox.sampleISOHierarchy() : MockISOBox.largeDataset()
    }

    /// Total node count
    private var totalNodes: Int {
        treeItems.reduce(0) { $0 + 1 + $1.descendantCount }
    }

    var body: some View {
        VStack(spacing: DS.Spacing.zero) {
            // Controls Section
            Card(elevation: .low, cornerRadius: DS.Radius.card, material: .regular) {
                VStack(spacing: DS.Spacing.l) {
                    SectionHeader(title: "Configuration", showDivider: false)

                    // Data source toggle
                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        Text("Data Source")
                            .font(DS.Typography.label)
                            .foregroundStyle(.secondary)

                        Picker("Data Source", selection: $useRealData) {
                            Text("ISO Sample (\(MockISOBox.sampleISOHierarchy().reduce(0) { $0 + 1 + $1.descendantCount }) nodes)")
                                .tag(true)
                            Text("Large Dataset (\(MockISOBox.largeDataset().reduce(0) { $0 + 1 + $1.descendantCount }) nodes)")
                                .tag(false)
                        }
                        .pickerStyle(.segmented)
                    }

                    // Selection mode toggle
                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        Text("Selection Mode")
                            .font(DS.Typography.label)
                            .foregroundStyle(.secondary)

                        Picker("Selection Mode", selection: $selectionMode) {
                            Text("Single").tag(TreeSelectionMode.single)
                            Text("Multiple").tag(TreeSelectionMode.multiple)
                        }
                        .pickerStyle(.segmented)
                    }

                    // Statistics
                    VStack(spacing: DS.Spacing.m) {
                        KeyValueRow(
                            key: "Total Nodes",
                            value: "\(totalNodes)",
                            isCopyable: false
                        )

                        if selectionMode == .single {
                            KeyValueRow(
                                key: "Selected",
                                value: selectedNode?.boxType ?? "None",
                                isCopyable: false
                            )
                        } else {
                            KeyValueRow(
                                key: "Selected",
                                value: "\(selectedNodes.count) nodes",
                                isCopyable: false
                            )
                        }
                    }
                }
                .padding(DS.Spacing.l)
            }
            .padding(DS.Spacing.l)

            // Tree View
            if selectionMode == .single {
                BoxTreePattern(
                    items: treeItems,
                    selection: $selectedNode
                ) { box in
                    BoxTreeNodeView(box: box)
                }
            } else {
                BoxTreePattern(
                    items: treeItems,
                    multiSelection: $selectedNodes
                ) { box in
                    BoxTreeNodeView(box: box)
                }
            }

            // Usage Tips
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                SectionHeader(title: "Usage Tips", showDivider: true)

                Label {
                    Text("Click triangles to expand/collapse nodes")
                        .font(DS.Typography.caption)
                } icon: {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(DS.Colors.accent)
                }

                Label {
                    Text("Click box name to select (single mode)")
                        .font(DS.Typography.caption)
                } icon: {
                    Image(systemName: "hand.tap")
                        .foregroundStyle(DS.Colors.accent)
                }

                Label {
                    Text("Use keyboard arrows to navigate")
                        .font(DS.Typography.caption)
                } icon: {
                    Image(systemName: "arrow.up.arrow.down")
                        .foregroundStyle(DS.Colors.accent)
                }

                Label {
                    Text("Large dataset tests lazy loading performance")
                        .font(DS.Typography.caption)
                } icon: {
                    Image(systemName: "speedometer")
                        .foregroundStyle(DS.Colors.accent)
                }
            }
            .padding(.horizontal, DS.Spacing.l)
            .padding(.vertical, DS.Spacing.l)
        }
        .navigationTitle("BoxTreePattern")
    }
}

// MARK: - Selection Mode

enum TreeSelectionMode {
    case single
    case multiple
}

// MARK: - Box Tree Node View

struct BoxTreeNodeView: View {
    let box: MockISOBox

    var body: some View {
        HStack(spacing: DS.Spacing.m) {
            // Box type badge
            Badge(
                text: box.boxType.uppercased(),
                level: box.status.badgeLevel,
                showIcon: false
            )

            // Box description
            VStack(alignment: .leading, spacing: DS.Spacing.s / 2) {
                Text(box.typeDescription)
                    .font(DS.Typography.label)

                Text(box.formattedSize)
                    .font(DS.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Child count indicator
            if box.childCount > 0 {
                Text("\(box.childCount)")
                    .font(DS.Typography.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, DS.Spacing.s)
                    .padding(.vertical, DS.Spacing.s / 2)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(DS.Radius.small)
            }
        }
    }
}

// MARK: - Previews

#Preview("Light Mode - ISO Sample") {
    NavigationStack {
        BoxTreePatternScreen()
            .preferredColorScheme(.light)
    }
}

#Preview("Dark Mode - ISO Sample") {
    NavigationStack {
        BoxTreePatternScreen()
            .preferredColorScheme(.dark)
    }
}

#Preview("Large Dataset") {
    struct PreviewWrapper: View {
        @State private var useRealData = false

        var body: some View {
            NavigationStack {
                BoxTreePatternScreen()
            }
        }
    }

    return PreviewWrapper()
}

#Preview("Multi-Selection") {
    struct PreviewWrapper: View {
        @State private var selectionMode: TreeSelectionMode = .multiple

        var body: some View {
            NavigationStack {
                BoxTreePatternScreen()
            }
        }
    }

    return PreviewWrapper()
}
