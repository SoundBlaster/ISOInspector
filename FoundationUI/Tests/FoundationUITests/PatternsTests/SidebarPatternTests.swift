// swift-tools-version: 6.0
#if canImport(SwiftUI)
import XCTest
import SwiftUI
@testable import FoundationUI

@MainActor
final class SidebarPatternTests: XCTestCase {
    typealias ItemID = UUID

    private var sampleSections: [SidebarPattern<ItemID, Text>.Section] {
        [
            .init(
                title: "Media",
                items: [
                    .init(id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEE1")!, title: "Overview"),
                    .init(id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEE2")!, title: "Metadata")
                ]
            ),
            .init(
                title: "Quality",
                items: [
                    .init(id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEE3")!, title: "Waveform")
                ]
            )
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
            get: { capturedSelection },
            set: { capturedSelection = $0 }
        )
        var pattern = SidebarPattern(sections: sections, selection: selection) { _ in
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
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEE9")!,
            title: "Review"
        )

        // Then
        XCTAssertEqual(item.accessibilityLabel, item.title)
    }
}
#endif
