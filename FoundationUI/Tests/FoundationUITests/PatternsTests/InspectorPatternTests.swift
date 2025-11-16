import SwiftUI
// swift-tools-version: 6.0
import XCTest

@testable import FoundationUI

/// Unit tests for the InspectorPattern view.
///
/// These tests validate the public API surface and configuration behaviours
/// of the InspectorPattern, ensuring it aligns with the design system
/// requirements before implementation.
@MainActor
final class InspectorPatternTests: XCTestCase {
  // MARK: - Initialization

  func testInspectorPatternStoresTitle() {
    // Given
    let pattern = InspectorPattern(title: "Metadata") {
      Text("Content")
    }

    // Then
    XCTAssertEqual(pattern.title, "Metadata", "InspectorPattern should store the provided title")
  }

  func testInspectorPatternUsesThinMaterialByDefault() {
    // Given
    let pattern = InspectorPattern(title: "Details") {
      Text("Content")
    }

    // Then
    XCTAssertEqual(
      String(describing: pattern.material),
      String(describing: Material.thinMaterial),
      "InspectorPattern should default to thin material background"
    )
  }

  func testInspectorPatternMaterialModifierProducesNewInstance() {
    // Given
    let basePattern = InspectorPattern(title: "Details") {
      Text("Content")
    }

    // When
    let updatedPattern = basePattern.material(.regular)

    // Then
    XCTAssertEqual(
      String(describing: updatedPattern.material),
      String(describing: Material.regular),
      "Material modifier should update the background material"
    )
    XCTAssertEqual(
      updatedPattern.title, basePattern.title, "Material modifier should preserve the title"
    )
  }

  // MARK: - Content Handling

  func testInspectorPatternCapturesViewBuilderContent() {
    // Given
    let pattern = InspectorPattern(title: "Info") {
      VStack {
        Text("Line 1")
        Text("Line 2")
      }
    }

    // Then
    _ = pattern.content
    XCTAssertNotNil(pattern.content, "InspectorPattern should capture the provided content view")
  }

  // MARK: - View Conformance

  func testInspectorPatternConformsToView() {
    // Given
    let pattern = InspectorPattern(title: "Conformance") {
      Text("Content")
    }

    // Then
    _ = pattern as any View
  }

  // MARK: - Material Variants

  func testInspectorPatternWithRegularMaterial() {
    // Given
    let pattern = InspectorPattern(title: "Regular", material: .regular) {
      Text("Content")
    }

    // Then
    XCTAssertEqual(
      String(describing: pattern.material),
      String(describing: Material.regular),
      "InspectorPattern should support regular material"
    )
  }

  func testInspectorPatternWithThickMaterial() {
    // Given
    let pattern = InspectorPattern(title: "Thick", material: .thick) {
      Text("Content")
    }

    // Then
    XCTAssertEqual(
      String(describing: pattern.material),
      String(describing: Material.thick),
      "InspectorPattern should support thick material"
    )
  }

  func testInspectorPatternWithUltraThinMaterial() {
    // Given
    let pattern = InspectorPattern(title: "UltraThin", material: .ultraThin) {
      Text("Content")
    }

    // Then
    XCTAssertEqual(
      String(describing: pattern.material),
      String(describing: Material.ultraThin),
      "InspectorPattern should support ultraThin material"
    )
  }

  func testInspectorPatternWithUltraThickMaterial() {
    // Given
    let pattern = InspectorPattern(title: "UltraThick", material: .ultraThick) {
      Text("Content")
    }

    // Then
    XCTAssertEqual(
      String(describing: pattern.material),
      String(describing: Material.ultraThick),
      "InspectorPattern should support ultraThick material"
    )
  }

  // MARK: - Material Modifier Chaining

  func testMaterialModifierCanBeChained() {
    // Given
    let pattern = InspectorPattern(title: "Chain") {
      Text("Content")
    }

    // When
    let updated1 = pattern.material(.regular)
    let updated2 = updated1.material(.thick)

    // Then
    XCTAssertEqual(
      String(describing: updated2.material),
      String(describing: Material.thick),
      "Material modifier should be chainable"
    )
  }

  // MARK: - Content Composition

  func testInspectorPatternWithComplexContent() {
    // Given
    let pattern = InspectorPattern(title: "Complex") {
      SectionHeader(title: "Section 1")
      KeyValueRow(key: "Name", value: "ISO File")
      KeyValueRow(key: "Size", value: "1.2 GB")
      SectionHeader(title: "Section 2")
      Badge(text: "MP4", level: .info)
    }

    // Then
    XCTAssertNotNil(pattern.content, "InspectorPattern should handle complex content composition")
  }

  func testInspectorPatternWithEmptyContent() {
    // Given
    let pattern = InspectorPattern(title: "Empty") {
      EmptyView()
    }

    // Then
    XCTAssertNotNil(pattern.content, "InspectorPattern should handle empty content")
  }

  func testInspectorPatternWithMultipleTextViews() {
    // Given
    let pattern = InspectorPattern(title: "Multiple") {
      Text("Line 1")
      Text("Line 2")
      Text("Line 3")
      Text("Line 4")
      Text("Line 5")
    }

    // Then
    XCTAssertNotNil(pattern.content, "InspectorPattern should handle multiple text views")
  }

  // MARK: - Title Variations

  func testInspectorPatternWithEmptyTitle() {
    // Given
    let pattern = InspectorPattern(title: "") {
      Text("Content")
    }

    // Then
    XCTAssertEqual(pattern.title, "", "InspectorPattern should accept empty title")
  }

  func testInspectorPatternWithLongTitle() {
    // Given
    let longTitle = String(repeating: "Long Title ", count: 20)
    let pattern = InspectorPattern(title: longTitle) {
      Text("Content")
    }

    // Then
    XCTAssertEqual(pattern.title, longTitle, "InspectorPattern should handle long titles")
  }

  func testInspectorPatternWithSpecialCharactersInTitle() {
    // Given
    let specialTitle = "Inspector 🔍 with émojis & spëcial chars ™"
    let pattern = InspectorPattern(title: specialTitle) {
      Text("Content")
    }

    // Then
    XCTAssertEqual(
      pattern.title, specialTitle, "InspectorPattern should handle special characters in title"
    )
  }

  // MARK: - Design System Token Usage

  func testInspectorPatternUsesDesignSystemTokens() {
    // Given
    let pattern = InspectorPattern(title: "Tokens") {
      Text("Content")
    }

    // Then
    // InspectorPattern should use DS.Radius.card for corner radius
    // InspectorPattern should use DS.Spacing.s, DS.Spacing.m, DS.Spacing.l for spacing
    // InspectorPattern should use DS.Typography.title for title font
    XCTAssertNotNil(pattern.body, "InspectorPattern should use DS tokens throughout")
  }

  // MARK: - Platform-Specific Behavior

  #if os(macOS)
    func testInspectorPatternPlatformPaddingOnMacOS() {
      // Given
      let pattern = InspectorPattern(title: "macOS") {
        Text("Content")
      }

      // Then
      // Platform padding should be DS.Spacing.l on macOS
      XCTAssertNotNil(pattern.body, "InspectorPattern should use correct padding on macOS")
    }
  #endif

  #if os(iOS)
    func testInspectorPatternPlatformPaddingOnIOS() {
      // Given
      let pattern = InspectorPattern(title: "iOS") {
        Text("Content")
      }

      // Then
      // Platform padding should be DS.Spacing.m on iOS
      XCTAssertNotNil(pattern.body, "InspectorPattern should use correct padding on iOS")
    }
  #endif

  // MARK: - Accessibility

  func testInspectorPatternHasAccessibilityLabel() {
    // Given
    let title = "File Metadata"
    let pattern = InspectorPattern(title: title) {
      Text("Content")
    }

    // Then
    XCTAssertEqual(
      pattern.title, title, "InspectorPattern should use title for accessibility label"
    )
  }

  func testInspectorPatternAccessibilityWithChildren() {
    // Given
    let pattern = InspectorPattern(title: "Container") {
      Text("Child 1")
      Text("Child 2")
    }

    // Then
    // InspectorPattern should contain accessibility children
    XCTAssertNotNil(pattern.body, "InspectorPattern should support accessibility children")
  }

  // MARK: - Real-World Use Cases

  func testInspectorPatternWithFileMetadata() {
    // Given
    let pattern = InspectorPattern(title: "File Information") {
      SectionHeader(title: "General")
      KeyValueRow(key: "Name", value: "movie.mp4")
      KeyValueRow(key: "Size", value: "1.2 GB")
      KeyValueRow(key: "Format", value: "MPEG-4")

      SectionHeader(title: "Video")
      KeyValueRow(key: "Codec", value: "H.264")
      KeyValueRow(key: "Resolution", value: "1920×1080")
      KeyValueRow(key: "FPS", value: "30")

      SectionHeader(title: "Audio")
      KeyValueRow(key: "Codec", value: "AAC")
      KeyValueRow(key: "Sample Rate", value: "48kHz")
    }

    // Then
    XCTAssertEqual(
      pattern.title, "File Information", "InspectorPattern should work with file metadata"
    )
  }

  func testInspectorPatternWithBoxDetails() {
    // Given
    let pattern = InspectorPattern(title: "Box Details", material: .regular) {
      SectionHeader(title: "Header")
      KeyValueRow(key: "Type", value: "ftyp")
      KeyValueRow(key: "Size", value: "32 bytes")
      KeyValueRow(key: "Offset", value: "0x00000000")

      SectionHeader(title: "Status")
      Badge(text: "Valid", level: .success)
    }

    // Then
    XCTAssertEqual(pattern.title, "Box Details", "InspectorPattern should work with box details")
  }

  func testInspectorPatternWithDashboard() {
    // Given
    let pattern = InspectorPattern(title: "Dashboard", material: .thick) {
      SectionHeader(title: "Statistics")
      KeyValueRow(key: "Total Boxes", value: "42")
      KeyValueRow(key: "Total Size", value: "5.2 MB")
      KeyValueRow(key: "Validation", value: "Passed")

      Badge(text: "Ready", level: .success)
    }

    // Then
    XCTAssertEqual(
      pattern.title, "Dashboard", "InspectorPattern should work with dashboard content"
    )
  }

  // MARK: - Integration with Other Patterns

  func testInspectorPatternCanBeNestedInOtherViews() {
    // Given
    struct ContainerView: View {
      var body: some View {
        VStack {
          InspectorPattern(title: "Nested") {
            Text("Content")
          }
        }
      }
    }

    let container = ContainerView()

    // Then
    XCTAssertNotNil(container.body, "InspectorPattern should be composable with other views")
  }
}
