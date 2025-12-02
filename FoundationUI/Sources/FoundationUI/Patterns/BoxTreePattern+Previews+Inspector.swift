import SwiftUI

#if DEBUG
    // MARK: - BoxTreePattern Inspector & Accessibility Previews

    private struct WithInspectorPatternPreview: View {
        struct PreviewNode: Identifiable {
            let id = UUID()
            let name: String
            let type: String
            let offset: String
            var children: [PreviewNode]
        }

        @State var expandedNodes: Set<UUID> = []
        @State var selection: UUID?

        let sampleData = [
            PreviewNode(name: "ftyp", type: "File Type", offset: "0x0000", children: []),
            PreviewNode(
                name: "moov", type: "Movie", offset: "0x0020",
                children: [
                    PreviewNode(name: "mvhd", type: "Movie Header", offset: "0x0028", children: []),
                    PreviewNode(name: "trak", type: "Track", offset: "0x0068", children: []),
                ]),
        ]

        var body: some View {
            HStack(spacing: 0) {
                // Tree view
                ScrollView {
                    BoxTreePattern(
                        data: sampleData, children: { $0.children.isEmpty ? nil : $0.children },
                        expandedNodes: $expandedNodes, selection: $selection,
                        content: { node in
                            HStack {
                                Text(node.name).font(DS.Typography.code)
                                Spacer()
                                Badge(text: node.type.prefix(3).uppercased(), level: .info)
                            }
                        }
                    ).padding(DS.Spacing.l)
                }.frame(width: 300)

                Divider()

                // Inspector view
                if let selectedId = selection,
                    let selectedNode = findNode(id: selectedId, in: sampleData)
                {
                    InspectorPattern(title: "Box Details") {
                        SectionHeader(title: "Information")
                        KeyValueRow(key: "Name", value: selectedNode.name)
                        KeyValueRow(key: "Type", value: selectedNode.type)
                        KeyValueRow(key: "Offset", value: selectedNode.offset)
                    }.frame(width: 300)
                } else {
                    Text("Select a box to view details").font(DS.Typography.body).foregroundStyle(
                        .secondary
                    ).frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }.frame(width: 600, height: 600)
        }

        private func findNode(id: UUID, in nodes: [PreviewNode]) -> PreviewNode? {
            for node in nodes {
                if node.id == id { return node }
                if let found = findNode(id: id, in: node.children) { return found }
            }
            return nil
        }
    }

    #Preview("With Inspector Pattern") { WithInspectorPatternPreview() }

    private struct DynamicTypeSmallPreview: View {
        struct PreviewNode: Identifiable {
            let id = UUID()
            let title: String
            var children: [PreviewNode]
        }

        @State var expandedNodes: Set<UUID> = []

        let sampleData = [
            PreviewNode(
                title: "Root 1",
                children: [
                    PreviewNode(title: "Child 1.1", children: []),
                    PreviewNode(title: "Child 1.2", children: []),
                ]), PreviewNode(title: "Root 2", children: []),
        ]

        var body: some View {
            ScrollView {
                BoxTreePattern(
                    data: sampleData, children: { $0.children.isEmpty ? nil : $0.children },
                    expandedNodes: $expandedNodes,
                    content: { node in Text(node.title).font(DS.Typography.body) }
                ).padding(DS.Spacing.l)
            }.frame(width: 400, height: 600).environment(\.dynamicTypeSize, .xSmall)
        }
    }

    #Preview("Dynamic Type - Small") { DynamicTypeSmallPreview() }

    private struct DynamicTypeLargePreview: View {
        struct PreviewNode: Identifiable {
            let id = UUID()
            let title: String
            var children: [PreviewNode]
        }

        @State var expandedNodes: Set<UUID> = []

        let sampleData = [
            PreviewNode(
                title: "Root Node", children: [PreviewNode(title: "Child Node", children: [])])
        ]

        var body: some View {
            ScrollView {
                BoxTreePattern(
                    data: sampleData, children: { $0.children.isEmpty ? nil : $0.children },
                    expandedNodes: $expandedNodes,
                    content: { node in Text(node.title).font(DS.Typography.body) }
                ).padding(DS.Spacing.l)
            }.frame(width: 500, height: 600).environment(\.dynamicTypeSize, .xxxLarge)
        }
    }

    #Preview("Dynamic Type - Large") { DynamicTypeLargePreview() }

    private struct EmptyTreePreview: View {
        struct PreviewNode: Identifiable {
            let id = UUID()
            let title: String
            var children: [PreviewNode]
        }

        @State var expandedNodes: Set<UUID> = []

        let emptyData: [PreviewNode] = []

        var body: some View {
            VStack(spacing: DS.Spacing.l) {
                Text("Empty tree state").font(DS.Typography.caption).foregroundStyle(.secondary)

                ScrollView {
                    if emptyData.isEmpty {
                        VStack(spacing: DS.Spacing.l) {
                            Image(systemName: "tray").font(.system(size: DS.Spacing.xl * 2))
                                .foregroundStyle(.secondary)
                            Text("No items in tree").font(DS.Typography.body).foregroundStyle(
                                .secondary)
                        }.frame(maxWidth: .infinity, maxHeight: .infinity).padding(DS.Spacing.xl)
                    } else {
                        BoxTreePattern(
                            data: emptyData, children: { $0.children.isEmpty ? nil : $0.children },
                            expandedNodes: $expandedNodes,
                            content: { node in Text(node.title).font(DS.Typography.body) })
                    }
                }
            }.frame(width: 400, height: 400)
        }
    }

    #Preview("Empty Tree") { EmptyTreePreview() }

    private struct FlatListPreview: View {
        struct PreviewNode: Identifiable {
            let id = UUID()
            let title: String
            var children: [PreviewNode]
        }

        @State var expandedNodes: Set<UUID> = []
        @State var selection: UUID?

        let flatData = [
            PreviewNode(title: "Item 1", children: []), PreviewNode(title: "Item 2", children: []),
            PreviewNode(title: "Item 3", children: []), PreviewNode(title: "Item 4", children: []),
            PreviewNode(title: "Item 5", children: []),
        ]

        var body: some View {
            ScrollView {
                BoxTreePattern(
                    data: flatData, children: { $0.children.isEmpty ? nil : $0.children },
                    expandedNodes: $expandedNodes, selection: $selection
                ) { node in
                    HStack {
                        Text(node.title).font(DS.Typography.body)
                        Spacer()
                        Badge(text: "ITEM", level: .info)
                    }
                }.padding(DS.Spacing.l)
            }.frame(width: 400, height: 600)
        }
    }

    #Preview("Flat List (No Nesting)") { FlatListPreview() }
#endif
