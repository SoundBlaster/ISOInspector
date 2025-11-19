#if canImport(SwiftUI) && canImport(UIKit) && os(macOS)
  import SwiftUI
  import XCTest
  import ISOInspectorKit
  import NestedA11yIDs
  @testable import ISOInspectorApp

  /// Accessibility identifier tests for ParseTree views.
  ///
  /// ## Important: These are UI Tests Disguised as Unit Tests
  ///
  /// **Current State:**
  /// - These tests create UIHostingController and UIWindow instances
  /// - They render full SwiftUI view hierarchies
  /// - They traverse rendered UIView trees to find accessibility identifiers
  /// - They only work on macOS (iOS rendering behaves differently)
  ///
  /// **Why This Is Problematic:**
  /// - **Not unit tests**: Unit tests should test view model logic without rendering
  /// - **Platform-specific**: Requires macOS guards, doesn't work on iOS
  /// - **Fragile**: Depends on SwiftUI → UIKit translation implementation details
  /// - **Slow**: Full rendering + layout + RunLoop overhead
  ///
  /// **Recommended Migration Path:**
  /// @todo #221 Migrate to proper XCUITest UI tests
  /// 1. Create a dedicated UITests target in Project.swift
  /// 2. Rewrite tests using XCUIApplication for proper UI testing
  /// 3. Benefits: Works on iOS/macOS, tests actual accessibility, more reliable
  ///
  /// **Alternative: Convert to View Model Unit Tests**
  /// See: DocumentViewModelTests.swift, ParseTreeOutlineViewModelTests.swift
  /// for examples of proper unit tests that don't render UI.
  @MainActor
  final class ParseTreeAccessibilityIdentifierTests: XCTestCase {
    func testExplorerAppliesRootIdentifier() {
      let store = ParseTreeStore()
      let annotations = AnnotationBookmarkSession(store: nil)
      let documentViewModel = DocumentViewModel(store: store, annotations: annotations)
      let view = ParseTreeExplorerView(viewModel: documentViewModel)
        .frame(width: 1024, height: 768)

      let controller = UIHostingController(rootView: view)
      let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1024, height: 768))
      window.rootViewController = controller
      window.makeKeyAndVisible()
      controller.view.setNeedsLayout()
      controller.view.layoutIfNeeded()

      XCTAssertEqual(controller.view.accessibilityIdentifier, ParseTreeAccessibilityID.root)
    }

    func testExplorerSearchFieldReceivesNestedIdentifier() {
      let store = ParseTreeStore()
      let annotations = AnnotationBookmarkSession(store: nil)
      let documentViewModel = DocumentViewModel(store: store, annotations: annotations)
      let view = ParseTreeExplorerView(viewModel: documentViewModel)
        .frame(width: 1024, height: 768)

      let controller = UIHostingController(rootView: view)
      let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1024, height: 768))
      window.rootViewController = controller
      window.makeKeyAndVisible()
      controller.view.setNeedsLayout()
      controller.view.layoutIfNeeded()

      RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

      let identifier = ParseTreeAccessibilityID.path(
        ParseTreeAccessibilityID.root,
        ParseTreeAccessibilityID.Outline.root,
        ParseTreeAccessibilityID.Outline.Filters.root,
        ParseTreeAccessibilityID.Outline.Filters.searchField
      )
      let searchField = findView(in: controller.view, withIdentifier: identifier)

      XCTAssertNotNil(
        searchField, "Expected to find search field with identifier \(identifier)")
    }

    func testInspectorToggleButtonReceivesNestedIdentifier() {
      let store = ParseTreeStore()
      let annotations = AnnotationBookmarkSession(store: nil)
      let documentViewModel = DocumentViewModel(store: store, annotations: annotations)
      let view = ParseTreeExplorerView(viewModel: documentViewModel)
        .frame(width: 1024, height: 768)

      let controller = UIHostingController(rootView: view)
      let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1024, height: 768))
      window.rootViewController = controller
      window.makeKeyAndVisible()
      controller.view.setNeedsLayout()
      controller.view.layoutIfNeeded()
      RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

      let identifier = ParseTreeAccessibilityID.path(
        ParseTreeAccessibilityID.root,
        ParseTreeAccessibilityID.Header.root,
        ParseTreeAccessibilityID.Header.inspectorToggle
      )
      let toggleButton = findView(in: controller.view, withIdentifier: identifier)

      XCTAssertNotNil(
        toggleButton, "Expected Inspector toggle button with identifier \(identifier)")
    }

    func testAnnotationNoteControlsExposeNestedIdentifiers() throws {
      let recordID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
      let now = Date()
      let record = AnnotationRecord(
        id: recordID,
        nodeID: 0,
        note: "Existing note",
        createdAt: now,
        updatedAt: now
      )
      let store = MockAnnotationStore(annotations: [record])
      let session = AnnotationBookmarkSession(store: store)
      let fileURL = URL(fileURLWithPath: "/tmp/example.mp4")
      session.setFileURL(fileURL)
      session.setSelectedNode(record.nodeID)

      let viewModel = ParseTreeDetailViewModel(hexSliceProvider: nil, annotationProvider: nil)
      let header = BoxHeader(
        type: try FourCharCode("test"),
        totalSize: 32,
        headerSize: 8,
        payloadRange: 8..<32,
        range: 0..<32,
        uuid: nil
      )
      let node = ParseTreeNode(
        header: header, metadata: nil, payload: nil, validationIssues: [], children: [])
      let snapshot = ParseTreeSnapshot(
        nodes: [node], validationIssues: [], lastUpdatedAt: now)
      viewModel.apply(snapshot: snapshot)
      viewModel.select(nodeID: node.id)

      let host = DetailHostView(
        viewModel: viewModel, session: session, selectedNodeID: node.id
      )
      .a11yRoot(ParseTreeAccessibilityID.root)
      .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.Detail.root)
      let controller = UIHostingController(rootView: host)
      let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 800, height: 600))
      window.rootViewController = controller
      window.makeKeyAndVisible()
      controller.view.setNeedsLayout()
      controller.view.layoutIfNeeded()
      RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

      let editIdentifier = ParseTreeAccessibilityID.path(
        ParseTreeAccessibilityID.root,
        ParseTreeAccessibilityID.Detail.root,
        ParseTreeAccessibilityID.Detail.notes,
        ParseTreeAccessibilityID.Detail.Notes.row(record.id),
        ParseTreeAccessibilityID.Detail.Notes.Controls.root,
        ParseTreeAccessibilityID.Detail.Notes.Controls.edit
      )
      let deleteIdentifier = ParseTreeAccessibilityID.path(
        ParseTreeAccessibilityID.root,
        ParseTreeAccessibilityID.Detail.root,
        ParseTreeAccessibilityID.Detail.notes,
        ParseTreeAccessibilityID.Detail.Notes.row(record.id),
        ParseTreeAccessibilityID.Detail.Notes.Controls.root,
        ParseTreeAccessibilityID.Detail.Notes.Controls.delete
      )

      guard
        let editButton = findView(in: controller.view, withIdentifier: editIdentifier)
          as? UIControl
      else {
        XCTFail("Expected Edit button with identifier \(editIdentifier)")
        return
      }
      XCTAssertNotNil(
        findView(in: controller.view, withIdentifier: deleteIdentifier),
        "Expected Delete control with identifier \(deleteIdentifier)")

      editButton.sendActions(for: .touchUpInside)
      RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

      let saveIdentifier = ParseTreeAccessibilityID.path(
        ParseTreeAccessibilityID.root,
        ParseTreeAccessibilityID.Detail.root,
        ParseTreeAccessibilityID.Detail.notes,
        ParseTreeAccessibilityID.Detail.Notes.row(record.id),
        ParseTreeAccessibilityID.Detail.Notes.Controls.root,
        ParseTreeAccessibilityID.Detail.Notes.Controls.save
      )
      let cancelIdentifier = ParseTreeAccessibilityID.path(
        ParseTreeAccessibilityID.root,
        ParseTreeAccessibilityID.Detail.root,
        ParseTreeAccessibilityID.Detail.notes,
        ParseTreeAccessibilityID.Detail.Notes.row(record.id),
        ParseTreeAccessibilityID.Detail.Notes.Controls.root,
        ParseTreeAccessibilityID.Detail.Notes.Controls.cancel
      )

      XCTAssertNotNil(
        findView(in: controller.view, withIdentifier: saveIdentifier),
        "Expected Save control with identifier \(saveIdentifier)")
      XCTAssertNotNil(
        findView(in: controller.view, withIdentifier: cancelIdentifier),
        "Expected Cancel control with identifier \(cancelIdentifier)")
    }

    // MARK: - Helpers

    private func findView(in root: UIView, withIdentifier identifier: String) -> UIView? {
      if root.accessibilityIdentifier == identifier {
        return root
      }
      if let elements = root.accessibilityElements as? [UIAccessibilityIdentification],
        elements.contains(where: { $0.accessibilityIdentifier == identifier })
      {
        return root
      }
      for subview in root.subviews {
        if let match = findView(in: subview, withIdentifier: identifier) {
          return match
        }
      }
      return nil
    }
  }

  private struct DetailHostView: View {
    let viewModel: ParseTreeDetailViewModel
    @ObservedObject private var session: AnnotationBookmarkSession
    @State private var selectedNodeID: ParseTreeNode.ID?
    @FocusState private var focus: InspectorFocusTarget?

    init(
      viewModel: ParseTreeDetailViewModel, session: AnnotationBookmarkSession,
      selectedNodeID: ParseTreeNode.ID?
    ) {
      self.viewModel = viewModel
      self._session = ObservedObject(wrappedValue: session)
      self._selectedNodeID = State(initialValue: selectedNodeID)
    }

    var body: some View {
      ParseTreeDetailView(
        viewModel: viewModel,
        annotationSession: session,
        selectedNodeID: $selectedNodeID,
        focusTarget: $focus
      )
    }
  }

  private final class MockAnnotationStore: AnnotationBookmarkStoring {
    var annotations: [AnnotationRecord]
    var bookmarks: [BookmarkRecord]

    init(annotations: [AnnotationRecord], bookmarks: [BookmarkRecord] = []) {
      self.annotations = annotations
      self.bookmarks = bookmarks
    }

    func annotations(for file: URL) throws -> [AnnotationRecord] {
      annotations
    }

    func bookmarks(for file: URL) throws -> [BookmarkRecord] {
      bookmarks
    }

    func createAnnotation(for file: URL, nodeID: Int64, note: String) throws -> AnnotationRecord {
      let record = AnnotationRecord(
        nodeID: nodeID,
        note: note,
        createdAt: Date(),
        updatedAt: Date()
      )
      annotations.append(record)
      return record
    }

    func updateAnnotation(for file: URL, annotationID: UUID, note: String) throws
      -> AnnotationRecord
    {
      guard let index = annotations.firstIndex(where: { $0.id == annotationID }) else {
        throw NSError(domain: "MockAnnotationStore", code: 1)
      }
      var updated = annotations[index]
      updated.note = note
      updated.updatedAt = Date()
      annotations[index] = updated
      return updated
    }

    func deleteAnnotation(for file: URL, annotationID: UUID) throws {
      annotations.removeAll { $0.id == annotationID }
    }

    func setBookmark(for file: URL, nodeID: Int64, isBookmarked: Bool) throws {
      if isBookmarked {
        if !bookmarks.contains(where: { $0.nodeID == nodeID }) {
          bookmarks.append(BookmarkRecord(nodeID: nodeID, createdAt: Date()))
        }
      } else {
        bookmarks.removeAll { $0.nodeID == nodeID }
      }
    }
  }
#endif
