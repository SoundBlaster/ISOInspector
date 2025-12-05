// swiftlint:disable file_length

import FoundationUI
import SwiftUI

#if os(macOS)
    import AppKit
#else
    import UIKit
#endif

/// ISO Inspector Demo Screen showcasing full pattern integration
struct ISOInspectorDemoScreen: View {
    // MARK: - State

    /// Currently selected ISO box ID
    @State private var selectedBoxID: UUID?

    /// Expanded box IDs in the tree
    @State private var expandedBoxIDs: Set<UUID> = []

    /// Current filter text
    @State private var filterText: String = ""

    /// Show action result alert
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    /// Sample ISO data
    @State private var isoBoxes: [MockISOBox] = MockISOBox.sampleISOHierarchy()

    // MARK: - Computed Properties

    /// Currently selected box (derived from selectedBoxID)
    private var selectedBox: MockISOBox? {
        guard let id = selectedBoxID else { return nil }
        return findBox(withID: id, in: isoBoxes)
    }

    /// Filtered boxes based on search text
    private var filteredBoxes: [MockISOBox] {
        guard !filterText.isEmpty else { return isoBoxes }

        func matchesFilter(_ box: MockISOBox) -> Bool {
            box.boxType.lowercased().contains(filterText.lowercased())
                || box.typeDescription.lowercased().contains(filterText.lowercased())
        }

        func filterRecursive(_ boxes: [MockISOBox]) -> [MockISOBox] {
            boxes.compactMap { box in
                let childrenMatch = filterRecursive(box.children)
                if matchesFilter(box) || !childrenMatch.isEmpty {
                    return MockISOBox(
                        id: box.id, boxType: box.boxType, size: box.size, offset: box.offset,
                        children: childrenMatch, metadata: box.metadata, status: box.status)
                }
                return nil
            }
        }

        return filterRecursive(isoBoxes)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbarView.padding(.horizontal, DS.Spacing.m).padding(.vertical, DS.Spacing.s)
                .background(DS.Colors.tertiary)

            Divider()

            // Main content area
            #if os(macOS)
                macOSLayout
            #else
                iOSLayout
            #endif
        }.navigationTitle("ISO Inspector Demo").alert(
            "Action Performed",
            isPresented: $showAlert,
            actions: {
                Button("OK", role: .cancel, action: {})
            },
            message: {
                Text(alertMessage)
            }
        )
    }
}

extension ISOInspectorDemoScreen {

    // MARK: - Toolbar

    private var toolbarView: some View {
        HStack(spacing: DS.Spacing.m) {
            // Search field
            HStack(spacing: DS.Spacing.s) {
                Image(systemName: "magnifyingglass").foregroundColor(DS.Colors.textSecondary)

                TextField("Filter boxes...", text: $filterText).textFieldStyle(.plain).font(
                    DS.Typography.body)

                if !filterText.isEmpty {
                    Button(
                        action: { filterText = "" },
                        label: {
                            Image(systemName: "xmark.circle.fill").foregroundColor(
                                DS.Colors.textSecondary)
                        }
                    ).buttonStyle(.plain)
                }
            }.padding(.horizontal, DS.Spacing.m).padding(.vertical, DS.Spacing.s).background(
                DS.Colors.secondary
            ).cornerRadius(DS.Radius.small)

            Spacer()

            // Action buttons
            Button(action: openFileAction, label: { Label("Open", systemImage: "folder.fill") })
                .keyboardShortcut("o", modifiers: .command)

            Button(action: copyAction, label: { Label("Copy", systemImage: "doc.on.doc.fill") })
                .keyboardShortcut("c", modifiers: .command).disabled(selectedBox == nil)

            Button(
                action: exportAction,
                label: { Label("Export", systemImage: "square.and.arrow.up.fill") }
            ).keyboardShortcut("e", modifiers: .command).disabled(selectedBox == nil)

            Button(action: refreshAction, label: { Label("Refresh", systemImage: "arrow.clockwise") })
                .keyboardShortcut("r", modifiers: .command)
        }.font(DS.Typography.body)
    }
}

extension ISOInspectorDemoScreen {

    // MARK: - macOS Layout (Three-column)

    #if os(macOS)
        private var macOSLayout: some View {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // Left sidebar (file list)
                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        Text("Files").font(DS.Typography.headline).padding(
                            .horizontal, DS.Spacing.m
                        ).padding(.top, DS.Spacing.m)

                        List {
                            Label("sample_video.mp4", systemImage: "film.fill").foregroundColor(
                                DS.Colors.accent)
                            Label("test_audio.m4a", systemImage: "music.note")
                            Label("demo.mov", systemImage: "video.fill")
                        }.listStyle(.sidebar)
                    }.frame(width: geometry.size.width * 0.2).background(DS.Colors.tertiary)

                    Divider()

                    // Center: Box tree
                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        Text("ISO Box Structure").font(DS.Typography.headline).padding(
                            .horizontal, DS.Spacing.m
                        ).padding(.top, DS.Spacing.m)

                        if filteredBoxes.isEmpty {
                            emptyStateView
                        } else {
                            BoxTreePattern(
                                data: filteredBoxes,
                                children: { $0.children.isEmpty ? nil : $0.children },
                                expandedNodes: $expandedBoxIDs,
                                selection: $selectedBoxID,
                                content: { box in
                                    HStack(spacing: DS.Spacing.s) {
                                        Badge(
                                            text: box.boxType, level: box.status.badgeLevel,
                                            showIcon: false)

                                        Text(box.typeDescription).font(DS.Typography.body)

                                        Spacer()

                                        Text(box.formattedSize).font(DS.Typography.caption)
                                            .foregroundColor(DS.Colors.textSecondary)
                                    }
                                }
                            )
                        }
                    }.frame(width: geometry.size.width * 0.4)

                    Divider()

                    // Right: Inspector
                    inspectorView.frame(width: geometry.size.width * 0.4)
                }
            }
        }
    #endif
}

extension ISOInspectorDemoScreen {

    // MARK: - iOS/iPadOS Layout (Adaptive)

    #if !os(macOS)
    private var iOSLayout: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Box tree
                if filteredBoxes.isEmpty {
                    emptyStateView
                } else {
                    BoxTreePattern(
                        data: filteredBoxes,
                        children: { $0.children.isEmpty ? nil : $0.children },
                        expandedNodes: $expandedBoxIDs,
                        selection: $selectedBoxID,
                        content: { box in
                            HStack(spacing: DS.Spacing.s) {
                                Badge(
                                    text: box.boxType, level: box.status.badgeLevel,
                                    showIcon: false
                                )

                                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                                    Text(box.typeDescription).font(DS.Typography.body)

                                    Text(box.formattedSize).font(DS.Typography.caption)
                                        .foregroundColor(DS.Colors.textSecondary)
                                }

                                Spacer()
                            }
                        }
                    )
                }
            }
        }.sheet(
            isPresented: Binding(
                get: { selectedBoxID != nil }, set: { if !$0 { selectedBoxID = nil } })
        ) {
            NavigationStack {
                inspectorView.navigationTitle("Box Details").navigationBarTitleDisplayMode(
                    .inline
                ).toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { selectedBoxID = nil }
                    }
                }
            }
        }
    }
    #endif
}

extension ISOInspectorDemoScreen {
    // MARK: - Inspector View

    @ViewBuilder private var inspectorView: some View {
        if let box = selectedBox {
            InspectorPattern(title: "Box Details") {
                // Basic Information
                SectionHeader(title: "Basic Information", showDivider: true)

                KeyValueRow(key: "Type", value: box.boxType).copyable(text: box.boxType)

                KeyValueRow(key: "Description", value: box.typeDescription)

                KeyValueRow(key: "Size", value: "\(box.size) bytes")

                KeyValueRow(key: "Formatted Size", value: box.formattedSize)

                KeyValueRow(key: "Offset", value: box.hexOffset).copyable(text: box.hexOffset)

                // Status
                SectionHeader(title: "Status", showDivider: true)

                HStack {
                    Text("Status").font(DS.Typography.label).foregroundColor(
                        DS.Colors.textSecondary)

                    Spacer()

                    Badge(
                        text: statusText(for: box.status), level: box.status.badgeLevel,
                        showIcon: true)
                }.padding(.vertical, DS.Spacing.s)

                // Hierarchy
                if !box.children.isEmpty {
                    SectionHeader(title: "Hierarchy", showDivider: true)

                    KeyValueRow(key: "Children", value: "\(box.childCount)")
                    KeyValueRow(key: "Total Descendants", value: "\(box.descendantCount)")
                    KeyValueRow(key: "Total Size", value: box.formattedSize)
                }

                // Metadata
                if !box.metadata.isEmpty {
                    SectionHeader(title: "Metadata", showDivider: true)

                    ForEach(Array(box.metadata.sorted(by: { $0.key < $1.key })), id: \.key) {
                        key, value in KeyValueRow(key: key, value: value).copyable(text: value)
                    }
                }
            }.material(.regular)
        } else {
            // Empty state
            VStack(spacing: DS.Spacing.l) {
                Image(systemName: "square.dashed").font(.system(size: 64)).foregroundColor(
                    DS.Colors.textSecondary)

                Text("No Box Selected").font(DS.Typography.title).foregroundColor(
                    DS.Colors.textPrimary)

                Text("Select a box from the tree to view its details").font(DS.Typography.body)
                    .foregroundColor(DS.Colors.textSecondary).multilineTextAlignment(.center)
            }.padding(DS.Spacing.xl).frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

extension ISOInspectorDemoScreen {
    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: DS.Spacing.l) {
            Image(systemName: "magnifyingglass").font(.system(size: 48)).foregroundColor(
                DS.Colors.textSecondary)

            Text("No Results").font(DS.Typography.title).foregroundColor(DS.Colors.textPrimary)

            Text("Try a different search term").font(DS.Typography.body).foregroundColor(
                DS.Colors.textSecondary)

            Button("Clear Filter") { filterText = "" }.padding(.top, DS.Spacing.m)
        }.padding(DS.Spacing.xl).frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension ISOInspectorDemoScreen {
    // MARK: - Actions

    private func openFileAction() {
        alertMessage = "Open File action triggered\nKeyboard shortcut: ⌘O"
        showAlert = true
    }

    private func copyAction() {
        guard let box = selectedBox else { return }

        #if os(macOS)
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(box.boxType, forType: .string)
        #else
            UIPasteboard.general.string = box.boxType
        #endif

        alertMessage = "Copied '\(box.boxType)' to clipboard\nKeyboard shortcut: ⌘C"
        showAlert = true
    }

    private func exportAction() {
        guard let box = selectedBox else { return }
        alertMessage = "Export '\(box.boxType)' action triggered\nKeyboard shortcut: ⌘E"
        showAlert = true
    }

    private func refreshAction() {
        // Regenerate sample data
        isoBoxes = MockISOBox.sampleISOHierarchy()
        selectedBoxID = nil
        expandedBoxIDs.removeAll()
        filterText = ""

        alertMessage = "Data refreshed\nKeyboard shortcut: ⌘R"
        showAlert = true
    }
}

extension ISOInspectorDemoScreen {
    // MARK: - Helpers

    /// Recursively find a box by ID in the hierarchy
    private func findBox(withID id: UUID, in boxes: [MockISOBox]) -> MockISOBox? {
        for box in boxes {
            if box.id == id { return box }
            if let found = findBox(withID: id, in: box.children) { return found }
        }
        return nil
    }

    private func statusText(for status: MockISOBox.BoxStatus) -> String {
        switch status {
        case .normal: return "Normal"
        case .warning: return "Warning"
        case .error: return "Error"
        case .highlighted: return "Highlighted"
        }
    }
}

// MARK: - Previews

#Preview("ISO Inspector Demo - Light") {
    NavigationStack { ISOInspectorDemoScreen() }.preferredColorScheme(.light)
}

#Preview("ISO Inspector Demo - Dark") {
    NavigationStack { ISOInspectorDemoScreen() }.preferredColorScheme(.dark)
}

// swiftlint:enable file_length
