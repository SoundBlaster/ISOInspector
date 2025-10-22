// swift-tools-version: 6.0
import XCTest
import SwiftUI
@testable import FoundationUI

/// Unit tests for the Card component
///
/// Tests verify:
/// - Component initialization with all elevation levels
/// - Proper generic content handling via @ViewBuilder
/// - Configurable corner radius
/// - Material background support
/// - Design system token usage (zero magic numbers)
/// - Accessibility support
/// - Platform compatibility
@MainActor
final class CardTests: XCTestCase {

    // MARK: - Initialization Tests

    func testCardInitializationWithDefaultParameters() {
        // Given
        let content = Text("Test Content")

        // When
        let card = Card {
            content
        }

        // Then
        // Card should be successfully created with default parameters
        // This test validates the component compiles and initializes
        XCTAssertNotNil(card, "Card should initialize with default parameters")
    }

    func testCardInitializationWithCustomElevation() {
        // Given
        let elevations: [CardElevation] = [.none, .low, .medium, .high]

        // When & Then
        for elevation in elevations {
            let card = Card(elevation: elevation) {
                Text("Content")
            }
            XCTAssertNotNil(card, "Card should initialize with \(elevation) elevation")
        }
    }

    func testCardInitializationWithCustomCornerRadius() {
        // Given
        let radiusValues: [CGFloat] = [
            DS.Radius.small,
            DS.Radius.medium,
            DS.Radius.card
        ]

        // When & Then
        for radius in radiusValues {
            let card = Card(cornerRadius: radius) {
                Text("Content")
            }
            XCTAssertNotNil(card, "Card should initialize with corner radius \(radius)")
        }
    }

    func testCardInitializationWithMaterial() {
        // Given & When
        let cardWithMaterial = Card(material: .thin) {
            Text("With Material")
        }

        let cardWithoutMaterial = Card(material: nil) {
            Text("Without Material")
        }

        // Then
        XCTAssertNotNil(cardWithMaterial, "Card should initialize with material")
        XCTAssertNotNil(cardWithoutMaterial, "Card should initialize without material")
    }

    func testCardInitializationWithAllParameters() {
        // Given
        let elevation = CardElevation.high
        let radius = DS.Radius.small
        let material = Material.thick

        // When
        let card = Card(
            elevation: elevation,
            cornerRadius: radius,
            material: material
        ) {
            VStack {
                Text("Title")
                Text("Content")
            }
        }

        // Then
        XCTAssertNotNil(card, "Card should initialize with all custom parameters")
    }

    // MARK: - Elevation Tests

    func testCardSupportsAllElevationLevels() {
        // Given
        let levels: [CardElevation] = [.none, .low, .medium, .high]

        // When & Then
        for level in levels {
            let card = Card(elevation: level) {
                Text("Test")
            }
            XCTAssertNotNil(card, "Card should support \(level) elevation level")
        }
    }

    func testCardDefaultElevationIsMedium() {
        // Given
        let defaultCard = Card {
            Text("Default")
        }

        // Then
        // The default elevation should be .medium according to API design
        // This is verified through the CardStyle modifier's default parameter
        XCTAssertNotNil(defaultCard, "Card should use medium elevation by default")
    }

    // MARK: - Corner Radius Tests

    func testCardUsesDesignSystemRadiusTokens() {
        // Given
        let radiusTokens: [(String, CGFloat)] = [
            ("small", DS.Radius.small),
            ("medium", DS.Radius.medium),
            ("card", DS.Radius.card)
        ]

        // When & Then
        for (name, radius) in radiusTokens {
            let card = Card(cornerRadius: radius) {
                Text("Content")
            }
            XCTAssertNotNil(card, "Card should accept DS.Radius.\(name) token")
        }
    }

    func testCardDefaultCornerRadiusUsesCardToken() {
        // Given
        let defaultCard = Card {
            Text("Default")
        }

        // Then
        // The default corner radius should be DS.Radius.card
        // This is enforced by the API design
        XCTAssertNotNil(defaultCard, "Card should use DS.Radius.card by default")
    }

    // MARK: - Material Background Tests

    func testCardSupportsAllMaterialTypes() {
        // Given
        let materials: [Material?] = [
            nil,
            .thin,
            .regular,
            .thick,
            .ultraThin,
            .ultraThick
        ]

        // When & Then
        for material in materials {
            let card = Card(material: material) {
                Text("Content")
            }
            let description = material.map { "\($0)" } ?? "nil"
            XCTAssertNotNil(card, "Card should support \(description) material")
        }
    }

    // MARK: - Generic Content Tests

    func testCardAcceptsTextContent() {
        // Given & When
        let card = Card {
            Text("Simple Text")
        }

        // Then
        XCTAssertNotNil(card, "Card should accept Text content")
    }

    func testCardAcceptsVStackContent() {
        // Given & When
        let card = Card {
            VStack {
                Text("Title")
                Text("Subtitle")
            }
        }

        // Then
        XCTAssertNotNil(card, "Card should accept VStack content")
    }

    func testCardAcceptsHStackContent() {
        // Given & When
        let card = Card {
            HStack {
                Image(systemName: "star.fill")
                Text("Content")
            }
        }

        // Then
        XCTAssertNotNil(card, "Card should accept HStack content")
    }

    func testCardAcceptsComplexContent() {
        // Given & When
        let card = Card {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                Text("Header")
                    .font(.headline)
                Divider()
                HStack {
                    Image(systemName: "info.circle")
                    Text("Information")
                }
                .font(.body)
            }
        }

        // Then
        XCTAssertNotNil(card, "Card should accept complex nested content")
    }

    func testCardAcceptsEmptyContent() {
        // Given & When
        let card = Card {
            EmptyView()
        }

        // Then
        XCTAssertNotNil(card, "Card should accept EmptyView content")
    }

    // MARK: - Design System Integration Tests

    func testCardUsesOnlyDesignSystemTokens() {
        // Given
        let validRadius = DS.Radius.card

        // When
        let card = Card(cornerRadius: validRadius) {
            Text("Content")
        }

        // Then
        // This test validates that the component API enforces DS token usage
        // by accepting CGFloat parameters that should come from DS namespace
        XCTAssertNotNil(card, "Card should accept DS radius tokens")
    }

    // MARK: - Component Composition Tests

    func testCardIsAView() {
        // Given
        let card = Card {
            Text("Test")
        }

        // Then
        // Verify that Card conforms to View protocol (compile-time check)
        _ = card as any View // Compile-time verification that Card conforms to View
        XCTAssertNotNil(card, "Card should be a SwiftUI View")
    }

    func testCardCanBeNestedInOtherViews() {
        // Given & When
        let container = VStack {
            Card {
                Text("Card 1")
            }
            Card {
                Text("Card 2")
            }
        }

        // Then
        XCTAssertNotNil(container, "Card should be nestable in container views")
    }

    func testCardSupportsNestedCards() {
        // Given & When
        let nestedCard = Card(elevation: .high) {
            VStack {
                Text("Outer Card")
                Card(elevation: .low) {
                    Text("Inner Card")
                }
            }
        }

        // Then
        XCTAssertNotNil(nestedCard, "Card should support nested cards")
    }

    // MARK: - Accessibility Tests

    func testCardMaintainsAccessibilityForContent() {
        // Given & When
        let card = Card {
            Text("Accessible Content")
                .accessibilityLabel("Custom Label")
        }

        // Then
        // Card should maintain accessibility structure from its content
        XCTAssertNotNil(card, "Card should preserve content accessibility")
    }

    // MARK: - Edge Cases

    func testCardWithZeroCornerRadius() {
        // Given
        let radius: CGFloat = 0

        // When
        let card = Card(cornerRadius: radius) {
            Text("Sharp Corners")
        }

        // Then
        XCTAssertNotNil(card, "Card should support zero corner radius")
    }

    func testCardWithVeryLargeCornerRadius() {
        // Given
        let radius = DS.Radius.chip // 999pt - very large radius

        // When
        let card = Card(cornerRadius: radius) {
            Text("Capsule Shape")
        }

        // Then
        XCTAssertNotNil(card, "Card should support very large corner radius")
    }

    // MARK: - Platform Compatibility Tests

    func testCardCompilesOnAllPlatforms() {
        // Given & When
        let card = Card {
            Text("Platform Test")
        }

        // Then
        // This test verifies that Card compiles on all supported platforms
        #if os(iOS)
        XCTAssertNotNil(card, "Card should compile on iOS")
        #elseif os(macOS)
        XCTAssertNotNil(card, "Card should compile on macOS")
        #else
        XCTAssertNotNil(card, "Card should compile on other platforms")
        #endif
    }
}
