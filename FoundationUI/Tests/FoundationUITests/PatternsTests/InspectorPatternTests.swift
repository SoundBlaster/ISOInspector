// swift-tools-version: 6.0
import XCTest
import SwiftUI
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
        XCTAssertEqual(pattern.material, .thinMaterial, "InspectorPattern should default to thin material background")
    }

    func testInspectorPatternMaterialModifierProducesNewInstance() {
        // Given
        let basePattern = InspectorPattern(title: "Details") {
            Text("Content")
        }

        // When
        let updatedPattern = basePattern.material(.regular)

        // Then
        XCTAssertEqual(updatedPattern.material, .regular, "Material modifier should update the background material")
        XCTAssertEqual(updatedPattern.title, basePattern.title, "Material modifier should preserve the title")
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
}
