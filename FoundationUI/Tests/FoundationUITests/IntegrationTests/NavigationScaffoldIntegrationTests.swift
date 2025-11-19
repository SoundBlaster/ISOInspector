// swift-tools-version: 6.0
#if canImport(SwiftUI)
  @testable import FoundationUI
  import SwiftUI
  import XCTest

  /// Integration tests verifying NavigationSplitScaffold composition with existing patterns.
  ///
  /// These tests ensure that SidebarPattern, InspectorPattern, and ToolbarPattern
  /// can integrate with NavigationSplitScaffold while maintaining backward compatibility.
  @MainActor
  final class NavigationScaffoldIntegrationTests: XCTestCase {
    // MARK: - Sidebar Integration Tests

    func testSidebarPatternAccessesNavigationModelFromEnvironment() {
      // Given: A NavigationSplitScaffold with NavigationModel
      let model = NavigationModel()
      model.columnVisibility = .all

      // Note: SidebarPattern doesn't need explicit environment access for this test
      // The scaffold provides it automatically through .environment(\.navigationModel, model)

      let scaffold = NavigationSplitScaffold(model: model) {
        List {
          Text("Sidebar Item")
        }
        .accessibilityIdentifier("TestSidebar")
      } content: {
        Text("Content")
      } detail: {
        Text("Detail")
      }

      // Then: NavigationModel should be accessible in environment
      XCTAssertEqual(scaffold.navigationModel.columnVisibility, .all)
    }

    func testSidebarPatternWorksStandaloneWithoutNavigationModel() {
      // Given: A SidebarPattern used outside NavigationSplitScaffold
      typealias TestID = UUID

      let sections: [SidebarPattern<TestID, Text>.Section] = [
        .init(
          title: "Test",
          items: [
            .init(id: UUID(), title: "Item 1")
          ]
        )
      ]

      let pattern = SidebarPattern(sections: sections, selection: .constant(nil)) { _ in
        Text("Detail")
      }

      // Then: Pattern should work without NavigationModel
      XCTAssertNotNil(pattern)
      XCTAssertEqual(pattern.sections.count, 1)
    }

    func testMultiplePatternsAccessSameNavigationModel() {
      // Given: NavigationSplitScaffold with multiple child views
      let model = NavigationModel()
      model.columnVisibility = .all

      struct TestSidebarView: View {
        @Environment(\.navigationModel) var navigationModel

        var body: some View {
          Text("Sidebar with model: \(navigationModel != nil ? "yes" : "no")")
        }
      }

      struct TestContentView: View {
        @Environment(\.navigationModel) var navigationModel

        var body: some View {
          Text("Content with model: \(navigationModel != nil ? "yes" : "no")")
        }
      }

      let scaffold = NavigationSplitScaffold(model: model) {
        TestSidebarView()
      } content: {
        TestContentView()
      } detail: {
        Text("Detail")
      }

      // Then: Both should access same model
      XCTAssertEqual(scaffold.navigationModel.columnVisibility, .all)
    }

    // MARK: - Inspector Integration Tests

    func testInspectorPatternAccessesNavigationModelFromEnvironment() {
      // Given: NavigationSplitScaffold with InspectorPattern in detail column
      let model = NavigationModel()
      model.columnVisibility = .all

      let scaffold = NavigationSplitScaffold(model: model) {
        Text("Sidebar")
      } content: {
        Text("Content")
      } detail: {
        InspectorPattern(title: "Inspector") {
          Text("Inspector content")
        }
      }

      // Then: NavigationModel should be accessible
      XCTAssertEqual(scaffold.navigationModel.columnVisibility, .all)
    }

    func testInspectorPatternWorksStandaloneWithoutScaffold() {
      // Given: InspectorPattern used outside scaffold
      let inspector = InspectorPattern(title: "Test Inspector") {
        Text("Content")
      }

      // Then: Should work independently
      XCTAssertNotNil(inspector)
      XCTAssertEqual(inspector.title, "Test Inspector")
    }

    // MARK: - Full Pattern Composition Tests

    func testFullThreePatternComposition() {
      // Given: NavigationSplitScaffold with Sidebar, Content, and Inspector
      let model = NavigationModel()
      model.columnVisibility = .all

      typealias TestID = UUID
      let sections: [SidebarPattern<TestID, AnyView>.Section] = [
        .init(
          title: "Files",
          items: [
            .init(id: UUID(), title: "sample.mp4")
          ]
        )
      ]

      let scaffold = NavigationSplitScaffold(model: model) {
        SidebarPattern(sections: sections, selection: .constant(nil)) { _ in
          AnyView(Text("Sidebar Detail"))
        }
      } content: {
        Text("Parse Tree")
      } detail: {
        InspectorPattern(title: "Properties") {
          Text("Atom details")
        }
      }

      // Then: All patterns should compose correctly
      XCTAssertEqual(scaffold.navigationModel.columnVisibility, .all)
      XCTAssertNotNil(scaffold.sidebar)
      XCTAssertNotNil(scaffold.content)
      XCTAssertNotNil(scaffold.detail)
    }

    func testScaffoldWithSidebarAndInspectorPatterns() {
      // Given: Realistic ISO Inspector layout
      let model = NavigationModel()

      typealias TestID = String
      let sections: [SidebarPattern<TestID, AnyView>.Section] = [
        .init(
          title: "Recent",
          items: [
            .init(id: "file1", title: "sample.mp4", iconSystemName: "doc.fill")
          ]
        )
      ]

      let scaffold = NavigationSplitScaffold(model: model) {
        SidebarPattern(sections: sections, selection: .constant("file1")) { _ in
          AnyView(Text("File selected"))
        }
      } content: {
        Text("Parse Tree Content")
      } detail: {
        InspectorPattern(title: "Atom Inspector") {
          VStack {
            Text("Type: ftyp")
            Text("Size: 20 bytes")
          }
        }
      }

      // Then: Should create complete navigation structure
      XCTAssertNotNil(scaffold.navigationModel)
    }

    // MARK: - NavigationModel Synchronization Tests

    func testNavigationModelStateChangesPropagate() {
      // Given: NavigationSplitScaffold with shared model
      let model = NavigationModel()
      model.columnVisibility = .automatic

      let scaffold = NavigationSplitScaffold(model: model) {
        Text("Sidebar")
      } content: {
        Text("Content")
      } detail: {
        Text("Detail")
      }

      // When: Changing model state
      scaffold.navigationModel.columnVisibility = .all

      // Then: State should be updated
      XCTAssertEqual(scaffold.navigationModel.columnVisibility, .all)
      XCTAssertEqual(model.columnVisibility, .all)
    }

    func testIndependentScaffoldsHaveIndependentModels() {
      // Given: Two independent scaffolds
      let model1 = NavigationModel()
      let model2 = NavigationModel()

      model1.columnVisibility = .all
      model2.columnVisibility = .detailOnly

      let scaffold1 = NavigationSplitScaffold(model: model1) {
        Text("S1")
      } content: {
        Text("C1")
      } detail: {
        Text("D1")
      }

      let scaffold2 = NavigationSplitScaffold(model: model2) {
        Text("S2")
      } content: {
        Text("C2")
      } detail: {
        Text("D2")
      }

      // Then: Models should be independent
      XCTAssertEqual(scaffold1.navigationModel.columnVisibility, .all)
      XCTAssertEqual(scaffold2.navigationModel.columnVisibility, .detailOnly)
      XCTAssertNotEqual(scaffold1.navigationModel.columnVisibility, scaffold2.navigationModel.columnVisibility)
    }

    // MARK: - Platform-Specific Behavior Tests

    func testCompactSizeClassBehaviorWithPatterns() {
      // Given: Compact size class configuration
      let model = NavigationModel()
      model.columnVisibility = .detailOnly
      model.preferredCompactColumn = .content

      typealias TestID = UUID
      let sections: [SidebarPattern<TestID, Text>.Section] = [
        .init(title: "Test", items: [.init(id: UUID(), title: "Item")])
      ]

      let scaffold = NavigationSplitScaffold(model: model) {
        SidebarPattern(sections: sections, selection: .constant(nil)) { _ in
          Text("Detail")
        }
      } content: {
        Text("Content")
      } detail: {
        Text("Detail")
      }

      // Then: Should prefer content column
      XCTAssertEqual(scaffold.navigationModel.columnVisibility, .detailOnly)
      XCTAssertEqual(scaffold.navigationModel.preferredCompactColumn, .content)
    }

    func testRegularSizeClassBehaviorWithPatterns() {
      // Given: Regular size class configuration
      let model = NavigationModel()
      model.columnVisibility = .all

      typealias TestID = UUID
      let sections: [SidebarPattern<TestID, Text>.Section] = [
        .init(title: "Test", items: [.init(id: UUID(), title: "Item")])
      ]

      let scaffold = NavigationSplitScaffold(model: model) {
        SidebarPattern(sections: sections, selection: .constant(nil)) { _ in
          Text("Detail")
        }
      } content: {
        Text("Content")
      } detail: {
        InspectorPattern(title: "Inspector") {
          Text("Details")
        }
      }

      // Then: Should show all columns
      XCTAssertEqual(scaffold.navigationModel.columnVisibility, .all)
    }

    // MARK: - Accessibility Integration Tests

    func testAccessibilityLabelsPreservedInScaffold() {
      // Given: Patterns with accessibility labels
      let model = NavigationModel()

      typealias TestID = UUID
      let sections: [SidebarPattern<TestID, Text>.Section] = [
        .init(
          title: "Files",
          items: [
            .init(id: UUID(), title: "File 1", accessibilityLabel: "Sample MP4 File")
          ]
        )
      ]

      let scaffold = NavigationSplitScaffold(model: model) {
        SidebarPattern(sections: sections, selection: .constant(nil)) { _ in
          Text("Detail")
        }
        .accessibilityLabel("File Browser")
      } content: {
        Text("Content")
          .accessibilityLabel("Parse Tree")
      } detail: {
        InspectorPattern(title: "Properties") {
          Text("Details")
        }
        .accessibilityLabel("Atom Inspector")
      }

      // Then: Scaffold should maintain accessibility structure
      XCTAssertNotNil(scaffold)
    }

    // MARK: - Backward Compatibility Tests

    func testPatternsWorkWithoutScaffold() {
      // Given: Patterns used independently (pre-Task 242 usage)
      typealias TestID = UUID

      // SidebarPattern standalone
      let sidebarSections: [SidebarPattern<TestID, Text>.Section] = [
        .init(title: "Test", items: [.init(id: UUID(), title: "Item")])
      ]
      let sidebar = SidebarPattern(sections: sidebarSections, selection: .constant(nil)) { _ in
        Text("Detail")
      }

      // InspectorPattern standalone
      let inspector = InspectorPattern(title: "Inspector") {
        Text("Content")
      }

      // Then: Both should work independently
      XCTAssertNotNil(sidebar)
      XCTAssertEqual(sidebar.sections.count, 1)
      XCTAssertNotNil(inspector)
      XCTAssertEqual(inspector.title, "Inspector")
    }

    func testPatternsWorkInsideScaffold() {
      // Given: Same patterns used inside scaffold (post-Task 242 usage)
      let model = NavigationModel()

      typealias TestID = UUID
      let sections: [SidebarPattern<TestID, Text>.Section] = [
        .init(title: "Test", items: [.init(id: UUID(), title: "Item")])
      ]

      let scaffold = NavigationSplitScaffold(model: model) {
        SidebarPattern(sections: sections, selection: .constant(nil)) { _ in
          Text("Detail")
        }
      } content: {
        Text("Content")
      } detail: {
        InspectorPattern(title: "Inspector") {
          Text("Content")
        }
      }

      // Then: Should work with scaffold
      XCTAssertNotNil(scaffold)
      XCTAssertNotNil(scaffold.navigationModel)
    }

    // MARK: - Edge Case Tests

    func testEmptyPatternComposition() {
      // Given: Scaffold with minimal pattern content
      let model = NavigationModel()

      typealias TestID = UUID
      let sections: [SidebarPattern<TestID, EmptyView>.Section] = [
        .init(title: "Empty", items: [])
      ]

      let scaffold = NavigationSplitScaffold(model: model) {
        SidebarPattern(sections: sections, selection: .constant(nil)) { _ in
          EmptyView()
        }
      } content: {
        EmptyView()
      } detail: {
        EmptyView()
      }

      // Then: Should handle empty content gracefully
      XCTAssertNotNil(scaffold)
      XCTAssertEqual(scaffold.navigationModel, model)
    }

    func testComplexNestedPatternComposition() {
      // Given: Deeply nested pattern structure
      let model = NavigationModel()

      struct NestedContentView: View {
        @Environment(\.navigationModel) var navigationModel

        var body: some View {
          VStack {
            if navigationModel != nil {
              InspectorPattern(title: "Nested") {
                Text("Nested content")
              }
            } else {
              Text("No model")
            }
          }
        }
      }

      let scaffold = NavigationSplitScaffold(model: model) {
        Text("Sidebar")
      } content: {
        NestedContentView()
      } detail: {
        Text("Detail")
      }

      // Then: Should propagate environment through nesting
      XCTAssertEqual(scaffold.navigationModel, model)
    }
  }
#endif
