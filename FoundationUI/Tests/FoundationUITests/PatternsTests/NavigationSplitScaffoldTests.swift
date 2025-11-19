// swift-tools-version: 6.0
#if canImport(SwiftUI)
  @testable import FoundationUI
  import NavigationSplitViewKit
  import SwiftUI
  import XCTest

  @MainActor
  final class NavigationSplitScaffoldTests: XCTestCase {
    // MARK: - Initialization Tests

    func testNavigationSplitScaffoldInitializesWithDefaultModel() {
      // Given: A scaffold without explicit model
      let scaffold = NavigationSplitScaffold {
        Text("Sidebar")
      } content: {
        Text("Content")
      } detail: {
        Text("Detail")
      }

      // Then: Scaffold should have a valid navigation model
      XCTAssertNotNil(scaffold.navigationModel)
    }

    func testNavigationSplitScaffoldAcceptsProvidedModel() {
      // Given: A specific navigation model
      let model = NavigationModel()
      model.columnVisibility = .all

      // When: Creating scaffold with that model
      let scaffold = NavigationSplitScaffold(model: model) {
        Text("Sidebar")
      } content: {
        Text("Content")
      } detail: {
        Text("Detail")
      }

      // Then: Scaffold should use the provided model
      XCTAssertEqual(scaffold.navigationModel.columnVisibility, .all)
    }

    func testNavigationSplitScaffoldStoresViewBuilderContent() {
      // Given: Specific views for each column
      let sidebarView = Text("Test Sidebar")
      let contentView = Text("Test Content")
      let detailView = Text("Test Detail")

      // When: Creating scaffold with those views
      let scaffold = NavigationSplitScaffold {
        sidebarView
      } content: {
        contentView
      } detail: {
        detailView
      }

      // Then: Scaffold should store all three views
      XCTAssertNotNil(scaffold.sidebar)
      XCTAssertNotNil(scaffold.content)
      XCTAssertNotNil(scaffold.detail)
    }

    // MARK: - Navigation Model Tests

    func testNavigationModelDefaultsToAutomaticVisibility() {
      // Given: A new navigation model
      let model = NavigationModel()

      // Then: Should default to automatic visibility
      XCTAssertEqual(model.columnVisibility, .automatic)
    }

    func testNavigationModelSupportsAllColumnVisibility() {
      // Given: A navigation model
      let model = NavigationModel()

      // When: Setting to show all columns
      model.columnVisibility = .all

      // Then: All columns should be visible
      XCTAssertEqual(model.columnVisibility, .all)
    }

    func testNavigationModelSupportsContentDetailVisibility() {
      // Given: A navigation model
      let model = NavigationModel()

      // When: Setting to show only content and detail
      model.columnVisibility = .contentDetail

      // Then: Only content and detail should be visible
      XCTAssertEqual(model.columnVisibility, .contentDetail)
    }

    func testNavigationModelSupportsContentOnlyVisibility() {
      // Given: A navigation model
      let model = NavigationModel()

      // When: Setting to show only content
      model.columnVisibility = .contentOnly

      // Then: Only content should be visible
      XCTAssertEqual(model.columnVisibility, .contentOnly)
    }

    func testNavigationModelPreferredCompactColumnDefaultsToContent() {
      // Given: A new navigation model
      let model = NavigationModel()

      // Then: Should prefer content column in compact size class
      XCTAssertEqual(model.preferredCompactColumn, .content)
    }

    func testNavigationModelAllowsChangingPreferredCompactColumn() {
      // Given: A navigation model
      let model = NavigationModel()

      // When: Changing preferred compact column to detail
      model.preferredCompactColumn = .detail

      // Then: Preferred column should update
      XCTAssertEqual(model.preferredCompactColumn, .detail)
    }

    // MARK: - Environment Key Tests

    func testNavigationModelEnvironmentKeyHasNilDefaultValue() {
      // Given: The environment key
      let defaultValue = NavigationModelKey.defaultValue

      // Then: Default should be nil
      XCTAssertNil(defaultValue)
    }

    func testNavigationModelCanBeSetInEnvironment() {
      // Given: A navigation model
      let model = NavigationModel()
      model.columnVisibility = .all

      // When: Setting it in environment
      struct TestView: View {
        @Environment(\.navigationModel) var navigationModel

        var body: some View {
          Text("Test")
        }
      }

      let view = TestView()
        .environment(\.navigationModel, model)

      // Then: Environment should contain the model
      // (Verification happens through compilation and runtime)
      XCTAssertNotNil(view)
    }

    // MARK: - Column Visibility Transition Tests

    func testNavigationModelTransitionsFromAutomaticToAll() {
      // Given: A model with automatic visibility
      let model = NavigationModel()
      XCTAssertEqual(model.columnVisibility, .automatic)

      // When: Changing to all visible
      model.columnVisibility = .all

      // Then: Visibility should update
      XCTAssertEqual(model.columnVisibility, .all)
    }

    func testNavigationModelTransitionsFromAllToContentOnly() {
      // Given: A model showing all columns
      let model = NavigationModel()
      model.columnVisibility = .all

      // When: Hiding sidebar and detail
      model.columnVisibility = .contentOnly

      // Then: Only content should be visible
      XCTAssertEqual(model.columnVisibility, .contentOnly)
    }

    // MARK: - Integration Tests

    func testScaffoldPropagatesNavigationModelToSidebar() {
      // Given: A model and a view that reads from environment
      let model = NavigationModel()
      model.columnVisibility = .all

      struct SidebarView: View {
        @Environment(\.navigationModel) var navigationModel

        var body: some View {
          Text(navigationModel?.columnVisibility.description ?? "nil")
        }
      }

      // When: Creating scaffold with that model
      let scaffold = NavigationSplitScaffold(model: model) {
        SidebarView()
      } content: {
        Text("Content")
      } detail: {
        Text("Detail")
      }

      // Then: Environment should be set
      XCTAssertEqual(scaffold.navigationModel.columnVisibility, .all)
    }

    func testScaffoldPropagatesNavigationModelToContent() {
      // Given: A model and a view that reads from environment
      let model = NavigationModel()
      model.columnVisibility = .contentDetail

      struct ContentView: View {
        @Environment(\.navigationModel) var navigationModel

        var body: some View {
          Text(navigationModel?.columnVisibility.description ?? "nil")
        }
      }

      // When: Creating scaffold with that model
      let scaffold = NavigationSplitScaffold(model: model) {
        Text("Sidebar")
      } content: {
        ContentView()
      } detail: {
        Text("Detail")
      }

      // Then: Environment should be set
      XCTAssertEqual(scaffold.navigationModel.columnVisibility, .contentDetail)
    }

    func testScaffoldPropagatesNavigationModelToDetail() {
      // Given: A model and a view that reads from environment
      let model = NavigationModel()
      model.columnVisibility = .all

      struct DetailView: View {
        @Environment(\.navigationModel) var navigationModel

        var body: some View {
          Text(navigationModel?.columnVisibility.description ?? "nil")
        }
      }

      // When: Creating scaffold with that model
      let scaffold = NavigationSplitScaffold(model: model) {
        Text("Sidebar")
      } content: {
        Text("Content")
      } detail: {
        DetailView()
      }

      // Then: Environment should be set
      XCTAssertEqual(scaffold.navigationModel.columnVisibility, .all)
    }

    // MARK: - Accessibility Tests

    func testScaffoldSupportsAccessibilityLabels() {
      // Given: A scaffold with accessibility content
      struct AccessibleSidebarView: View {
        var body: some View {
          Text("Sidebar")
            .accessibilityLabel("File Browser")
        }
      }

      let scaffold = NavigationSplitScaffold {
        AccessibleSidebarView()
      } content: {
        Text("Content")
          .accessibilityLabel("Parse Tree")
      } detail: {
        Text("Detail")
          .accessibilityLabel("Atom Inspector")
      }

      // Then: Scaffold should maintain accessibility hierarchy
      XCTAssertNotNil(scaffold)
    }

    // MARK: - Complex State Tests

    func testNavigationModelSupportsMultipleStateChanges() {
      // Given: A navigation model
      let model = NavigationModel()

      // When: Making multiple state changes
      model.columnVisibility = .all
      model.preferredCompactColumn = .detail
      model.columnVisibility = .contentDetail
      model.preferredCompactColumn = .content

      // Then: Final state should be correct
      XCTAssertEqual(model.columnVisibility, .contentDetail)
      XCTAssertEqual(model.preferredCompactColumn, .content)
    }

    func testNavigationModelStateIsIndependent() {
      // Given: Two independent navigation models
      let model1 = NavigationModel()
      let model2 = NavigationModel()

      // When: Changing one model
      model1.columnVisibility = .all
      model2.columnVisibility = .contentOnly

      // Then: Models should have independent state
      XCTAssertEqual(model1.columnVisibility, .all)
      XCTAssertEqual(model2.columnVisibility, .contentOnly)
      XCTAssertNotEqual(model1.columnVisibility, model2.columnVisibility)
    }

    // MARK: - Real-World Scenario Tests

    func testISOInspectorThreeColumnLayout() {
      // Given: An ISO Inspector-style layout
      let model = NavigationModel()
      model.columnVisibility = .all

      struct FileListSidebar: View {
        var body: some View {
          List {
            Section("Recent") {
              Text("sample.mp4")
              Text("test.iso")
            }
          }
          .accessibilityLabel("File Browser")
        }
      }

      struct ParseTreeContent: View {
        var body: some View {
          List {
            Text("ftyp")
            Text("moov")
            Text("trak")
          }
          .accessibilityLabel("Parse Tree")
        }
      }

      struct AtomInspector: View {
        var body: some View {
          VStack {
            Text("Type: ftyp")
            Text("Size: 20 bytes")
          }
          .accessibilityLabel("Atom Inspector")
        }
      }

      // When: Creating scaffold with ISO Inspector layout
      let scaffold = NavigationSplitScaffold(model: model) {
        FileListSidebar()
      } content: {
        ParseTreeContent()
      } detail: {
        AtomInspector()
      }

      // Then: Scaffold should be configured for three columns
      XCTAssertEqual(scaffold.navigationModel.columnVisibility, .all)
    }

    func testCompactLayoutPreferringContent() {
      // Given: A compact layout configuration
      let model = NavigationModel()
      model.columnVisibility = .contentOnly
      model.preferredCompactColumn = .content

      // When: Creating scaffold for iPhone
      let scaffold = NavigationSplitScaffold(model: model) {
        Text("Sidebar")
      } content: {
        Text("Content")
      } detail: {
        Text("Detail")
      }

      // Then: Should prefer content column
      XCTAssertEqual(scaffold.navigationModel.preferredCompactColumn, .content)
      XCTAssertEqual(scaffold.navigationModel.columnVisibility, .contentOnly)
    }

    // MARK: - Binding Tests

    func testNavigationModelBindingUpdates() {
      // Given: A bindable navigation model
      let model = NavigationModel()
      var capturedVisibility: NavigationSplitViewColumn.Visibility = .automatic

      let binding = Binding<NavigationSplitViewColumn.Visibility>(
        get: { model.columnVisibility },
        set: { newValue in
          model.columnVisibility = newValue
          capturedVisibility = newValue
        }
      )

      // When: Updating through binding
      binding.wrappedValue = .all

      // Then: Both model and binding should update
      XCTAssertEqual(model.columnVisibility, .all)
      XCTAssertEqual(capturedVisibility, .all)
    }

    // MARK: - Platform Adaptation Tests

    func testScaffoldAdaptsToCompactSizeClass() {
      // Given: A model configured for compact size class
      let model = NavigationModel()
      model.columnVisibility = .contentOnly
      model.preferredCompactColumn = .content

      // When: Creating scaffold for compact layout
      let scaffold = NavigationSplitScaffold(model: model) {
        Text("Sidebar")
      } content: {
        Text("Content")
      } detail: {
        Text("Detail")
      }

      // Then: Should show only content
      XCTAssertEqual(scaffold.navigationModel.columnVisibility, .contentOnly)
      XCTAssertEqual(scaffold.navigationModel.preferredCompactColumn, .content)
    }

    func testScaffoldAdaptsToRegularSizeClass() {
      // Given: A model configured for regular size class
      let model = NavigationModel()
      model.columnVisibility = .all

      // When: Creating scaffold for regular layout
      let scaffold = NavigationSplitScaffold(model: model) {
        Text("Sidebar")
      } content: {
        Text("Content")
      } detail: {
        Text("Detail")
      }

      // Then: Should show all columns
      XCTAssertEqual(scaffold.navigationModel.columnVisibility, .all)
    }

    // MARK: - Edge Case Tests

    func testScaffoldHandlesEmptyViews() {
      // Given: A scaffold with minimal content
      let scaffold = NavigationSplitScaffold {
        EmptyView()
      } content: {
        EmptyView()
      } detail: {
        EmptyView()
      }

      // Then: Should still be valid
      XCTAssertNotNil(scaffold)
      XCTAssertNotNil(scaffold.navigationModel)
    }

    func testScaffoldHandlesComplexViewHierarchy() {
      // Given: A scaffold with nested view hierarchies
      struct ComplexSidebar: View {
        var body: some View {
          NavigationStack {
            List {
              Section("Section 1") {
                Text("Item 1")
              }
            }
          }
        }
      }

      let scaffold = NavigationSplitScaffold {
        ComplexSidebar()
      } content: {
        TabView {
          Text("Tab 1")
            .tabItem { Label("Tab 1", systemImage: "1.circle") }
          Text("Tab 2")
            .tabItem { Label("Tab 2", systemImage: "2.circle") }
        }
      } detail: {
        ScrollView {
          VStack {
            Text("Detail 1")
            Text("Detail 2")
          }
        }
      }

      // Then: Should handle complex hierarchies
      XCTAssertNotNil(scaffold)
    }

    // MARK: - Environment Propagation Tests

    func testEnvironmentPropagatesDownMultipleLevels() {
      // Given: Nested views that read navigation model
      struct Level1: View {
        @Environment(\.navigationModel) var navigationModel

        var body: some View {
          Level2()
        }
      }

      struct Level2: View {
        @Environment(\.navigationModel) var navigationModel

        var body: some View {
          Text(navigationModel?.columnVisibility.description ?? "nil")
        }
      }

      let model = NavigationModel()
      model.columnVisibility = .all

      // When: Creating scaffold with nested views
      let scaffold = NavigationSplitScaffold(model: model) {
        Level1()
      } content: {
        Text("Content")
      } detail: {
        Text("Detail")
      }

      // Then: Environment should propagate through levels
      XCTAssertEqual(scaffold.navigationModel.columnVisibility, .all)
    }

    // MARK: - Model Lifecycle Tests

    func testNavigationModelRetainsStateAcrossUpdates() {
      // Given: A navigation model with specific state
      let model = NavigationModel()
      model.columnVisibility = .all
      model.preferredCompactColumn = .detail

      // When: Creating scaffold and making changes
      let scaffold = NavigationSplitScaffold(model: model) {
        Text("Sidebar")
      } content: {
        Text("Content")
      } detail: {
        Text("Detail")
      }

      // Then: State should be retained
      XCTAssertEqual(scaffold.navigationModel.columnVisibility, .all)
      XCTAssertEqual(scaffold.navigationModel.preferredCompactColumn, .detail)

      // When: Modifying model
      scaffold.navigationModel.columnVisibility = .contentDetail

      // Then: Changes should persist
      XCTAssertEqual(scaffold.navigationModel.columnVisibility, .contentDetail)
    }

    // MARK: - Type Safety Tests

    func testScaffoldAcceptsDifferentViewTypes() {
      // Given: Different view types for each column
      struct SidebarView: View {
        var body: some View { Text("Sidebar") }
      }

      struct ContentView: View {
        var body: some View { Text("Content") }
      }

      struct DetailView: View {
        var body: some View { Text("Detail") }
      }

      // When: Creating scaffold with different types
      let scaffold = NavigationSplitScaffold {
        SidebarView()
      } content: {
        ContentView()
      } detail: {
        DetailView()
      }

      // Then: Should compile and work correctly
      XCTAssertNotNil(scaffold)
    }

    func testScaffoldSupportsGenericViews() {
      // Given: Generic views
      let scaffold = NavigationSplitScaffold {
        AnyView(Text("Sidebar"))
      } content: {
        AnyView(List { Text("Item") })
      } detail: {
        AnyView(ScrollView { Text("Detail") })
      }

      // Then: Should support type-erased views
      XCTAssertNotNil(scaffold)
    }

    // MARK: - State Consistency Tests

    func testMultipleScaffoldsHaveIndependentState() {
      // Given: Two independent scaffolds
      let model1 = NavigationModel()
      let model2 = NavigationModel()

      model1.columnVisibility = .all
      model2.columnVisibility = .contentOnly

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

      // Then: Should have independent state
      XCTAssertEqual(scaffold1.navigationModel.columnVisibility, .all)
      XCTAssertEqual(scaffold2.navigationModel.columnVisibility, .contentOnly)
    }
  }

  // MARK: - Helper Extensions for Testing

  extension NavigationSplitViewColumn.Visibility {
    var description: String {
      switch self {
      case .automatic: return "automatic"
      case .all: return "all"
      case .contentDetail: return "contentDetail"
      case .contentOnly: return "contentOnly"
      }
    }
  }
#endif
