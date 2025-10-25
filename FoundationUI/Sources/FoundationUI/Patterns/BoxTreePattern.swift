// swift-tools-version: 6.0
import SwiftUI

/// Renders a hierarchical tree of ISO boxes with expand/collapse controls and selection handling.
public struct BoxTreePattern<ID: Hashable>: View {
    @Binding private var selection: Set<ID>
    @StateObject private var controller: BoxTreeController<ID>

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    /// Creates the pattern with the specified tree nodes and selection binding.
    /// - Parameters:
    ///   - nodes: Root nodes that represent the ISO structure to display.
    ///   - selection: Binding to the selected node identifiers.
    ///   - allowsMultipleSelection: When `true`, enables multi-select interactions.
    public init(
        nodes: [BoxTreeNode<ID>],
        selection: Binding<Set<ID>>,
        allowsMultipleSelection: Bool = true
    ) {
        _selection = selection
        _controller = StateObject(wrappedValue: BoxTreeController(
            nodes: nodes,
            allowsMultipleSelection: allowsMultipleSelection,
            initialSelection: selection.wrappedValue
        ))
    }

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DS.Spacing.s) {
                ForEach(controller.visibleNodes) { visibleNode in
                    row(for: visibleNode)
                }
            }
            .padding(DS.Spacing.m)
        }
        .background(DS.Color.surfaceBackground)
        .onChange(of: controller.selection) { newValue in
            if selection != newValue {
                selection = newValue
            }
        }
        .onChange(of: selection) { newValue in
            if controller.selection != newValue {
                controller.setSelection(newValue)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Box Tree"))
    }

    @ViewBuilder
    private func row(for visibleNode: BoxTreeController<ID>.VisibleNode) -> some View {
        let node = visibleNode.node
        let isSelected = controller.selection.contains(node.id)
        let indentation = controller.indentation(forDepth: visibleNode.depth)

        HStack(spacing: DS.Spacing.s) {
            if !node.isLeaf {
                Button {
                    performAnimatedToggle(for: node.id)
                } label: {
                    Image(systemName: visibleNode.isExpanded ? "chevron.down" : "chevron.right")
                        .font(DS.Typography.icon)
                        .foregroundStyle(DS.Color.textPrimary)
                        .accessibilityLabel(Text(visibleNode.isExpanded ? "Collapse" : "Expand"))
                }
                .buttonStyle(.plain)
            } else {
                Spacer()
                    .frame(width: DS.Spacing.s)
            }

            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text(node.title)
                    .font(DS.Typography.body)
                    .foregroundStyle(DS.Color.textPrimary)
                if let subtitle = node.subtitle {
                    Text(subtitle)
                        .font(DS.Typography.caption)
                        .foregroundStyle(DS.Color.textSecondary.opacity(DS.Opacity.subtleText))
                }
            }
            .padding(.vertical, DS.Spacing.xs)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, indentation)
        .padding(.horizontal, DS.Spacing.s)
        .padding(.vertical, DS.Spacing.xs)
        .background(isSelected ? DS.Color.selectionBackground : Color.clear)
        .cornerRadius(DS.Radius.small)
        .contentShape(Rectangle())
        .onTapGesture {
            performSelection(for: node.id)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(node.title))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func performAnimatedToggle(for id: ID) {
        if let animation = DS.Animation.resolvedQuick(prefersReducedMotion: reduceMotion) {
            withAnimation(animation) {
                controller.toggleExpansion(for: id)
            }
        } else {
            controller.toggleExpansion(for: id)
        }
    }

    private func performSelection(for id: ID) {
        controller.select(id)
        selection = controller.selection
    }
}

// MARK: - Preview Catalogue

private enum BoxTreePreviewData {
    static var nodes: [BoxTreeNode<UUID>] {
        let fileType = BoxTreeNode(id: UUID(), title: "ftyp", subtitle: "File Type Box")
        let mvhd = BoxTreeNode(id: UUID(), title: "mvhd", subtitle: "Movie Header")
        let trak = BoxTreeNode(id: UUID(), title: "trak", subtitle: "Track Box")
        let moov = BoxTreeNode(id: UUID(), title: "moov", subtitle: "Movie Box", children: [mvhd, trak])
        let root = BoxTreeNode(id: UUID(), title: "ISO File", subtitle: "1.2 MB", children: [fileType, moov])
        return [root]
    }
}

#Preview("BoxTreePattern – Light") {
    BoxTreePattern(
        nodes: BoxTreePreviewData.nodes,
        selection: .constant([])
    )
    .padding(DS.Spacing.l)
}

#Preview("BoxTreePattern – Dark") {
    BoxTreePattern(
        nodes: BoxTreePreviewData.nodes,
        selection: .constant([])
    )
    .padding(DS.Spacing.l)
    .preferredColorScheme(.dark)
}
