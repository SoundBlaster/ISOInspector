// swift-tools-version: 6.0
import XCTest
import SwiftUI
import SnapshotTesting
@testable import FoundationUI

/// Snapshot tests for SectionHeader component visual regression testing
///
/// These tests capture visual snapshots of the SectionHeader component in various
/// configurations to prevent unintended visual changes and ensure consistent
/// rendering across platforms, themes, and accessibility settings.
///
/// ## Test Coverage
/// - With and without divider
/// - Light and Dark mode
/// - Dynamic Type sizes (XS, M, XXL)
/// - Long vs short titles
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
final class SectionHeaderSnapshotTests: XCTestCase {

    // MARK: - Basic Tests (Light Mode)

    func testSectionHeaderWithoutDivider() {
        let header = SectionHeader(title: "File Properties")
        let view = header
            .frame(width: 300, height: 100)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testSectionHeaderWithDivider() {
        let header = SectionHeader(title: "File Properties", showDivider: true)
        let view = header
            .frame(width: 300, height: 100)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    // MARK: - Dark Mode Tests

    func testSectionHeaderWithoutDividerDarkMode() {
        let header = SectionHeader(title: "File Properties")
        let view = header
            .frame(width: 300, height: 100)
            .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testSectionHeaderWithDividerDarkMode() {
        let header = SectionHeader(title: "File Properties", showDivider: true)
        let view = header
            .frame(width: 300, height: 100)
            .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    // MARK: - Dynamic Type Tests

    func testSectionHeaderDynamicTypeExtraSmall() {
        let header = SectionHeader(title: "Metadata", showDivider: true)
        let view = header
            .frame(width: 300, height: 100)
            .environment(\.sizeCategory, .xSmall)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testSectionHeaderDynamicTypeMedium() {
        let header = SectionHeader(title: "Metadata", showDivider: true)
        let view = header
            .frame(width: 300, height: 100)
            .environment(\.sizeCategory, .medium)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testSectionHeaderDynamicTypeExtraExtraLarge() {
        let header = SectionHeader(title: "Metadata", showDivider: true)
        let view = header
            .frame(width: 350, height: 150)
            .environment(\.sizeCategory, .accessibilityXxLarge)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    // MARK: - Title Length Variants

    func testSectionHeaderShortTitle() {
        let header = SectionHeader(title: "Info", showDivider: true)
        let view = header
            .frame(width: 300, height: 100)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testSectionHeaderMediumTitle() {
        let header = SectionHeader(title: "Technical Details", showDivider: true)
        let view = header
            .frame(width: 300, height: 100)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testSectionHeaderLongTitle() {
        let header = SectionHeader(title: "This is a much longer section header title", showDivider: true)
        let view = header
            .frame(width: 350, height: 100)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testSectionHeaderWithSpecialCharacters() {
        let header = SectionHeader(title: "Box Structure ⚠️ Warning", showDivider: true)
        let view = header
            .frame(width: 300, height: 100)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    // MARK: - RTL Support Tests

    func testSectionHeaderRTLWithoutDivider() {
        let header = SectionHeader(title: "معلومات الملف")
        let view = header
            .frame(width: 300, height: 100)
            .environment(\.layoutDirection, .rightToLeft)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testSectionHeaderRTLWithDivider() {
        let header = SectionHeader(title: "البيانات الوصفية", showDivider: true)
        let view = header
            .frame(width: 300, height: 100)
            .environment(\.layoutDirection, .rightToLeft)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    // MARK: - Multiple Sections Comparison

    func testSectionHeaderMultipleSections() {
        let view = VStack(alignment: .leading, spacing: DS.Spacing.l) {
            SectionHeader(title: "Basic Information", showDivider: true)
            SectionHeader(title: "Technical Details", showDivider: true)
            SectionHeader(title: "Box Structure", showDivider: true)
        }
        .frame(width: 300, height: 300)
        .padding()

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testSectionHeaderVariousTitles() {
        let view = VStack(alignment: .leading, spacing: DS.Spacing.l) {
            SectionHeader(title: "Short")
            SectionHeader(title: "Medium Length Title", showDivider: true)
            SectionHeader(title: "This is a much longer section header title", showDivider: true)
            SectionHeader(title: "with special ⚠️ chars", showDivider: false)
        }
        .frame(width: 350, height: 300)
        .padding()

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    // MARK: - Real-World Usage Tests

    func testSectionHeaderWithContent() {
        let view = VStack(alignment: .leading, spacing: DS.Spacing.m) {
            SectionHeader(title: "File Properties", showDivider: true)

            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                HStack {
                    Text("Name:")
                        .font(.body)
                    Text("example.mp4")
                        .font(.caption)
                }
                HStack {
                    Text("Size:")
                        .font(.body)
                    Text("42.3 MB")
                        .font(.caption)
                }
            }
        }
        .frame(width: 300, height: 200)
        .padding()

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testSectionHeaderWithBadges() {
        let view = VStack(alignment: .leading, spacing: DS.Spacing.m) {
            SectionHeader(title: "Metadata", showDivider: true)

            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                HStack {
                    Text("Type:")
                        .font(.body)
                    Badge(text: "VIDEO", level: .info)
                }
                HStack {
                    Text("Status:")
                        .font(.body)
                    Badge(text: "VALID", level: .success)
                }
            }
        }
        .frame(width: 300, height: 200)
        .padding()

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testSectionHeaderInScrollView() {
        let view = ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    SectionHeader(title: "Basic Information", showDivider: true)
                    Text("Content for basic information")
                        .font(.body)
                }

                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    SectionHeader(title: "Technical Details", showDivider: true)
                    Text("Content for technical details")
                        .font(.body)
                }

                VStack(alignment: .leading, spacing: DS.Spacing.m) {
                    SectionHeader(title: "Box Structure", showDivider: true)
                    Text("Content for box structure")
                        .font(.body)
                }
            }
            .padding()
        }
        .frame(width: 350, height: 500)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    // MARK: - Comparison Tests

    func testSectionHeaderWithAndWithoutDividerComparison() {
        let view = VStack(alignment: .leading, spacing: DS.Spacing.xl) {
            VStack(alignment: .leading) {
                Text("Without Divider:")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                SectionHeader(title: "Section Title", showDivider: false)
            }

            VStack(alignment: .leading) {
                Text("With Divider:")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                SectionHeader(title: "Section Title", showDivider: true)
            }
        }
        .frame(width: 300, height: 250)
        .padding()

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testSectionHeaderDarkModeComparison() {
        let view = VStack(alignment: .leading, spacing: DS.Spacing.xl) {
            SectionHeader(title: "Box Structure", showDivider: true)
            SectionHeader(title: "Metadata", showDivider: true)
            SectionHeader(title: "File Properties", showDivider: true)
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
