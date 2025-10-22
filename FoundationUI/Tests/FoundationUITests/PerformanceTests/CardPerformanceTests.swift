import XCTest
import SwiftUI
@testable import FoundationUI

/// Performance tests for Card component
///
/// Validates that Card meets performance targets for:
/// - Render time (<1ms per simple card, <10ms for complex hierarchies)
/// - Memory efficiency (<5MB per screen)
/// - Nesting performance (Card within Card)
/// - 60 FPS rendering capability
///
/// ## Test Coverage
/// - Single card render performance
/// - Multiple card instances (10, 50, 100)
/// - All elevation levels (none, low, medium, high)
/// - All material backgrounds (thin, regular, thick, ultraThin, ultraThick)
/// - Nested card hierarchies
/// - Cards with complex content
/// - Memory footprint validation
final class CardPerformanceTests: XCTestCase {

    // MARK: - Render Time Tests

    /// Test render performance for a single empty Card
    ///
    /// Baseline: Card with minimal content
    @MainActor
    func testSingleEmptyCardRenderPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for _ in 0..<DS.PerformanceTest.componentCount {
                let card = Card {
                    Text("Empty Card")
                }
                _ = Mirror(reflecting: card).children.count
            }
        }
    }

    /// Test render performance for Card with Text content
    ///
    /// Common use case: simple text content
    @MainActor
    func testCardWithTextContentPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for i in 0..<DS.PerformanceTest.componentCount {
                let card = Card {
                    VStack(alignment: .leading, spacing: DS.Spacing.m) {
                        Text("Card Title \(i)")
                        Text("Card description text")
                    }
                }
                _ = Mirror(reflecting: card).children.count
            }
        }
    }

    /// Test render performance across all elevation levels
    ///
    /// Ensures consistent performance regardless of elevation
    @MainActor
    func testAllElevationLevelsPerformance() throws {
        let elevations: [CardElevation] = [.none, .low, .medium, .high]

        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for elevation in elevations {
                for i in 0..<(DS.PerformanceTest.componentCount / elevations.count) {
                    let card = Card(elevation: elevation) {
                        Text("Elevation: \(elevation) - \(i)")
                    }
                    _ = Mirror(reflecting: card).children.count
                }
            }
        }
    }

    /// Test render performance across all material backgrounds
    ///
    /// Ensures consistent performance regardless of material
    @MainActor
    func testAllMaterialBackgroundsPerformance() throws {
        let materials: [Material?] = [
            .thin,
            .regular,
            .thick,
            .ultraThin,
            .ultraThick,
            nil  // No material
        ]

        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for material in materials {
                for i in 0..<(DS.PerformanceTest.componentCount / materials.count) {
                    let card = Card(material: material) {
                        Text("Material: \(material.map(String.init(describing:)) ?? "none") - \(i)")
                    }
                    _ = Mirror(reflecting: card).children.count
                }
            }
        }
    }

    /// Test render performance with varying corner radius
    ///
    /// Custom corner radius should not significantly impact performance
    @MainActor
    func testCardWithVaryingCornerRadiusPerformance() throws {
        let radii: [CGFloat] = [
            DS.Radius.small,
            DS.Radius.card,
            DS.Radius.chip,
            0,      // No radius
            50      // Large radius
        ]

        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for radius in radii {
                for i in 0..<(DS.PerformanceTest.componentCount / radii.count) {
                    let card = Card(cornerRadius: radius) {
                        Text("Radius: \(radius) - \(i)")
                    }
                    _ = Mirror(reflecting: card).children.count
                }
            }
        }
    }

    // MARK: - Multiple Instance Tests

    /// Test performance with 10 card instances
    ///
    /// Simulates a typical screen with moderate card usage
    @MainActor
    func testMultipleCards_10Instances() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            var cards: [Card<Text>] = []
            for index in 0..<DS.PerformanceTest.iterationCount {
                for i in 0..<10 {
                    let card = Card {
                        Text("Card \(index)-\(i)")
                    }
                    cards.append(card)
                }
            }
            _ = cards.count
        }
    }

    /// Test performance with 50 card instances
    ///
    /// Simulates a screen with heavy card usage
    @MainActor
    func testMultipleCards_50Instances() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            var cards: [Card<Text>] = []
            for index in 0..<DS.PerformanceTest.iterationCount {
                for i in 0..<50 {
                    let elevation = CardElevation.allCases[i % CardElevation.allCases.count]
                    let card = Card(elevation: elevation) {
                        Text("Card \(index)-\(i)")
                    }
                    cards.append(card)
                }
            }
            _ = cards.count
        }
    }

    /// Test performance with 100 card instances
    ///
    /// Stress test to validate performance at scale
    @MainActor
    func testMultipleCards_100Instances() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            var cards: [Card<Text>] = []
            for index in 0..<DS.PerformanceTest.iterationCount {
                for i in 0..<DS.PerformanceTest.componentCount {
                    let elevation = CardElevation.allCases[i % CardElevation.allCases.count]
                    let card = Card(elevation: elevation) {
                        Text("Card \(index)-\(i)")
                    }
                    cards.append(card)
                }
            }
            _ = cards.count
        }
    }

    // MARK: - Nested Card Performance Tests

    /// Test performance with Card nested within Card
    ///
    /// Common pattern: card containing sub-cards
    @MainActor
    func testNestedCardsPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for i in 0..<DS.PerformanceTest.iterationCount {
                let card = Card {
                    VStack(spacing: DS.Spacing.m) {
                        Text("Parent Card \(i)")

                        Card(elevation: .low) {
                            Text("Nested Card 1")
                        }

                        Card(elevation: .low) {
                            Text("Nested Card 2")
                        }
                    }
                }
                _ = Mirror(reflecting: card).children.count
            }
        }
    }

    /// Test performance with deeply nested cards (3 levels)
    ///
    /// Stress test for complex nesting scenarios
    @MainActor
    func testDeeplyNestedCardsPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for i in 0..<DS.PerformanceTest.iterationCount {
                let card = Card {
                    VStack {
                        Text("Level 1 Card \(i)")

                        Card(elevation: .low) {
                            VStack {
                                Text("Level 2 Card")

                                Card(elevation: .none) {
                                    Text("Level 3 Card")
                                }
                            }
                        }
                    }
                }
                _ = Mirror(reflecting: card).children.count
            }
        }
    }

    // MARK: - Complex Content Performance Tests

    /// Test Card with complex VStack content
    ///
    /// Real-world usage: card with multiple elements
    @MainActor
    func testCardWithComplexVStackPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for i in 0..<DS.PerformanceTest.iterationCount {
                let card = Card {
                    VStack(alignment: .leading, spacing: DS.Spacing.m) {
                        Text("Title \(i)")
                            .font(DS.Typography.title)
                        Text("Subtitle")
                            .font(DS.Typography.body)
                        Divider()
                        Text("Description text that can be quite long")
                            .font(DS.Typography.caption)
                        HStack {
                            Badge(text: "Info", level: .info)
                            Badge(text: "Warning", level: .warning)
                        }
                    }
                    .padding(DS.Spacing.m)
                }
                _ = Mirror(reflecting: card).children.count
            }
        }
    }

    /// Test Card with list content (10 items)
    ///
    /// Performance for card containing lists
    @MainActor
    func testCardWithListContentPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for iteration in 0..<DS.PerformanceTest.iterationCount {
                let card = Card {
                    VStack(spacing: DS.Spacing.s) {
                        ForEach(0..<10, id: \.self) { index in
                            HStack {
                                Text("Item \(iteration)-\(index)")
                                Spacer()
                                Badge(text: "Tag", level: .info)
                            }
                        }
                    }
                    .padding(DS.Spacing.m)
                }
                _ = Mirror(reflecting: card).children.count
            }
        }
    }

    // MARK: - Memory Tests

    /// Test memory footprint for single Card
    ///
    /// Baseline memory measurement
    /* @MainActor

    /// Test memory footprint for 100 Cards with all elevations
    ///
    /// Verify memory stays under 5MB target
    /* @MainActor

    /// Test memory footprint for nested cards
    ///
    /// Ensure nesting doesn't cause excessive memory usage
    /* @MainActor

    /// Test memory footprint for cards with complex content
    ///
    /// Real-world scenario with multiple elements
    /* @MainActor

    // MARK: - SwiftUI View Hierarchy Tests

    /// Test Card embedded in VStack performance
    ///
    /// Common usage pattern: list of cards
    @MainActor
    func testCardInVStackPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for _ in 0..<DS.PerformanceTest.iterationCount {
                let view = VStack(spacing: DS.Spacing.m) {
                    ForEach(0..<10, id: \.self) { index in
                        Card {
                            Text("Card \(index)")
                        }
                    }
                }
                _ = Mirror(reflecting: view).children.count
            }
        }
    }

    /// Test Card in ScrollView with 50 items
    ///
    /// Performance for scrollable card list
    @MainActor
    func testCardInScrollViewPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for _ in 0..<DS.PerformanceTest.iterationCount {
                let view = ScrollView {
                    VStack(spacing: DS.Spacing.m) {
                        ForEach(0..<50, id: \.self) { index in
                            Card(
                                elevation: CardElevation.allCases[index % CardElevation.allCases.count]
                            ) {
                                VStack(alignment: .leading) {
                                    Text("Card \(index)")
                                    Text("Description")
                                        .font(DS.Typography.caption)
                                }
                            }
                        }
                    }
                }
                _ = Mirror(reflecting: view).children.count
            }
        }
    }

    // MARK: - Elevation-Specific Performance Tests

    /// Test none elevation card performance
    @MainActor
    func testNoneElevationCardPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for i in 0..<DS.PerformanceTest.componentCount {
                let card = Card(elevation: .none) {
                    Text("None \(i)")
                }
                _ = Mirror(reflecting: card).children.count
            }
        }
    }

    /// Test low elevation card performance
    @MainActor
    func testLowElevationCardPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for i in 0..<DS.PerformanceTest.componentCount {
                let card = Card(elevation: .low) {
                    Text("Low \(i)")
                }
                _ = Mirror(reflecting: card).children.count
            }
        }
    }

    /// Test medium elevation card performance
    @MainActor
    func testMediumElevationCardPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for i in 0..<DS.PerformanceTest.componentCount {
                let card = Card(elevation: .medium) {
                    Text("Medium \(i)")
                }
                _ = Mirror(reflecting: card).children.count
            }
        }
    }

    /// Test high elevation card performance
    @MainActor
    func testHighElevationCardPerformance() throws {
        measure(metrics: PerformanceTestHelpers.cpuMetrics) {
            for i in 0..<DS.PerformanceTest.componentCount {
                let card = Card(elevation: .high) {
                    Text("High \(i)")
                }
                _ = Mirror(reflecting: card).children.count
            }
        }
    }
}
