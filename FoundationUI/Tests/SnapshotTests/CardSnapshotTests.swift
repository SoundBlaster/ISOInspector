// swift-tools-version: 6.0
import XCTest
import SwiftUI
import SnapshotTesting
@testable import FoundationUI

/// Snapshot tests for Card component visual regression testing
///
/// These tests capture visual snapshots of the Card component in various
/// configurations to prevent unintended visual changes and ensure consistent
/// rendering across platforms, themes, and accessibility settings.
///
/// ## Test Coverage
/// - All CardElevation levels (none, low, medium, high)
/// - All corner radius options (via DS.Radius tokens)
/// - Light and Dark mode
/// - Dynamic Type sizes (XS, M, XXL)
/// - Different material backgrounds (thin, regular, thick)
/// - Various content types (text, images, nested components)
/// - Platform-specific rendering
///
/// ## Recording Snapshots
/// To record new baseline snapshots:
/// 1. Set `isRecording = true` in any test
/// 2. Run the test suite: `swift test`
/// 3. Verify generated snapshots look correct
/// 4. Commit snapshots to repository
/// 5. Set `isRecording = false`
@MainActor
final class CardSnapshotTests: XCTestCase {

    // MARK: - Elevation Tests (Light Mode)

    func testCardElevationNone() {
        let card = Card(elevation: .none) {
            Text("No Elevation")
                .padding()
        }
        let view = card
            .frame(width: 300, height: 150)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testCardElevationLow() {
        let card = Card(elevation: .low) {
            Text("Low Elevation")
                .padding()
        }
        let view = card
            .frame(width: 300, height: 150)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testCardElevationMedium() {
        let card = Card(elevation: .medium) {
            Text("Medium Elevation (Default)")
                .padding()
        }
        let view = card
            .frame(width: 300, height: 150)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testCardElevationHigh() {
        let card = Card(elevation: .high) {
            Text("High Elevation")
                .padding()
        }
        let view = card
            .frame(width: 300, height: 150)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    // MARK: - Dark Mode Tests

    func testCardElevationNoneDarkMode() {
        let card = Card(elevation: .none) {
            Text("No Elevation")
                .padding()
        }
        let view = card
            .frame(width: 300, height: 150)
            .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testCardElevationLowDarkMode() {
        let card = Card(elevation: .low) {
            Text("Low Elevation")
                .padding()
        }
        let view = card
            .frame(width: 300, height: 150)
            .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testCardElevationMediumDarkMode() {
        let card = Card(elevation: .medium) {
            Text("Medium Elevation")
                .padding()
        }
        let view = card
            .frame(width: 300, height: 150)
            .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testCardElevationHighDarkMode() {
        let card = Card(elevation: .high) {
            Text("High Elevation")
                .padding()
        }
        let view = card
            .frame(width: 300, height: 150)
            .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    // MARK: - Corner Radius Tests

    func testCardCornerRadiusSmall() {
        let card = Card(elevation: .medium, cornerRadius: DS.Radius.small) {
            Text("Small Corner Radius")
                .padding()
        }
        let view = card
            .frame(width: 300, height: 150)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testCardCornerRadiusMedium() {
        let card = Card(elevation: .medium, cornerRadius: DS.Radius.medium) {
            Text("Medium Corner Radius")
                .padding()
        }
        let view = card
            .frame(width: 300, height: 150)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testCardCornerRadiusCard() {
        let card = Card(elevation: .medium, cornerRadius: DS.Radius.card) {
            Text("Card Corner Radius (Default)")
                .padding()
        }
        let view = card
            .frame(width: 300, height: 150)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    // MARK: - Material Background Tests

    func testCardWithThinMaterial() {
        let card = Card(elevation: .medium, material: .thin) {
            VStack {
                Text("Thin Material")
                    .font(.headline)
                Text("Translucent background")
                    .font(.caption)
            }
            .padding()
        }
        let view = card
            .frame(width: 300, height: 150)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testCardWithRegularMaterial() {
        let card = Card(elevation: .medium, material: .regular) {
            VStack {
                Text("Regular Material")
                    .font(.headline)
                Text("Standard translucent background")
                    .font(.caption)
            }
            .padding()
        }
        let view = card
            .frame(width: 300, height: 150)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testCardWithThickMaterial() {
        let card = Card(elevation: .medium, material: .thick) {
            VStack {
                Text("Thick Material")
                    .font(.headline)
                Text("More opaque background")
                    .font(.caption)
            }
            .padding()
        }
        let view = card
            .frame(width: 300, height: 150)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testCardWithUltraThinMaterial() {
        let card = Card(elevation: .low, material: .ultraThin) {
            Text("Ultra Thin Material")
                .padding()
        }
        let view = card
            .frame(width: 300, height: 150)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testCardWithUltraThickMaterial() {
        let card = Card(elevation: .high, material: .ultraThick) {
            Text("Ultra Thick Material")
                .padding()
        }
        let view = card
            .frame(width: 300, height: 150)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    // MARK: - Dynamic Type Tests

    func testCardDynamicTypeExtraSmall() {
        let card = Card(elevation: .medium) {
            VStack(alignment: .leading) {
                Text("Title")
                    .font(.headline)
                Text("Content with extra small text size")
                    .font(.body)
            }
            .padding()
        }
        let view = card
            .frame(width: 300, height: 200)
            .environment(\.sizeCategory, .extraSmall)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testCardDynamicTypeMedium() {
        let card = Card(elevation: .medium) {
            VStack(alignment: .leading) {
                Text("Title")
                    .font(.headline)
                Text("Content with medium text size")
                    .font(.body)
            }
            .padding()
        }
        let view = card
            .frame(width: 300, height: 200)
            .environment(\.sizeCategory, .medium)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testCardDynamicTypeExtraExtraLarge() {
        let card = Card(elevation: .medium) {
            VStack(alignment: .leading) {
                Text("Title")
                    .font(.headline)
                Text("Content with extra extra large text size")
                    .font(.body)
            }
            .padding()
        }
        let view = card
            .frame(width: 350, height: 250)
            .environment(\.sizeCategory, .accessibilityExtraExtraLarge)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    // MARK: - Content Variation Tests

    func testCardWithSimpleText() {
        let card = Card(elevation: .medium) {
            Text("Simple Text Content")
                .padding()
        }
        let view = card
            .frame(width: 300, height: 150)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testCardWithVStackContent() {
        let card = Card(elevation: .medium) {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                Text("Card Title")
                    .font(.headline)
                Text("This is the main content of the card with multiple lines of text.")
                    .font(.body)
                Text("Additional information")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        let view = card
            .frame(width: 350, height: 250)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testCardWithBadges() {
        let card = Card(elevation: .medium) {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                Text("Status Card")
                    .font(.headline)
                HStack {
                    Badge(text: "VALID", level: .success)
                    Badge(text: "NEW", level: .info)
                }
            }
            .padding()
        }
        let view = card
            .frame(width: 300, height: 200)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    // MARK: - Nested Cards Tests

    func testNestedCards() {
        let card = Card(elevation: .high) {
            VStack(spacing: DS.Spacing.m) {
                Text("Outer Card")
                    .font(.headline)

                Card(elevation: .low) {
                    Text("Inner Card")
                        .padding()
                }
            }
            .padding()
        }
        let view = card
            .frame(width: 350, height: 250)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    // MARK: - RTL Support Tests

    func testCardRTLLocale() {
        let card = Card(elevation: .medium) {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                Text("عنوان")
                    .font(.headline)
                Text("هذا هو المحتوى الرئيسي للبطاقة")
                    .font(.body)
            }
            .padding()
        }
        let view = card
            .frame(width: 300, height: 200)
            .environment(\.layoutDirection, .rightToLeft)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    // MARK: - Comparison Tests

    func testCardAllElevationsComparison() {
        let view = VStack(spacing: DS.Spacing.l) {
            Card(elevation: .none) {
                Text("None")
                    .padding()
            }
            Card(elevation: .low) {
                Text("Low")
                    .padding()
            }
            Card(elevation: .medium) {
                Text("Medium")
                    .padding()
            }
            Card(elevation: .high) {
                Text("High")
                    .padding()
            }
        }
        .frame(width: 300, height: 600)
        .padding()

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testCardAllElevationsDarkMode() {
        let view = VStack(spacing: DS.Spacing.l) {
            Card(elevation: .none) {
                Text("None")
                    .padding()
            }
            Card(elevation: .low) {
                Text("Low")
                    .padding()
            }
            Card(elevation: .medium) {
                Text("Medium")
                    .padding()
            }
            Card(elevation: .high) {
                Text("High")
                    .padding()
            }
        }
        .frame(width: 300, height: 600)
        .padding()
        .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    // MARK: - Real-World Usage Tests

    func testCardRealWorldUsageInspectorPanel() {
        let card = Card(elevation: .medium) {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                SectionHeader(title: "File Information")
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    HStack {
                        Text("Type:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Badge(text: "VALID", level: .success)
                    }
                    HStack {
                        Text("Size:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("2.4 MB")
                            .font(.caption)
                    }
                }
            }
            .padding()
        }
        let view = card
            .frame(width: 350, height: 250)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }
}
