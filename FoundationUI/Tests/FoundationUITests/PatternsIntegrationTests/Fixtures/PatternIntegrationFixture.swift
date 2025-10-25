// swift-tools-version: 6.0
import SwiftUI
@testable import FoundationUI

/// Fixture coordinating Sidebar, Inspector, and Toolbar patterns for integration tests.
@MainActor
struct PatternIntegrationFixture {
    struct Document: Hashable, Identifiable {
        let id: String
        let title: String
        let iconSystemName: String
    }

    private(set) var documents: [Document]
    private var documentIndexByID: [String: Int]

    private var selectionStore: SelectionStore

    var selection: String? { selectionStore.selection }
    var selectionBinding: Binding<String?> { selectionStore.binding }
    var accessibilityAnnouncements: [String] { selectionStore.announcements }

    init(documents: [Document]) {
        self.documents = documents
        self.documentIndexByID = Dictionary(uniqueKeysWithValues: documents.enumerated().map { ($1.id, $0) })
        self.selectionStore = SelectionStore()
    }

    mutating func configureInitialSelection(_ identifier: String?) {
        selectionStore.selection = identifier
    }

    func makeSidebarPattern() -> SidebarPattern<String, InspectorPattern<PatternContent>> {
        SidebarPattern(
            sections: [SidebarPattern<String, InspectorPattern<PatternContent>>.Section(
                title: "Library",
                items: documents.map { document in
                    SidebarPattern<String, InspectorPattern<PatternContent>>.Item(
                        id: document.id,
                        title: document.title,
                        iconSystemName: document.iconSystemName,
                        accessibilityLabel: "Open \(document.title)"
                    )
                }
            )],
            selection: selectionBinding
        ) { identifier in
            let detail = makeInspectorContent(for: identifier)
            return InspectorPattern(title: detail.title, material: .regular) {
                PatternContent(
                    documentTitle: detail.title,
                    subtitle: detail.subtitle,
                    toolbar: makeToolbar(for: identifier)
                )
            }
        }
    }

    func makeInspectorContent(for identifier: String?) -> (title: String, subtitle: String) {
        guard
            let identifier,
            let index = documentIndexByID[identifier]
        else {
            return (title: "No Selection", subtitle: "Select an item to inspect")
        }

        let document = documents[index]
        return (
            title: document.title,
            subtitle: "Document ID: \(document.id)"
        )
    }

    func makeToolbar(for identifier: String?) -> ToolbarPattern {
        let binding = selectionBinding
        _ = identifier

        return ToolbarPattern(
            items: ToolbarPattern.Items(
                primary: [
                    .init(
                        id: "select.next",
                        iconSystemName: "arrow.down.circle",
                        title: "Next",
                        accessibilityHint: "Select the next document",
                        role: .primaryAction,
                        shortcut: .init(key: "j", modifiers: [.command])
                    ) { [documents, documentIndexByID, binding] in
                        guard
                            let current = binding.wrappedValue,
                            let currentIndex = documentIndexByID[current]
                        else {
                            binding.wrappedValue = documents.first?.id
                            return
                        }

                        let nextIndex = documents.index(after: currentIndex)
                        if nextIndex < documents.endIndex {
                            binding.wrappedValue = documents[nextIndex].id
                        }
                    },
                ],
                secondary: [
                    .init(
                        id: "announce.metadata",
                        iconSystemName: "speaker.wave.2.fill",
                        title: "Announce",
                        accessibilityHint: "Read the current inspector metadata",
                        role: .neutral
                    ) { [selectionStore, binding] in
                        let message: String
                        if let identifier = binding.wrappedValue {
                            message = "Inspector metadata updated for \(identifier)"
                        } else {
                            message = "Inspector metadata unavailable"
                        }

                        selectionStore.recordAnnouncement(message: message)
                    }
                ],
                overflow: [
                    .init(
                        id: "archive",
                        iconSystemName: "archivebox",
                        title: "Archive",
                        accessibilityHint: "Archive the current document",
                        role: .destructive,
                        shortcut: .init(key: "a", modifiers: [.command])
                    )
                ]
            ),
            layoutOverride: .expanded
        )
    }
}

// MARK: - Supporting Types

@MainActor
private final class SelectionStore {
    var selection: String?
    private(set) var announcements: [String] = []

    private(set) lazy var binding: Binding<String?> = Binding(
        get: { [weak self] in self?.selection },
        set: { [weak self] newValue in self?.selection = newValue }
    )

    func recordAnnouncement(message: String) {
        announcements.append(message)
    }
}

struct PatternContent: View {
    let documentTitle: String
    let subtitle: String
    let toolbar: ToolbarPattern

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.l) {
            Text(documentTitle)
                .font(DS.Typography.title)
                .accessibilityLabel(Text(documentTitle))
            Text(subtitle)
                .font(DS.Typography.body)
                .foregroundStyle(DS.Color.textSecondary)
            toolbar
        }
        .padding(DS.Spacing.l)
        .accessibilityElement(children: .contain)
    }
}
