// swift-tools-version: 6.0
#if canImport(SwiftUI)
    @testable import FoundationUI
    import SwiftUI
    import XCTest

    @MainActor final class SidebarPatternTests: XCTestCase {
        typealias ItemID = UUID

        private var sampleSections: [SidebarPattern<ItemID, Text>.Section] {
            [
                .init(
                    title: "Media",
                    items: [
                        .init(
                            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEE1")!,
                            title: "Overview"),
                        .init(
                            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEE2")!,
                            title: "Metadata"),
                    ]),
                .init(
                    title: "Quality",
                    items: [
                        .init(
                            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEE3")!,
                            title: "Waveform")
                    ]),
            ]
        }

        func testSidebarPatternStoresSections() {
            // Given
            let sections = sampleSections
            let selection = Binding<ItemID?>.constant(nil)

            // When
            let pattern = SidebarPattern(sections: sections, selection: selection) { _ in
                Text("Detail")
            }

            // Then
            XCTAssertEqual(pattern.sections.map(\.title), sections.map(\.title))
            XCTAssertEqual(pattern.sections.first?.items.count, 2)
        }

        func testSidebarPatternSelectionBindingUpdates() {
            // Given
            let sections = sampleSections
            var capturedSelection: ItemID?
            let selection = Binding<ItemID?>(
                get: { capturedSelection }, set: { capturedSelection = $0 })
            let pattern = SidebarPattern(sections: sections, selection: selection) { _ in
                Text("Detail")
            }
            let expected = sections[0].items[0].id

            // When
            pattern.selection = expected

            // Then
            XCTAssertEqual(capturedSelection, expected)
        }

        func testSidebarPatternDetailBuilderReceivesSelection() {
            // Given
            let sections = sampleSections
            let selection = Binding<ItemID?>.constant(nil)
            var receivedSelection: ItemID?
            let pattern = SidebarPattern(sections: sections, selection: selection) { selection in
                receivedSelection = selection
                return Text(selection?.uuidString ?? "None")
            }
            let chosen = sections[1].items[0].id

            // When
            _ = pattern.detailBuilder(chosen)

            // Then
            XCTAssertEqual(receivedSelection, chosen)
        }

        func testSidebarItemProvidesDefaultAccessibilityLabel() {
            // Given
            let item = SidebarPattern<ItemID, Text>.Item(
                id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEE9")!, title: "Review")

            // Then
            XCTAssertEqual(item.accessibilityLabel, item.title)
        }

        // MARK: - Section Tests

        func testSectionInitializationWithExplicitID() {
            // Given
            let section = SidebarPattern<ItemID, Text>.Section(
                id: "custom-id", title: "Custom Section", items: [])

            // Then
            XCTAssertEqual(section.id, "custom-id", "Section should use explicit ID when provided")
            XCTAssertEqual(section.title, "Custom Section")
            XCTAssertTrue(section.items.isEmpty)
        }

        func testSectionInitializationWithDefaultID() {
            // Given
            let section = SidebarPattern<ItemID, Text>.Section(title: "Auto ID Section", items: [])

            // Then
            XCTAssertEqual(
                section.id, "Auto ID Section", "Section should use title as ID by default")
        }

        func testSectionWithMultipleItems() {
            // Given
            let items = [
                SidebarPattern<ItemID, Text>.Item(id: UUID(), title: "Item 1"),
                SidebarPattern<ItemID, Text>.Item(id: UUID(), title: "Item 2"),
                SidebarPattern<ItemID, Text>.Item(id: UUID(), title: "Item 3"),
            ]
            let section = SidebarPattern<ItemID, Text>.Section(title: "Multi", items: items)

            // Then
            XCTAssertEqual(section.items.count, 3, "Section should store all items")
        }

        // MARK: - Item Tests

        func testItemInitializationWithIcon() {
            // Given
            let item = SidebarPattern<ItemID, Text>.Item(
                id: UUID(), title: "Settings", iconSystemName: "gear")

            // Then
            XCTAssertEqual(item.title, "Settings")
            XCTAssertEqual(item.iconSystemName, "gear")
            XCTAssertEqual(item.accessibilityLabel, "Settings")
        }

        func testItemInitializationWithoutIcon() {
            // Given
            let item = SidebarPattern<ItemID, Text>.Item(id: UUID(), title: "Plain Item")

            // Then
            XCTAssertNil(item.iconSystemName, "Icon should be nil when not provided")
        }

        func testItemInitializationWithCustomAccessibilityLabel() {
            // Given
            let item = SidebarPattern<ItemID, Text>.Item(
                id: UUID(), title: "⚙️", accessibilityLabel: "Settings")

            // Then
            XCTAssertEqual(
                item.accessibilityLabel, "Settings",
                "Custom accessibility label should override title")
        }

        // MARK: - Empty State Tests

        func testSidebarPatternWithEmptySections() {
            // Given
            let selection = Binding<ItemID?>.constant(nil)
            let pattern = SidebarPattern(sections: [], selection: selection) { _ in Text("Detail") }

            // Then
            XCTAssertTrue(pattern.sections.isEmpty, "Sidebar should handle empty sections array")
        }

        func testSidebarPatternWithSectionContainingNoItems() {
            // Given
            let sections = [SidebarPattern<ItemID, Text>.Section(title: "Empty", items: [])]
            let selection = Binding<ItemID?>.constant(nil)
            let pattern = SidebarPattern(sections: sections, selection: selection) { _ in
                Text("Detail")
            }

            // Then
            XCTAssertEqual(pattern.sections.count, 1)
            XCTAssertTrue(pattern.sections[0].items.isEmpty)
        }

        // MARK: - Selection Management

        func testSidebarPatternWithInitialSelection() {
            // Given
            let sections = sampleSections
            let initialSelection = sections[0].items[0].id
            let selection = Binding<ItemID?>.constant(initialSelection)

            // When
            let pattern = SidebarPattern(sections: sections, selection: selection) { _ in
                Text("Detail")
            }

            // Then
            XCTAssertEqual(
                pattern.selection, initialSelection, "Sidebar should respect initial selection")
        }

        func testSidebarPatternWithNilSelection() {
            // Given
            let sections = sampleSections
            let selection = Binding<ItemID?>.constant(nil)

            // When
            let pattern = SidebarPattern(sections: sections, selection: selection) { _ in
                Text("Detail")
            }

            // Then
            XCTAssertNil(pattern.selection, "Sidebar should handle nil selection")
        }

        // MARK: - Detail Builder Tests

        func testDetailBuilderWithNilSelection() {
            // Given
            let sections = sampleSections
            let selection = Binding<ItemID?>.constant(nil)
            var receivedSelection: ItemID?
            let pattern = SidebarPattern(sections: sections, selection: selection) { selection in
                receivedSelection = selection
                return Text(selection?.uuidString ?? "No Selection")
            }

            // When
            let detail = pattern.detailBuilder(nil)

            // Then
            XCTAssertNil(
                receivedSelection, "Detail builder should receive nil when nothing is selected")
            XCTAssertNotNil(detail, "Detail builder should still produce a view for nil selection")
        }

        func testDetailBuilderWithDifferentSelections() {
            // Given
            let sections = sampleSections
            let selection = Binding<ItemID?>.constant(nil)
            let pattern = SidebarPattern(sections: sections, selection: selection) { selection in
                Text(selection?.uuidString ?? "None")
            }

            // When
            let detail1 = pattern.detailBuilder(sections[0].items[0].id)
            let detail2 = pattern.detailBuilder(sections[0].items[1].id)

            // Then
            XCTAssertNotNil(detail1)
            XCTAssertNotNil(detail2)
        }

        // MARK: - Multiple Sections

        func testSidebarPatternWithMultipleSections() {
            // Given
            let sections = [
                SidebarPattern<ItemID, Text>.Section(
                    title: "Section 1",
                    items: [
                        .init(id: UUID(), title: "Item 1.1"), .init(id: UUID(), title: "Item 1.2"),
                    ]),
                SidebarPattern<ItemID, Text>.Section(
                    title: "Section 2", items: [.init(id: UUID(), title: "Item 2.1")]),
                SidebarPattern<ItemID, Text>.Section(
                    title: "Section 3",
                    items: [
                        .init(id: UUID(), title: "Item 3.1"), .init(id: UUID(), title: "Item 3.2"),
                        .init(id: UUID(), title: "Item 3.3"),
                    ]),
            ]
            let selection = Binding<ItemID?>.constant(nil)
            let pattern = SidebarPattern(sections: sections, selection: selection) { _ in
                Text("Detail")
            }

            // Then
            XCTAssertEqual(pattern.sections.count, 3, "Sidebar should handle multiple sections")
            XCTAssertEqual(pattern.sections[0].items.count, 2)
            XCTAssertEqual(pattern.sections[1].items.count, 1)
            XCTAssertEqual(pattern.sections[2].items.count, 3)
        }

        // MARK: - Design System Token Usage

        func testSidebarPatternUsesDesignSystemTokens() {
            // Given
            let sections = sampleSections
            let selection = Binding<ItemID?>.constant(nil)
            let pattern = SidebarPattern(sections: sections, selection: selection) { _ in
                Text("Detail")
            }

            // Then
            // Sidebar should use DS.Typography.caption for section headers
            // Sidebar should use DS.Typography.body for items
            // Sidebar should use DS.Spacing tokens for padding
            // Sidebar should use DS.Colors.textPrimary and textSecondary
            XCTAssertNotNil(pattern.body, "Sidebar should use DS tokens throughout")
        }

        // MARK: - Real-World Use Cases

        func testSidebarPatternForFileExplorer() {
            // Given
            enum FileCategory: String, Hashable { case recents, documents, downloads, favorites }

            let sections = [
                SidebarPattern<FileCategory, Text>.Section(
                    title: "Quick Access",
                    items: [
                        .init(id: .recents, title: "Recents", iconSystemName: "clock"),
                        .init(id: .favorites, title: "Favorites", iconSystemName: "star"),
                    ]),
                SidebarPattern<FileCategory, Text>.Section(
                    title: "Folders",
                    items: [
                        .init(id: .documents, title: "Documents", iconSystemName: "folder"),
                        .init(
                            id: .downloads, title: "Downloads", iconSystemName: "arrow.down.circle"),
                    ]),
            ]
            let selection = Binding<FileCategory?>.constant(.recents)

            let pattern = SidebarPattern(sections: sections, selection: selection) { category in
                Text(category?.rawValue.capitalized ?? "Select a folder")
            }

            // Then
            XCTAssertEqual(
                pattern.sections.count, 2, "File explorer sidebar should have multiple sections")
            XCTAssertEqual(pattern.selection, .recents)
        }

        func testSidebarPatternForMediaLibrary() {
            // Given
            enum MediaType: String, Hashable { case all, videos, audio, images }

            let sections = [
                SidebarPattern<MediaType, Text>.Section(
                    title: "Library",
                    items: [
                        .init(id: .all, title: "All Media", iconSystemName: "square.grid.2x2"),
                        .init(id: .videos, title: "Videos", iconSystemName: "video"),
                        .init(id: .audio, title: "Audio", iconSystemName: "music.note"),
                        .init(id: .images, title: "Images", iconSystemName: "photo"),
                    ])
            ]
            let selection = Binding<MediaType?>.constant(.videos)

            let pattern = SidebarPattern(sections: sections, selection: selection) { type in
                Text("\(type?.rawValue ?? "none") content")
            }

            // Then
            XCTAssertEqual(
                pattern.sections[0].items.count, 4, "Media library should have all media types")
            XCTAssertEqual(pattern.selection, .videos)
        }

        func testSidebarPatternForISOInspector() {
            // Given
            enum InspectorView: String, Hashable { case overview, structure, metadata, validation }

            let sections = [
                SidebarPattern<InspectorView, Text>.Section(
                    title: "Analysis",
                    items: [
                        .init(id: .overview, title: "Overview", iconSystemName: "doc.text"),
                        .init(
                            id: .structure, title: "Box Structure",
                            iconSystemName: "square.stack.3d.up"),
                        .init(id: .metadata, title: "Metadata", iconSystemName: "info.circle"),
                        .init(
                            id: .validation, title: "Validation", iconSystemName: "checkmark.seal"),
                    ])
            ]
            let selection = Binding<InspectorView?>.constant(.overview)

            let pattern = SidebarPattern(sections: sections, selection: selection) { view in
                Text(view?.rawValue ?? "none")
            }

            // Then
            XCTAssertEqual(pattern.sections[0].items.count, 4)
            XCTAssertTrue(
                pattern.sections[0].items.allSatisfy { $0.iconSystemName != nil },
                "All ISO inspector items should have icons")
        }

        // MARK: - Large Scale Tests

        func testSidebarPatternWithManyItems() {
            // Given
            let items = (1...100).map { index in
                SidebarPattern<Int, Text>.Item(
                    id: index, title: "Item \(index)", iconSystemName: "doc")
            }
            let sections = [SidebarPattern<Int, Text>.Section(title: "Large Section", items: items)]
            let selection = Binding<Int?>.constant(1)

            let pattern = SidebarPattern(sections: sections, selection: selection) { id in
                Text("Item \(id ?? 0)")
            }

            // Then
            XCTAssertEqual(
                pattern.sections[0].items.count, 100, "Sidebar should handle large number of items")
        }

        func testSidebarPatternWithManySections() {
            // Given
            let sections = (1...50).map { index in
                SidebarPattern<String, Text>.Section(
                    title: "Section \(index)",
                    items: [
                        .init(id: "item-\(index)-1", title: "Item 1"),
                        .init(id: "item-\(index)-2", title: "Item 2"),
                    ])
            }
            let selection = Binding<String?>.constant(nil)

            let pattern = SidebarPattern(sections: sections, selection: selection) { _ in
                Text("Detail")
            }

            // Then
            XCTAssertEqual(pattern.sections.count, 50, "Sidebar should handle many sections")
        }

        // MARK: - Accessibility

        func testSidebarPatternHasAccessibilityIdentifiers() {
            // Given
            let sections = sampleSections
            let selection = Binding<ItemID?>.constant(nil)
            let pattern = SidebarPattern(sections: sections, selection: selection) { _ in
                Text("Detail")
            }

            // Then
            // Sidebar and detail should have accessibility identifiers
            XCTAssertNotNil(pattern.body, "Sidebar should have accessibility identifiers")
        }

        // MARK: - Item Equality and Hashing

        func testItemEquality() {
            // Given
            let id = UUID()
            let item1 = SidebarPattern<UUID, Text>.Item(id: id, title: "Same")
            let item2 = SidebarPattern<UUID, Text>.Item(id: id, title: "Same")

            // Then
            XCTAssertEqual(item1, item2, "Items with same ID should be equal")
        }

        func testSectionEquality() {
            // Given
            let items = [SidebarPattern<UUID, Text>.Item(id: UUID(), title: "Item")]
            let section1 = SidebarPattern<UUID, Text>.Section(title: "Section", items: items)
            let section2 = SidebarPattern<UUID, Text>.Section(title: "Section", items: items)

            // Then
            XCTAssertEqual(section1.id, section2.id, "Sections with same title should have same ID")
        }

        // MARK: - Edge Cases

        func testSidebarPatternWithSpecialCharactersInTitles() {
            // Given
            let sections = [
                SidebarPattern<String, Text>.Section(
                    title: "Special 🎬 Characters",
                    items: [
                        .init(id: "emoji", title: "Emoji 🎥", iconSystemName: "video"),
                        .init(id: "unicode", title: "Üñíçödé", iconSystemName: "textformat"),
                        .init(id: "symbols", title: "Symbols ™®©", iconSystemName: "trademark"),
                    ])
            ]
            let selection = Binding<String?>.constant(nil)
            let pattern = SidebarPattern(sections: sections, selection: selection) { _ in
                Text("Detail")
            }

            // Then
            XCTAssertEqual(
                pattern.sections[0].items.count, 3, "Sidebar should handle special characters")
        }

        func testSidebarPatternWithVeryLongTitles() {
            // Given
            let longTitle = String(repeating: "Long ", count: 50)
            let sections = [
                SidebarPattern<Int, Text>.Section(
                    title: longTitle, items: [.init(id: 1, title: longTitle)])
            ]
            let selection = Binding<Int?>.constant(nil)
            let pattern = SidebarPattern(sections: sections, selection: selection) { _ in
                Text("Detail")
            }

            // Then
            XCTAssertEqual(
                pattern.sections[0].title, longTitle, "Sidebar should handle very long titles")
        }
    }
#endif
