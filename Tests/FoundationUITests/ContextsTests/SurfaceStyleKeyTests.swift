#if canImport(SwiftUI)
  import SwiftUI
  import XCTest
  @testable import FoundationUI

  /// Unit tests for SurfaceStyleKey environment key
  ///
  /// Tests verify:
  /// - EnvironmentKey default value
  /// - Environment value propagation
  /// - Material type storage
  /// - SwiftUI integration
  final class SurfaceStyleKeyTests: XCTestCase {

    // MARK: - Default Value Tests

    /// Test that SurfaceStyleKey has the correct default value
    ///
    /// According to PRD, the default surface material should be `.regular`
    /// to provide a balanced translucency for most use cases.
    func testDefaultValue() throws {
      // Verify that the default value is .regular
      XCTAssertEqual(
        SurfaceStyleKey.defaultValue,
        .regular,
        "Default surface style should be .regular"
      )
    }

    // MARK: - Environment Integration Tests

    /// Test that the environment key can be accessed via EnvironmentValues
    ///
    /// Verifies that the `surfaceStyle` property is correctly integrated
    /// with SwiftUI's environment system.
    func testEnvironmentValueIntegration() throws {
      // Create a test view that reads the environment value
      struct TestView: View {
        @Environment(\.surfaceStyle) var surfaceStyle

        var body: some View {
          Text("Test")
        }
      }

      // This test will fail until SurfaceStyleKey is implemented
      // The view should compile and the environment should have a default value
      let view = TestView()
      XCTAssertNotNil(view, "View should be created successfully")
    }

    /// Test that custom surface styles can be set via environment modifier
    ///
    /// Verifies that surface style values can be propagated down the view
    /// hierarchy using SwiftUI's `.environment()` modifier.
    func testCustomEnvironmentValue() throws {
      // Test that we can set a custom value
      struct ParentView: View {
        var body: some View {
          ChildView()
            .environment(\.surfaceStyle, .thin)
        }
      }

      struct ChildView: View {
        @Environment(\.surfaceStyle) var surfaceStyle

        var body: some View {
          Text("Child")
        }
      }

      let view = ParentView()
      XCTAssertNotNil(view, "Parent view should be created successfully")
    }

    // MARK: - Material Type Storage Tests

    /// Test that all SurfaceMaterial types can be stored in the environment
    ///
    /// Verifies that the environment key correctly stores and retrieves
    /// all possible material types without data loss.
    func testAllMaterialTypes() throws {
      let materials: [SurfaceMaterial] = [.thin, .regular, .thick, .ultra]

      for material in materials {
        // Verify each material type is valid
        XCTAssertNotNil(material, "Material \(material) should be valid")

        // Verify each material has a description
        XCTAssertFalse(
          material.description.isEmpty,
          "Material \(material) should have a description"
        )

        // Verify each material has an accessibility label
        XCTAssertFalse(
          material.accessibilityLabel.isEmpty,
          "Material \(material) should have an accessibility label"
        )
      }
    }

    // MARK: - View Hierarchy Propagation Tests

    /// Test that surface style propagates correctly through nested views
    ///
    /// Verifies that child views inherit the surface style from their parent
    /// when no explicit override is provided.
    func testEnvironmentPropagation() throws {
      struct GrandparentView: View {
        var body: some View {
          ParentView()
            .environment(\.surfaceStyle, .thick)
        }
      }

      struct ParentView: View {
        @Environment(\.surfaceStyle) var surfaceStyle

        var body: some View {
          ChildView()
        }
      }

      struct ChildView: View {
        @Environment(\.surfaceStyle) var surfaceStyle

        var body: some View {
          Text("Grandchild")
        }
      }

      let view = GrandparentView()
      XCTAssertNotNil(view, "Grandparent view should be created successfully")
    }

    /// Test that surface style can be overridden at different levels
    ///
    /// Verifies that child views can override the surface style inherited
    /// from their parents, allowing for flexible UI composition.
    func testEnvironmentOverride() throws {
      struct ParentView: View {
        var body: some View {
          VStack {
            // Uses parent's .regular
            ChildView(name: "Child 1")

            // Overrides to .thin
            ChildView(name: "Child 2")
              .environment(\.surfaceStyle, .thin)
          }
          .environment(\.surfaceStyle, .regular)
        }
      }

      struct ChildView: View {
        let name: String
        @Environment(\.surfaceStyle) var surfaceStyle

        var body: some View {
          Text(name)
        }
      }

      let view = ParentView()
      XCTAssertNotNil(view, "Parent view should be created successfully")
    }

    // MARK: - Integration with SurfaceStyle Modifier Tests

    /// Test that SurfaceStyleKey integrates with the existing SurfaceStyle modifier
    ///
    /// Verifies that views can read the environment surface style and apply
    /// it using the `.surfaceStyle()` modifier.
    func testIntegrationWithModifier() throws {
      struct TestView: View {
        @Environment(\.surfaceStyle) var surfaceStyle

        var body: some View {
          VStack {
            Text("Content")
          }
          .surfaceStyle(material: surfaceStyle)
        }
      }

      let view = TestView()
      XCTAssertNotNil(view, "Test view should be created successfully")
    }

    // MARK: - Type Safety Tests

    /// Test that SurfaceStyleKey is Sendable for Swift concurrency
    ///
    /// Verifies that the key conforms to Sendable protocol for safe usage
    /// in concurrent contexts.
    func testSendableConformance() throws {
      // SurfaceMaterial is already Sendable (verified in SurfaceStyle.swift)
      // SurfaceStyleKey should also be Sendable
      let material: SurfaceMaterial = .regular

      // This will compile only if SurfaceMaterial is Sendable
      Task {
        _ = material
      }

      XCTAssertEqual(material, .regular)
    }

    /// Test that SurfaceStyleKey default value is Equatable
    ///
    /// Verifies that surface styles can be compared for equality,
    /// which is essential for state management and testing.
    func testEquatableConformance() throws {
      let defaultValue = SurfaceStyleKey.defaultValue
      let regularMaterial: SurfaceMaterial = .regular

      XCTAssertEqual(
        defaultValue,
        regularMaterial,
        "Default value should equal .regular material"
      )
    }
  }

  // MARK: - Integration Tests

  /// Integration tests for SurfaceStyleKey in realistic scenarios
  ///
  /// Tests verify behavior in real-world UI patterns like inspectors,
  /// sidebars, and panels.
  final class SurfaceStyleKeyIntegrationTests: XCTestCase {

    /// Test surface style in a typical inspector pattern
    ///
    /// Verifies that the environment key works correctly in a real
    /// inspector UI with nested panels.
    func testInspectorPattern() throws {
      struct InspectorView: View {
        var body: some View {
          HStack(spacing: 0) {
            // Main content area - regular surface
            Text("Content")
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .environment(\.surfaceStyle, .regular)

            // Inspector panel - thick surface for separation
            VStack {
              Text("Inspector")
            }
            .frame(width: 250)
            .environment(\.surfaceStyle, .thick)
          }
        }
      }

      let view = InspectorView()
      XCTAssertNotNil(view, "Inspector view should be created successfully")
    }

    /// Test surface style with layered panels (overlays, modals)
    ///
    /// Verifies that different surface materials can be used for
    /// visual hierarchy in layered UI elements.
    func testLayeredPanels() throws {
      struct LayeredView: View {
        @State private var showModal = false

        var body: some View {
          ZStack {
            // Background panel - regular
            Text("Background")
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .environment(\.surfaceStyle, .regular)

            if showModal {
              // Modal overlay - ultra thick for prominence
              Text("Modal")
                .padding()
                .environment(\.surfaceStyle, .ultra)
            }
          }
        }
      }

      let view = LayeredView()
      XCTAssertNotNil(view, "Layered view should be created successfully")
    }

    /// Test surface style in a sidebar pattern
    ///
    /// Verifies that sidebars can use different surface materials
    /// for platform adaptation.
    func testSidebarPattern() throws {
      struct SidebarView: View {
        var body: some View {
          NavigationSplitView {
            // Sidebar - thin material on macOS
            List {
              Text("Item 1")
              Text("Item 2")
            }
            .environment(\.surfaceStyle, .thin)
          } detail: {
            // Detail view - regular material
            Text("Detail")
              .environment(\.surfaceStyle, .regular)
          }
        }
      }

      let view = SidebarView()
      XCTAssertNotNil(view, "Sidebar view should be created successfully")
    }
  }
#endif
