// swift-tools-version: 6.0
#if canImport(SwiftUI)
  @testable import FoundationUI
  import SwiftUI
  import XCTest

  /// Integration tests covering composition between SidebarPattern, InspectorPattern, and ToolbarPattern.
  @MainActor
  final class PatternIntegrationTests: XCTestCase {
    func testSidebarSelectionDrivesInspectorDetailTitle() {
      // Given
      var fixture = PatternIntegrationFixture(documents: sampleDocuments())
      fixture.configureInitialSelection(nil)

      // When
      let sidebar = fixture.makeSidebarPattern()
      fixture.selectionBinding.wrappedValue = fixture.documents.first?.id
      let inspector = sidebar.detailBuilder(fixture.selection)

      // Then
      XCTAssertEqual(inspector.title, fixture.documents.first?.title)
      XCTAssertEqual(
        String(describing: inspector.material),
        String(describing: Material.regular),
        "Inspector should honor material override for composed content"
      )
    }

    func testToolbarPrimaryActionAdvancesSidebarSelection() {
      // Given
      var fixture = PatternIntegrationFixture(documents: sampleDocuments())
      fixture.configureInitialSelection(fixture.documents.first?.id)
      let sidebar = fixture.makeSidebarPattern()
      let toolbar = fixture.makeToolbar(for: fixture.selection)

      guard let nextAction = toolbar.items.primary.first(where: { $0.id == "select.next" }) else {
        XCTFail("Expected select.next toolbar action to be available")
        return
      }

      // When
      nextAction.action()
      let inspector = sidebar.detailBuilder(fixture.selection)

      // Then
      XCTAssertEqual(fixture.selection, fixture.documents[1].id)
      XCTAssertEqual(inspector.title, fixture.documents[1].title)
    }

    func testToolbarAccessibilityAnnouncementRecordsSelection() {
      // Given
      var fixture = PatternIntegrationFixture(documents: sampleDocuments())
      fixture.configureInitialSelection(fixture.documents.first?.id)
      let toolbar = fixture.makeToolbar(for: fixture.selection)

      guard
        let announceAction = toolbar.items.secondary.first(where: { $0.id == "announce.metadata" })
      else {
        XCTFail("Expected accessibility announce action to exist")
        return
      }

      // When
      announceAction.action()

      // Then
      XCTAssertEqual(
        fixture.accessibilityAnnouncements.last, "Inspector metadata updated for document-1"
      )
      XCTAssertEqual(announceAction.accessibilityLabel, "Announce")
      XCTAssertEqual(announceAction.accessibilityHint, "Read the current inspector metadata")
      XCTAssertEqual(announceAction.shortcut, nil)
    }

    func testToolbarOverflowAccessibilityLabelIncludesShortcutGlyph() {
      // Given
      let fixture = PatternIntegrationFixture(documents: sampleDocuments())
      let toolbar = fixture.makeToolbar(for: fixture.selection)

      guard let overflow = toolbar.items.overflow.first(where: { $0.id == "archive" }) else {
        XCTFail("Expected overflow archive item")
        return
      }

      // Then
      XCTAssertEqual(overflow.accessibilityLabel, "Archive, ⌘A")
      if case .destructive = overflow.role {
        // Expected destructive role for archive actions.
      } else {
        XCTFail("Archive action should be destructive")
      }
      // @todo: Integrate snapshot-based verification when SwiftUI previews are available on CI runners.
    }

    // MARK: - Helpers

    private func sampleDocuments() -> [PatternIntegrationFixture.Document] {
      [
        .init(id: "document-1", title: "Annual Report", iconSystemName: "doc.text"),
        .init(id: "document-2", title: "Invoices", iconSystemName: "tray.full"),
        .init(id: "document-3", title: "Compliance", iconSystemName: "checkmark.shield"),
      ]
    }
  }
#endif
