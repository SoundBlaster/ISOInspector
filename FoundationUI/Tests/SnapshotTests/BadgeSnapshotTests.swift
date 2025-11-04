// swift-tools-version: 6.0
import XCTest
import SwiftUI
import SnapshotTesting
@testable import FoundationUI

/// Snapshot tests for Badge component visual regression testing
///
/// These tests capture visual snapshots of the Badge component in various
/// configurations to prevent unintended visual changes and ensure consistent
/// rendering across platforms, themes, and accessibility settings.
///
/// ## Test Coverage
/// - All BadgeLevel variants (info, warning, error, success)
/// - Light and Dark mode
/// - Dynamic Type sizes (XS, M, XXL)
/// - With and without icons
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
///
/// ## Updating Snapshots
/// When intentional visual changes are made:
/// 1. Temporarily set `isRecording = true`
/// 2. Run tests to update baselines
/// 3. Review diff to confirm changes are expected
/// 4. Commit updated snapshots
/// 5. Set `isRecording = false`
final class BadgeSnapshotTests: XCTestCase {

    // MARK: - Light Mode Tests

    func testBadgeInfoLightMode() {
        let badge = Badge(text: "INFO", level: .info)
        let view = badge
            .frame(width: 200, height: 100)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testBadgeWarningLightMode() {
        let badge = Badge(text: "WARNING", level: .warning)
        let view = badge
            .frame(width: 200, height: 100)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testBadgeErrorLightMode() {
        let badge = Badge(text: "ERROR", level: .error)
        let view = badge
            .frame(width: 200, height: 100)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testBadgeSuccessLightMode() {
        let badge = Badge(text: "SUCCESS", level: .success)
        let view = badge
            .frame(width: 200, height: 100)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    // MARK: - Dark Mode Tests

    func testBadgeInfoDarkMode() {
        let badge = Badge(text: "INFO", level: .info)
        let view = badge
            .frame(width: 200, height: 100)
            .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testBadgeWarningDarkMode() {
        let badge = Badge(text: "WARNING", level: .warning)
        let view = badge
            .frame(width: 200, height: 100)
            .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testBadgeErrorDarkMode() {
        let badge = Badge(text: "ERROR", level: .error)
        let view = badge
            .frame(width: 200, height: 100)
            .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testBadgeSuccessDarkMode() {
        let badge = Badge(text: "SUCCESS", level: .success)
        let view = badge
            .frame(width: 200, height: 100)
            .preferredColorScheme(.dark)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    // MARK: - Badge with Icons

    func testBadgeWithIconInfo() {
        let badge = Badge(text: "Information", level: .info, showIcon: true)
        let view = badge
            .frame(width: 250, height: 100)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testBadgeWithIconWarning() {
        let badge = Badge(text: "Warning", level: .warning, showIcon: true)
        let view = badge
            .frame(width: 250, height: 100)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testBadgeWithIconError() {
        let badge = Badge(text: "Error", level: .error, showIcon: true)
        let view = badge
            .frame(width: 250, height: 100)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testBadgeWithIconSuccess() {
        let badge = Badge(text: "Success", level: .success, showIcon: true)
        let view = badge
            .frame(width: 250, height: 100)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    // MARK: - Dynamic Type Tests

    func testBadgeDynamicTypeExtraSmall() {
        let badge = Badge(text: "WARNING", level: .warning)
        let view = badge
            .frame(width: 200, height: 100)
            .environment(\.sizeCategory, .xSmall)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testBadgeDynamicTypeMedium() {
        let badge = Badge(text: "WARNING", level: .warning)
        let view = badge
            .frame(width: 200, height: 100)
            .environment(\.sizeCategory, .medium)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testBadgeDynamicTypeExtraExtraLarge() {
        let badge = Badge(text: "WARNING", level: .warning)
        let view = badge
            .frame(width: 300, height: 150)
            .environment(\.sizeCategory, .accessibilityXxLarge)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    // MARK: - Text Length Variants

    func testBadgeShortText() {
        let badge = Badge(text: "OK", level: .success)
        let view = badge
            .frame(width: 150, height: 100)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testBadgeLongText() {
        let badge = Badge(text: "CRITICAL FAILURE", level: .error)
        let view = badge
            .frame(width: 300, height: 100)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    // MARK: - RTL Support Tests

    func testBadgeRTLLocale() {
        let badge = Badge(text: "تحذير", level: .warning)
        let view = badge
            .frame(width: 200, height: 100)
            .environment(\.layoutDirection, .rightToLeft)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testBadgeWithIconRTL() {
        let badge = Badge(text: "معلومات", level: .info, showIcon: true)
        let view = badge
            .frame(width: 250, height: 100)
            .environment(\.layoutDirection, .rightToLeft)

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    // MARK: - Combined Tests

    func testBadgeAllLevelsComparison() {
        let view = VStack(spacing: DS.Spacing.m) {
            Badge(text: "INFO", level: .info)
            Badge(text: "WARNING", level: .warning)
            Badge(text: "ERROR", level: .error)
            Badge(text: "SUCCESS", level: .success)
        }
        .frame(width: 300, height: 300)
        .padding()

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testBadgeAllLevelsWithIconsComparison() {
        let view = VStack(spacing: DS.Spacing.m) {
            Badge(text: "Information", level: .info, showIcon: true)
            Badge(text: "Warning", level: .warning, showIcon: true)
            Badge(text: "Error", level: .error, showIcon: true)
            Badge(text: "Success", level: .success, showIcon: true)
        }
        .frame(width: 300, height: 300)
        .padding()

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }

    func testBadgeAllLevelsDarkMode() {
        let view = VStack(spacing: DS.Spacing.m) {
            Badge(text: "INFO", level: .info)
            Badge(text: "WARNING", level: .warning)
            Badge(text: "ERROR", level: .error)
            Badge(text: "SUCCESS", level: .success)
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

    // MARK: - Real-World Usage Tests

    func testBadgeInContextWithLabel() {
        let view = HStack {
            Text("Status:")
                .font(.body)
            Badge(text: "VALID", level: .success, showIcon: true)
        }
        .frame(width: 300, height: 100)
        .padding()

        assertSnapshot(
            of: view,
            as: .image(layout: .sizeThatFits),
            record: false
        )
    }
}
