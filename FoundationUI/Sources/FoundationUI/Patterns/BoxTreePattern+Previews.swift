import SwiftUI

#if DEBUG
    // MARK: - BoxTreePattern Previews

    private struct SimpleTreePreview: View {
        struct PreviewNode: Identifiable {
            let id = UUID()
            let title: String
            var children: [PreviewNode]
        }

        @State var expandedNodes: Set<UUID> = []
        @State var selection: UUID?

        let sampleData = [
            PreviewNode(title: "ftyp", children: []),
            PreviewNode(
                title: "moov",
                children: [
                    PreviewNode(title: "mvhd", children: []),
                    PreviewNode(
                        title: "trak",
                        children: [
                            PreviewNode(title: "tkhd", children: []),
                            PreviewNode(
                                title: "mdia",
                                children: [
                                    PreviewNode(title: "mdhd", children: []),
                                    PreviewNode(title: "hdlr", children: []),
                                ]),
                        ]),
                ]), PreviewNode(title: "mdat", children: []),
        ]

        var body: some View {
            ScrollView {
                BoxTreePattern(
                    data: sampleData, children: { $0.children.isEmpty ? nil : $0.children },
                    expandedNodes: $expandedNodes, selection: $selection,
                    content: { node in
                        HStack {
                            Text(node.title).font(DS.Typography.code)
                            Spacer()
                            Badge(text: "BOX", level: .info)
                        }
                    }
                ).padding(DS.Spacing.l)
            }.frame(width: 400, height: 600)
        }
    }

    #Preview("Simple Tree") { SimpleTreePreview() }

    private struct DeepNestingPreview: View {
        struct PreviewNode: Identifiable {
            let id = UUID()
            let title: String
            let level: Int
            var children: [PreviewNode]
        }

        @State var expandedNodes: Set<UUID> = []

        func makeDeepTree(currentLevel: Int = 0, maxLevel: Int = 5) -> [PreviewNode] {
            guard currentLevel < maxLevel else { return [] }
            return [
                PreviewNode(
                    title: "Level \(currentLevel)", level: currentLevel,
                    children: makeDeepTree(currentLevel: currentLevel + 1, maxLevel: maxLevel))
            ]
        }

        var body: some View {
            let deepData = makeDeepTree()

            ScrollView {
                BoxTreePattern(
                    data: deepData, children: { $0.children.isEmpty ? nil : $0.children },
                    expandedNodes: $expandedNodes,
                    content: { node in Text(node.title).font(DS.Typography.body) }
                ).padding(DS.Spacing.l)
            }.frame(width: 400, height: 600)
        }
    }

    #Preview("Deep Nesting") { DeepNestingPreview() }

    private struct MultiSelectionPreview: View {
        struct PreviewNode: Identifiable {
            let id = UUID()
            let title: String
            var children: [PreviewNode]
        }

        @State var expandedNodes: Set<UUID> = []
        @State var selection: Set<UUID> = []

        let sampleData = [
            PreviewNode(
                title: "Root 1",
                children: [
                    PreviewNode(title: "Child 1.1", children: []),
                    PreviewNode(title: "Child 1.2", children: []),
                ]),
            PreviewNode(title: "Root 2", children: [PreviewNode(title: "Child 2.1", children: [])]),
        ]

        var body: some View {
            VStack(alignment: .leading) {
                Text("Selected: \(selection.count) nodes").font(DS.Typography.caption)
                    .foregroundStyle(.secondary).padding(.horizontal, DS.Spacing.l)

                ScrollView {
                    BoxTreePattern(
                        data: sampleData, children: { $0.children.isEmpty ? nil : $0.children },
                        expandedNodes: $expandedNodes, multiSelection: $selection,
                        content: { node in Text(node.title).font(DS.Typography.body) }
                    ).padding(DS.Spacing.l)
                }
            }.frame(width: 400, height: 600)
        }
    }

    #Preview("Multi-Selection") { MultiSelectionPreview() }

    private struct LargeTreePreview: View {
        struct PreviewNode: Identifiable {
            let id = UUID()
            let title: String
            var children: [PreviewNode]
        }

        @State var expandedNodes: Set<UUID> = []

        var body: some View {
            // Generate 100 root nodes with 10 children each (1000+ total nodes)
            let largeData = (0..<100).map { i in
                PreviewNode(
                    title: "Node \(i)",
                    children: (0..<10).map { j in
                        PreviewNode(title: "Child \(i).\(j)", children: [])
                    })
            }

            VStack(alignment: .leading) {
                Text("1000+ nodes (lazy rendering)").font(DS.Typography.caption).foregroundStyle(
                    .secondary
                ).padding(.horizontal, DS.Spacing.l)

                ScrollView {
                    BoxTreePattern(
                        data: largeData, children: { $0.children.isEmpty ? nil : $0.children },
                        expandedNodes: $expandedNodes,
                        content: { node in Text(node.title).font(DS.Typography.body) }
                    ).padding(DS.Spacing.l)
                }
            }.frame(width: 400, height: 600)
        }
    }

    #Preview("Large Tree (Performance)") { LargeTreePreview() }

    private struct DarkModePreview: View {
        struct PreviewNode: Identifiable {
            let id = UUID()
            let title: String
            var children: [PreviewNode]
        }

        @State var expandedNodes: Set<UUID> = []
        @State var selection: UUID?

        let sampleData = [
            PreviewNode(title: "ftyp", children: []),
            PreviewNode(
                title: "moov",
                children: [
                    PreviewNode(title: "mvhd", children: []),
                    PreviewNode(title: "trak", children: []),
                ]),
        ]

        var body: some View {
            ScrollView {
                BoxTreePattern(
                    data: sampleData, children: { $0.children.isEmpty ? nil : $0.children },
                    expandedNodes: $expandedNodes, selection: $selection,
                    content: { node in Text(node.title).font(DS.Typography.code) }
                ).padding(DS.Spacing.l)
            }.frame(width: 400, height: 600).preferredColorScheme(.dark)
        }
    }

    #Preview("Dark Mode") { DarkModePreview() }

#endif
