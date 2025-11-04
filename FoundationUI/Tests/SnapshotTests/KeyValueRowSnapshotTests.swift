// swift-tools-version: 6.0
import XCTest
import SwiftUI
import SnapshotTesting
@testable import FoundationUI

/// Snapshot tests for KeyValueRow component visual regression testing
///
/// These tests capture visual snapshots of the KeyValueRow component in various
/// configurations to prevent unintended visual changes and ensure consistent
/// rendering across platforms, themes, and accessibility settings.
///
/// ## Test Coverage
/// - Horizontal and vertical layouts
/// - Light and Dark mode
/// - Dynamic Type sizes (XS, M, XXL)
/// - With and without copyable text
/// - Long text truncation
/// - Monospaced vs regular fonts
/// - RTL locale support
/// - Platform-specific rendering
///
/// ## Recording Snapshots
/// To record new baseline snapshots:
/// 1. Set `isRecording = true` in any test
/// 2. Run the test suite: `swift test`
/// 3. Verify generated snapshots look correct
/// 4. Commit snapshots to repository
/// 5. Set `isRecording = false`
final class KeyValueRowSnapshotTests: XCTestCase {

    // MARK: - Horizontal Layout Tests (Light Mode)

    func testKeyValueRowHorizontalLayout() {
        let row = KeyValueRow(key: "Type", value: "ftyp")
        let view = row
            .frame(width: 300, height: 100)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testKeyValueRowHorizontalLayoutLongValue() {
        let row = KeyValueRow(key: "Description", value: "This is a long description text")
        let view = row
            .frame(width: 350, height: 100)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testKeyValueRowHorizontalLayoutShortKey() {
        let row = KeyValueRow(key: "ID", value: "12345")
        let view = row
            .frame(width: 300, height: 100)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    // MARK: - Vertical Layout Tests

    func testKeyValueRowVerticalLayout() {
        let row = KeyValueRow(key: "Type", value: "ftyp", layout: .vertical)
        let view = row
            .frame(width: 300, height: 150)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testKeyValueRowVerticalLayoutLongValue() {
        let row = KeyValueRow(
            key: "Description",
            value: "This is a very long description that should display properly in vertical layout",
            layout: .vertical
        )
        let view = row
            .frame(width: 350, height: 200)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testKeyValueRowVerticalLayoutHexValue() {
        let row = KeyValueRow(
            key: "Offset",
            value: "0x00001234ABCDEF",
            layout: .vertical
        )
        let view = row
            .frame(width: 300, height: 150)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    // MARK: - Dark Mode Tests

    func testKeyValueRowHorizontalDarkMode() {
        let row = KeyValueRow(key: "Size", value: "1024 bytes")
        let view = row
            .frame(width: 300, height: 100)
            .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testKeyValueRowVerticalDarkMode() {
        let row = KeyValueRow(
            key: "Description",
            value: "A detailed description in dark mode",
            layout: .vertical
        )
        let view = row
            .frame(width: 300, height: 150)
            .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    // MARK: - Copyable Text Tests

    func testKeyValueRowCopyableHorizontal() {
        let row = KeyValueRow(
            key: "Hash",
            value: "a1b2c3d4e5f6",
            copyable: true
        )
        let view = row
            .frame(width: 300, height: 100)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testKeyValueRowCopyableVertical() {
        let row = KeyValueRow(
            key: "Full Path",
            value: "/Users/example/Documents/file.mp4",
            layout: .vertical,
            copyable: true
        )
        let view = row
            .frame(width: 350, height: 150)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    // MARK: - Dynamic Type Tests

    func testKeyValueRowDynamicTypeExtraSmall() {
        let row = KeyValueRow(key: "Type", value: "ftyp")
        let view = row
            .frame(width: 300, height: 100)
            .environment(\.sizeCategory, .xSmall)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testKeyValueRowDynamicTypeMedium() {
        let row = KeyValueRow(key: "Type", value: "ftyp")
        let view = row
            .frame(width: 300, height: 100)
            .environment(\.sizeCategory, .medium)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testKeyValueRowDynamicTypeExtraExtraLarge() {
        let row = KeyValueRow(key: "Type", value: "ftyp")
        let view = row
            .frame(width: 350, height: 150)
            .environment(\.sizeCategory, .accessibilityXxLarge)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testKeyValueRowVerticalDynamicTypeExtraExtraLarge() {
        let row = KeyValueRow(
            key: "Description",
            value: "Long text in accessibility size",
            layout: .vertical
        )
        let view = row
            .frame(width: 350, height: 200)
            .environment(\.sizeCategory, .accessibilityXxLarge)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    // MARK: - Text Length Variants

    func testKeyValueRowVeryShortValues() {
        let row = KeyValueRow(key: "ID", value: "1")
        let view = row
            .frame(width: 300, height: 100)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testKeyValueRowVeryLongKey() {
        let row = KeyValueRow(
            key: "Very Long Key Name That Might Wrap",
            value: "12345"
        )
        let view = row
            .frame(width: 300, height: 120)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testKeyValueRowVeryLongValueHorizontal() {
        let row = KeyValueRow(
            key: "Hash",
            value: "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0"
        )
        let view = row
            .frame(width: 350, height: 120)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testKeyValueRowVeryLongValueVertical() {
        let row = KeyValueRow(
            key: "Full Description",
            value: "This is an extremely long value that contains multiple sentences and should properly wrap across several lines when displayed in vertical layout mode.",
            layout: .vertical
        )
        let view = row
            .frame(width: 350, height: 250)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    // MARK: - RTL Support Tests

    func testKeyValueRowRTLHorizontal() {
        let row = KeyValueRow(key: "النوع", value: "ftyp")
        let view = row
            .frame(width: 300, height: 100)
            .environment(\.layoutDirection, .rightToLeft)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testKeyValueRowRTLVertical() {
        let row = KeyValueRow(
            key: "الوصف",
            value: "هذا هو النص الطويل",
            layout: .vertical
        )
        let view = row
            .frame(width: 300, height: 150)
            .environment(\.layoutDirection, .rightToLeft)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testKeyValueRowRTLCopyable() {
        let row = KeyValueRow(
            key: "المسار",
            value: "/path/to/file",
            layout: .vertical,
            copyable: true
        )
        let view = row
            .frame(width: 300, height: 150)
            .environment(\.layoutDirection, .rightToLeft)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    // MARK: - Multiple Rows Comparison

    func testKeyValueRowMultipleHorizontal() {
        let view = VStack(alignment: .leading, spacing: DS.Spacing.m) {
            KeyValueRow(key: "Type", value: "ftyp")
            KeyValueRow(key: "Size", value: "1024 bytes")
            KeyValueRow(key: "Offset", value: "0x00001234")
        }
        .frame(width: 300, height: 300)
        .padding()

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testKeyValueRowMultipleVertical() {
        let view = VStack(alignment: .leading, spacing: DS.Spacing.l) {
            KeyValueRow(key: "Type", value: "ftyp", layout: .vertical)
            KeyValueRow(key: "Description", value: "File Type Box", layout: .vertical)
            KeyValueRow(key: "Offset", value: "0x00000000", layout: .vertical)
        }
        .frame(width: 300, height: 400)
        .padding()

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testKeyValueRowMixedLayouts() {
        let view = VStack(alignment: .leading, spacing: DS.Spacing.m) {
            KeyValueRow(key: "Type", value: "ftyp")
            KeyValueRow(key: "Description", value: "A longer description text", layout: .vertical)
            KeyValueRow(key: "Size", value: "1024")
            KeyValueRow(key: "Full Path", value: "/very/long/path/to/file.mp4", layout: .vertical)
        }
        .frame(width: 350, height: 500)
        .padding()

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    // MARK: - Real-World Usage Tests

    func testKeyValueRowInCard() {
        let view = Card(elevation: .medium) {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                SectionHeader(title: "File Properties", showDivider: true)

                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    KeyValueRow(key: "Type", value: "ftyp")
                    KeyValueRow(key: "Size", value: "2.4 MB")
                    KeyValueRow(key: "Modified", value: "2025-10-22")
                }
            }
            .padding()
        }
        .frame(width: 350, height: 300)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testKeyValueRowWithBadges() {
        let view = VStack(alignment: .leading, spacing: DS.Spacing.m) {
            SectionHeader(title: "Metadata", showDivider: true)

            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                HStack {
                    KeyValueRow(key: "Type", value: "VIDEO")
                    Badge(text: "VALID", level: .success)
                }
                KeyValueRow(key: "Size", value: "42.3 MB")
                KeyValueRow(key: "Duration", value: "00:05:23")
            }
        }
        .frame(width: 350, height: 250)
        .padding()

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testKeyValueRowTechnicalData() {
        let view = Card(elevation: .medium) {
            VStack(alignment: .leading, spacing: DS.Spacing.l) {
                SectionHeader(title: "Technical Details", showDivider: true)

                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    KeyValueRow(
                        key: "Box Type",
                        value: "ftyp",
                        layout: .vertical,
                        copyable: true
                    )
                    KeyValueRow(
                        key: "Offset",
                        value: "0x00000000",
                        layout: .vertical,
                        copyable: true
                    )
                    KeyValueRow(
                        key: "Size",
                        value: "32 bytes",
                        layout: .vertical
                    )
                }
            }
            .padding()
        }
        .frame(width: 350, height: 400)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    // MARK: - Comparison Tests

    func testKeyValueRowLayoutComparison() {
        let view = VStack(alignment: .leading, spacing: DS.Spacing.xl) {
            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                Text("Horizontal Layout:")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                KeyValueRow(key: "Type", value: "ftyp")
            }

            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                Text("Vertical Layout:")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                KeyValueRow(key: "Type", value: "ftyp", layout: .vertical)
            }
        }
        .frame(width: 300, height: 300)
        .padding()

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testKeyValueRowDarkModeComparison() {
        let view = VStack(alignment: .leading, spacing: DS.Spacing.m) {
            KeyValueRow(key: "Type", value: "ftyp")
            KeyValueRow(key: "Size", value: "1024 bytes")
            KeyValueRow(
                key: "Description",
                value: "File Type Box",
                layout: .vertical
            )
        }
        .frame(width: 300, height: 300)
        .padding()
        .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }
}
